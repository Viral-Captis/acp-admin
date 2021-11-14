module ShopHelper
  def next_shop_delivery
    @next_shop_delivery ||= Delivery.shop_open.next
  end

  def live_stock(variant, order)
    return unless variant.stock

    variant_order = order.items.find { |i| i.product_variant_id == variant.id }

    stock = variant.stock
    stock -= variant_order.quantity if variant_order
    stock
  end

  def display_variants(arbre, product)
    arbre.ul do
      product.variants.each do |variant|
        arbre.li do
          arbre.span do
            link_to edit_shop_product_path(product, anchor: :variants) do
              parts = [variant.name]
              parts << cur(variant.price)
              parts << "<b>#{variant.stock}x</b>" unless variant.stock.nil?
              parts.join(', ').html_safe
            end
          end
        end
      end
    end
  end

  def products_collection(products)
    products.includes(:variants).map do |product|
      [product.name, product.id, disabled: product.variants.all?(&:out_of_stock?)]
    end
  end

  def product_variants_collection(products, product_id)
    products.includes(:variants).flat_map do |product|
      product.variants.map do |variant|
        [
          variant.name,
          variant.id,
          data: { product_id: variant.product_id, disabled: !!variant.out_of_stock? },
          disabled: (variant.out_of_stock? || product.id != product_id)
        ]
      end
    end
  end
end
