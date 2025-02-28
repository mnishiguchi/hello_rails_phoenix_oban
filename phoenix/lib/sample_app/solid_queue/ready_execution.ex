defmodule SampleApp.SolidQueue.ReadyExecution do
  @moduledoc """
  Represents a job that is ready for execution in Solid Queue.

  This schema maps to the `solid_queue_ready_executions` table, which
  tracks jobs that are available for processing by Solid Queue workers.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "solid_queue_ready_executions" do
    field :job_id, :integer
    field :queue_name, :string
    field :priority, :integer, default: 0

    timestamps(inserted_at: :created_at, updated_at: false, type: :utc_datetime_usec)
  end

  def changeset(ready_execution, attrs) do
    ready_execution
    |> cast(attrs, [:job_id, :queue_name, :priority])
    |> validate_required([:job_id, :queue_name])
  end
end
