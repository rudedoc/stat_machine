# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    @hero_metrics = [
      { label: 'Average Edge', value: '+12.4%', caption: 'vs. closing line' },
      { label: 'Win Rate', value: '68%', caption: 'verified last 30 days' },
      { label: 'Sports Covered', value: '27', caption: 'updated hourly' }
    ]

    @feature_cards = [
      {
        title: 'Signal Engine',
        body: 'Ingests 15k+ markets nightly and ranks them by true price vs. sportsbook odds.',
        badge: 'AI Core'
      },
      {
        title: 'Market Radar',
        body: 'Tracks steam moves across major books to verify that every pick still has value.',
        badge: 'Realtime'
      },
      {
        title: 'Confidence Coach',
        body: 'Explains why a projection pops so you can bet with conviction.',
        badge: 'Insights'
      }
    ]

    now = (Time.zone || Time).now
    @prediction_feed = [
      {
        league: 'Premier League',
        match: 'Arsenal vs. Chelsea',
        kickoff: (now + 8.hours).iso8601,
        confidence: 93,
        probability: 0.67,
        edge: '+11.4% value',
        trend: 'Rising'
      },
      {
        league: 'NBA',
        match: 'Warriors @ Nuggets',
        kickoff: (now + 5.hours).iso8601,
        confidence: 88,
        probability: 0.61,
        edge: '+9.7% value',
        trend: 'Stable'
      },
      {
        league: 'Serie A',
        match: 'Inter vs. Juventus',
        kickoff: (now + 26.hours).iso8601,
        confidence: 84,
        probability: 0.58,
        edge: '+7.9% value',
        trend: 'Building'
      },
      {
        league: 'NFL Futures',
        match: 'Eagles season wins',
        kickoff: (now + 14.days).iso8601,
        confidence: 80,
        probability: 0.63,
        edge: '+6.3% value',
        trend: 'Watch'
      }
    ]

    @value_spots = [
      { label: 'Sharp AI Plays', detail: 'Auto-filtered for 8%+ edge across 12 books.' },
      { label: 'Beat The Closing Line', detail: 'Average CLV swing of +18 cents per wager.' },
      { label: 'Personalized Cards', detail: 'Sync sportsbooks to tailor the slip to you.' }
    ]
  end

  def profile
    @profile_props = {
      component: 'profile-shell',
      profile_endpoint: api_v1_profile_path,
      copy: {
        heading: 'Your Stat Machine profile',
        subheading: 'Authenticate with Firebase to sync tickets and personalized insights.'
      }
    }
  end

  def stats
    api = BetfairApi.new

    if params[:country].present? && params[:competition_id].present?
      # Stage 3: Show matches for specific league
      @matches = api.fetch_match_odds_by_competition(params[:competition_id])
    elsif params[:country].present?
      # Stage 2: Show leagues in selected country
      @competitions = api.list_competitions([params[:country]])
    else
      # Stage 1: Show country choices
      @countries = api.list_countries
    end
  end
end
