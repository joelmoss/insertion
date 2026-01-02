# frozen_string_literal: true

module Insertion
  class BareInsert < Insert
    def initialize(model, **)
      @model = model
      super(**)
    end
  end
end
