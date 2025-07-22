require "http/client"
require "json"
require "../models/payment_request"

class PaymentProcessor
  DEFAULT_URL = "http://payment-processor-default:8080"
  FALLBACK_URL = "http://payment-processor-fallback:8080"

  DEFAULT_FEE = 0.05
  FALLBACK_FEE = 0.15  

  @timeout_default : Int32
  @timeout_fallback : Int32
  @retry_api_default : Int32
  @disable_log : Bool

  def initialize
    @timeout_default = ENV["TIMEOUT_DEFAULT"]?.try(&.to_i) || 180
    @timeout_fallback = ENV["TIMEOUT_FALLBACK"]?.try(&.to_i) || 95
    @retry_api_default = ENV["RETRY_API_DEFAULT"]?.try(&.to_i) || 3
    @disable_log = ENV["DISABLE_LOG"]? == "true"
  end

  def process_payment(correlation_id : String, amount : Float64, requested_at : Time)
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
      uri = URI.parse("#{url}/payments/service-health")
      client = HTTP::Client.new(uri.host.not_nil!, uri.port)
      client.read_timeout = timeout.seconds
      client.connect_timeout = (timeout / 2).seconds

      response = client.get("/payments/service-health",
        headers: HTTP::Headers{"Content-Type" => "application/json"})

      if response.status_code == 200
        data = JSON.parse(response.body)
        result = {
          "failing" => data["failing"].as_bool,
          "minResponseTime" => data["minResponseTime"].as_i
        }
      else
        result = {"failing" => true, "minResponseTime" => 9999}
      end
      
      client.close
      result
    rescue ex
      puts "Health check error for #{processor}: #{ex.message}" unless @disable_log
      {"failing" => true, "minResponseTime" => 9999}
    end
  end

  private def try_default_processor(payload : String)
    try_processor_with_retry(DEFAULT_URL, payload, "default", DEFAULT_FEE, @retry_api_default, @timeout_default)
  end

  private def try_fallback_processor(payload : String)
    try_processor_with_retry(FALLBACK_URL, payload, "fallback", FALLBACK_FEE, 1, @timeout_fallback)
  end

  private def try_processor_with_retry(url : String, payload : String, processor_type : String, fee_rate : Float64, retries : Int32, timeout : Int32)
    uri = URI.parse(url)
    retries.times do |attempt|
      begin
        client = HTTP::Client.new(uri.host.not_nil!, uri.port)
        client.read_timeout = timeout.seconds
        client.connect_timeout = (timeout / 2).seconds

        response = client.post("/payments",
          headers: HTTP::Headers{"Content-Type" => "application/json"},
          body: payload)

        if response.status_code >= 200 && response.status_code < 300
          puts "#{processor_type} processor success on attempt #{attempt + 1}" unless @disable_log
          client.close
          return {true, processor_type, fee_rate}
        else
          puts "#{processor_type} processor HTTP error (attempt #{attempt + 1}): #{response.status_code} - #{response.body}" unless @disable_log
        end
        client.close
      rescue ex
        puts "#{processor_type} processor error (attempt #{attempt + 1}): #{ex.message}" unless @disable_log
        sleep(0.1) if attempt < retries - 1
      end
    end

    {false, "", 0.0}
  end
end