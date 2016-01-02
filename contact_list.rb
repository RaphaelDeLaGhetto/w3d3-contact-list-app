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
        puts "#{contact[0]}: #{contact[1]} (#{contact[2]})"
      end
      puts '---'
      puts "#{contacts.count} records total"
    when 'new'
      # kernel#gets only works if argv is empty
      puts 'Name:'
      name = STDIN.gets.chomp
      puts 'Email:'
      email = STDIN.gets.chomp
      Contact.create(name, email)
    when 'show'
      id = @input[1].to_i
      record = Contact.find(id)
      if record.nil?
        puts "That contact doesn't exist"
      else
        puts "#{record.id}: #{record.name} (#{record.email})"
        record.phone_numbers.each do |number|
          puts "   #{number[1]}"
        end
      end
    when 'search'
      contacts = Contact.search(@input[1])
      contacts.each do |contact|
        puts "#{contact[0]}: #{contact[1]} (#{contact[2]})"
      end
      puts '---'
      puts "#{contacts.count} #{"record".pluralize(contacts.count)} total"
    when 'update'
      id = @input[1].to_i
      record = Contact.find(id)
      return puts "That contact doesn't exist" if record.nil?

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
        puts "Phone #{index+1} (#{number[1]}):"
        new_phone = STDIN.gets.strip
        if !new_phone.empty?
          old_phone = PhoneNumber.find(number[0].to_i)
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
        PhoneNumber.create(new_phone, id)
      end
    when 'destroy'
      id = @input[1].to_i
      record = Contact.find(id)
      return puts "That contact doesn't exist" if record.nil?
      puts record.destroy.result_status == PG::Constants::PGRES_COMMAND_OK ? "Contact destroyed" : "Couldn't destroy contact"
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
  ContactList.new(ARGV).process
end
