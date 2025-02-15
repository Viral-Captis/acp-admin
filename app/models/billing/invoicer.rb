module Billing
  class Invoicer
    attr_reader :member, :membership, :invoices, :date, :fy_month

    def self.invoice(member, **attrs)
      invoicer = new(member)
      return unless invoicer.next_date&.today?

      invoicer.invoice(**attrs)
    end

    def self.force_invoice!(member, **attrs)
      new(member).invoice(**attrs)
    end

    def initialize(member, membership = nil, date = nil)
      @member = member
      @membership = membership || [
        member.current_year_membership,
        member.future_membership
      ].compact.select(&:billable?).first
      @invoices = member.invoices.not_canceled.current_year
      @date = date || Date.current
      @fy_month = Current.acp.fy_month_for(@date)
    end

    def billable?
      next_date && current_period.cover?(next_date)
    end

    def next_date
      return unless Current.acp.recurring_billing?

      @next_date ||=
        if membership&.billable?
          n_date =
            if current_period_billed?
              if current_period == periods.last
                next_billing_day
              else
                next_billing_day(beginning_of_next_period)
              end
            elsif Current.acp.billing_starts_after_first_delivery?
              next_billing_day_after_first_billable_delivery
            else
              next_billing_day(membership.started_on)
            end
          n_date >= membership.fiscal_year.end_of_year ? date : n_date
        elsif member.support?
          if annual_fee_billable? || member.missing_acp_shares_number&.positive?
            next_billing_day
          elsif Current.acp.annual_fee?
            next_billing_day(Current.fiscal_year.end_of_year + 1.day)
          end
        end
    end

    def invoice(**attrs)
      return unless billable?

      I18n.with_locale(member.language) do
        invoice = build_invoice(**attrs)
        invoice.save
        invoice
      end
    end

    private

    def build_invoice(**attrs)
      attrs[:date] = date
      if annual_fee_billable?
        attrs[:object_type] = 'AnnualFee'
        attrs[:annual_fee] = member.annual_fee
      end
      if membership&.billable?
        attrs[:object] = membership
        attrs[:membership_amount_fraction] = membership_amount_fraction
        attrs[:memberships_amount_description] = membership_amount_description
      end

      member.invoices.build(attrs)
    end

    def annual_fee_billable?
      member.annual_fee&.positive? &&
        (member.support? || (membership.billable? && !membership.trial_only?)) &&
        invoices.annual_fee.none?
    end

    def membership_amount_fraction
      membership_end_fy_month = Current.acp.fy_month_for(membership.ended_on)
      remaining_months = [membership_end_fy_month, fy_month].max - fy_month + 1
      (remaining_months / period_length_in_months.to_f).ceil
    end

    def membership_amount_description
      fraction_number = (fy_month / period_length_in_months.to_f).ceil
      I18n.t("billing.membership_amount_description.x#{member.billing_year_division}", number: fraction_number)
    end

    def period_length_in_months
      @period_length_in_months ||= 12 / member.billing_year_division
    end

    def current_period
      @current_period ||= periods.find { |d| d.cover?(date) }
    end

    def current_period_billed?
      invoices.where(object: membership).any? { |i|
        current_period.cover?(i.date)
      }
    end

    def beginning_of_next_period
      current_period.max + 1.day
    end

    def periods
      @periods ||= begin
        min = Current.acp.fiscal_year_for(date).beginning_of_year
        member.billing_year_division.times.map do |i|
          old_min = min
          max = min + period_length_in_months.months
          min = max
          old_min...max
        end
      end
    end

    def next_billing_day_after_first_billable_delivery
      baskets = membership.baskets.not_empty
      basket = baskets.not_trial.first || baskets.trial.last || baskets.first
      next_billing_day(basket.delivery.date)
    end

    def next_billing_day(day = date)
      day = [day, date].compact.max.to_date
      day + ((Current.acp.recurring_billing_wday - day.wday) % 7).days
    end
  end
end
