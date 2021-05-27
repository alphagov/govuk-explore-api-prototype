class SectionLink
  include ActiveModel::Validations

  validates_presence_of :text, :link

  attr_accessor :text, :link

  def initialize(attrs)
    attrs.each { |key, value| instance_variable_set("@#{key}", value) }
    validate!
  end

  def self.load(params)
    parsed_params = params.dup
    new(parsed_params)
  end

  def self.load_all(section_links)
    section_links.map { |o| load(o) }
  end
end
