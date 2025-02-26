defmodule SampleApp.SolidQueue do
  alias SampleApp.Repo
  alias SampleApp.SolidQueueJob

  def enqueue_solid_queue_job(class_name, args \\ []) do
    job = %{
      queue_name: "default",
      class_name: class_name,
      arguments: JSON.encode!(args),
      priority: 0,
      scheduled_at: NaiveDateTime.utc_now(),
      created_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    }

    %SolidQueueJob{}
    |> SolidQueueJob.changeset(job)
    |> Repo.insert!()
  end
end


