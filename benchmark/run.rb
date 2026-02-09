# frozen_string_literal: true

# Benchmark: Insertion vs Rails create! vs FactoryBot vs insert_all
#
# Usage: bundle exec ruby benchmark/run.rb

require 'bundler/setup'

ENV['RAILS_ENV'] = 'test'
require_relative '../test/dummy/config/environment'

require 'benchmark/ips'
require 'factory_bot_rails'

# Set up the database schema
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :email
    t.integer :age
    t.timestamps null: false
  end

  create_table :posts, force: true do |t|
    t.string :title
    t.text :body
    t.integer :user_id
    t.timestamps null: false
  end
end

# Set up FactoryBot
FactoryBot.definition_file_paths = [File.expand_path('../test/factories', __dir__)]
FactoryBot.find_definitions

# Pre-load a fixture user for the fixture-lookup scenario
fixture_user = User.create!(name: 'Fixture User', email: 'fixture@example.com', age: 30)
FIXTURE_USER_ID = fixture_user.id

puts '=' * 70
puts 'Benchmark: Insertion vs Rails create! vs FactoryBot'
puts "Ruby #{RUBY_VERSION} | Rails #{Rails::VERSION::STRING} | SQLite"
puts '=' * 70
puts

# ---------------------------------------------------------------------------
# Scenario 1: Single record creation
# ---------------------------------------------------------------------------
puts '-' * 70
puts 'Scenario 1: Single record creation'
puts '-' * 70

Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)

  x.report('Insertion.insert') do
    Insertion.insert(:user, name: 'Test', email: 'test@example.com', age: 25)
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.report('User.create!') do
    User.create!(name: 'Test', email: 'test@example.com', age: 25)
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.report('FactoryBot.create') do
    FactoryBot.create(:user)
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.report('Fixture lookup') do
    User.find(FIXTURE_USER_ID)
  end

  x.compare!
end

puts

# ---------------------------------------------------------------------------
# Scenario 2: Record with association
# ---------------------------------------------------------------------------
puts '-' * 70
puts 'Scenario 2: Record with association (User + Post)'
puts '-' * 70

Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)

  x.report('Insertion.insert') do
    user = Insertion.insert(:user, name: 'Test', email: 'test@example.com', age: 25)
    Insertion.insert(:post, title: 'Hello', body: 'World', user_id: user.id)
    Post.delete_all
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.report('ActiveRecord create!') do
    user = User.create!(name: 'Test', email: 'test@example.com', age: 25)
    Post.create!(title: 'Hello', body: 'World', user_id: user.id)
    Post.delete_all
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.report('FactoryBot.create') do
    FactoryBot.create(:post)
    Post.delete_all
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.compare!
end

puts

# ---------------------------------------------------------------------------
# Scenario 3: Bulk creation (100 records)
# ---------------------------------------------------------------------------
puts '-' * 70
puts 'Scenario 3: Bulk creation (100 records)'
puts '-' * 70

now = Time.current
bulk_attrs = Array.new(100) do |i|
  { name: "User #{i}", email: "user#{i}@example.com", age: 25,
    created_at: now, updated_at: now }
end

Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)

  x.report('Insertion.insert x100') do
    100.times do |i|
      Insertion.insert(:user, name: "User #{i}", email: "user#{i}@example.com", age: 25)
    end
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.report('User.create! x100') do
    100.times do |i|
      User.create!(name: "User #{i}", email: "user#{i}@example.com", age: 25)
    end
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.report('FactoryBot.create x100') do
    100.times { FactoryBot.create(:user) }
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.report('User.insert_all x100') do
    User.insert_all(bulk_attrs) # rubocop:disable Rails/SkipsModelValidations
    User.where.not(id: FIXTURE_USER_ID).delete_all
  end

  x.compare!
end
