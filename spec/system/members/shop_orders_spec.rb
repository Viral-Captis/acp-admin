require 'rails_helper'

describe 'Shop::Order' do
  let(:member) { create(:member, id: 110128) }

  before do
    Capybara.app_host = 'http://membres.ragedevert.test'
    login(member)
  end

  let(:product1) {
    create(:shop_product,
      variants_attributes: {
        '0' => {
          name: '1 kg',
          price: 10,
          stock: 3
        }
      })
  }
  let(:product2) {
    create(:shop_product,
      variants_attributes: {
        '0' => {
          name: '1 kg',
          price: 5
        }
      })
  }

  specify 'remove a cart order item' do
    order = create(:shop_order, :cart,
      member: member,
        items_attributes: {
        '0' => {
          product_id: product1.id,
          product_variant_id: product1.variants.first.id,
          quantity: 1
        },
        '1' => {
          product_id: product2.id,
          product_variant_id: product2.variants.first.id,
          quantity: 1
        }
      })

    visit '/shop/order'
    fill_in "shop_order_items_attributes_0_quantity", with: 3
    fill_in "shop_order_items_attributes_1_quantity", with: 0
    find('input[aria-label="update_order"]', visible: false).click

    expect(order.reload.items.pluck(:product_id, :quantity))
      .to eq([[product1.id, 3]])
  end
end
