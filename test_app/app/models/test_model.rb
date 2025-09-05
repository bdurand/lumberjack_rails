# frozen_string_literal: true

class TestModel < ApplicationRecord
  validates :name, presence: true
end
