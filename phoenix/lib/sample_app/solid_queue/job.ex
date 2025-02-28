defmodule SampleApp.SolidQueue.Job do
  @moduledoc """
  Represents a job in Solid Queue.

  This schema maps to the `solid_queue_jobs` table, where enqueued jobs
  are stored before being processed by Solid Queue workers.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "solid_queue_jobs" do
    field(:queue_name, :string, default: "default")
    field(:class_name, :string)
    field(:arguments, :string)
    field(:priority, :integer, default: 0)
    field(:scheduled_at, :utc_datetime_usec)
    field(:active_job_id, :string)
    field(:concurrency_key, :string)
    field(:finished_at, :utc_datetime_usec)

    timestamps(inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime_usec)
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [
      :queue_name,
      :class_name,
      :arguments,
      :priority,
      :scheduled_at,
      :active_job_id
    ])
    |> validate_required([:queue_name, :class_name, :arguments, :scheduled_at, :active_job_id])
  end
end
