defmodule SampleApp.SolidQueueTest do
  use SampleApp.DataCase, async: true

  alias SampleApp.SolidQueue
  alias SampleApp.SolidQueue.Job
  alias SampleApp.SolidQueue.ReadyExecution

  describe "enqueue/2" do
    test "successfully enqueues a job and marks it as ready" do
      job_class = "EchoJob"
      args = %{message: "Hello from Phoenix"}

      assert {:ok, job} = SolidQueue.enqueue(job_class, args: args)

      # Verify job is inserted into solid_queue_jobs
      inserted_job = Repo.get!(Job, job.id)
      assert inserted_job.class_name == job_class
      assert inserted_job.queue_name == "default"
      assert inserted_job.priority == 0
      assert is_binary(inserted_job.arguments)

      parsed_arguments = JSON.decode!(inserted_job.arguments)

      assert Map.keys(parsed_arguments) == [
               "arguments",
               "enqueued_at",
               "exception_executions",
               "executions",
               "job_class",
               "job_id",
               "locale",
               "priority",
               "provider_job_id",
               "queue_name",
               "scheduled_at",
               "timezone"
             ]

      assert parsed_arguments["arguments"] == [%{"message" => args.message}]
      assert inserted_job.scheduled_at |> is_struct(DateTime)

      # Verify job is inserted into solid_queue_ready_executions
      ready_execution = Repo.get_by!(ReadyExecution, job_id: job.id)
      assert ready_execution.queue_name == "default"
      assert ready_execution.priority == 0
    end
  end
end
