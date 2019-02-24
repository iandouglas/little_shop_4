module Helpers
  module Shopping
    def add_item_to_cart(item)
      visit item_path(item)

      click_link 'Add to Cart'

      visit cart_path
    end
  end
end
