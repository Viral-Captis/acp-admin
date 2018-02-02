ActiveAdmin.register Distribution do
  menu parent: 'Autre', priority: 10

  includes :responsible_member
  index download_links: false do
    column :name
    column :address
    column :zip
    column :city
    if Distribution.pluck(:price).any?(&:positive?)
      column :price, ->(d) { number_to_currency(d.price) }
    end
    column :responsible_member
    actions
  end

  show do |distribution|
    attributes_table title: 'Détails' do
      row :name
      row(:price) { number_to_currency(distribution.price) }
      row :note
    end

    attributes_table title: 'Adresse' do
      row :address_name
      row :address
      row :zip
      row :city
    end

    attributes_table title: 'Contact' do
      row(:emails) { display_emails(distribution.emails_array) }
      row(:phones) { display_phones(distribution.phones_array) }
      row :responsible_member
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :price
      f.input :note, input_html: { rows: 3 }
    end

    f.inputs 'Adresse' do
      f.input :address_name
      f.input :address
      f.input :city
      f.input :zip
    end

    f.inputs 'Contact' do
      f.input :emails
      f.input :phones
      f.input :responsible_member, collection: Member.order(:name)
    end

    f.actions
  end

  permit_params *%i[
    name price note
    address_name address zip city
    emails phones responsible_member_id
  ]

  config.filters = false
  config.per_page = 25
end
