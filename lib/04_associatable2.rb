require_relative '03_associatable'
require 'byebug'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      table_name = self.class.table_name
      through_options = self.class.assoc_options[through_name]
      through_table = through_options.model_class.table_name
      source_options = through_options.model_class.assoc_options[source_name]
      source_table = source_options.model_class.table_name
      results = DBConnection.execute(<<-SQL,id)
        SELECT
          #{source_table}.*
        FROM
          #{table_name}
        JOIN
          #{through_table}
        ON
          #{table_name}.#{through_options.foreign_key} = #{through_table}.#{through_options.primary_key}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{source_options.foreign_key} = #{source_table}.#{source_options.primary_key}
        WHERE
          #{table_name}.id = ?
      SQL

      source_options.model_class.parse_all(results).first
    end
  end
end
