require 'pry'

class User
  @@list = []

  def self.find(id)
    @@list.find { |element| element.id == id }
  end

  def self.add(id:, cash: 0, products: [])
    return false if @@list.find { |element| element.id == id }

    User.new(id: id, cash: cash, products: products).tap do |user|
      @@list << user
    end
  end

  def self.purge
    @@list = []
  end

  attr_reader :id, :products, :cash

  def initialize(id:, products: [], cash: 0)
    @id = id
    @products = products
    @cash = cash
  end

  def already_have_product?(product)
    @products.any? { |product_| product_.id == product.id }
  end

  def can_afford_to_buy_product?(product)
    cash >= product.price
  end

  def buy_product(product)
    @cash -= product.price
    @products << product

    Receipt.new(user: self, product: product)
  end
end

class Product
  @@list = []

  def self.find(id)
    @@list.find { |element| element.id == id }
  end

  def self.add(id:, price: 0)
    return false if @@list.find { |element| element.id == id }

    Product.new(id: id, price: price).tap do |product|
      @@list << product
    end
  end

  def self.purge
    @@list = []
  end

  attr_reader :id, :price

  def initialize(id: rand(100000), price: 0)
    @id = id
    @price = price
  end
end

class Receipt
  attr_reader :user, :product

  def initialize(user:, product:)
    @user = user
    @product = product
  end
end

class SendReceipt
  def self.call(user, receipt)
    if 2 < rand(5)
      false
    else
      true
    end
  end
end

class MyService
  def self.call(user_id, product_id)
    new(user_id, product_id).call
  end

  attr_reader :user_id, :product_id

  def initialize(user_id, product_id)
    @user_id = user_id
    @product_id = product_id
  end

  def call
    user = User.find(user_id)
    if user
      product = Product.find(product_id)
      if product
        if user.already_have_product?(product)
          'User already owns this product'
        else
          if user.can_afford_to_buy_product?(product)
            receipt = user.buy_product(product)

            if SendReceipt.call(user, receipt)
              'The product has been purchased and the receipt is sent to your email'
            else
              'The product has been purchased but we had some problems with sending receipt'
            end
          else
            "User can't afford to buy this product"
          end
        end
      else
        'Product not found'
      end
    else
      'User not registered'
    end
  end
end

RSpec.describe 'Dry Monads' do
  before do
    User.purge
    Product.purge
  end

  context 'when an user is persisted' do
    context 'when a product is persisted' do
      context 'when the user already have a given product' do
        it 'returns an error message' do
          product = Product.add(id: 1)
          User.add(id: 1, products: [product])

          result = MyService.call(1, 1)

          expect(result).to eq('User already owns this product')
        end
      end

      context 'when the user does not have a given product' do
        context 'when the user can afford to buy a given product' do
          context "context when SendReceipt service return true" do
            it 'returns a success message' do
              user = User.add(id: 1, cash: 10)
              product = Product.add(id: 1, price: 5)
              receipt = Receipt.new(user: user, product: product)
              allow(Receipt).to receive(:new).with(user: user, product: product).and_return(receipt)
              allow(SendReceipt).to receive(:call).with(user, receipt).and_return(true)

              result = MyService.call(1, 1)

              expect(result).to eq('The product has been purchased and the receipt is sent to your email')
            end
          end

          context "context when SendReceipt service return false" do
            it 'returns an error message' do
              user = User.add(id: 1, cash: 10)
              product = Product.add(id: 1, price: 5)
              receipt = Receipt.new(user: user, product: product)
              allow(Receipt).to receive(:new).with(user: user, product: product).and_return(receipt)
              allow(SendReceipt).to receive(:call).with(user, receipt).and_return(false)

              result = MyService.call(1, 1)

              expect(result).to eq('The product has been purchased but we had some problems with sending receipt')
            end
          end
        end

        context "when the user can't afford to buy a given product" do
          it 'raises an error message' do
            User.add(id: 1, cash: 2)
            Product.add(id: 1, price: 5)

            result = MyService.call(1, 1)

            expect(result).to eq("User can't afford to buy this product")
          end
        end
      end
    end

    context 'when a product is NOT persisted' do
      it 'returns an error message' do
        User.add(id: 1)

        result = MyService.call(1, 1)

        expect(result).to eq('Product not found')
      end
    end
  end

  context 'when an user is NOT persisted' do
    it 'return an error message' do
      result = MyService.call(1, 1)

      expect(result).to eq('User not registered')
    end
  end
end
