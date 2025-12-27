# app/services/sportmonks_prediction_importer.rb
class SportmonksPredictionImporter
  # Common Prediction Type IDs in v3
  VITAL_STATS = {
    expected_goals: 5304,
    ball_possession: 45,
    both_teams_to_score: 192,
    clean_sheets: 194,
    attacks: 43,
    dangerous_attacks: 44,
    shots_on_target: 86
  }.freeze

  PREDICTION_TYPES = VITAL_STATS.values

  def self.sync_all!
    client = SportmonksClient.new

    # Only sync events that are linked and upcoming in the next 48 hours
    Event.where.not(sportmonks_fixture_id: nil)
         .where(kick_off: Time.current..48.hours.from_now)
         .find_each do |event|

      response = client.get_data("predictions/probabilities/fixtures/#{event.sportmonks_fixture_id}")
      next unless response && response['data']

      # Save to a jsonb 'predictions' column on your Event table
      predictions_data = response['data'].each_with_object({}) do |pred, hash|
        type_id = pred['type_id']
        hash[type_id] = pred['predictions']
      end

      event.update(predictions: predictions_data)
      puts "📈 Imported predictions for #{event.name}"
    end
  end
end
