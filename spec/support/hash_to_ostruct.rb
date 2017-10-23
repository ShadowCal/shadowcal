require 'ostruct'

class Hash
  def to_ostruct
    JSON.parse(to_json, object_class: OpenStruct)
  end
end
