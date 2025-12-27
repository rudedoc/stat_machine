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

ActiveRecord::Schema[8.1].define(version: 2025_12_27_175456) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "competitions", force: :cascade do |t|
    t.string "betfair_id", null: false
    t.string "competition_region"
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "sportmonks_league_id"
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["betfair_id"], name: "index_competitions_on_betfair_id", unique: true
    t.index ["country_code"], name: "index_competitions_on_country_code"
  end

  create_table "competitors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "market_id", null: false
    t.string "name", null: false
    t.string "selection_id", null: false
    t.integer "sportmonks_team_id"
    t.datetime "updated_at", null: false
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
    t.integer "sportmonks_id"
    t.string "subregion"
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_countries_on_country_code", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "betfair_competition_id", null: false
    t.string "betfair_event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "kick_off", null: false
    t.string "name", null: false
    t.jsonb "predictions"
    t.integer "sportmonks_fixture_id"
    t.datetime "updated_at", null: false
    t.index ["betfair_competition_id"], name: "index_events_on_betfair_competition_id"
    t.index ["betfair_event_id"], name: "index_events_on_betfair_event_id", unique: true
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

  add_foreign_key "competitors", "markets"
  add_foreign_key "markets", "events"
  add_foreign_key "prices", "competitors"
end
