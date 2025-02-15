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

ActiveRecord::Schema[8.0].define(version: 2025_02_15_120309) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "oban_job_state", ["available", "scheduled", "executing", "retryable", "completed", "discarded", "cancelled"]

  create_table "oban_jobs", comment: "12", force: :cascade do |t|
    t.enum "state", default: "available", null: false, enum_type: "oban_job_state"
    t.string "queue", default: "default", null: false
    t.string "worker", null: false
    t.jsonb "args", default: {}, null: false
    t.jsonb "meta", default: {}, null: false
    t.jsonb "tags", default: [], null: false, array: true
    t.jsonb "attempted_by", default: [], null: false, array: true
    t.jsonb "errors", default: [], null: false, array: true
    t.integer "attempt", default: 0, null: false
    t.integer "max_attempts", default: 20, null: false
    t.integer "priority", default: 0, null: false
    t.datetime "inserted_at", default: -> { "timezone('UTC'::text, now())" }, null: false
    t.datetime "scheduled_at", default: -> { "timezone('UTC'::text, now())" }, null: false
    t.datetime "attempted_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.datetime "discarded_at"
    t.index ["args"], name: "index_oban_jobs_on_args", using: :gin
    t.index ["attempted_at", "id"], name: "oban_jobs_attempted_at_id_index", where: "(state = ANY (ARRAY['completed'::oban_job_state, 'discarded'::oban_job_state]))"
    t.index ["id"], name: "index_oban_jobs_on_id", unique: true
    t.index ["meta"], name: "index_oban_jobs_on_meta", using: :gin
    t.index ["queue"], name: "index_oban_jobs_on_queue"
    t.index ["scheduled_at"], name: "index_oban_jobs_on_scheduled_at", where: "(state = ANY (ARRAY['available'::oban_job_state, 'scheduled'::oban_job_state]))"
    t.index ["state", "queue", "priority", "scheduled_at", "id"], name: "oban_jobs_state_queue_priority_scheduled_at_id_index"
    t.index ["state", "queue"], name: "index_oban_jobs_on_state_and_queue"
    t.index ["state"], name: "index_oban_jobs_on_state"
    t.check_constraint "attempt >= 0 AND attempt <= max_attempts", name: "attempt_range"
    t.check_constraint "char_length(queue::text) > 0 AND char_length(queue::text) < 128", name: "queue_length"
    t.check_constraint "char_length(worker::text) > 0 AND char_length(worker::text) < 128", name: "worker_length"
    t.check_constraint "max_attempts > 0", name: "positive_max_attempts"
    t.check_constraint "priority >= 0", name: "non_negative_priority"
  end

  create_table "oban_peers", primary_key: "name", id: :text, force: :cascade do |t|
    t.text "node", null: false
    t.datetime "started_at", null: false
    t.datetime "expires_at", null: false
  end
end
