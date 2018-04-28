ActiveAdmin.register Membership do
  menu priority: 3

  scope :all
  scope :past
  scope :current, default: true
  scope :future

  filter :member,
    as: :select,
    collection: -> { Member.joins(:memberships).order(:name).distinct }
  filter :basket_size, as: :select, collection: -> { BasketSize.all }
  filter :basket_complements,
    as: :select,
    collection: -> { BasketComplement.all },
    if: :any_basket_complements?
  filter :distribution, as: :select, collection: -> { Distribution.all }
  filter :renew
  filter :started_on
  filter :ended_on

  includes :member, :delivered_baskets

  index do
    column :member, ->(m) { auto_link m.member }
    column :started_on, ->(m) { l m.started_on, format: :number }
    column :ended_on, ->(m) { l m.ended_on, format: :number }
    column halfdays_human_name,
      ->(m) { auto_link m, "#{m.recognized_halfday_works} / #{m.halfday_works}" },
      sortable: 'halfday_works', class: 'col-halfday_works'
    column :baskets_count,
      ->(m) { auto_link m, "#{m.delivered_baskets.size} / #{m.baskets_count}" }
    actions
  end

  csv do
    column(:id)
    column(:name) { |m| m.member.name }
    column(:emails) { |m| m.member.emails_array.join(', ') }
    column(:phones) { |m| m.member.phones_array.map(&:phony_formatted).join(', ') }
    column(:basket_size) { |m| basket_size_description(m, text_only: true) }
    if BasketComplement.any?
      column(:basket_complements) { |m|
        basket_complements_description(m.memberships_basket_complements.includes(:basket_complement),
          text_only: true)
      }
    end
    column(:distribution) { |m| m.distribution&.name }
    column(halfday_scoped_attribute(:halfday_works)) { |m| m.halfday_works }
    column(halfday_scoped_attribute(:missing_halfday_works)) { |m| m.missing_halfday_works }
    column(:started_on)
    column(:ended_on)
  end

  show do |m|
    columns do
      column do
        next_basket = m.next_basket
        panel "#{m.baskets_count} #{Basket.model_name.human(count: m.baskets_count)}" do
          table_for(m.baskets.includes(
            :delivery,
            :basket_size,
            :distribution,
            :complements,
            baskets_basket_complements: :basket_complement
          ),
            row_class: ->(b) { 'next' if b == next_basket },
            class: 'table-baskets'
          ) do |basket|
            column(:delivery)
            column(:description)
            column(:distribution)
            column(class: 'col-status') { |b|
              status_tag(:trial) if b.trial?
              status_tag(:absent) if b.absent?
            }
            column(class: 'col-actions') { |b|
              link_to t('.edit'), edit_basket_path(b), class: 'edit_link'
            }
          end
        end
      end

      column do
        attributes_table do
          row :id
          row :member
          row(:started_on) { l m.started_on }
          row(:ended_on) { l m.ended_on }
          row :renew
        end

        attributes_table title: Membership.human_attribute_name(:description) do
          row(:basket_size) { basket_size_description(m) }
          row :distribution
          if BasketComplement.any?
            row(:memberships_basket_complements) {
              basket_complements_description(
                m.memberships_basket_complements.includes(:basket_complement))
            }
          end
        end

        attributes_table title: halfdays_human_name do
          row(:halfday_works_asked) { m.halfday_works }
          row(:halfday_works_coming) {
            link_to(
              m.member.halfday_participations.coming.during_year(m.fiscal_year).sum(:participants_count),
              halfday_participations_path(scope: :coming, q: {
                member_id_eq: resource.member_id,
                halfday_date_gteq_datetime: resource.fiscal_year.beginning_of_year,
                halfday_date_lteq_datetime: resource.fiscal_year.end_of_year
              }))
          }
          row(:halfday_works_pending) {
            link_to(
              m.member.halfday_participations.pending.during_year(m.fiscal_year).sum(:participants_count),
              halfday_participations_path(scope: :pending, q: {
                member_id_eq: resource.member_id,
                halfday_date_gteq_datetime: resource.fiscal_year.beginning_of_year,
                halfday_date_lteq_datetime: resource.fiscal_year.end_of_year
              }))
          }
          row(:halfday_works_validated) {
            link_to(
              m.member.halfday_participations.validated.during_year(m.fiscal_year).sum(:participants_count),
              halfday_participations_path(scope: :validated, q: {
                member_id_eq: resource.member_id,
                halfday_date_gteq_datetime: resource.fiscal_year.beginning_of_year,
                halfday_date_lteq_datetime: resource.fiscal_year.end_of_year
              }))
          }
          row(:halfday_works_rejected) {
            link_to(
              m.member.halfday_participations.rejected.during_year(m.fiscal_year).sum(:participants_count),
              halfday_participations_path(scope: :rejected, q: {
                member_id_eq: resource.member_id,
                halfday_date_gteq_datetime: resource.fiscal_year.beginning_of_year,
                halfday_date_lteq_datetime: resource.fiscal_year.end_of_year
              }))
          }
          row(:halfday_works_paid) {
            link_to(
              m.member.invoices.not_canceled.halfday_participation_type.during_year(m.fiscal_year).sum(:paid_missing_halfday_works),
              invoices_path(scope: :all, q: {
                member_id_eq: resource.member_id,
                object_type_eq: 'HalfdayParticipation',
                date_gteq: resource.fiscal_year.beginning_of_year,
                date_lteq: resource.fiscal_year.end_of_year
              }))
          }
        end

        attributes_table(
          title: link_to(
            t('.billing'),
            invoices_path(scope: :all, q: {
              member_id_eq: resource.member_id,
              object_type_eq: 'Membership',
              date_gteq: resource.fiscal_year.beginning_of_year,
              date_lteq: resource.fiscal_year.end_of_year
            }))
          ) do
          if m.member.try(:salary_basket?)
            em t('.salary_basket')
          elsif m.baskets_count.zero?
            em t('.no_baskets')
          else
            row(:basket_sizes_price) {
              display_price_description(m.basket_sizes_price, basket_sizes_price_info(m.baskets))
            }
            row(:baskets_annual_price_change) {
              number_to_currency(m.baskets_annual_price_change)
            }
            if m.basket_complements.any?
              row(:basket_complements_price) {
                display_price_description(m.basket_complements_price, basket_complements_price_info(m.baskets))
              }
              row(:basket_complements_annual_price_change) {
                number_to_currency(m.basket_complements_annual_price_change)
              }
            end
            row(:distributions_price) {
              display_price_description(m.distributions_price, distributions_price_info(m.baskets))
            }
            row(halfday_scoped_attribute(:halfday_works_annual_price)) { number_to_currency(m.halfday_works_annual_price) }
            row(:price) { number_to_currency(m.price) }
          end
        end

        active_admin_comments
      end
    end
  end

  form do |f|
    f.inputs Member.model_name.human do
      f.input :member,
        collection: Member.order(:name).map { |d| [d.name, d.id] },
        include_blank: false
    end
    f.inputs Membership.human_attribute_name(:dates) do
      f.input :started_on, as: :datepicker, include_blank: false
      f.input :ended_on, as: :datepicker, include_blank: false
      f.input :renew unless resource.new_record? || resource.current_year?
    end

    unless resource.new_record?
      f.inputs halfdays_human_name do
        f.input :annual_halfday_works,
          label: "#{halfdays_human_name} (#{t('.full_year')})",
          hint: true
        f.input :halfday_works_annual_price, label: true, hint: true
      end
    end

    f.inputs t('.basket_and_distribution') do
      unless resource.new_record?
        em t('.membership_edit_warning')
      end
      f.input :basket_size, include_blank: false, input_html: { class: 'js-reset_price' }
      f.input :basket_price, hint: true
      f.input :baskets_annual_price_change, hint: true
      f.input :basket_quantity
      f.input :distribution, include_blank: false, input_html: { class: 'js-reset_price' }
      f.input :distribution_price, hint: true
      if Current.acp.seasons?
        f.input :seasons,
          as: :check_boxes,
          collection: seasons_collection,
          hint: true
      end

      if BasketComplement.any?
        f.has_many :memberships_basket_complements, allow_destroy: true do |ff|
          ff.input :basket_complement,
            collection: BasketComplement.all,
            prompt: true,
            input_html: { class: 'js-reset_price' }
          ff.input :price, hint: true
          ff.input :quantity
          if Current.acp.seasons?
            ff.input :seasons,
              as: :check_boxes,
              collection: seasons_collection,
              hint: true
          end
        end
        f.input :basket_complements_annual_price_change, hint: true
      end
    end
    f.actions
  end

  permit_params \
    :member_id,
    :basket_size_id, :basket_price, :basket_quantity, :baskets_annual_price_change,
    :distribution_id, :distribution_price,
    :started_on, :ended_on, :renew,
    :halfday_works_annual_price, :annual_halfday_works,
    :basket_complements_annual_price_change,
    seasons: [],
    memberships_basket_complements_attributes: [
      :id, :basket_complement_id,
      :price, :quantity,
      :_destroy,
      seasons: []
    ]

  action_item :trigger_recurring_billing, only: :show, if: -> {
    authorized?(:trigger_recurring_billing, resource) && RecurringBilling.new(resource.member).needed?
  } do
    link_to t('.trigger_recurring_billing'), trigger_recurring_billing_membership_path(resource),
      method: :post,
      title: t('.trigger_recurring_billing_title')
  end

  member_action :trigger_recurring_billing, method: :post do
    RecurringBilling.invoice(resource.member)
    redirect_to invoices_path(q: { member_id_eq: resource.member_id, date_gteq: resource.fiscal_year.beginning_of_year, date_lteq: resource.fiscal_year.end_of_year }, scope: :all, order: :date_asc)
  end

  before_build do |membership|
    fy_range = Delivery.next.fy_range
    membership.member_id ||= params[:member_id]
    membership.basket_size_id ||= params[:basket_size_id]
    membership.distribution_id ||= params[:distribution_id]
    params[:subscribed_basket_complement_ids]&.each do |id|
      membership.memberships_basket_complements.build(basket_complement_id: id)
    end
    membership.started_on ||= params[:started_on] || fy_range.min
    membership.ended_on ||= fy_range.max
  end

  controller do
    def apply_filtering(chain)
      super(chain).distinct
    end
  end

  config.per_page = 30
  config.comments = true
end
