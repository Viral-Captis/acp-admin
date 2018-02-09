class Delivery < ActiveRecord::Base
  include HasFiscalYearScopes

  default_scope { order(:date) }

  has_one :gribouille
  has_many :baskets
  has_many :basket_contents
  has_and_belongs_to_many :basket_complements,
    after_add: :add_subscribed_baskets_complement!,
    after_remove: :remove_subscribed_baskets_complement!

  scope :past, -> { where('date < ?', Date.current) }
  scope :coming, -> { where('date >= ?', Date.current) }
  scope :between, ->(range) { where(date: range) }

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

  def next?
    self.class.next&.id == id
  end

  def delivered?
    date < Time.current
  end

  def display_name
    "#{date} ##{number}"
  end

  def number
    year_dates.index(date) + 1
  end

  def add_subscribed_baskets_complement!(complement)
    baskets_with_membership_subscribed_to(complement)
      .includes(membership: :memberships_basket_complements)
      .each do |basket|
        membership_basket_complement =
          basket
            .membership
            .memberships_basket_complements
            .find { |mbc| mbc.basket_complement_id == complement.id }
        basket.add_complement!(complement,
          quantity: membership_basket_complement.quantity,
          price: membership_basket_complement.price)
      end
  end

  def remove_subscribed_baskets_complement!(complement)
    baskets_with_membership_subscribed_to(complement).each do |basket|
      basket.remove_complement!(complement)
    end
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

  def year_dates
    Rails.cache.fetch "#{fy_year}_deliveries_dates" do
      Delivery.between(fy_range).pluck(:date)
    end
  end

  def baskets_with_membership_subscribed_to(complement)
    baskets
      .joins(membership: :memberships_basket_complements)
      .where(memberships_basket_complements: { basket_complement_id: complement.id })
  end
end
