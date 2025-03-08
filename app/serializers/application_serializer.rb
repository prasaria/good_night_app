# app/serializers/application_serializer.rb
class ApplicationSerializer
  def initialize(resource)
    @resource = resource
  end

  def as_json(*)
    raise NotImplementedError, "Subclasses must implement as_json"
  end

  # Helper to serialize collections
  def self.render_collection(collection)
    collection.map { |item| new(item).as_json }
  end
end
