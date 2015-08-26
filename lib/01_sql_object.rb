require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    table.first.map(&:to_sym)
  end

  def self.finalize!

    columns.each do |column|

      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end

    nil
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        "#{table_name}".*
      FROM
        "#{table_name}"
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        "#{table_name}".*
      FROM
        "#{table_name}"
      WHERE
        id = ?
    SQL

    parse_all(result).first
  end

  def initialize(params = {})
    params.each do |ivar,value|
      attr_name = ivar.to_sym

      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end

      send("#{ivar}=".to_sym,value)
    end

    self
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      send(column)
    end
  end

  def save
    if id.nil?
      insert
    else
      update
    end

    self
  end


  def insert
    columns = self.class.columns
    col_names = columns.join(',')
    question_marks = (["?"] * columns.length).join(',')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name}(#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id

    nil
  end

  def update
    set_values = self.class.columns.map { |column| "#{column} = ?" }.join(",")

    DBConnection.execute(<<-SQL,*attribute_values,id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_values}
      WHERE
        id = ?
    SQL

    nil
  end


end
