# Represents a job in Oban's job queue.
# This model provides a method to enqueue jobs into the Oban job queue table (`oban_jobs`),
# allowing Rails to communicate with a Phoenix app that processes jobs using Oban.
class ObanJob < ApplicationRecord
  self.table_name = "oban_jobs"

  # Prevent conflicts with ActiveRecord's `errors` method
  self.ignored_columns = %w[errors]

  class << self
    # Enqueues a job into Oban.
    #
    # @param worker_module [String] The name of the worker module in Phoenix.
    # @param opts [Hash] Options for job configuration (queue, args, meta, etc.).
    # @return [ObanJob] The created job record.
    #
    # @example Enqueue a job for Phoenix to process
    #   ObanJob.enqueue("SampleApp.Workers.EchoWorker", args: { name: "Phoenix" })
    def enqueue(worker_module, **opts)
      create!(
        {
          worker: worker_module.to_s,
          queue: "default",
          args: {},
          meta: {},
          tags: [],
          max_attempts: 20,
          priority: 0,
          inserted_at: Time.current,
          scheduled_at: Time.current
        }.merge(opts)
      )
    end
  end
end
