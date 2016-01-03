require 'active_record'
require './lib/contact'

# Represents a person in an address book.
class PhoneNumber < ActiveRecord::Base
  belongs_to :contact, dependent: :destroy

  # Provides functionality for managing a list of PhoneNumbers in a database.
  class << self
    # Returns an array of phone_numbers who match the given term.
    def search(term=nil)
      return [] if term.nil? || term.empty?
      contact_ids = self.where("number ILIKE :query", query: "%#{term}%").pluck(:contact_id)
      Contact.find(contact_ids)
    end
  end
end
