class SpecialistTopic
  include ActiveModel::Validations

  validates_presence_of :key, :title, :description, :sections
  validate { errors.add(:sections, "is not an array") unless sections.is_a? Array }

  attr_accessor :key, :title, :description, :sections

  def initialize(attrs)
    attrs.each { |key, value| instance_variable_set("@#{key}", value) }
    validate!
  end

  def self.load(params)
    parsed_params = params.dup
    parsed_params["sections"] = Section.load_all(params["sections"].to_a)
    new(parsed_params)
  end

  def self.load_all(specialist_topics)
    specialist_topics.map { |o| load(o) }
  end
end
