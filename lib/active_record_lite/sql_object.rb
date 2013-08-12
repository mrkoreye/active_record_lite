require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    rows = DBConnection.execute("SELECT * FROM #{@table_name}")
    self.parse_all(rows)
  end

  def self.find(id)
    found = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{@table_name}
      WHERE id = ?
    SQL
    self.new(found[0]) unless found[0].nil?
  end

  def save
    self.id.nil? ? create : update
  end

  private
  def create
    quest = (['?'] * atts_array.length).join(',')
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO #{self.class.table_name}
      (#{atts_array.join(',')})
      VALUES (#{quest})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = atts_array.map { |att| "#{att} = ?"}.join(',')
    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE #{self.class.table_name}
      SET #{set_line}
      WHERE id = #{self.id}
    SQL
  end

  def atts_array
    self.class.attributes.select { |att| att != :id }
  end

  def attribute_values
    atts_array.map { |att| self.send(att) }
  end
end
