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

ActiveRecord::Schema.define(version: 20171217190730) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "absences", id: :serial, force: :cascade do |t|
    t.integer "member_id"
    t.date "started_on"
    t.date "ended_on"
    t.text "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["member_id"], name: "index_absences_on_member_id"
  end

  create_table "active_admin_comments", id: :serial, force: :cascade do |t|
    t.string "namespace", limit: 255
    t.text "body"
    t.string "resource_id", limit: 255, null: false
    t.string "resource_type", limit: 255, null: false
    t.integer "author_id"
    t.string "author_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admins", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "rights", default: "standard", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "basket_contents", id: :serial, force: :cascade do |t|
    t.integer "delivery_id", null: false
    t.integer "vegetable_id", null: false
    t.decimal "quantity", precision: 8, scale: 2, null: false
    t.string "unit", null: false
    t.decimal "small_basket_quantity", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "big_basket_quantity", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "lost_quantity", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "small_baskets_count", default: 0, null: false
    t.integer "big_baskets_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_basket_contents_on_delivery_id"
    t.index ["vegetable_id", "delivery_id"], name: "index_basket_contents_on_vegetable_id_and_delivery_id", unique: true
    t.index ["vegetable_id"], name: "index_basket_contents_on_vegetable_id"
  end

  create_table "basket_contents_distributions", id: false, force: :cascade do |t|
    t.integer "basket_content_id", null: false
    t.integer "distribution_id", null: false
    t.index ["basket_content_id", "distribution_id"], name: "index_basket_contents_distributions_unique", unique: true
    t.index ["basket_content_id"], name: "index_basket_contents_distributions_on_basket_content_id"
    t.index ["distribution_id"], name: "index_basket_contents_distributions_on_distribution_id"
  end

  create_table "basket_sizes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.decimal "annual_price", precision: 8, scale: 2, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deliveries", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "note"
    t.index ["date"], name: "index_deliveries_on_date"
  end

  create_table "distributions", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "address", limit: 255
    t.string "zip", limit: 255
    t.string "city", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal "basket_price", precision: 8, scale: 2, null: false
    t.string "emails"
  end

  create_table "gribouilles", id: :serial, force: :cascade do |t|
    t.integer "delivery_id", null: false
    t.text "header"
    t.text "basket_content"
    t.text "fields_echo"
    t.text "events"
    t.text "footer"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.oid "attachment_0"
    t.string "attachment_name_0"
    t.string "attachment_mime_type_0"
    t.oid "attachment_1"
    t.string "attachment_name_1"
    t.string "attachment_mime_type_1"
    t.oid "attachment_2"
    t.string "attachment_name_2"
    t.string "attachment_mime_type_2"
    t.index ["delivery_id"], name: "index_gribouilles_on_delivery_id"
  end

  create_table "halfday_participations", id: :serial, force: :cascade do |t|
    t.integer "halfday_id", null: false
    t.integer "member_id", null: false
    t.integer "validator_id"
    t.string "state", default: "pending", null: false
    t.datetime "validated_at"
    t.datetime "rejected_at"
    t.integer "participants_count", default: 1, null: false
    t.string "carpooling_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["halfday_id"], name: "index_halfday_participations_on_halfday_id"
    t.index ["member_id"], name: "index_halfday_participations_on_member_id"
    t.index ["validator_id"], name: "index_halfday_participations_on_validator_id"
  end

  create_table "halfdays", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.string "place", null: false
    t.string "place_url"
    t.string "activity", null: false
    t.text "description"
    t.integer "participants_limit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_halfdays_on_date"
    t.index ["start_time"], name: "index_halfdays_on_start_time"
  end

  create_table "invoices", id: :serial, force: :cascade do |t|
    t.integer "member_id", null: false
    t.date "date", null: false
    t.decimal "balance", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.decimal "support_amount", precision: 8, scale: 2
    t.string "memberships_amount_description"
    t.decimal "memberships_amount", precision: 8, scale: 2
    t.json "memberships_amounts_data"
    t.decimal "remaining_memberships_amount", precision: 8, scale: 2
    t.decimal "paid_memberships_amount", precision: 8, scale: 2
    t.json "isr_balance_data", default: {}, null: false
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.oid "pdf"
    t.decimal "isr_balance", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "manual_balance", precision: 8, scale: 2, default: "0.0", null: false
    t.text "note"
    t.string "member_billing_interval", null: false
    t.integer "overdue_notices_count", default: 0, null: false
    t.datetime "overdue_notice_sent_at"
    t.index ["member_id"], name: "index_invoices_on_member_id"
  end

  create_table "members", id: :serial, force: :cascade do |t|
    t.string "emails", limit: 255
    t.string "phones", limit: 255
    t.string "address", limit: 255
    t.string "zip", limit: 255
    t.string "city", limit: 255
    t.string "token", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_name", limit: 255, null: false
    t.string "last_name", limit: 255, null: false
    t.boolean "support_member", null: false
    t.datetime "waiting_started_at"
    t.string "billing_interval", limit: 255, null: false
    t.text "food_note"
    t.text "note"
    t.integer "validator_id"
    t.datetime "validated_at"
    t.boolean "gribouille"
    t.integer "waiting_basket_size_id"
    t.integer "waiting_distribution_id"
    t.boolean "salary_basket", default: false
    t.string "delivery_address", limit: 255
    t.string "delivery_zip", limit: 255
    t.string "delivery_city", limit: 255
    t.datetime "inscription_submitted_at"
    t.datetime "deleted_at"
    t.datetime "welcome_email_sent_at"
    t.integer "old_old_invoice_identifier"
    t.boolean "renew_membership", default: false, null: false
    t.index ["deleted_at"], name: "index_members_on_deleted_at"
    t.index ["inscription_submitted_at"], name: "index_members_on_inscription_submitted_at"
    t.index ["old_old_invoice_identifier"], name: "index_members_on_old_old_invoice_identifier"
    t.index ["waiting_basket_size_id"], name: "index_members_on_waiting_basket_size_id"
    t.index ["waiting_distribution_id"], name: "index_members_on_waiting_distribution_id"
    t.index ["waiting_started_at"], name: "index_members_on_waiting_started_at"
    t.index ["welcome_email_sent_at"], name: "index_members_on_welcome_email_sent_at"
  end

  create_table "memberships", id: :serial, force: :cascade do |t|
    t.integer "basket_size_id", null: false
    t.integer "distribution_id", null: false
    t.integer "member_id", null: false
    t.decimal "halfday_works_annual_price", precision: 8, scale: 2
    t.integer "annual_halfday_works"
    t.date "started_on", null: false
    t.date "ended_on", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "note"
    t.datetime "deleted_at"
    t.index ["basket_size_id"], name: "index_memberships_on_basket_size_id"
    t.index ["deleted_at"], name: "index_memberships_on_deleted_at"
    t.index ["distribution_id"], name: "index_memberships_on_distribution_id"
    t.index ["ended_on"], name: "index_memberships_on_ended_on"
    t.index ["member_id"], name: "index_memberships_on_member_id"
    t.index ["started_on"], name: "index_memberships_on_started_on"
  end

  create_table "old_invoices", id: :serial, force: :cascade do |t|
    t.integer "member_id", null: false
    t.date "date", null: false
    t.text "number", null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.decimal "balance", precision: 8, scale: 2, null: false
    t.hstore "data", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["member_id"], name: "index_old_invoices_on_member_id"
    t.index ["number"], name: "index_old_invoices_on_number"
  end

  create_table "vegetables", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_vegetables_on_name", unique: true
  end

  add_foreign_key "basket_contents", "deliveries"
  add_foreign_key "basket_contents", "vegetables"
  add_foreign_key "basket_contents_distributions", "basket_contents"
  add_foreign_key "basket_contents_distributions", "distributions"
  add_foreign_key "halfday_participations", "admins", column: "validator_id"
  add_foreign_key "halfday_participations", "halfdays"
  add_foreign_key "halfday_participations", "members"
end
