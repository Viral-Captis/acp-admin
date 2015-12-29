class InvoiceOverdueNoticer
  DAYS_DELAY = 35.days.freeze
  attr_reader :invoice

  def self.perform(*args)
    new(*args).perform
  end

  def initialize(invoice)
    @invoice = invoice
  end

  def perform
    return unless invoice.status == :open && last_sent_at < DAYS_DELAY.ago

    @invoice.increment(:overdue_notices_count)
    @invoice.overdue_notice_sent_at = Time.zone.now
    @invoice.save!

    InvoiceMailer.overdue_notice(invoice).deliver_later
  end

  def last_sent_at
    invoice.overdue_notice_sent_at || invoice.sent_at
  end
end
