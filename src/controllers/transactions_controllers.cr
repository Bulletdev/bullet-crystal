require "json"
require "uuid"
require "../models/client"
require "../models/transaction"

class PaymentsController
  def initialize(@db : Database, @redis : RedisService, @payment_processor : PaymentProcessor)
  end

  def process_payment(context)
    requested_at = Time.utc

    begin
      body = context.request.body.try(&.gets_to_end)
      return bad_request(context) unless body

      payment_request = PaymentRequest.from_json(body)

      return bad_request(context) unless valid_uuid?(payment_request.correlationId)
      return bad_request(context) unless payment_request.amount > 0

      result = @payment_processor.process_payment(
        payment_request.correlationId,
        payment_request.amount,
        requested_at
      )

      if result[:success]
        @db.save_payment(
          payment_request.correlationId,
          payment_request.amount,
          requested_at,
          result[:processor_type].as(String),
          result[:fee_rate].as(Float64)
        )

        context.response.status = HTTP::Status::OK
        context.response.print ""
      else
        context.response.status = HTTP::Status::INTERNAL_SERVER_ERROR
        context.response.print ""
      end
    rescue JSON::ParseException
      bad_request(context)
    rescue
      context.response.status = HTTP::Status::INTERNAL_SERVER_ERROR
      context.response.print ""
    end
  end

  def payments_summary(context)
    begin
      from_param = context.request.query_params["from"]?
      to_param = context.request.query_params["to"]?

      from = from_param ? Time.parse_rfc3339(from_param) : nil
      to = to_param ? Time.parse_rfc3339(to_param) : nil

      cache_key = "summary:#{from_param}:#{to_param}"
      cached = @redis.get(cache_key) rescue nil
      if cached
        context.response.status = HTTP::Status::OK
        context.response.print cached
        return
      end

      summary = @db.get_summary(from, to)
      result = summary.to_json

      begin
        @redis.setex(cache_key, 2, result)
      rescue
        # ignora erro de cache
      end

      context.response.status = HTTP::Status::OK
      context.response.print result
    rescue
      context.response.status = HTTP::Status::BAD_REQUEST
      context.response.print ""
    end
  end

  def purge_payments(context)
    begin
      @db.purge_payments
      context.response.status = HTTP::Status::OK
      context.response.print "{\"result\": \"ok\"}"
    rescue
      context.response.status = HTTP::Status::INTERNAL_SERVER_ERROR
      context.response.print "{\"error\": \"internal error\"}"
    end
  end

  def check_processor_health(processor : String)
    return nil unless @redis.can_check_health(processor)

    cached = @redis.get_health_cache(processor)
    return cached if cached

    health_data = @payment_processor.check_health(processor)
    @redis.set_health_cache(processor, health_data)
    health_data
  end

  private def valid_uuid?(uuid_string : String)
    UUID.parse?(uuid_string) != nil
  end

  private def bad_request(context)
    context.response.status = HTTP::Status::BAD_REQUEST
    context.response.print ""
  end
end 
