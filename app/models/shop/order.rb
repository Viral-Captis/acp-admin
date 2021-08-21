module Shop
  class Order < ActiveRecord::Base
    include NumbersHelper
    include HasState

    self.table_name = 'shop_orders'

    has_states :cart, :pending, :invoiced

    belongs_to :member, optional: false
    belongs_to :delivery, optional: false
    has_many :items, class_name: 'Shop::OrderItem', inverse_of: :order, dependent: :destroy
    has_many :invoices, as: :object
    has_one :invoice, -> { not_canceled }, as: :object

    validates :items, presence: true
    validates :member_id, uniqueness: { scope: :delivery_id }
    validate :unique_items

    before_save :set_amount

    accepts_nested_attributes_for :items,
      reject_if: ->(attrs) { attrs[:quantity].to_i.zero? },
      allow_destroy: true

    def date
      created_at.to_date
    end

    def can_update?
      cart? || pending?
    end

    def can_destroy?
      cart? || pending?
    end

    def can_invoice?
      pending?
    end

    def can_cancel?
      invoiced?
    end

    def invoice!
      invalid_transition(:invoice!) unless can_invoice?

      transaction do
        invoice = create_invoice!
        update!(state: INVOICED_STATE)
        invoice
      end
    end

    def cancel!
      invalid_transition(:cancel!) unless can_cancel?

      transaction do
        invoice.cancel!
        update!(state: PENDING_STATE)
      end
    end

    private

    def set_amount
      self.amount = items.reject(&:marked_for_destruction?).sum(&:amount)
    end

    def unique_items
      used_items = []
      items.each do |item|
        item_sign = [item.product_id, item.product_variant_id]
        if item_sign.in?(used_items)
          item.errors.add(:product_variant_id, :taken)
        end
        used_items << item_sign
      end
    end

    def create_invoice!
      self.invoices.create!(
        send_email: true,
        member: member,
        date: Date.today,
        items_attributes: items.map.with_index { |item, index|
          [index.to_s, {
            description: item.description,
            amount: item.amount
          }]
        }.to_h)
    end
  end
end
