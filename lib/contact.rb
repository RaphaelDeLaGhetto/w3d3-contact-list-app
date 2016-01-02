require './lib/base_model'
require './lib/phone_number'

# Represents a person in an address book.
class Contact < BaseModel

  attr_accessor :name, :email, :id

  def initialize(name, email, id=nil)
    @name = name
    @email = email
    @id = id
  end

  def save
    if @id
      self.class.connection.exec_params('UPDATE contacts SET name = $1, email = $2 WHERE id = $3::int', [@name, @email, @id])
    else
      self.class.connection.exec_params('INSERT INTO contacts (name, email) VALUES ($1, $2)', [@name, @email])
    end
  end

  def destroy
    self.class.connection.exec_params('DELETE FROM contacts WHERE id = $1::int', [@id])
  end

  def phone_numbers
    PhoneNumber.all(@id)
  end

  # Provides functionality for managing a list of Contacts in a database.
  class << self

    # Returns an Array of Contacts loaded from the database.
    def all
      contacts = []
      self.connection.exec('SELECT * FROM contacts') do |result|
        contacts = result.values
      end
    end

    # Creates a new contact, adding it to the database, returning the new contact.
    def create(name, email)
      new(name, email).save
    end

    # Returns the contact with the specified id. If no contact has the id, returns nil.
    def find(id=nil)
      record = self.connection.exec_params('SELECT * FROM contacts '\
                                           'WHERE id = $1::int', [id]) if id.is_a?(Integer)
 
      record.nil? || record.num_tuples.zero? ? nil : new(record[0].values[1], record[0].values[2], record[0].values[0])
    end

    # Returns an array of contacts who match the given term.
    def search(term=nil)
      return [] if term.nil? || term.empty?
      self.connection.exec("SELECT * FROM contacts WHERE name ILIKE '%#{term}%' OR email ILIKE '%#{term}%'").values
    end
  end
end
