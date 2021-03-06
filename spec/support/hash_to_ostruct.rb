# frozen_string_literal: true

require "ostruct"

class OpenStruct2 < OpenStruct
  attr_accessor :id
end

class Hash
  def to_ostruct
    JSON.parse(to_json, object_class: OpenStruct2)
  end
end
