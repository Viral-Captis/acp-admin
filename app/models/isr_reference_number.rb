require 'isr_digit_checker'
require 'rounding'

class ISRReferenceNumber
  include ISRDigitChecker

  ISR_LENGHT_WITHOUT_CHECK_DIGIT = 26
  ISR_AND_CHF_CODE = '01'

  attr_reader :invoice_id, :amount

  def initialize(invoice_id, amount)
    @invoice_id = invoice_id
    @amount = amount
  end

  def full_ref
    "#{amount_ref}>#{ref.delete(' ')}+ #{ccp_ref}>"
  end

  def ref
    ref = "#{isr_identity} #{invoice_ref}"
    ref = check_digit!(ref)
    format_ref(ref)
  end

  def amount_cents
    amount_str.last(2)
  end

  private

  def invoice_ref
    ref = invoice_id.to_s
    ref.prepend('0') while ref.length != invoice_ref_length
    ref
  end

  def invoice_ref_length
    @invoice_ref_length ||=
      ISR_LENGHT_WITHOUT_CHECK_DIGIT - isr_identity.delete(' ').length
  end

  def format_ref(ref)
    ref
      .delete(' ')
      .reverse
      .gsub(/(.{5})(?=.)/, '\1 \2')
      .reverse
  end

  def isr_identity
    Current.acp.isr_identity.delete(' ')
  end

  def ccp_ref
    Current.acp.ccp.delete('-')
  end

  def amount_ref
    ref = ISR_AND_CHF_CODE + amount_str
    check_digit!(ref)
  end

  def amount_str
    rounded_amount = '%.2f' % amount.round_to_five_cents
    rounded_amount.to_s.delete('.').tap do |ref|
      ref.prepend('0') while ref.length != 10
    end
  end
end
