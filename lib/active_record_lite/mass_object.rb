class MassObject
  def self.set_attrs(*attributes)
    self.instance_variable_set(:@atts, attributes)
    attributes.each do |attribute|
      self.send(:attr_accessor, attribute)
    end
  end

  def self.attributes
    self.instance_variable_get(:@atts)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def initialize(params = {})
    params.each do |att, value|
      att = att.to_sym
      if self.class.attributes.include?(att)
        self.send("#{att}=", value)
      else
        raise "mass assignment to unregistered attribute #{att}"
      end
    end
  end

end


