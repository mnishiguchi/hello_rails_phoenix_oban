class CreateObanTables < ActiveRecord::Migration[8.0]
  def up
    # Step 1: Create ENUM type `oban_job_state`
    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'oban_job_state') THEN
          CREATE TYPE oban_job_state AS ENUM (
            'available', 'scheduled', 'executing', 'retryable',
            'completed', 'discarded', 'cancelled'
          );
        END IF;
      END$$;
    SQL

    # Step 2: Create `oban_jobs` table
    create_table :oban_jobs, id: :bigserial, force: :cascade do |t|
      t.column :state, :oban_job_state, null: false, default: "available"
      t.string :queue, null: false, default: "default"
      t.string :worker, null: false
      t.jsonb :args, null: false, default: {}
      t.jsonb :meta, null: false, default: {}
      t.jsonb :tags, null: false, array: true, default: []
      t.jsonb :attempted_by, null: false, array: true, default: []
      t.jsonb :errors, null: false, array: true, default: []

      t.integer :attempt, null: false, default: 0
      t.integer :max_attempts, null: false, default: 20
      t.integer :priority, null: false, default: 0
      t.datetime :inserted_at, null: false, precision: 6, default: -> { "timezone('UTC', now())" }
      t.datetime :scheduled_at, null: false, precision: 6, default: -> { "timezone('UTC', now())" }
      t.datetime :attempted_at, precision: 6
      t.datetime :completed_at, precision: 6
      t.datetime :cancelled_at, precision: 6
      t.datetime :discarded_at, precision: 6
    end

    # Step 3: Indexes
    add_index :oban_jobs, :id, unique: true
    add_index :oban_jobs, :queue
    add_index :oban_jobs, :state
    add_index :oban_jobs, [:state, :queue]
    add_index :oban_jobs, :scheduled_at, where: "state IN ('available', 'scheduled')"
    add_index :oban_jobs, [:state, :queue, :priority, :scheduled_at, :id], name: "oban_jobs_state_queue_priority_scheduled_at_id_index"
    add_index :oban_jobs, [:attempted_at, :id], where: "state IN ('completed', 'discarded')", name: "oban_jobs_attempted_at_id_index"
    add_index :oban_jobs, :args, using: :gin
    add_index :oban_jobs, :meta, using: :gin

    # Step 4: Constraints
    execute <<~SQL
      ALTER TABLE oban_jobs ADD CONSTRAINT attempt_range CHECK (attempt BETWEEN 0 AND max_attempts);
      ALTER TABLE oban_jobs ADD CONSTRAINT non_negative_priority CHECK (priority >= 0);
      ALTER TABLE oban_jobs ADD CONSTRAINT positive_max_attempts CHECK (max_attempts > 0);
      ALTER TABLE oban_jobs ADD CONSTRAINT queue_length CHECK (char_length(queue) > 0 AND char_length(queue) < 128);
      ALTER TABLE oban_jobs ADD CONSTRAINT worker_length CHECK (char_length(worker) > 0 AND char_length(worker) < 128);
    SQL

    # Step 5: Create `oban_jobs_notify` function
    execute <<~SQL
      CREATE OR REPLACE FUNCTION oban_jobs_notify() RETURNS trigger AS $$
      DECLARE
        channel text;
        notice json;
      BEGIN
        IF NEW.state = 'available' OR NEW.scheduled_at <= now() THEN
          channel = 'oban_insert';
          notice = json_build_object('queue', NEW.queue);
          PERFORM pg_notify(channel, notice::text);
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Step 6: Create trigger for state updates
    execute <<~SQL
      CREATE TRIGGER oban_notify
      AFTER INSERT ON oban_jobs
      FOR EACH ROW EXECUTE FUNCTION oban_jobs_notify();
    SQL

    # Step 7: Create `oban_peers` table
    create_table :oban_peers, id: false do |t|
      t.text :name, null: false, primary_key: true
      t.text :node, null: false
      t.datetime :started_at, null: false, precision: 6
      t.datetime :expires_at, null: false, precision: 6
    end

    # Step 8: Make `oban_peers` unlogged for performance
    execute "ALTER TABLE oban_peers SET UNLOGGED"

    # Step 9: Set schema version comment
    execute "COMMENT ON TABLE oban_jobs IS '12'"
  end

  def down
    drop_table :oban_peers

    execute "DROP TRIGGER IF EXISTS oban_notify ON oban_jobs"
    execute "DROP FUNCTION IF EXISTS oban_jobs_notify()"
    drop_table :oban_jobs
    execute "DROP TYPE IF EXISTS oban_job_state"
  end
end
