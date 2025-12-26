# config/initializers/firebase_id_token.rb
class FirebaseMemoryRedis
  Entry = Struct.new(:value, :expires_at)

  def initialize
    @store = {}
  end

  def get(key)
    entry = @store[key]
    return unless entry

    if entry.expires_at && Time.now >= entry.expires_at
      @store.delete(key)
      return
    end

    entry.value
  end

  def set(key, value, ex: nil, px: nil, **_opts)
    ttl = ex ? ex.to_f : px ? px.to_f / 1000 : nil
    @store[key] = Entry.new(value, ttl ? Time.now + ttl : nil)
    'OK'
  end

  def setex(key, seconds, value)
    set(key, value, ex: seconds)
  end

  def del(*keys)
    keys.flatten.count { |key| !@store.delete(key).nil? }
  end

  def expire(key, seconds)
    entry = @store[key]
    return false unless entry

    entry.expires_at = Time.now + seconds
    true
  end

  def exists?(key)
    !get(key).nil?
  end
end

redis_url = ENV['REDIS_URL']
redis_backend = if redis_url.present?
  Redis.new(url: redis_url)
else
  FirebaseMemoryRedis.new
end

FirebaseIdToken.configure do |config|
  config.redis = redis_backend
  config.project_ids = ['ai-score-predict']
end

skip_cert_sync = ActiveModel::Type::Boolean.new.cast(ENV['SKIP_FIREBASE_CERT_SYNC'])

unless skip_cert_sync
  begin
    FirebaseIdToken::Certificates.request!
    Rails.logger.info('Firebase certificates successfully updated in Redis.') if defined?(Rails)
  rescue StandardError => e
    Rails.logger.warn("Firebase certificate sync failed: #{e.message}") if defined?(Rails)
  end
else
  Rails.logger.info('Skipping Firebase certificate sync (SKIP_FIREBASE_CERT_SYNC=1).') if defined?(Rails)
end
