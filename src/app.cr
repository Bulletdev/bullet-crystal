require "http/server"
require "json"
require "./services/database"
require "./services/redis_service"
require "./services/payment_processor"
require "./controllers/transactions_controllers"

class App
  def initialize
    @db = Database.new
    @redis = RedisService.new
    @payment_processor = PaymentProcessor.new
    @controller = PaymentsController.new(@db, @redis, @payment_processor)
  end

  def call(context)
    case {context.request.method, context.request.path}
    when {"POST", "/payments"}
      @controller.process_payment(context)
    when {"GET", "/payments-summary"}
      @controller.payments_summary(context)
    when {"POST", "/purge-payments"}
      @controller.purge_payments(context)
    else
      context.response.status = HTTP::Status::NOT_FOUND
      context.response.print ""
    end
  end
end

port = ENV.fetch("PORT", "3000").to_i
app = App.new

server = HTTP::Server.new do |context|
  context.response.content_type = "application/json"
  app.call(context)
end

puts "Server starting on port #{port}"
server.bind_tcp port
server.listen
