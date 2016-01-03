require './lib/contact'
require './lib/phone_number'
require 'active_support/inflector'


# Interfaces between a user and their contact list. Reads from and writes to standard I/O.
class ContactList

  def initialize(argv=[])
    @input = argv
  end

  def process
    case @input[0]
    when 'list'
      contacts = Contact.all
      contacts.each do |contact|
        puts "#{contact.id}: #{contact.name} (#{contact.email})"
      end
      puts '---'
      puts "#{contacts.count} records total"
    when 'new'
      # kernel#gets only works if argv is empty
      puts 'Name:'
      name = STDIN.gets.chomp
      puts 'Email:'
      email = STDIN.gets.chomp
      Contact.create(name: name, email: email)
    when 'show'
      id = @input[1].to_i
      begin
        record = Contact.find(id)
        puts "#{record.id}: #{record.name} (#{record.email})"
        record.phone_numbers.each do |number|
          puts "   #{number.number}"
        end
      rescue
        puts "That contact doesn't exist"
      end
    when 'search'
      contacts = Contact.search(@input[1])
      contacts.each do |contact|
        puts "#{contact.id}: #{contact.name} (#{contact.email})"
      end
      puts '---'
      puts "#{contacts.count} #{"record".pluralize(contacts.count)} total"
    when 'update'
      id = @input[1].to_i
      begin
        record = Contact.find(id)
  
        # Name and email 
        puts "Name (#{record.name}):"
        name = STDIN.gets.strip
        record.name = name if !name.empty?
        puts "Email (#{record.email}):"
        email = STDIN.gets.strip
        record.email = email if !email.empty?
        record.save
  
        # Phone numbers 
        record.phone_numbers.each_with_index do |number, index|
          puts "Enter 'X' to delete phone number" if index == 0
          puts "Phone #{index+1} (#{number.number}):"
          new_phone = STDIN.gets.strip
          if !new_phone.empty?
            old_phone = PhoneNumber.find(number.id)
            if new_phone == 'X'
              old_phone.destroy
            else
              old_phone.number = new_phone
              old_phone.save
            end
          end
        end
  
        # Add new numbers?
        loop do 
          puts 'New phone number:' 
          new_phone = STDIN.gets.strip
          break if new_phone.empty?
          record.phone_numbers.create(number: new_phone)
        end
      rescue
        puts "That contact doesn't exist"
      end
    when 'destroy'
      id = @input[1].to_i
      begin
        record = Contact.find(id)
        record.destroy
        puts "Contact destroyed"
      rescue
        puts "That contact doesn't exist"
      end
    when nil 
      puts "Here is a list of available commands:\n"\
           "  new     - Create a new contact\n"\
           "  list    - List all contacts\n"\
           "  show    - Show a contact\n"\
           "  search  - Search contacts\n"\
           "  update  - Update a contact\n"\
           "  destroy - Remove a contact\n"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  # Connect to the DB
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'test_contacts',
    username: 'development',
    password: 'development',
    host: 'localhost',
    port: 5432,
    pool: 5,
    encoding: 'unicode',
    min_messages: 'error'
  )
  ContactList.new(ARGV).process
end
