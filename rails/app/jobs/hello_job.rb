class HelloJob < ApplicationJob
  queue_as :default

  def perform(name = "world")
    Rails.logger.info "Hello, #{name}! #{msg}"
  end

  def msg
    [
      "踏み出せば、その一足が道となる。",
      "元氣ですかーーーーッ！！！",
      "元氣が一番、元氣があれば何でもできる！"
    ].sample
  end
end
