# frozen_string_literal: true

class Price < ApplicationRecord
  belongs_to :competitor

  validates :percentage, :captured_at, presence: true
end
