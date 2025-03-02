# Represents a job in Oban's job queue.
# This model provides a method to enqueue jobs into the Oban job queue table (`oban_jobs`),
# allowing Rails to communicate with a Phoenix app that processes jobs using Oban.
class ObanJob < ApplicationRecord
  self.table_name = "oban_jobs"

  # Prevent conflicts with ActiveRecord's `errors` method
  self.ignored_columns = %w[errors]

  # Ensure `inserted_at` is set before creation
  before_create -> { self.inserted_at ||= Time.current }

  # Alias `created_at` to `inserted_at` for Rails compatibility
  alias_attribute :created_at, :inserted_at

  class << self
    # Enqueues a job into Oban.
    #
    # @param worker_module [String] The name of the worker module in Phoenix.
    # @param args [Hash] Arguments for the job execution.
    # @param opts [Hash] Additional options for the job (queue, priority, etc.).
    # @return [ObanJob] The created job record.
    #
    # @example Enqueue a job for Phoenix to process
    #   ObanJob.enqueue("SampleApp.Workers.EchoWorker", args: { name: "Phoenix" })
    def enqueue(worker_module, args:, **opts)
      create!(
        {
          worker: worker_module.to_s,
          queue: "default",
          args: args,
          meta: {},
          tags: [],
          max_attempts: 20,
          priority: 0,
          scheduled_at: Time.current,
          **opts
        }
      )
    end

    # Enqueues a RailsWorker job with a task name and arguments.
    #
    # @param task_name [String] The name of the task to execute in Phoenix.
    # @param task_args [Hash] Arguments for the task execution.
    # @param opts [Hash] Additional options for the job (priority, queue, etc.).
    # @return [ObanJob] The created job record.
    #
    # @example Enqueue a task to be processed by RailsWorker in Phoenix
    #   ObanJob.enqueue_rails_worker("sum_ab", { a: 5, b: 10 }, queue: "critical")
    def enqueue_rails_worker(task_name, task_args = {}, **opts)
      enqueue("SampleApp.Workers.RailsWorker", args: { task_name: task_name, task_args: task_args }, **opts)
    end
  end
end
