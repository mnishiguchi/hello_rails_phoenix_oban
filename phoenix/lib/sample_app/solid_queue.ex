defmodule SampleApp.SolidQueue do
  alias SampleApp.SolidQueue
  alias SampleApp.Repo
  alias SampleApp.SolidQueue

  @doc """
  Enqueues a job in SolidQueue and marks it as ready for execution.

  This function ensures that the job is inserted into `solid_queue_jobs`
  and immediately marked as ready in `solid_queue_ready_executions`,
  making it available for processing.

  ## Example:
      SampleApp.SolidQueue.enqueue("EchoJob", args: %{message: "Hello from Phoenix"})
  """
  def enqueue(class_name, opts \\ []) do
    args = Keyword.get(opts, :args, %{})
    job_id = Ecto.UUID.generate()
    queue_name = Keyword.get(opts, :queue_name, "default")
    priority = Keyword.get(opts, :priority, 0)
    timezone = Keyword.get(opts, :timezone, "UTC")
    locale = Keyword.get(opts, :locale, "en")
    now = DateTime.utc_now()

    # Construct ActiveJob-style JSON
    active_job_json =
      %{
        "provider_job_id" => nil,
        "job_class" => class_name,
        "job_id" => job_id,
        "queue_name" => queue_name,
        "priority" => priority,
        "arguments" => [args],
        "executions" => 0,
        "exception_executions" => %{},
        "locale" => locale,
        "timezone" => timezone,
        "enqueued_at" => now,
        "scheduled_at" => now
      }
      |> JSON.encode!()

    # Define the transaction using Ecto.Multi
    Ecto.Multi.new()
    # Insert job into `solid_queue_jobs`
    |> Ecto.Multi.insert(
      :job,
      %SolidQueue.Job{}
      |> SolidQueue.Job.changeset(%{
        active_job_id: job_id,
        queue_name: queue_name,
        class_name: class_name,
        arguments: active_job_json,
        priority: priority,
        scheduled_at: DateTime.truncate(now, :second)
      })
    )
    # Mark job as ready for execution
    |> Ecto.Multi.insert(
      :ready_execution,
      fn %{job: job} ->
        %SolidQueue.ReadyExecution{}
        |> SolidQueue.ReadyExecution.changeset(%{
          job_id: job.id,
          queue_name: queue_name,
          priority: priority
        })
      end
    )
    # Execute the transaction
    |> Repo.transaction()
    |> case do
      {:ok, %{job: job}} ->
        {:ok, job}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end
end
