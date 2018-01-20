class HalfdayParticipation < ActiveRecord::Base
  MEMBER_PER_YEAR = 2
  PRICE = 60

  attr_reader :carpooling, :halfday_ids

  belongs_to :halfday
  belongs_to :member
  belongs_to :validator, class_name: 'Admin', optional: true

  scope :validated, -> { where(state: 'validated') }
  scope :rejected, -> { where(state: 'rejected') }
  scope :pending, -> {
    joins(:halfday).merge(Halfday.past).where(state: 'pending')
  }
  scope :coming, -> { joins(:halfday).merge(Halfday.coming) }
  scope :during_year, ->(year) {
    joins(:halfday)
      .where(halfdays: { date: Current.acp.fiscal_year_for(year).range })
  }
  scope :carpooling, ->(date) {
    joins(:halfday).where(halfdays: { date: date }).where.not(carpooling_phone: nil)
  }

  validates :halfday, presence: true, uniqueness: { scope: :member_id }
  validate :participants_limit_must_not_be_reached, unless: :validated_at?

  before_create :set_carpooling_phone
  after_update :send_notifications
  after_save :update_membership_validated_halfday_works

  def coming?
    pending? && halfday.date > Date.current
  end

  def state
    coming? ? 'coming' : super
  end

  %w[validated rejected pending].each do |state|
    define_method "#{state}?" do
      self[:state] == state
    end
  end

  def value
    participants_count
  end

  def carpooling_phone=(phone)
    super PhonyRails.normalize_number(phone, default_country_code: 'CH')
  end

  def carpooling=(carpooling)
    @carpooling = carpooling == '1'
  end

  def carpooling?
    carpooling_phone
  end

  def validate!(validator)
    return if coming?
    update(
      state: 'validated',
      validated_at: Time.current,
      validator: validator,
      rejected_at: nil)
  end

  def reject!(validator)
    return if coming?
    update(
      state: 'rejected',
      rejected_at: Time.current,
      validator: validator,
      validated_at: nil)
  end

  def self.send_coming_mails
    all.joins(:halfday).where(halfdays: { date: 2.days.from_now }).each do |hp|
      begin
        HalfdayMailer.coming(hp).deliver_now
      rescue => ex
        ExceptionNotifier.notify_exception(ex,
          data: { emails: hp.member.emails, member: hp.member })
      end
    end
  end

  private

  def set_carpooling_phone
    if @carpooling
      if carpooling_phone.blank?
        self.carpooling_phone = member.phones_array.first
      end
    else
      self.carpooling_phone = nil
    end
  end

  def update_membership_validated_halfday_works
    membership = member.memberships.during_year(halfday.date.year).first
    membership&.update_validated_halfday_works!
  end

  def send_notifications
    if saved_change_to_validated_at? && validated_at?
      HalfdayMailer.validated(self).deliver_now
    end
    if saved_change_to_rejected_at? && rejected_at?
      HalfdayMailer.rejected(self).deliver_now
    end
  rescue => ex
    ExceptionNotifier.notify_exception(ex,
      data: { emails: member.emails, member: member })
  end

  def participants_limit_must_not_be_reached
    if halfday&.full?
      errors.add(:halfday, 'La demi-journée est déjà complète, merci!')
    end
  end
end
