# app/controllers/api/v1/events_controller.rb
class Api::V1::EventsController < Api::V1::BaseController
  before_action :authenticate_firebase_user, only: :predictions
  before_action :set_country
  before_action :set_competition
  before_action :set_event, only: [:show, :predictions]

  def index
    events = event_scope
    render json: events.map { |event| serialize_event(event) }
  end

  def show
    render json: serialize_event(@event, include_markets: true)
  end

  def predictions
    ensure_sportmonks_link!

    if @event.sportmonks_fixture_id.blank?
      render json: {
        error: 'unlinked_fixture',
        message: 'This event has not been linked to a Sportmonks fixture yet.'
      }, status: :unprocessable_entity and return
    end

    profile = SportmonksClient.new.fixture_prediction_profile(@event.sportmonks_fixture_id)
    if profile.blank?
      render json: {
        error: 'prediction_unavailable',
        message: 'Prediction data is unavailable for the linked fixture at this time.'
      }, status: :bad_gateway and return
    end

    render json: serialize_prediction_profile(profile)
  end

  private

  def set_country
    code = params[:country_id].presence
    @country = Country.find_by!(country_code: code)
  end

  def set_competition
    @competition = @country.competitions.find_by!(betfair_id: params[:competition_id])
  end

  def set_event
    @event = event_scope.find_by(betfair_event_id: params[:id])
  end

  def event_scope
    Event.where(betfair_competition_id: @competition.betfair_id)
         .includes(markets: { competitors: :prices })
         .order(:kick_off)
  end

  def serialize_event(event, include_markets: false)
    data = {
      betfair_event_id: event.betfair_event_id,
      event_name: event.name,
      kick_off: event.kick_off,
      betfair_competition_id: event.betfair_competition_id,
      country_code: event.competition&.country_code || @country.country_code
    }

    primary_market = event.primary_market
    data[:primary_market] = serialize_market(primary_market, include_competitors: false) if primary_market

    if include_markets
      data[:markets] = event.markets.map { |market| serialize_market(market, include_competitors: true) }.compact
    end

    data
  end

  def serialize_market(market, include_competitors: false)
    return unless market

    payload = {
      betfair_market_id: market.betfair_market_id,
      name: market.name,
      status: market.status,
      inplay: market.inplay,
      last_synced_at: market.last_synced_at,
      probabilities: market.latest_probabilities
    }

    if include_competitors
      payload[:competitors] = market.competitors.map { |competitor| serialize_competitor(competitor) }
    end

    payload
  end

  def serialize_competitor(competitor)
    price = competitor.latest_price
    {
      selection_id: competitor.selection_id,
      name: competitor.name,
      latest_percentage: price&.percentage&.to_f,
      last_captured_at: price&.captured_at
    }
  end

  def serialize_prediction_profile(profile)
    {
      fixture_id: profile[:fixture_id],
      event_name: profile[:name],
      kick_off: profile[:kick_off],
      league: profile[:league],
      season: profile[:season],
      predictions: profile[:predictions],
      teams: profile[:teams]
    }
  end

  def ensure_sportmonks_link!
    return if @event.sportmonks_fixture_id.present?

    SportmonksLinker.link_event!(@event)
    @event.reload
  end
end
