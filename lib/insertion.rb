# frozen_string_literal: true

require_relative 'insertion/version'
require_relative 'insertion/engine'

module Insertion
  autoload :Insert, 'insertion/insert'
  autoload :BareInsert, 'insertion/bare_insert'

  module_function

  def insert(model_name, *, **)
    model_name = model_name.to_s.classify

    if (insert = "#{model_name}Insert".safe_constantize)
      begin
        insert.new(*, **).do_insert!
      rescue ArgumentError => e
        raise insert::ArgumentError.new(e.message, class_name: insert), cause: e
      end
    else
      BareInsert.new(model_name.constantize, *, **).do_insert!
    end
  end

  def build(model_name, *, **)
    model_name = model_name.to_s.classify

    if (insert = "#{model_name}Insert".safe_constantize)
      begin
        insert.new(*, **).build_insert!
      rescue ArgumentError => e
        raise insert::ArgumentError.new(e.message, class_name: insert), cause: e
      end
    else
      BareInsert.new(model_name.constantize, *, **).build_insert!
    end
  end
end
