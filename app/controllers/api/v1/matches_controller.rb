# app/controllers/api/v1/matches_controller.rb
class Api::V1::MatchesController < ActionController::API
  def index
    matches = BetfairApi.new.fetch_match_odds_by_competition(params[:competition_id])

    # Format data to include probability calculations for the mobile app
    response = matches.map do |match|
      {
        event_name: match[:event_name],
        kick_off: match[:kick_off],
        inplay: match[:inplay],
        market_id: match[:market_id],
        probabilities: ProbabilityCalculator.to_percentages(match[:runners])
      }
    end

    render json: response
  end
end
