require "http/client"
require "json"

class PaymentProcessor
  DEFAULT_URL = "http://payment-processor-default:8080"
  FALLBACK_URL = "http://payment-processor-fallback:8080"

  DEFAULT_FEE = 0.05
  FALLBACK_FEE = 0.08

  def process_payment(correlation_id : String, amount : Float64, requested_at : Time)
    payload = {
      "correlationId" => correlation_id,
      "amount" => amount,
      "requestedAt" => requested_at.to_rfc3339
    }

    success, processor_type, fee_rate = try_default_processor(payload)
    unless success
      success, processor_type, fee_rate = try_fallback_processor(payload)
    end

    if success
      {success: true, processor_type: processor_type, fee_rate: fee_rate}
    else
      {success: false, processor_type: "", fee_rate: 0.0}
    end
  end

  def check_health(processor : String)
    url = processor == "default" ? DEFAULT_URL : FALLBACK_URL

    begin
      response = HTTP::Client.get("#{url}/payments/service-health",
        headers: HTTP::Headers{"Content-Type" => "application/json"})

      if response.status_code == 200
        data = JSON.parse(response.body)
        {
          "failing" => data["failing"].as_bool,
          "minResponseTime" => data["minResponseTime"].as_i
        }
      else
        {"failing" => true, "minResponseTime" => 9999}
      end
    rescue
      {"failing" => true, "minResponseTime" => 9999}
    end
  end

  private def try_default_processor(payload)
    try_processor(DEFAULT_URL, payload, "default", DEFAULT_FEE)
  end

  private def try_fallback_processor(payload)
    try_processor(FALLBACK_URL, payload, "fallback", FALLBACK_FEE)
  end

  private def try_processor(url : String, payload, processor_type : String, fee_rate : Float64)
    begin
      response = HTTP::Client.post("#{url}/payments",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
        body: payload.to_json)

      if response.status_code >= 200 && response.status_code < 300
        {true, processor_type, fee_rate}
      else
        {false, "", 0.0}
      end
    rescue
      {false, "", 0.0}
    end
  end
end 