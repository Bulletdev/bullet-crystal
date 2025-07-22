require "http/server"
require "json"
require "./services/database"
require "./services/redis_service"
require "./services/payment_processor"
require "./controllers/transactions_controllers"

class App
  @disable_log : Bool

  def initialize
    @db = Database.new
    @redis = RedisService.new
    @payment_processor = PaymentProcessor.new
    @controller = PaymentsController.new(@db, @redis, @payment_processor)
    @disable_log = ENV["DISABLE_LOG"]? == "true"
  end

  def call(context)
    case {context.request.method, context.request.path}
    when {"POST", "/payments"}
      @controller.process_payment(context)
    when {"GET", "/payments-summary"}
      @controller.payments_summary(context)
    when {"POST", "/purge-payments"}
      @controller.purge_payments(context)
    when {"POST", "/admin/purge-payments"}
      @controller.purge_payments(context)
    else
      context.response.status = HTTP::Status::NOT_FOUND
      context.response.print "Not found"
    end
  end
end

port = ENV.fetch("PORT", "4444").to_i
app = App.new

server = HTTP::Server.new do |context|
  context.response.content_type = "application/json"
  app.call(context)
end

puts "Server starting on port #{port}" unless ENV["DISABLE_LOG"]? == "true"
server.bind_tcp "0.0.0.0", port
server.listen