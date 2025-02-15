defmodule SampleApp.Workers.EchoWorker do
  @moduledoc """
  Logs received arguments when executed as an Oban job.
  """

  use Oban.Worker, queue: :default

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.info("[EchoWorker] Received arguments: #{inspect(args)}")
    :ok
  end

  @doc """
  Enqueues a job with the given arguments.

  ## Example

      SampleApp.Workers.EchoWorker.enqueue(%{"message" => "Hello"})
  """
  @spec enqueue(map()) :: {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
  def enqueue(args) when is_map(args) do
    args
    |> Oban.Job.new(queue: :default, worker: __MODULE__)
    |> Oban.insert()
  end
end
