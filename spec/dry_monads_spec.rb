require 'pry'
require 'dry/monads'

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
  include Dry::Monads[:maybe, :result, :do]

  def self.call(user_id, product_id)
    new(user_id, product_id).call
  end

  attr_reader :user_id, :product_id

  def initialize(user_id, product_id)
    @user_id = user_id
    @product_id = product_id
  end

  def call
    case _call
      when Success() then 'The product has been purchased and the receipt is sent to your email'
      when Failure(:user_not_registered) then 'User not registered'
      when Failure(:product_not_found) then 'Product not found'
      when Failure(:user_already_owns_this_product) then 'User already owns this product'
      when Failure(:cant_afford_to_buy_product) then "User can't afford to buy this product"
      when Failure(:product_purchased_email_not_sent) then 'The product has been purchased but we had some problems with sending receipt'
    end
  end

  private

  def _call
    user = yield find_user(user_id)
    product = yield find_product(product_id)
    yield user_already_have_product?(user, product)
    yield user_can_afford_to_buy_product?(user, product)
    yield send_receipt(user, product)

    Success()
  end

  def find_user(user_id)
    Maybe(User.find(user_id)).to_result(:user_not_registered)
  end

  def find_product(product_id)
    Maybe(Product.find(product_id)).to_result(:product_not_found)
  end

  def user_already_have_product?(user, product)
    if user_already_have_product = user.already_have_product?(product)
      Failure(:user_already_owns_this_product)
    else
      Success(user_already_have_product)
    end
  end

  def user_can_afford_to_buy_product?(user, product)
    if can_afford_to_buy_product = user.can_afford_to_buy_product?(product)
      Success()
    else
      Failure(:cant_afford_to_buy_product)
    end
  end

  def send_receipt(user, product)
    receipt = user.buy_product(product)
    if is_receipt_sent = SendReceipt.call(user, receipt)
      Success()
    else
      Failure(:product_purchased_email_not_sent)
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
