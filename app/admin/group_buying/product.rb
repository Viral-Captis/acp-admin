ActiveAdmin.register GroupBuying::Product do
  menu parent: :group_buying, priority: 4
  actions :all, except: [:show]

  filter :producer,
    as: :select,
    collection: -> { GroupBuying::Producer.order(:name) }
  filter :available
  filter :price

  includes :producer

  index do
    column :name, ->(product) { auto_link product }, sortable: :names
    column :available, ->(product) { status_tag(product.available? ? :yes : :no) }
    column :price, ->(product) { number_to_currency(product.price) }
    actions
  end

  csv do
    column(:name)
    column(:producer) { |p| p.producer.name }
    column(:price) { |p| number_to_currency(p.price) }
    column(:available)
    column(:created_at)
    column(:updated_at)
  end

  form do |f|
    f.inputs t('.details') do
      f.input :producer
      translated_input(f, :names)
      f.input :price, as: :number, step: 0.05, min: -99999.95, max: 99999.95
      f.input :available, as: :boolean
    end
    f.inputs do
      translated_input(f, :descriptions,
        as: :action_text,
        required: false)
    end
    f.actions
  end

  permit_params(
    :producer_id,
    :available,
    :price,
    names: I18n.available_locales,
    descriptions: I18n.available_locales)

  controller do
    include TranslatedCSVFilename
  end

  config.sort_order = 'names_desc'
end
