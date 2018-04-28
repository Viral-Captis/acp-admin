ActiveAdmin.register Delivery do
  menu parent: :other, priority: 10

  scope :past_year
  scope :current_year, default: true
  scope :future_year

  # Workaround for ActionController::UnknownFormat (xlsx download)
  # https://github.com/activeadmin/activeadmin/issues/4945#issuecomment-302729459
  index download_links: -> { params[:action] == 'show' ? [:xlsx, :pdf] : false } do
    column '#', ->(delivery) { auto_link delivery, delivery.number }
    column :date, ->(delivery) { auto_link delivery, l(delivery.date) }
    column :note, ->(delivery) { truncate delivery.note, length: 175 }
    actions defaults: true do |delivery|
      link_to('XLSX', delivery_path(delivery, format: :xlsx), class: 'xlsx_link') +
        link_to('PDF', delivery_path(delivery, format: :pdf), class: 'pdf_link')
    end
  end

  show do |delivery|
    attributes_table do
      row('#') { delivery.number }
      row(:date) { l delivery.date }
      row(:note) { simple_format delivery.note }
    end
  end

  action_item :xlsx, only: :show do
    link_to t('active_admin.page.index.xlsx_recap'), delivery_path(resource, format: :xlsx)
  end

  action_item :pdf, only: :show do
    link_to t('active_admin.page.index.signature_sheets'), delivery_path(resource, format: :pdf)
  end

  form do |f|
    f.inputs do
      f.input :date, as: :datepicker, include_blank: false
      f.input :note
      if BasketComplement.any?
        f.input :basket_complements,
          as: :check_boxes,
          collection: BasketComplement.all,
          hint: true
      end
      f.actions
    end
  end

  controller do
    def show
      respond_to do |format|
        format.html
        format.xlsx do
          xlsx = XLSX::Delivery.new(resource)
          send_data xlsx.data,
            content_type: xlsx.content_type,
            filename: xlsx.filename
        end
        format.pdf do
          pdf = PDF::Delivery.new(resource)
          send_data pdf.render,
            content_type: pdf.content_type,
            filename: pdf.filename
        end
      end
    end

    def update
      super do |success, _failure|
        success.html { redirect_to root_path }
      end
    end
  end

  permit_params :date, :note, basket_complement_ids: []

  config.filters = false
  config.sort_order = 'date_asc'
  config.per_page = 52
end
