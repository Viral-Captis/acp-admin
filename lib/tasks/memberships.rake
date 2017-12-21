namespace :memberships do
  desc 'Create next year memprships'
  task seed_next_year: :environment do
    Member.renew_membership.each do |member|
      ActiveRecord.transition do
        member.memberships.create!(
          distribution: member.distribution,
          basket_size: member.basket_size,
          started_on: (Date.current + 1.year).beginning_of_year,
          ended_on: (Date.current + 1.year).end_of_year,
          annual_halfday_works: member.current_membership&.annual_halfday_works || HalfdayParticipation::MEMBER_PER_YEAR,
          halfday_works_annual_price: member.current_membership&.halfday_works_annual_price || 0)
        member.update!( # out of waiting queue
          waiting_started_at: nil,
          waiting_basket_size_id: nil,
          waiting_distribution_id: nil)
      end
    end
    # Check custom annual_halfday_works/halfday_works_annual_price after:
    # Membership.future.select { |m| m.halfday_works_annual_price != 0 || m.annual_halfday_works != 2 }.map(&:id).sort
  end
end
