class Section
  include ActiveModel::Validations

  validate { errors.add(:section_links, "is not an array") unless section_links.is_a? Array }

  attr_accessor :label, :section_links

  def initialize(attrs)
    attrs.each { |key, value| instance_variable_set("@#{key}", value) }
    validate!
  end

  def self.load(params)
    parsed_params = params.dup
    parsed_params["section_links"] = SectionLink.load_all(params["section_links"].to_a)
    new(parsed_params)
  end

  def self.load_all(sections)
    sections.map { |o| load(o) }
  end
end
