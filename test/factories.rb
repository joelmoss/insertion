# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    age { 25 }

    trait :with_posts do
      transient do
        posts_count { 1 }
      end

      after(:create) do |user, evaluator|
        create_list(:post, evaluator.posts_count, user: user)
      end
    end
  end

  factory :post do
    sequence(:title) { |n| "Post #{n}" }
    body { 'Lorem ipsum dolor sit amet' }
    user
  end
end
