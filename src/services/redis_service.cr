require "redis"

class RedisService
  @redis : Redis

  def initialize
    redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")
    @redis = Redis.new(url: redis_url)
  end

  def get_health_cache(processor : String)
    key = "health:#{processor}"
    cached = @redis.get(key)
    if cached
      JSON.parse(cached)
    else
      nil
    end
  end

  def set_health_cache(processor : String, data : Hash)
    key = "health:#{processor}"
    @redis.setex(key, 5, data.to_json)
  end

  def can_check_health(processor : String)
    key = "health_check:#{processor}"
    result = @redis.set(key, "1", ex: 5, nx: true)
    result == "OK"
  end

  def get(key : String)
    @redis.get(key)
  end

  def setex(key : String, seconds : Int32, value : String)
    @redis.setex(key, seconds, value)
  end
end 
