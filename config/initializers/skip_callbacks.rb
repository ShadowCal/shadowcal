# frozen_string_literal: true

class ActiveRecord::Base
  cattr_accessor :skip_callbacks
end
