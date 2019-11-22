ActiveAdmin.register GroupBuying::Delivery do
  menu parent: :group_buying, priority: 2

  scope :all
  scope :coming, default: true
  scope :past

  filter :date
  filter :during_year,
    as: :select,
    collection: -> { fiscal_years_collection }

  includes :orders, :orders_without_canceled

  index download_links: false do
    column '#', ->(delivery) { auto_link delivery, delivery.id }
    column :date, ->(delivery) { auto_link delivery, l(delivery.date) }
    column :orderable_until, ->(delivery) { auto_link delivery, l(delivery.orderable_until) }
    column :orders, ->(delivery) {
      link_to(delivery.orders_without_canceled.size, group_buying_orders_path(q: { delivery_id_eq: delivery.id }))
    }
    actions
  end

  show do |delivery|
    columns do
      column do
        GroupBuying::DeliveryTotal.all_by_producer(delivery).each do |producer, items|
          panel producer.name do
            table_for items, class: 'totals table-group_buying_orders', i18n: GroupBuying::OrderItem do
              column(:product) { |i| auto_link i.product }
              column(:quantity)
              column(:amount) { |i| number_to_currency(i.amount) }
            end
          end
        end
      end
      column do
        attributes_table do
          row :id
          row(:date) { l(delivery.date, date_format: :long) }
          row(:orderable_until) { l(delivery.orderable_until, date_format: :long) }
          row(:orders) {
            link_to(delivery.orders_without_canceled.count, group_buying_orders_path(q: { delivery_id_eq: delivery.id }))
          }
          row(:canceled_orders) {
            link_to(delivery.orders.canceled.count, group_buying_orders_path(q: { delivery_id_eq: delivery.id }, scope: 'canceled'))
          }
        end
        panel GroupBuying::Delivery.human_attribute_name(:description) do
          delivery.description
        end
        active_admin_comments
      end
    end
  end

  form do |f|
    f.inputs t('.details') do
      f.input :date, as: :datepicker, required: true
      f.input :orderable_until, as: :datepicker, required: true
    end
    f.inputs do
      translated_input(f, :descriptions, as: :action_text)
    end
    f.actions
  end

  permit_params(
    :date,
    :orderable_until,
    descriptions: I18n.available_locales)

  config.sort_order = 'date_asc'
end
