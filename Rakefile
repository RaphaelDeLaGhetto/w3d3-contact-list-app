require 'pg'
require 'csv'
require 'active_record'
require './lib/contact'
require './lib/phone_number'

def connect_and_create
  # Output messages from Active Record to standard out
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  
  puts 'Establishing connection to database ...'
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
  puts 'CONNECTED'
  
  puts 'Setting up Database (recreating tables) ...'
  
  ActiveRecord::Schema.define do
    drop_table :contacts if ActiveRecord::Base.connection.table_exists?(:contacts)
    drop_table :phone_numbers if ActiveRecord::Base.connection.table_exists?(:phone_numbers)

    create_table :contacts, force: true do |t|
      t.string :name
      t.string :email
      t.timestamps null: false
    end

    create_table :phone_numbers do |t|
      t.references :contact
      t.string :number
      t.timestamps null: false
    end
  end
end

namespace :test do

  desc 'setup test database'
  task :create_db do
    conn = PG.connect(dbname: 'postgres')
    conn.exec('DROP DATABASE IF EXISTS test_contacts')
    conn.exec('CREATE DATABASE test_contacts')
    connect_and_create
  end
end

desc 'setup database'
task :create_db do
  conn = PG.connect(dbname: 'postgres')
  conn.exec('DROP DATABASE IF EXISTS contacts')
  conn.exec('CREATE DATABASE contacts')
  connect_and_create

  CSV.foreach("data/contacts.csv") do |record|
    contact = Contact.where(name: record[0], email: record[1]).first_or_create
    contact.phone_numbers.create(number: record[2])
  end
end
