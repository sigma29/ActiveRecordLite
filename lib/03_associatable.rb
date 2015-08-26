require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.class_name = (options[:class_name] || name.to_s.camelcase)
    self.foreign_key = (options[:foreign_key] ||
      "#{name.to_s.underscore}_id".to_sym)
    self.primary_key = (options[:primary_key] || :id)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.class_name = (options[:class_name] ||
      name.to_s.singularize.camelcase)
    self.foreign_key = (options[:foreign_key] ||
      "#{self_class_name.to_s.underscore}_id".to_sym)
    self.primary_key = (options[:primary_key] || :id)
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name,options)
    self.assoc_options[name.to_sym] = options
    define_method(name) do
      foreign_key_name = options.foreign_key
      foreign_key = send(foreign_key_name)
      target_model_class = options.model_class

      target_model_class.where({:id => foreign_key}).first
    end
    # ...
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method(name) do
      foreign_key = options.foreign_key
      target_model_class = options.model_class

      target_model_class.where({foreign_key => id})
    end
  end
end

class SQLObject
  extend Associatable

  def self.assoc_options
    @options_hash ||= {}
  end
end
