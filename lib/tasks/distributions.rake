namespace :distributions do
  desc 'Send next_delivery emails for distributions'
  task deliver_next_delivery: :environment do
    ACP.switch_each! do
      next_delivery = Delivery.next
      if next_delivery && Date.current == (next_delivery.date - 1.day)
        Distribution.with_emails.each do |distribution|
          begin
            DistributionMailer.next_delivery(distribution, next_delivery).deliver_now
          rescue => ex
            ExceptionNotifier.notify_exception(ex,
              data: { distribution: distribution, delivery: next_delivery })
          end
        end
        p "#{Current.acp.name}: Distributions next_delivery sent."
      end
    end
  end
end
