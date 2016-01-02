require './lib/base_model'

# Represents a person in an address book.
class PhoneNumber < BaseModel

  attr_accessor :number, :contact_id, :id

  def initialize(number, contact_id, id=nil)
    @number = number
    @contact_id = contact_id
    @id = id
  end

  def save
    if @id
      self.class.connection.exec_params('UPDATE phone_numbers SET number = $1, contact_id = $2 WHERE id = $3::int', [@number, @contact_id, @id])
    else
      self.class.connection.exec_params('INSERT INTO phone_numbers (number, contact_id) VALUES ($1, $2)', [@number, @contact_id])
    end
  end

  def destroy
    self.class.connection.exec_params('DELETE FROM phone_numbers WHERE id = $1::int', [@id])
  end

  # Provides functionality for managing a list of PhoneNumbers in a database.
  class << self

    # Returns an Array of PhoneNumbers loaded from the database.
    def all(contact_id)
      phone_numbers = []
      self.connection.exec_params('SELECT id, number FROM phone_numbers WHERE contact_id = $1::int', [contact_id]) do |result|
        phone_numbers = result.values
      end
      phone_numbers
    end

    # Creates a new phone_number, adding it to the database, returning the new phone_number.
    def create(number, contact_id)
      new(number, contact_id).save
    end

    # Returns the phone_number with the specified id. If no phone_number has the id, returns nil.
    def find(id=nil)
      record = self.connection.exec_params('SELECT * FROM phone_numbers WHERE id = $1::int', [id]) if id.is_a?(Integer)
      record.nil? || record.num_tuples.zero? ? nil : new(record[0].values[1], record[0].values[2], record[0].values[0])
    end

    # Returns an array of phone_numbers who match the given term.
    def search(term=nil)
      return [] if term.nil? || term.empty?
      self.connection.exec("SELECT * FROM contacts WHERE id IN (SELECT contact_id FROM phone_numbers WHERE number ILIKE '%#{term}%')").values
    end
  end
end
