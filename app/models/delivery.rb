class Delivery < ActiveRecord::Base
  include HasFiscalYearScopes
  include BulkDatesInsert

  default_scope { order(:date) }

  has_many :baskets
  has_many :basket_contents, dependent: :destroy
  has_and_belongs_to_many :basket_complements,
    after_add: :add_subscribed_baskets_complement!,
    after_remove: :remove_subscribed_baskets_complement!

  scope :past, -> { where('date < ?', Date.current) }
  scope :coming, -> { where('date >= ?', Date.current) }
  scope :between, ->(range) { where(date: range) }

  after_save :update_fiscal_year_numbers
  before_destroy :really_destroy_baskets!

  def self.create_all(count, first_date)
    date = first_date.next_weekday + 2.days # Wed
    count.times do
      create(date: date)
      date = next_date(date)
    end
  end

  def self.next
    coming.first
  end

  def delivered?
    date < Time.current
  end

  def display_name(format: :default)
    "#{I18n.l(date, format: format)} - ##{number}"
  end

  def add_subscribed_baskets_complement!(complement)
    baskets_with_membership_subscribed_to(complement)
      .includes(membership: :memberships_basket_complements)
      .each do |basket|
        mbc = membership_basket_complement_for(basket, complement)
        basket.add_complement!(complement,
          quantity: mbc.season_quantity(self),
          price: mbc.delivery_price)
      end
  end

  def remove_subscribed_baskets_complement!(complement)
    baskets_with_membership_subscribed_to(complement).each do |basket|
      basket.remove_complement!(complement)
    end
  end

  def season
    Current.acp.season_for(date.month)
  end

  def basket_counts
    @basket_counts ||= BasketCounts.new(self)
  end

  private

  def self.next_date(date)
    fy_year = Current.acp.fiscal_year_for(date).year
    if date >= Date.new(fy_year, 5, 18) && date <= Date.new(fy_year, 12, 21)
      date + 1.week
    else
      date + 2.weeks
    end
  end

  def update_fiscal_year_numbers
    return unless date_previously_changed? || date

    self.class.during_year(fiscal_year).each_with_index do |d, i|
      d.update_column(:number, i + 1)
    end
  end

  def membership_basket_complement_for(basket, complement)
    basket
      .membership
      .memberships_basket_complements
      .find { |mbc| mbc.basket_complement_id == complement.id }
  end

  def baskets_with_membership_subscribed_to(complement)
    baskets
      .joins(membership: :memberships_basket_complements)
      .where(memberships_basket_complements: { basket_complement_id: complement.id })
  end

  def really_destroy_baskets!
    baskets.with_deleted.find_each(&:really_destroy!)
  end
end
