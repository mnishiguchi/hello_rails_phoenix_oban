# Represents a job in SolidQueue that processes results from Phoenix.
#
# This job is enqueued by `RailsWorker` in Phoenix after it completes a task.
class PhoenixJob < ApplicationJob
  queue_as :default

  # Processes the result received from Phoenix
  #
  # @param task_name [String] Name of the completed task.
  # @param result [Any] The computed result of the task.
  # @param oban_job_id [Integer] The ID of the original Oban job in Phoenix.
  def perform(args)
    oban_job_id = args.fetch("oban_job_id")
    task_name = args.fetch("task_name")
    result = args.fetch("result")

    Rails.logger.info("[PhoenixJob] Received result from ObanJob ##{oban_job_id} for task: #{task_name} -> #{result.inspect}")

    handle_result(task_name, result)
  end

  private

  def handle_result(task_name, result)
    # TODO: Implement actual processing logic (e.g., update database, send notification)
  end
end
