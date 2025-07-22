require "http/client"
require "json"
require "../models/payment_request"  

class PaymentProcessor
  DEFAULT_URL = "http://payment-processor-default:8080"
  FALLBACK_URL = "http://payment-processor-fallback:8080"

  DEFAULT_FEE = 0.05
  FALLBACK_FEE = 0.08

  @timeout_default : Int32
  @timeout_fallback : Int32
  @retry_api_default : Int32
  @http_client_worker : Int32

  def initialize
    @timeout_default = ENV["TIMEOUT_DEFAULT"]?.try(&.to_i) || 180
    @timeout_fallback = ENV["TIMEOUT_FALLBACK"]?.try(&.to_i) || 95
    @retry_api_default = ENV["RETRY_API_DEFAULT"]?.try(&.to_i) || 3
    @http_client_worker = ENV["HTTP_CLIENT_WORKER"]?.try(&.to_i) || 10
  end

  def process_payment(correlation_id : String, amount : Float64, requested_at : Time)
    # Usa a struct para criar o payload
    request = PaymentProcessorRequest.new(correlation_id, amount, requested_at)
    payload = request.to_json

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
    timeout = processor == "default" ? @timeout_default : @timeout_fallback

    begin
      response = make_request("GET", "#{url}/payments/service-health", nil, timeout)

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

  private def try_default_processor(payload : String)
    try_processor(DEFAULT_URL, payload, "default", DEFAULT_FEE, @timeout_default)
  end

  private def try_fallback_processor(payload : String)
    try_processor(FALLBACK_URL, payload, "fallback", FALLBACK_FEE, @timeout_fallback)
  end

  private def try_processor(url : String, payload : String, processor_type : String, fee_rate : Float64, timeout : Int32)
    retries = processor_type == "default" ? @retry_api_default : 1
    
    retries.times do |attempt|
      begin
        response = make_request("POST", "#{url}/payments", payload, timeout)

        if response.status_code >= 200 && response.status_code < 300
          return {true, processor_type, fee_rate}
        end
      rescue
        next if attempt < retries - 1
      end
    end

    {false, "", 0.0}
  end

  private def make_request(method : String, url : String, body : String?, timeout : Int32)
    uri = URI.parse(url)
    client = HTTP::Client.new(uri.host.not_nil!, uri.port || 8080)
    client.read_timeout = timeout.seconds
    client.connect_timeout = (timeout / 2).seconds

    begin
      case method
      when "GET"
        response = client.get(uri.path || "/", headers: HTTP::Headers{"Content-Type" => "application/json"})
      when "POST"
        response = client.post(uri.path || "/", 
          headers: HTTP::Headers{"Content-Type" => "application/json"},
          body: body)
      else
        raise "Unsupported method: #{method}"
      end
      
      response
    ensure
      client.close
    end
  end
end