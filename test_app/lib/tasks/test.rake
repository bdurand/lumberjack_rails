# frozen_string_literal: true

namespace :lumberjack do
  task test: :environment do
    puts "info message"
    warn "warning message"
  end

  task :no_environment do
    puts "info message"
    warn "warning message"
  end
end
