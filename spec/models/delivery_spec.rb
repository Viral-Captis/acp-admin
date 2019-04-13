require 'rails_helper'

describe Delivery do
  it_behaves_like 'bulk_dates_insert'

  it 'returns delivery season' do
    Current.acp.update!(
      summer_month_range_min: 4,
      summer_month_range_max: 9)
    delivery = create(:delivery, date: '12-10-2017')

    expect(delivery.season).to eq 'winter'
  end

  it 'adds basket_complement on subscribed baskets' do
    create(:basket_complement, id: 1, price: 3.2)
    create(:basket_complement, id: 2, price: 4.5)

    membership_1 = create(:membership, subscribed_basket_complement_ids: [1, 2])
    membership_2 = create(:membership, subscribed_basket_complement_ids: [2])
    membership_3 = create(:membership, subscribed_basket_complement_ids: [1])

    delivery = create(:delivery)

    basket1 = create(:basket, membership: membership_1, delivery: delivery)
    basket2 = create(:basket, membership: membership_2, delivery: delivery)
    basket3 = create(:basket, membership: membership_3, delivery: delivery)
    basket3.update!(complement_ids: [1, 2])

    delivery.update!(basket_complement_ids: [1, 2])

    basket1.reload
    expect(basket1.complement_ids).to match_array [1, 2]
    expect(basket1.complements_price).to eq 3.2 + 4.5

    basket2.reload
    expect(basket2.complement_ids).to match_array [2]
    expect(basket2.complements_price).to eq 4.5

    basket3.reload
    expect(basket3.complement_ids).to match_array [1, 2]
    expect(basket3.complements_price).to eq 3.2 + 4.5
  end


  it 'adds basket_complement on subscribed baskets (with season)', freeze: '01-01-2018' do
    Current.acp.update!(
      summer_month_range_min: 4,
      summer_month_range_max: 9)

    create(:basket_complement, id: 1, price: 4.5, name: 'Oeuf')
    membership = create(:membership, memberships_basket_complements_attributes: {
        '0' => { basket_complement_id: 1, price: nil, quantity: 1, seasons: ['summer']  },
      })

    delivery1 = create(:delivery, date: '06-06-2018')
    delivery2 = create(:delivery, date: '06-12-2018')

    basket1 = create(:basket, membership: membership, delivery: delivery1)
    basket2 = create(:basket, membership: membership, delivery: delivery2)

    delivery1.update!(basket_complement_ids: [1])

    basket1.reload
    expect(basket1.complement_ids).to match_array [1]
    expect(basket1.complements_description).to eq 'Oeuf'
    expect(basket1.complements_price).to eq 4.5

    delivery2.update!(basket_complement_ids: [1])

    basket2.reload
    expect(basket2.complement_ids).to match_array [1]
    expect(basket2.complements_description).to be_nil
    expect(basket2.complements_price).to be_zero
  end

  it 'removes basket_complement on subscribed baskets' do
    create(:basket_complement, id: 1, price: 3.2)
    create(:basket_complement, id: 2, price: 4.5)

    membership_1 = create(:membership, subscribed_basket_complement_ids: [1, 2])
    membership_2 = create(:membership, subscribed_basket_complement_ids: [2])
    membership_3 = create(:membership, subscribed_basket_complement_ids: [1])

    delivery = create(:delivery, basket_complement_ids: [1, 2])

    basket1 = create(:basket, membership: membership_1, delivery: delivery)
    basket2 = create(:basket, membership: membership_2, delivery: delivery)
    basket3 = create(:basket, membership: membership_3, delivery: delivery)
    basket3.update!(complement_ids: [1, 2])

    delivery.update!(basket_complement_ids: [1])

    basket1.reload
    expect(basket1.complement_ids).to match_array [1]
    expect(basket1.complements_price).to eq 3.2

    basket2.reload
    expect(basket2.complement_ids).to be_empty
    expect(basket2.complements_price).to be_zero

    basket3.reload
    expect(basket3.complement_ids).to match_array [1, 2]
    expect(basket3.complements_price).to eq 3.2 + 4.5
  end

  it 'adds baskets when a depot is added' do
    depot = create(:depot, deliveries_count: 3)
    delivery1 = depot.deliveries[0]
    delivery2 = depot.deliveries[1]
    delivery3 = depot.deliveries[2]
    depot.update!(delivery_ids: [delivery1.id, delivery3.id])

    membership1 = create(:membership, depot: depot)
    membership2 = create(:membership, depot: depot)

    expect(membership1.deliveries).to eq [delivery1, delivery3]
    expect(membership2.deliveries).to eq membership1.deliveries

    expect {
      delivery2.update!(depot_ids: [depot.id])
    }.to change { Basket.count }.by(2)

    expect(membership1.reload.deliveries).to eq [delivery1, delivery2, delivery3]
    expect(membership2.reload.deliveries).to eq membership1.deliveries

    expect(membership1.baskets[1].delivery).to eq delivery2
    expect(membership2.baskets[1].delivery).to eq delivery2
  end

  it 'adds baskets when a depot is added with membership already with a basket to another depot' do
    depot1 = create(:depot, deliveries_count: 3)
    delivery1 = depot1.deliveries[0]
    delivery2 = depot1.deliveries[1]
    delivery3 = depot1.deliveries[2]
    depot1.update!(delivery_ids: [delivery1.id, delivery3.id])
    depot2 = create(:depot, delivery_ids: [delivery2.id])
    membership = create(:membership, depot: depot1)
    create(:basket, membership: membership, depot: depot2, delivery: delivery2)

    expect(membership.deliveries).to eq [delivery1, delivery2, delivery3]
    expect(membership.baskets.map(&:depot)).to eq [depot1, depot2, depot1]

    expect {
      delivery2.update!(depot_ids: [depot1.id, depot2.id])
    }.to change { Basket.count }.by(0)

    expect(membership.reload.deliveries).to eq [delivery1, delivery2, delivery3]
    expect(membership.reload.baskets.map(&:depot)).to eq [depot1, depot2, depot1]
  end

  it 'removes baskets when a depot is removed' do
    depot = create(:depot, deliveries_count: 3)
    delivery1 = depot.deliveries[0]
    delivery2 = depot.deliveries[1]
    delivery3 = depot.deliveries[2]
    membership1 = create(:membership, depot: depot)
    membership2 = create(:membership, depot: depot)

    expect(membership1.deliveries).to eq [delivery1, delivery2, delivery3]
    expect(membership2.deliveries).to eq membership1.deliveries

    expect {
      delivery2.update!(depot_ids: [])
    }.to change { Basket.with_deleted.count }.by(-2)

    expect(membership1.reload.deliveries).to eq [delivery1, delivery3]
    expect(membership2.reload.deliveries).to eq membership1.deliveries
  end

  it 'updates all fiscal year delivery numbers' do
    first = create(:delivery, date: '2018-02-01')
    last = create(:delivery, date: '2018-11-01')

    expect(first.number).to eq 1
    expect(last.number).to eq 2

    delivery = create(:delivery, date: '2018-06-01')

    expect(first.reload.number).to eq 1
    expect(delivery.reload.number).to eq 2
    expect(last.reload.number).to eq 3

    delivery.update!(date: '2018-01-01')

    expect(delivery.reload.number).to eq 1
    expect(first.reload.number).to eq 2
    expect(last.reload.number).to eq 3
  end
end
