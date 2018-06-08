class Member < ActiveRecord::Base
  include HasState
  include HasEmails
  include HasPhones
  include HasLanguage

  BILLING_INTERVALS = %w[annual quarterly].freeze

  acts_as_paranoid
  uniquify :token, length: 10

  attr_accessor :public_create
  attribute :support_price, :decimal, default: -> { Current.acp.support_price }

  has_states :pending, :waiting, :active, :support, :inactive

  belongs_to :validator, class_name: 'Admin', optional: true
  belongs_to :waiting_basket_size, class_name: 'BasketSize', optional: true
  belongs_to :waiting_distribution, class_name: 'Distribution', optional: true
  has_and_belongs_to_many :waiting_basket_complements, class_name: 'BasketComplement'
  has_many :absences
  has_many :invoices
  has_many :payments
  has_many :current_year_invoices, -> { current_year }, class_name: 'Invoice'
  has_many :halfday_participations
  has_many :memberships
  has_one :first_membership, -> { order(:started_on) }, class_name: 'Membership'
  has_one :current_membership, -> { current }, class_name: 'Membership'
  has_one :future_membership, -> { future }, class_name: 'Membership'
  has_one :current_or_future_membership, -> { current_or_future }, class_name: 'Membership'
  has_one :current_year_membership, -> { current_year }, class_name: 'Membership'
  has_many :baskets, through: :memberships
  has_one :next_basket, through: :current_or_future_membership
  has_many :delivered_baskets,
    through: :memberships,
    source: :delivered_baskets,
    class_name: 'Basket'

  scope :billable, -> { where(state: [ACTIVE_STATE, SUPPORT_STATE]) }
  scope :with_name, ->(name) { where('members.name ILIKE ?', "%#{name}%") }
  scope :with_address, ->(address) { where('members.address ILIKE ?', "%#{address}%") }

  validates_acceptance_of :terms_of_service
  validates :billing_year_division,
    presence: true,
    inclusion: { in: proc { Current.acp.billing_year_divisions } }
  validates :name, presence: true
  validates :emails, presence: true, on: :create
  validates :address, :city, :zip, presence: true, unless: :inactive?
  validates :waiting_basket_size, inclusion: { in: proc { BasketSize.all } }, allow_nil: true, on: :create
  validates :waiting_distribution, inclusion: { in: proc { Distribution.all } }, if: :waiting_basket_size, on: :create
  validates :support_price, numericality: { greater_than: 0, allow_nil: true }

  after_save :update_membership_halfday_works
  after_create :notify_new_inscription_to_admins, if: :public_create

  def newsletter?
    (
      state.in?([WAITING_STATE, ACTIVE_STATE, SUPPORT_STATE]) &&
        newsletter.in?([true, nil])
    ) || newsletter == true
  end

  def billable?
    active? || support?
  end

  def name=(name)
    super name.strip
  end

  def display_address
    address.present? ? "#{address}, #{city} (#{zip})" : '–'
  end

  def display_delivery_address
    if final_delivery_address.present?
      "#{final_delivery_address}, #{final_delivery_city} (#{final_delivery_zip})"
    else
      '–'
    end
  end

  def page_url
    [Current.acp.email_default_host, token].join('/')
  end

  def same_delivery_address?
    display_address == display_delivery_address
  end

  def final_delivery_address
    read_attribute(:delivery_address).presence || address
  end

  def final_delivery_city
    read_attribute(:delivery_city).presence || city
  end

  def final_delivery_zip
    read_attribute(:delivery_zip).presence || zip
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[with_name with_address with_email with_phone]
  end

  def update_active_state!
    if current_or_future_membership
      activate! unless active?
    elsif active?
      deactivate!
    end
  end

  def update_trial_baskets!
    transaction do
      baskets.update_all(trial: false)
      baskets.limit(Current.acp.trial_basket_count).update_all(trial: true)
    end
  end

  def update_absent_baskets!
    transaction do
      baskets.absent.update_all(absent: false)
      absences.each do |absence|
        baskets.between(absence.period).update_all(absent: true)
      end
    end
  end

  def validate!(validator)
    invalid_transition(:validate!) unless pending?

    if waiting_basket_size_id? || waiting_distribution_id?
      self.waiting_started_at ||= Time.current
      self.state = WAITING_STATE
    elsif support_price&.positive?
      self.state = SUPPORT_STATE
    else
      self.state = INACTIVE_STATE
    end
    self.validated_at = Time.current
    self.validator = Time.validator
    save!
  end

  def wait!
    invalid_transition(:wait!) unless support? || inactive?

    self.state = WAITING_STATE
    self.waiting_started_at = Time.current
    self.support_price ||= Current.acp.support_price
    save!
  end

  def activate!
    invalid_transition(:activate!) unless current_or_future_membership
    return if active?

    self.state = ACTIVE_STATE
    self.support_price ||= Current.acp.support_price
    save!
  end

  def deactivate!
    invalid_transition(:deactivate!) if current_or_future_membership

    update!(
      state: INACTIVE_STATE,
      waiting_started_at: nil,
      support_price: nil)
  end

  def send_welcome_email
    return unless active? && emails?
    return if welcome_email_sent_at?

    Email.deliver_now(:member_welcome, self)
    touch(:welcome_email_sent_at)
  end

  def absent?(date)
    absences.any? { |absence| absence.period.include?(date) }
  end

  def membership(year = nil)
    year ||= Current.fiscal_year
    memberships.during_year(year).first
  end

  def to_param
    token
  end

  def can_destroy?
    pending? || waiting?
  end

  def invoices_amount
    invoices.not_canceled.sum(:amount)
  end

  def payments_amount
    payments.sum(:amount)
  end

  def credit_amount
    [payments_amount - invoices_amount, 0].max
  end

  private

  def public_create_and_not_support?
    public_create && !support?
  end

  def baskets_in_trial?
    Current.acp.trial_basket_count.positive? &&
      delivered_baskets.count <= Current.acp.trial_basket_count
  end

  def update_membership_halfday_works
    if saved_change_to_attribute?(:salary_basket?)
      current_year_membership&.update_halfday_works!
    end
  end

  def notify_new_inscription_to_admins
    Admin.notification('new_inscription').find_each do |admin|
      Email.deliver_later(:member_new, admin, self)
    end
  end
end
