require 'json'
require 'dry/schema'
require 'pry'

Dry::Schema.load_extensions(:json_schema)

AccountRateTypeSchema = Dry::Schema.Params do
  optional(:date).maybe(:date)
  optional(:name).maybe(:string)
  optional(:value).maybe(:string)
end

PersonalCrDetailTypeSchema = Dry::Schema.Params do
  required(:client_type_id).value(:integer)
  required(:first_name).maybe(:string)
  required(:id).value(:integer)
  required(:last_name).maybe(:string)
  required(:len_subject_id).maybe(:string)
  required(:middle_name).maybe(:string)
  required(:spor_client_id).maybe(:integer)
  required(:suffix).maybe(:string)

  required(:ratings).array(:hash) do
    required(:label).maybe(:string)
    required(:data).hash do
      required(:value).value([:string, :float, :nil])
      required(:apply_styles).value(:bool)
    end
  end
end

CustomSchema = Dry::Schema.Params do
  required(:account_cr_detail).hash do
    optional(:client_gsd_score).hash(AccountRateTypeSchema)
    optional(:currency_code).value(:string, min_size?: 3, max_size?: 3)
    optional(:fuddy_credit_rank).hash(AccountRateTypeSchema)
    optional(:fuddy_credit).hash(AccountRateTypeSchema)
    optional(:fuddy_name).hash(AccountRateTypeSchema)
    optional(:fuddy_rating).hash(AccountRateTypeSchema)
    optional(:fuddy_risk_rank).hash(AccountRateTypeSchema)
    optional(:fuddy_risk).hash(AccountRateTypeSchema)
    optional(:fuddy_s_rating).hash(AccountRateTypeSchema)
    optional(:market_cap).hash(AccountRateTypeSchema)
    optional(:pdk_bin).hash(AccountRateTypeSchema)
    optional(:pdk_score).hash(AccountRateTypeSchema)
    optional(:rating_firm_name).hash(AccountRateTypeSchema)
    optional(:rating_other).hash(AccountRateTypeSchema)
    optional(:risk_implied_rating).hash(AccountRateTypeSchema)
    optional(:zf_rating).hash(AccountRateTypeSchema)
  end
  required(:personal_cr_detail).hash do
    required(:jep).array(PersonalCrDetailTypeSchema)
    required(:tag8).array(PersonalCrDetailTypeSchema)
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
