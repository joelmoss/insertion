# frozen_string_literal: true

Rails.application.configure do
  config.autoload_paths << "#{root}/db/inserts"
end
