# app/controllers/api/v1/events_controller.rb
class Api::V1::EventsController < Api::V1::BaseController
  before_action :set_country
  before_action :set_competition
  before_action :ensure_events!, only: :index
  before_action :set_event, only: :show

  def index
    events = event_scope
    render json: events.map { |event| serialize_event(event) }
  end

  def show
    render json: serialize_event(@event, include_markets: true)
  end

  private

  def set_country
    code = params[:country_id].presence
    @country = Country.find_by!(country_code: code)
  end

  def set_competition
    @competition = @country.competitions.find_by!(betfair_id: params[:competition_id])
  end

  def ensure_events!
    return if event_scope.exists?

    BetfairSnapshotPersister.persist_for_competition!(@competition.betfair_id)
  end

  def set_event
    @event = event_scope.find_by(betfair_event_id: params[:id])
    return if @event.present?

    BetfairSnapshotPersister.persist_for_competition!(@competition.betfair_id)
    @event = event_scope.find_by!(betfair_event_id: params[:id])
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
end
