# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170221013222) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_roles", force: :cascade do |t|
    t.integer  "account_id", null: false
    t.integer  "role_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "account_roles", ["account_id", "role_id"], name: "index_account_roles_on_account_id_and_role_id", unique: true, using: :btree
  add_index "account_roles", ["account_id"], name: "index_account_roles_on_account_id", using: :btree

  create_table "accounts", force: :cascade do |t|
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.integer  "failed_logins_count",             default: 0
    t.datetime "lock_expires_at"
    t.string   "unlock_token"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.datetime "last_activity_at"
    t.string   "last_login_from_ip_address"
    t.string   "ethereum_wallet"
  end

  add_index "accounts", ["email"], name: "index_accounts_on_email", unique: true, using: :btree
  add_index "accounts", ["last_logout_at", "last_activity_at"], name: "index_accounts_on_last_logout_at_and_last_activity_at", using: :btree
  add_index "accounts", ["remember_me_token"], name: "index_accounts_on_remember_me_token", using: :btree
  add_index "accounts", ["reset_password_token"], name: "index_accounts_on_reset_password_token", using: :btree

  create_table "authentications", force: :cascade do |t|
    t.integer  "account_id",               null: false
    t.string   "provider",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slack_team_name",          null: false
    t.string   "slack_team_id",            null: false
    t.string   "slack_user_id",            null: false
    t.string   "slack_token"
    t.string   "slack_user_name",          null: false
    t.string   "slack_first_name"
    t.string   "slack_last_name"
    t.string   "slack_team_domain"
    t.string   "slack_team_image_34_url"
    t.string   "slack_team_image_132_url"
    t.string   "slack_image_32_url"
    t.jsonb    "oauth_response"
  end

  add_index "authentications", ["account_id"], name: "index_authentications_on_account_id", using: :btree
  add_index "authentications", ["slack_team_id"], name: "index_authentications_on_slack_team_id", using: :btree
  add_index "authentications", ["slack_user_id"], name: "index_authentications_on_slack_user_id", using: :btree

  create_table "award_types", force: :cascade do |t|
    t.integer  "project_id",                          null: false
    t.string   "name",                                null: false
    t.integer  "amount",                              null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "community_awardable", default: false, null: false
  end

  add_index "award_types", ["project_id"], name: "index_award_types_on_project_id", using: :btree

  create_table "awards", force: :cascade do |t|
    t.integer  "issuer_id",                                  null: false
    t.text     "description"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "award_type_id",                              null: false
    t.integer  "authentication_id",                          null: false
    t.string   "ethereum_transaction_address"
    t.text     "proof_id",                                   null: false
    t.string   "proof_link"
    t.decimal  "quantity",                     default: 1.0
    t.integer  "total_amount"
    t.integer  "unit_amount"
  end

  add_index "awards", ["authentication_id"], name: "index_awards_on_authentication_id", using: :btree
  add_index "awards", ["award_type_id"], name: "index_awards_on_award_type_id", using: :btree
  add_index "awards", ["issuer_id"], name: "index_awards_on_issuer_id", using: :btree

  create_table "beta_signups", force: :cascade do |t|
    t.string  "email_address",                  null: false
    t.string  "name"
    t.string  "slack_instance"
    t.boolean "opt_in",         default: false, null: false
    t.jsonb   "oauth_response"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "issuer_id"
    t.integer  "recipient_id"
    t.integer  "amount"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "payments", ["issuer_id"], name: "index_payments_on_issuer_id", using: :btree
  add_index "payments", ["project_id"], name: "index_payments_on_project_id", using: :btree
  add_index "payments", ["recipient_id"], name: "index_payments_on_recipient_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "title",                                                                 null: false
    t.text     "description"
    t.string   "tracker"
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.boolean  "public",                                                default: false, null: false
    t.integer  "owner_account_id",                                                      null: false
    t.string   "slack_team_id",                                                         null: false
    t.string   "image_id"
    t.string   "slack_team_name"
    t.string   "slack_team_domain"
    t.string   "slack_team_image_34_url"
    t.string   "slack_channel"
    t.string   "slack_team_image_132_url"
    t.integer  "maximum_coins",                                         default: 0,     null: false
    t.text     "contributor_agreement_url"
    t.text     "video_url"
    t.string   "ethereum_contract_address"
    t.boolean  "ethereum_enabled",                                      default: false
    t.integer  "payment_type",                                          default: 0
    t.boolean  "exclusive_contributions"
    t.string   "legal_project_owner"
    t.boolean  "require_confidentiality"
    t.decimal  "royalty_percentage",          precision: 16, scale: 13
    t.integer  "maximum_royalties_per_month"
    t.boolean  "license_finalized",                                     default: false, null: false
    t.integer  "denomination",                                          default: 0,     null: false
    t.datetime "revenue_sharing_end_date"
  end

  add_index "projects", ["owner_account_id"], name: "index_projects_on_owner_account_id", using: :btree
  add_index "projects", ["public"], name: "index_projects_on_public", using: :btree
  add_index "projects", ["slack_team_id", "public"], name: "index_projects_on_slack_team_id_and_public", using: :btree

  create_table "revenues", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "currency"
    t.decimal  "amount"
    t.text     "comment"
    t.text     "transaction_reference"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "recorded_by_id"
  end

  add_index "revenues", ["project_id"], name: "index_revenues_on_project_id", using: :btree
  add_index "revenues", ["recorded_by_id"], name: "index_revenues_on_recorded_by_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "key",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
