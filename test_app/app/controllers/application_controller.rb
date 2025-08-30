class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :log_duration

  def log_duration
    start_time = Time.now
    result = yield
    duration = Time.now - start_time
    Rails.logger.tag(duration: duration)
    result
  end
end
