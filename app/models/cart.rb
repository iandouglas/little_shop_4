class Cart
  attr_reader :contents

  def initialize(contents)
    @contents = contents || Hash.new(0)
  end

  def total_count
    @contents.sum do |item_id, quantity|
      quantity.to_i
    end
  end

  def add_item(id)
    @contents[id] = (@contents[id].to_i + 1).to_s
  end

  def remove_item(id)
    current_quantity = @contents[id] = (@contents[id].to_i - 1).to_s
    @contents.delete(id) if current_quantity.to_i <= 0
  end

  def clear_item(id)
    @contents.delete(id)
  end

  def total
    @contents.sum do |item, quantity|
      Item.find(item).price * quantity.to_i
    end
  end

  def discounted_total(coupon)
    unused_value = coupon.value
    @contents.sum do |item, quantity|
      item = Item.find(item)
      if item.user_id == coupon.user_id
        if coupon.percent
          item.price * quantity.to_i * coupon.value / 100
        else
          subtotal_for_item = item.price * quantity.to_i
          if subtotal_for_item > unused_value
            new_subtotal = subtotal_for_item - unused_value
            unused_value = 0
          else
            unused_value -= subtotal_for_item
            new_subtotal = 0
          end
          new_subtotal
        end
      else
        item.price * quantity.to_i
      end
    end
  end
end
