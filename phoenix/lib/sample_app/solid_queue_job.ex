defmodule SampleApp.SolidQueueJob do
  use Ecto.Schema
  import Ecto.Changeset
  alias SampleApp.Repo

  @primary_key {:id, :id, autogenerate: true}
  schema "solid_queue_jobs" do
    field :queue_name, :string
    field :class_name, :string
    field :arguments, :string
    field :priority, :integer, default: 0
    field :scheduled_at, :utc_datetime_usec

    timestamps(inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime_usec)
  end

  @doc """
  Enqueues a job in SolidQueue.

  ## Example:
      SampleApp.SolidQueueJob.enqueue("EchoJob", args: %{message: "Hello from Phoenix"})

  """
  def enqueue(class_name, opts \\ []) do
    args = Keyword.get(opts, :args, %{})
    job_id = Ecto.UUID.generate()

    job_data = %{
      "job_class" => class_name,
      "job_id" => job_id,
      "provider_job_id" => job_id,
      "queue_name" => Keyword.get(opts, :queue_name, "default"),
      "priority" => Keyword.get(opts, :priority, 0),
      "arguments" => [
        Map.put(args, "_aj_ruby2_keywords", Map.keys(args))
      ],
      "executions" => 0,
      "exception_executions" => %{},
      "locale" => "en",
      "timezone" => "UTC",
      "enqueued_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "scheduled_at" =>
        opts
        |> Keyword.get(:scheduled_at, DateTime.utc_now())
        |> DateTime.to_iso8601()
    }

    job_attrs = %{
      queue_name: job_data["queue_name"],
      class_name: class_name,
      arguments: Jason.encode!(job_data),
      priority: job_data["priority"],
      scheduled_at: DateTime.truncate(DateTime.utc_now(), :second),
      provider_job_id: job_data["provider_job_id"]
    }

    %__MODULE__{}
    |> changeset(job_attrs)
    |> Repo.insert!()
  end

  defp changeset(job, attrs) do
    job
    |> cast(attrs, [
      :queue_name,
      :class_name,
      :arguments,
      :priority,
      :scheduled_at
    ])
    |> validate_required([:queue_name, :class_name, :arguments])
  end
end
