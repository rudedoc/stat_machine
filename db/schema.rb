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

ActiveRecord::Schema[8.1].define(version: 2025_12_27_211015) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookmakers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_bookmakers_on_external_id"
  end

  create_table "countries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id"
    t.jsonb "extra_data"
    t.string "image_path"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_countries_on_external_id"
  end

  create_table "fixture_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "fixture_id", null: false
    t.string "location"
    t.bigint "participant_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.boolean "winner"
    t.index ["fixture_id"], name: "index_fixture_participants_on_fixture_id"
    t.index ["participant_id"], name: "index_fixture_participants_on_participant_id"
  end

  create_table "fixtures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id"
    t.integer "external_venue_id"
    t.bigint "league_id", null: false
    t.string "leg"
    t.string "name"
    t.string "result_info"
    t.integer "round_id"
    t.bigint "season_id", null: false
    t.integer "stage_id"
    t.datetime "starting_at"
    t.integer "state_id"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_fixtures_on_external_id"
    t.index ["league_id"], name: "index_fixtures_on_league_id"
    t.index ["season_id"], name: "index_fixtures_on_season_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.boolean "active"
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.integer "external_id"
    t.string "image_path"
    t.string "name"
    t.string "short_code"
    t.bigint "sport_id", null: false
    t.string "sub_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_leagues_on_country_id"
    t.index ["external_id"], name: "index_leagues_on_external_id"
    t.index ["sport_id"], name: "index_leagues_on_sport_id"
  end

  create_table "markets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "developer_name"
    t.integer "external_id"
    t.boolean "has_winning_calculations"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_markets_on_external_id"
  end

  create_table "participants", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.integer "external_id"
    t.integer "founded"
    t.string "gender"
    t.string "image_path"
    t.string "name"
    t.boolean "placeholder"
    t.string "short_code"
    t.bigint "sport_id", null: false
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_participants_on_country_id"
    t.index ["external_id"], name: "index_participants_on_external_id"
    t.index ["sport_id"], name: "index_participants_on_sport_id"
  end

  create_table "predictions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id"
    t.bigint "fixture_id", null: false
    t.jsonb "predictions"
    t.integer "type_id"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_predictions_on_external_id"
    t.index ["fixture_id"], name: "index_predictions_on_fixture_id"
    t.index ["type_id"], name: "index_predictions_on_type_id"
  end

  create_table "prices", force: :cascade do |t|
    t.bigint "bookmaker_id", null: false
    t.datetime "created_at", null: false
    t.bigint "external_id"
    t.bigint "fixture_id", null: false
    t.string "handicap"
    t.string "label"
    t.bigint "market_id", null: false
    t.string "probability"
    t.boolean "stopped"
    t.string "total"
    t.datetime "updated_at", null: false
    t.string "value"
    t.boolean "winning"
    t.index ["bookmaker_id"], name: "index_prices_on_bookmaker_id"
    t.index ["external_id"], name: "index_prices_on_external_id"
    t.index ["fixture_id"], name: "index_prices_on_fixture_id"
    t.index ["market_id"], name: "index_prices_on_market_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ending_at"
    t.integer "external_id"
    t.boolean "is_current"
    t.bigint "league_id", null: false
    t.string "name"
    t.datetime "starting_at"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_seasons_on_external_id"
    t.index ["league_id"], name: "index_seasons_on_league_id"
  end

  create_table "sports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_sports_on_external_id"
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

  add_foreign_key "fixture_participants", "fixtures"
  add_foreign_key "fixture_participants", "participants"
  add_foreign_key "fixtures", "leagues"
  add_foreign_key "fixtures", "seasons"
  add_foreign_key "leagues", "countries"
  add_foreign_key "leagues", "sports"
  add_foreign_key "participants", "countries"
  add_foreign_key "participants", "sports"
  add_foreign_key "predictions", "fixtures"
  add_foreign_key "prices", "bookmakers"
  add_foreign_key "prices", "fixtures"
  add_foreign_key "prices", "markets"
  add_foreign_key "seasons", "leagues"
end
