# config/initializers/firebase_id_token.rb
FirebaseIdToken.configure do |config|
  # If using a local Redis, this is usually enough
  config.redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))

  # List your project ID(s) here
  config.project_ids = ['ai-score-predict']
end

FirebaseIdToken::Certificates.request!
puts "Firebase certificates successfully updated in Redis."
