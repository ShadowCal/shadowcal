# frozen_string_literal: true

require "ostruct"

class OpenStruct2 < OpenStruct
  def id
    @id
  end

  def id=(id)
    @id = id
  end
end

class Hash
  def to_ostruct
    JSON.parse(to_json, object_class: OpenStruct2)
  end
end
