# app/controllers/events_controller.rb
class EventsController < ApplicationController
  before_action :set_competition, only: :index
  before_action :set_event, only: :show

  def index
    @country = Country.find_by(country_code: @competition.country_code)
    @events = event_scope
    if @events.empty?
      BetfairSnapshotPersister.persist_for_competition!(@competition.betfair_id)
      @events = event_scope
    end
  end

  def show
    @competition = Competition.find_by(betfair_id: @event.betfair_competition_id)
    @country = Country.find_by(country_code: @competition&.country_code)
    @markets = @event.markets
    @related_articles = @event.related_articles
  end

  private

  def set_competition
    @competition = Competition.find_by!(betfair_id: params[:competition_id])
  end

  def set_event
    @event = Event
             .includes(:tags, markets: { competitors: %i[tags prices] })
             .find_by!(betfair_event_id: params[:id])
  end

  def event_scope
    Event.upcoming
         .where(betfair_competition_id: @competition.betfair_id)
         .includes(markets: { competitors: :prices })
         .order(:kick_off)
  end

end
