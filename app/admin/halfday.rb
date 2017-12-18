ActiveAdmin.register Halfday do
  menu parent: 'Autre', priority: 1
  actions :all, except: [:show]

  scope :past
  scope :coming,  default: true

  index do
    column :date, ->(h) { l h.date, format: :medium }, sortable: :date
    column :period, ->(h) { h.period }
    column :place, ->(h) { display_place(h) }
    column :activity, ->(h) { h.activity }
    column :participants_limit, ->(h) { h.participants_limit || '-' }
    actions
  end

  filter :place, as: :select, collection: -> { Halfday.distinct.pluck(:place).sort }
  filter :activity, as: :select, collection: -> { Halfday.distinct.pluck(:activity).sort }
  filter :date

  form do |f|
    f.inputs 'Date et horaire' do
      years_range = Delivery.years_range
      f.input :date,
        start_year: years_range.first,
        end_year: years_range.last,
        include_blank: false
      f.input :start_time, as: :time_select, include_blank: false, minute_step: 30
      f.input :end_time, as: :time_select, include_blank: false, minute_step: 30
    end
    f.inputs 'Lieu et activité' do
      if f.object.new_record?
        f.input :preset_id,
          collection: Halfday::Preset.all + [Halfday::Preset.new(0, 'Autre')],
          include_blank: false
      end
      f.input :place, input_html: { disabled: f.object.use_preset? }
      f.input :place_url, input_html: { disabled: f.object.use_preset? }
      f.input :activity, input_html: { disabled: f.object.use_preset? }
    end
    f.inputs 'Détails' do
      f.input :description, input_html: { rows: 5 }, hint: 'Mauvais exemple: Arrachage de mauvaises herbes, vous verrez ça fait du bien.'
      f.input :participants_limit, as: :number, hint: 'Laisser vide si pas de limite.'
    end
    f.actions
  end

  permit_params *%i[
    date
    start_time
    end_time
    preset_id
    place
    place_url
    activity
    description
    participants_limit
  ]

  controller do
    def build_resource
      super
      resource.preset_id ||= 1
      resource.date ||= Date.current
      resource
    end

    def create
      overwrite_date_of_time_params
      super do |format|
        redirect_to collection_url and return if resource.valid?
      end
    end

    def update
      overwrite_date_of_time_params
      super do |format|
        redirect_to collection_url and return if resource.valid?
      end
    end

    def overwrite_date_of_time_params
      %w[1 2 3].each do |i|
        params['halfday']["start_time(#{i}i)"] = params['halfday']["date(#{i}i)"]
        params['halfday']["end_time(#{i}i)"] = params['halfday']["date(#{i}i)"]
      end
    end
  end

  config.per_page = 25
  config.sort_order = 'date_asc'
end
