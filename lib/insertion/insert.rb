# frozen_string_literal: true

module Insertion
  class Insert
    class Error < ::StandardError
      def initialize(message = nil, class_name: nil)
        @class_name = class_name
        super(message)
      end

      def to_s
        @class_name ? "(#{@class_name}) #{super}" : super
      end
    end

    class ArgumentError < Error; end

    def self.insert(model_name, *, **) = Insertion.insert(model_name, *, **)

    def initialize(**attributes)
      @attributes = attributes
    end

    def attributes
      @attributes ||= {}
    end

    def do_insert!
      result = model.insert!(attributes, returning: Arel.sql('*')) # rubocop:disable Rails/SkipsModelValidations
      record = model.instantiate result.to_a.first

      after_insert(record) if respond_to?(:after_insert)

      record
    end

    def build_insert!
      result = nil
      model.transaction do
        result = model.insert!(attributes, returning: Arel.sql('*')) # rubocop:disable Rails/SkipsModelValidations
        raise ActiveRecord::Rollback
      end

      record = model.instantiate(result.to_a.first).dup

      after_build(record) if respond_to?(:after_build)

      record
    end

    private

      def insert(model_name, *, **) = Insertion.insert(model_name, *, **)
      def build(model_name, *, **) = Insertion.build(model_name, *, **)

      def model
        @model ||= self.class.name.sub(/Insert$/, '').constantize
      end
  end
end
