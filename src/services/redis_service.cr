require "redis"

class RedisService
  @redis : Redis

  def initialize
    redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")
    @cache_ttl = ENV["CACHE_TTL"]?.try(&.to_i) || 5
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
    @redis.setex(key, @cache_ttl, data.to_json)
  end

  def can_check_health(processor : String)
    key = "health_check:#{processor}"
    result = @redis.set(key, "1", ex: @cache_ttl, nx: true)
    result == "OK"
  end

  def get(key : String)
    @redis.get(key)
  end

  def setex(key : String, seconds : Int32, value : String)
    @redis.setex(key, seconds, value)
  end
end