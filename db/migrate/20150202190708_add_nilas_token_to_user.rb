# frozen_string_literal: true

class AddNilasTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :nilas_token, :text
  end
end
