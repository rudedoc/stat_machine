# app/controllers/events_controller.rb
class EventsController < ApplicationController
  before_action :set_competition, only: :index
  before_action :set_event, only: [:show, :sentiment]

  def index
    @country = Country.find_by(country_code: @competition.country_code)
    @events = event_scope
  end

  def show
    load_event_context
    @markets = @event.markets
  end

  def sentiment
    load_event_context
    @related_articles = @event.related_articles(limit: 12)
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

  def load_event_context
    @competition = Competition.find_by(betfair_id: @event.betfair_competition_id)
    @country = Country.find_by(country_code: @competition&.country_code)
    @tag_sentiments = ArticleTag.sentiment_summary_for(@event.tags.map(&:id))
  end

end
