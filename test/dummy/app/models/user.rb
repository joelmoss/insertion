# frozen_string_literal: true

class User < ApplicationRecord
  has_many :posts # rubocop:disable Rails/HasManyOrHasOneDependent
end
