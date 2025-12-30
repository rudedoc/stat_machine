class EntityExtractor
  # We use a strict prompt to force valid JSON output
  SYSTEM_PROMPT = <<~TEXT
    You are a soccer data expert. specific entities from the text.

    Rules:
    1. Extract specific "teams" (clubs or national teams).
    2. Extract specific "persons" (players, managers, referees).
    3. Determine the "sentiment" of the news (positive, negative, neutral).
    4. Ignore generic terms like "the club" or "the striker".
    5. Return ONLY raw JSON. No markdown formatting.

    Output Format:
    {
      "teams": ["Liverpool", "Arsenal"],
      "persons": ["Mohamed Salah", "Mikel Arteta"],
      "sentiment": "neutral"
    }
  TEXT

  def initialize(text)
    @text = text
    @client = OpenAI::Client.new
  end

  def call
    # 1. Validation: Don't waste money on empty/short strings
    return empty_result if @text.blank? || @text.length < 50

    # 2. Call OpenAI
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini", # Fastest and cheapest for this task
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: @text.truncate(2000) } # Truncate to save costs
        ],
        temperature: 0.1, # Low temperature = more deterministic/factual
        response_format: { type: "json_object" } # JSON Mode on
      }
    )

    # 3. Parse Response
    content = response.dig("choices", 0, "message", "content")
    JSON.parse(content)

  rescue JSON::ParserError => e
    Rails.logger.error("EntityExtractor JSON Error: #{e.message}")
    empty_result
  rescue Faraday::Error => e
    Rails.logger.error("EntityExtractor API Error: #{e.message}")
    empty_result
  end

  private

  def empty_result
    { "teams" => [], "persons" => [], "sentiment" => "neutral" }
  end
end
