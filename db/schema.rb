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

ActiveRecord::Schema[8.1].define(version: 2025_12_26_235500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "competitions", force: :cascade do |t|
    t.string "betfair_id", null: false
    t.string "competition_region"
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.integer "market_count", default: 0, null: false
    t.string "name", null: false
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["betfair_id"], name: "index_competitions_on_betfair_id", unique: true
    t.index ["country_code"], name: "index_competitions_on_country_code"
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
end
