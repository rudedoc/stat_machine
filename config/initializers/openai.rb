OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN") { Rails.application.credentials.dig(:openai, :access_token) }
  config.log_errors = true # Highly recommended for debugging
end
