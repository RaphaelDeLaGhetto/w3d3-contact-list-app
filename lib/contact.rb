require 'active_record'

# Represents a person in an address book.
class Contact < ActiveRecord::Base
  has_many :phone_numbers

  class << self
    # Returns an array of contacts who match the given term.
    def search(term=nil)
      return [] if term.nil? || term.empty?
      self.where("name ILIKE :query OR email ILIKE :query", query: "%#{term}%")
    end
  end
end
