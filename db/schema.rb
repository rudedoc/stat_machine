# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_30_201759) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "article_tags", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_tags_on_article_id"
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "feed_source_id", null: false
    t.datetime "published_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["feed_source_id"], name: "index_articles_on_feed_source_id"
  end

  create_table "competitions", force: :cascade do |t|
    t.string "betfair_id", null: false
    t.string "competition_region"
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["betfair_id"], name: "index_competitions_on_betfair_id", unique: true
    t.index ["country_code"], name: "index_competitions_on_country_code"
  end

  create_table "competitors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "exchange_data", default: {}, null: false
    t.bigint "market_id", null: false
    t.string "name", null: false
    t.string "selection_id", null: false
    t.datetime "updated_at", null: false
    t.index ["exchange_data"], name: "index_competitors_on_exchange_data", using: :gin
    t.index ["market_id", "selection_id"], name: "index_competitors_on_market_id_and_selection_id", unique: true
    t.index ["market_id"], name: "index_competitors_on_market_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "betfair_name"
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.string "flag"
    t.string "name", null: false
    t.string "region"
    t.string "subregion"
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_countries_on_country_code", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "betfair_competition_id", null: false
    t.string "betfair_event_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "exchange_data"
    t.integer "football_api_id"
    t.datetime "kick_off", null: false
    t.string "name", null: false
    t.jsonb "predictions"
    t.datetime "updated_at", null: false
    t.index ["betfair_competition_id"], name: "index_events_on_betfair_competition_id"
    t.index ["betfair_event_id"], name: "index_events_on_betfair_event_id", unique: true
    t.index ["football_api_id"], name: "index_events_on_football_api_id"
  end

  create_table "feed_sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feed_url", null: false
    t.datetime "last_checked_at"
    t.datetime "last_imported_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["feed_url"], name: "index_feed_sources_on_feed_url", unique: true
    t.index ["last_checked_at"], name: "index_feed_sources_on_last_checked_at"
  end

  create_table "markets", force: :cascade do |t|
    t.string "betfair_market_id", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.boolean "inplay", default: false, null: false
    t.datetime "last_synced_at"
    t.string "name", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["betfair_market_id"], name: "index_markets_on_betfair_market_id", unique: true
    t.index ["event_id"], name: "index_markets_on_event_id"
  end

  create_table "prices", force: :cascade do |t|
    t.datetime "captured_at", null: false
    t.bigint "competitor_id", null: false
    t.datetime "created_at", null: false
    t.decimal "percentage", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["competitor_id", "captured_at"], name: "index_prices_on_competitor_id_and_captured_at"
    t.index ["competitor_id"], name: "index_prices_on_competitor_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.bigint "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_on_tag_and_taggable", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
  end

  create_table "tags", force: :cascade do |t|
    t.string "aliases", default: [], array: true
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["aliases"], name: "index_tags_on_aliases", using: :gin
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email"
    t.string "firebase_uid", null: false
    t.datetime "last_authenticated_at"
    t.string "photo_url"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["firebase_uid"], name: "index_users_on_firebase_uid", unique: true
  end

  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "articles", "feed_sources"
  add_foreign_key "competitors", "markets"
  add_foreign_key "markets", "events"
  add_foreign_key "prices", "competitors"
  add_foreign_key "taggings", "tags"
end
