namespace :gribouilles do
  desc 'Send all gribouilles to our members'
  task deliver: :environment do
    Apartment::Tenant.switch!('ragedevert')

    next_delivery = Delivery.coming.first
    if next_delivery && Date.current == (next_delivery.date - 1.day)
      gribouille = next_delivery.gribouille
      if gribouille&.deliverable?
        Member.gribouille.each do |member|
          member.emails_array.each do |email|
            begin
              GribouilleMailer.basket(gribouille, member, email).deliver_now
            rescue => ex
              ExceptionNotifier.notify_exception(ex,
                data: { email: email, member: member })
            end
          end
        end
        gribouille.touch(:sent_at)
        p 'Gribouilles sent.'
      end
    end
  end
end
