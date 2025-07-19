require "json"

class Payment
  include JSON::Serializable

  property id : String
  property correlation_id : String
  property amount : Float64
  property requested_at : Time
  property processor_type : String
  property fee_rate : Float64
  property fee_amount : Float64

  def initialize(@id : String, @correlation_id : String, @amount : Float64, @requested_at : Time, @processor_type : String, @fee_rate : Float64, @fee_amount : Float64)
  end
end
