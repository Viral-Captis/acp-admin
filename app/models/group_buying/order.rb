module GroupBuying
  class Order < ActiveRecord::Base
    include NumbersHelper
    include HasState

    self.table_name = 'group_buying_orders'

    attr_accessor :terms_of_service

    belongs_to :member, optional: false
    belongs_to :delivery, class_name: 'GroupBuying::Delivery', optional: false
    has_many :items, class_name: 'GroupBuying::OrderItem', inverse_of: :order, dependent: :destroy
    has_one :invoice, as: :object, dependent: :destroy

    scope :all_without_canceled, -> { joins(:invoice).merge(Invoice.all_without_canceled) }
    scope :open, -> { joins(:invoice).merge(Invoice.open) }
    scope :closed, -> { joins(:invoice).merge(Invoice.closed) }
    scope :canceled, -> { joins(:invoice).merge(Invoice.canceled) }

    validate :items_must_be_present
    validates_acceptance_of :terms_of_service, if: :terms_of_service_must_be_accepted?

    before_create :set_amount
    before_create :create_invoice
    after_create_commit :notify_admins!

    accepts_nested_attributes_for :items,
      reject_if: ->(attrs) { attrs[:quantity].to_i.zero? }

    def date
      created_at.to_date
    end

    def state
      invoice.state
    end

    def cancel!
      invoice.cancel!
    end

    def canceled?
      invoice.canceled?
    end

    def can_cancel?
      invoice.can_cancel?
    end

    def can_destroy?
      false
    end

    def items_grouped_by_producer
      Product.available
        .joins(:producer).preload("rich_text_description_#{I18n.locale}".to_sym, producer: "rich_text_description_#{I18n.locale}".to_sym)
        .order('group_buying_producers.name')
        .order_by_name
        .map { |product|
          items.find { |i| i.product_id == product.id } ||
            self.items.new(product_id: product.id, quantity: 0)
        }.group_by { |i| i.product.producer }
    end

    private

    def items_must_be_present
      errors.add(:base, :no_items) if items.none?
    end

    # Avoid to have the error on terms_of_service as it breaks
    # the pretty_check_boxes with the field_with_errors wrapper
    def terms_of_service_must_be_accepted?
      return unless Current.acp.group_buying_terms_of_service_url
      return if ActiveRecord::Type::Boolean.new.cast(@terms_of_service)

      true
    end

    def set_amount
      self.amount = items.sum(&:amount)
    end

    def create_invoice
      @invoice = Invoice.create!(
        send_email: true,
        member: member,
        date: date,
        object_type: 'GroupBuying::Order',
        items_attributes: items.map.with_index { |item, index|
          price = cur(item.price, unit: false)
          [index.to_s, {
            description: "#{item.product.name} #{item.quantity}x#{price}",
            amount: item.amount
          }]
        }.to_h)
      self[:id] = @invoice.id
      @invoice.update_columns(object_id: id)
    end

    def notify_admins!
      Admin.notify!(:new_group_buying_order, order: self)
    end
  end
end
