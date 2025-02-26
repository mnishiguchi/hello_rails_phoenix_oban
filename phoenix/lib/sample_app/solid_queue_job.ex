defmodule SampleApp.SolidQueueJob do
  use Ecto.Schema
  import Ecto.Changeset

  schema "solid_queue_jobs" do
    field :queue_name, :string, default: "default"
    field :class_name, :string
    field :arguments, :string
    field :priority, :integer, default: 0
    field :scheduled_at, :naive_datetime
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [
      :queue_name,
      :class_name,
      :arguments,
      :priority,
      :scheduled_at,
      :created_at,
      :updated_at
    ])
    |> validate_required([:queue_name, :class_name, :arguments, :created_at, :updated_at])
  end
end
