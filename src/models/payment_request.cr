require "json"

struct PaymentRequest
  include JSON::Serializable

  property correlationId : String
  property amount : Float64
  property requestedAt : String?

  def initialize(@correlationId : String, @amount : Float64, @requestedAt : String? = nil)
  end
end

struct PaymentProcessorRequest
  include JSON::Serializable
  
  property correlationId : String
  property amount : Float64
  property requestedAt : String

  def initialize(@correlationId : String, @amount : Float64, requested_at : Time)
    @requestedAt = requested_at.to_rfc3339
  end
end