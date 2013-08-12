require 'active_support/inflector'
require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :p_key, :f_key, :c_name

  def other_class
    @c_name.constantize
  end

  def other_table_name
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @c_name = params[:class_name] || name.to_s.camelize
    @f_key = params[:foreign_key] || "#{name}_id"
    @p_key = params[:primary_key] || "id"
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @c_name = params[:class_name] || name.to_s.singularize.camelize
    @f_key = params[:foreign_key] || "#{self_class}".underscore << "_id"
    @p_key = params[:primary_key] || "id"
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = aps

    self.send(:define_method, name) do
      result = DBConnection.execute(<<-SQL, self.send(aps.f_key))
        SELECT *
        FROM #{aps.other_table_name}
        WHERE #{aps.p_key} = ?
        SQL
      aps.other_class.parse_all(result)
    end
  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self.class)

    self.send(:define_method, name) do
      result = DBConnection.execute(<<-SQL, self.send(aps.p_key))
        SELECT *
        FROM #{aps.other_table_name}
        WHERE #{aps.f_key} = ?
        SQL
      aps.other_class.parse_all(result)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    self.send(:define_method, name) do
      params1 = self.class.assoc_params[assoc1]
      params2 = params1.other_class.assoc_params[assoc2]

      result = DBConnection.execute(<<-SQL, self.send(params1.f_key))
        SELECT DISTINCT houses.*
        FROM #{self.class.table_name} AS cats
        JOIN #{params1.other_table_name} AS humans ON cats.#{params1.f_key} = humans.#{params2.p_key}
        JOIN #{params2.other_table_name} AS houses ON humans.#{params2.f_key} = houses.#{params2.p_key}
        WHERE humans.#{params1.p_key} = ?
        SQL
      params2.other_class.parse_all(result)
    end

  end
end



















