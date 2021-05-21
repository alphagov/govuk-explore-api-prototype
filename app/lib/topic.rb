class Topic
  include ActiveModel::Validations

  CONFIG_PATH = Rails.root.join("app/lib/topics.yml")

  validates_presence_of :title, :link, :specialist_topics
  validate { errors.add(:specialist_topics, "is not an array") unless specialist_topics.is_a? Array }

  attr_accessor :title, :link, :specialist_topics

  def initialize(attrs)
    attrs.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
    validate!
  end

  def self.load(params)
    parsed_params = params.dup
    parsed_params["specialist_topics"] = SpecialistTopic.load_all(params["specialist_topics"].to_a)
    new(parsed_params)
  end

  def self.load_all
    @load_all = nil if Rails.env.development?
    @load_all ||= YAML.load_file(CONFIG_PATH)["topics"].map { |topic| load(topic) }
  end
end
