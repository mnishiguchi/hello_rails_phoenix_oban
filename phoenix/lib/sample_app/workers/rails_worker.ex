defmodule SampleApp.Workers.RailsWorker do
  @moduledoc """
  Processes tasks sent from Rails via Oban and enqueues the result as a SolidQueue job.

  ## Workflow:
  1. Rails enqueues a job with `ObanJob.enqueue_rails_worker/2`, specifying a `task_name` and `task_args`.
  2. This worker receives the job and executes the corresponding task.
  3. The result is enqueued as a SolidQueue job (`PhoenixJob`), which Rails will later process.

  ## Example:
      # Enqueued by Rails
      ObanJob.enqueue_rails_worker("sum_ab", %{a: 10, b: 20})

  This results in:
      - `RailsWorker` computing `10 + 20 = 30`
      - The result `{task_name: "sum_ab", result: 30}` enqueued as a SolidQueue job (`PhoenixJob`)
  """

  use Oban.Worker, queue: :default

  require Logger
  alias SampleApp.SolidQueue

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_name" => task_name, "task_args" => task_args}} = oban_job) do
    Logger.info("[RailsWorker] Executing task: #{task_name} with args: #{inspect(task_args)}")

    with {:ok, result} <- execute_task(task_name, task_args),
         {:ok, _solid_queue_job} <- enqueue_phoenix_job(oban_job.id, task_name, result) do
      Logger.info("[RailsWorker] Successfully enqueued result for task: #{task_name}")
      :ok
    else
      {:error, reason} ->
        Logger.error("[RailsWorker] Error processing task #{task_name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp execute_task("sum_ab", %{"a" => a, "b" => b}) do
    {:ok, a + b}
  end

  defp execute_task(task_name, args) do
    Logger.warning("[RailsWorker] Unknown task: #{task_name} with args: #{inspect(args)}")
    {:error, :unknown_task}
  end

  defp enqueue_phoenix_job(oban_job_id, task_name, result) do
    SolidQueue.enqueue(
      "PhoenixJob",
      %{oban_job_id: oban_job_id, task_name: task_name, result: result},
      []
    )
  end
end
