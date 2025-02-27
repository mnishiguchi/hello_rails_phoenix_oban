class EchoJob < ApplicationJob
  self.queue_adapter = :solid_queue

  def perform(*args)
    Rails.logger.info("[EchoJob] Received arguments: #{args.inspect}")
  end
end
