class Payment < ActiveRecord::Base
  acts_as_paranoid

  default_scope { order(:date) }

  belongs_to :member
  belongs_to :invoice, optional: true

  scope :current_year, -> { during_year(Date.current.year) }
  scope :during_year, ->(year) {
    date = Date.new(year)
    where('date >= ? AND date <= ?', date.beginning_of_year, date.end_of_year)
  }
  scope :isr, -> { where.not(isr_data: nil) }
  scope :manual, -> { where(isr_data: nil) }
  scope :invoice_id_eq, ->(id) { where(invoice_id: id) }

  validates :date, presence: true
  validates :amount, numericality: { greater_than: 0.0 }, presence: true
  validates :isr_data, uniqueness: true, allow_nil: true

  after_create :update_invoices_balance

  def self.update_invoices_balance!(member)
    invoices = member.invoices.not_canceled.order(:date)
    last_invoice = invoices.last
    amount = member.payments.sum(&:amount)

    transaction do
      member.invoices.update_all(balance: 0)
      invoices.each do |invoice|
        if amount.positive?
          balance = invoice == last_invoice ? amount : [amount, invoice.amount].min
          invoice.update_column(:balance, balance)
          amount -= balance
        end
        invoice.close_or_open!
      end
    end
  end

  def invoice=(invoice)
    self.member = invoice.member
    super
  end

  def type
    isr_data? ? 'isr' : 'manual'
  end

  def isr?
    type == 'isr'
  end

  def manual?
    type == 'manual'
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[invoice_id_eq]
  end

  def can_destroy?
    manual?
  end

  private

  def update_invoices_balance
    self.class.update_invoices_balance!(member.reload)
  end
end
