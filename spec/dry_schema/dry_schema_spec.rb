require 'json'
require 'dry/schema'
require 'pry'

Dry::Schema.load_extensions(:json_schema)

CustomSchema = Dry::Schema.Params do
  required(:account_cr_detail).hash do
  end
  required(:personal_cr_detail).hash do
  end
  required(:account_id).value(:integer)
  required(:refreshed_at).value(:date_time)
end

RSpec.describe 'Dry::Schema' do
  it 'returns true' do
    hand_written_schema = JSON.parse(File.read('spec/dry_schema/hand_written_schema.json'))

    result = JSON.parse(CustomSchema.json_schema.to_json)

    expect(result).to eq(hand_written_schema)
  end
end
