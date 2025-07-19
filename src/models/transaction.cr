require "json"

struct PaymentRequest
  include JSON::Serializable

  property correlationId : String
  property amount : Float64

  def initialize(@correlationId : String, @amount : Float64)
  end
end

struct PaymentSummaryRequest
  property from : Time?
  property to : Time?

  def initialize(@from : Time?, @to : Time?)
  end
end
