defmodule SampleApp.Worker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    IO.puts("👋 Hello from Phoenix! Received job with name: #{name}")

    # Simulate work being done
    :timer.sleep(1000)

    IO.puts("✅ Job completed successfully in Phoenix!")
    :ok
  end
end

