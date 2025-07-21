require "pg"
require "db"

class Database
  @pool : DB::Database

  def initialize
    database_url = ENV.fetch("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/rinha_payments")
    unless database_url.includes?("max_pool_size")
      if database_url.includes?("?")
        database_url += "&max_pool_size=20"
      else
        database_url += "?max_pool_size=20"
      end
    end
    @pool = DB.open(database_url)
  end

  def with_connection(&block : DB::Connection ->)
    @pool.using_connection(&block)
  end

  def save_payment(correlation_id : String, amount : Float64, requested_at : Time, processor_type : String, fee_rate : Float64)
    fee_amount = amount * fee_rate
    with_connection do |conn|
      conn.exec(
        "INSERT INTO payments (correlation_id, amount, requested_at, processor_type, fee_rate, fee_amount) VALUES ($1, $2, $3, $4, $5, $6)",
        correlation_id, amount, requested_at, processor_type, fee_rate, fee_amount
      )
    end
  end

  def get_summary(from : Time?, to : Time?)
    with_connection do |conn|
      query = "SELECT processor_type, COUNT(*) as total_requests, SUM(amount) as total_amount FROM payments"
      params = [] of DB::Any

      if from && to
        query += " WHERE requested_at >= $1 AND requested_at <= $2"
        params = [from, to]
      elsif from
        query += " WHERE requested_at >= $1"
        params = [from]
      elsif to
        query += " WHERE requested_at <= $1"
        params = [to]
      end

      query += " GROUP BY processor_type"

      result = Hash(String, Hash(String, Int32 | Float64)).new
      result["default"] = {"totalRequests" => 0, "totalAmount" => 0.0}
      result["fallback"] = {"totalRequests" => 0, "totalAmount" => 0.0}

      conn.query(query, args: params) do |rs|
        rs.each do
          processor_type = rs.read(String)
          total_requests = rs.read(Int64).to_i32
          total_amount = rs.read(PG::Numeric).to_f64
          result[processor_type] = {"totalRequests" => total_requests, "totalAmount" => total_amount}
        end
      end

      result
    end
  end

  def purge_payments
    with_connection do |conn|
      conn.exec("DELETE FROM payments")
    end
  end

end