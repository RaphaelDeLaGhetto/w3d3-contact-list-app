require_relative '../contact_list'
require './lib/contact'

describe ContactList do
  describe '#process' do

    context 'program is executed without arguments' do
      it "displays a help menu" do
        expect { ContactList.new([]).process }.to output("Here is a list of available commands:\n"\
                                                         "  new     - Create a new contact\n"\
                                                         "  list    - List all contacts\n"\
                                                         "  show    - Show a contact\n"\
                                                         "  search  - Search contacts\n"\
                                                         "  update  - Update a contact\n"\
                                                         "  destroy - Remove a contact\n").to_stdout
      end
    end
  
    context "program is executed with 'list' argument" do
      it "outputs a list of all contacts" do
        expect { ContactList.new(['list']).process }.to output("1: Khurram Virani (kvirani@lighthouselabs.ca)\n"\
                                                               "2: Don Burks (don@lighthouselabs.ca)\n"\
                                                               "---\n"\
                                                               "2 records total\n").to_stdout
      end
    end

    context "program is executed with 'new' argument" do
      before(:each) do
        # New contact details
        @name = 'Dan'
        @email = 'daniel@capitolhill.ca'

        # Stage the test
        @contact_list = ContactList.new(['new'])

        # Commandline input 
        call = -1 
        allow(STDIN).to receive_message_chain(:gets) do 
          [@name, @email][call += 1]
        end
        @response = @contact_list.process
      end

      it "prompts agent for name and email information" do
        expect(STDOUT).to receive(:puts).with('Name:')
        expect(STDOUT).to receive(:puts).with('Email:')

        contact = ContactList.new(['new'])

        allow(STDIN).to receive(:gets) { 'some input' }
        contact.process
      end

      it "adds a new contact to the database" do
        results = Contact.connection.exec('SELECT count(*) FROM contacts');
        expect(results.values[0][0].to_i).to eq(3)
      end

      it "responds with OK" do
        expect(@response.result_status).to eq(PG::Constants::PGRES_COMMAND_OK)
      end
    end

    context "program is executed with 'show' argument" do
      it 'outputs the information belonging to the contact with the corresponding id' do
        expect { ContactList.new(['show', '1']).process }.to output("1: Khurram Virani (kvirani@lighthouselabs.ca)\n"\
                                                                    "   (604)555-1234\n").to_stdout
        expect { ContactList.new(['show', '2']).process }.to output("2: Don Burks (don@lighthouselabs.ca)\n"\
                                                                    "   (604)555-4321\n").to_stdout
        Contact.connection.exec("INSERT INTO phone_numbers (number, contact_id) VALUES ('(604)266-1234', 2)");
        expect { ContactList.new(['show', '2']).process }.to output("2: Don Burks (don@lighthouselabs.ca)\n"\
                                                                    "   (604)555-4321\n"\
                                                                    "   (604)266-1234\n").to_stdout
      end

      it "doesn't barf if the given id is out of range" do
        expect { ContactList.new(['show', '-1']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['show', '0']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['show', '3']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['show', 'junk']).process }.to output("That contact doesn't exist\n").to_stdout
      end
    end

    context "program is executed with 'search' argument" do
      it 'outputs the information belonging to the contacts whose details match the search term' do
        expect { ContactList.new(['search', 'khurram']).process }.to output("1: Khurram Virani (kvirani@lighthouselabs.ca)\n"\
                                                                            "---\n"\
                                                                            "1 record total\n").to_stdout
        expect { ContactList.new(['search', 'don']).process }.to output("2: Don Burks (don@lighthouselabs.ca)\n"\
                                                                        "---\n"\
                                                                        "1 record total\n").to_stdout
        expect { ContactList.new(['search', 'LIGHTHOUSE']).process }.to output("1: Khurram Virani (kvirani@lighthouselabs.ca)\n"\
                                                                               "2: Don Burks (don@lighthouselabs.ca)\n"\
                                                                               "---\n"\
                                                                               "2 records total\n").to_stdout
      end

      it "doesn't barf if nothing matches the search term" do
         expect { ContactList.new(['search', 'daniel']).process }.to output("---\n"\
                                                                            "0 records total\n").to_stdout
      end
    end

    context "program is executed with 'update' argument" do
      before(:each) do
        @name = "Khurram Macho Man Virani"
        @email = "khurram@wwe.com"
        @phone = "(604)555-9999"
      end

      it "prompts agent for name and email information" do
        expect(STDOUT).to receive(:puts).with('Name (Khurram Virani):')
        expect(STDOUT).to receive(:puts).with('Email (kvirani@lighthouselabs.ca):')
        expect(STDOUT).to receive(:puts).with("Enter 'X' to delete phone number")
        expect(STDOUT).to receive(:puts).with('Phone 1 ((604)555-1234):')
        expect(STDOUT).to receive(:puts).with('New phone number:')

        contact = ContactList.new(['update', '1'])
        call = -1 
        allow(STDIN).to receive_message_chain(:gets) do 
          [@name, @email, @phone, ''][call += 1]
        end
        contact.process
      end

      it "updates the existing contact database" do
        results = Contact.connection.exec("SELECT * FROM contacts WHERE id = '1'");
        expect(results.values[0][0]).to eq('1')
        expect(results.values[0][1]).to eq('Khurram Virani')
        expect(results.values[0][2]).to eq('kvirani@lighthouselabs.ca')

        phone_numbers = Contact.connection.exec("SELECT * FROM phone_numbers WHERE contact_id = 1")
        expect(phone_numbers.values[0][0]).to eq('1')
        expect(phone_numbers.values[0][1]).to eq('(604)555-1234')
        expect(phone_numbers.values[0][2]).to eq('1')
        
        contact = ContactList.new(['update', '1'])

        # Commandline input 
        call = -1 
        allow(STDIN).to receive_message_chain(:gets) do 
          [@name, @email, @phone, ''][call += 1]
        end
        contact.process

        results = Contact.connection.exec("SELECT * FROM contacts WHERE id = '1'");
        expect(results.values[0][0]).to eq('1')
        expect(results.values[0][1]).to eq('Khurram Macho Man Virani')
        expect(results.values[0][2]).to eq('khurram@wwe.com')

        phone_numbers = Contact.connection.exec("SELECT * FROM phone_numbers WHERE contact_id = 1")
        expect(phone_numbers.values.count).to eq(1)
        expect(phone_numbers.values[0][0]).to eq('1')
        expect(phone_numbers.values[0][1]).to eq('(604)555-9999')
        expect(phone_numbers.values[0][2]).to eq('1')
      end

      it "does not add a new record" do
        results = Contact.connection.exec('SELECT count(*) FROM contacts');
        expect(results.values[0][0].to_i).to eq(2)

        contact = ContactList.new(['update', '1'])
        call = -1 
        allow(STDIN).to receive_message_chain(:gets) do 
          ['some input', ' some input  ', "some input\n", ''][call += 1]
        end
        contact.process

        results = Contact.connection.exec('SELECT count(*) FROM contacts');
        expect(results.values[0][0].to_i).to eq(2)
      end

      it "doesn't change record if no input provided" do
        results = Contact.connection.exec("SELECT * FROM contacts WHERE id = '1'");
        expect(results.values[0][0]).to eq('1')
        expect(results.values[0][1]).to eq('Khurram Virani')
        expect(results.values[0][2]).to eq('kvirani@lighthouselabs.ca')

        contact = ContactList.new(['update', '1'])

        call = -1 
        allow(STDIN).to receive_message_chain(:gets) do 
          ['', '   ', "\n", ''][call += 1]
        end
        contact.process

        results = Contact.connection.exec("SELECT * FROM contacts WHERE id = '1'");
        expect(results.values[0][0]).to eq('1')
        expect(results.values[0][1]).to eq('Khurram Virani')
        expect(results.values[0][2]).to eq('kvirani@lighthouselabs.ca')
      end

      it "doesn't barf if ID is out of range" do
        expect { ContactList.new(['update', '-1']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['update', '0']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['update', '3']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['update', 'junk']).process }.to output("That contact doesn't exist\n").to_stdout
      end

      it "lets you delete phone numbers by entering 'X'" do
        results = Contact.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(2)

        contact = ContactList.new(['update', '1'])

        call = -1 
        allow(STDIN).to receive_message_chain(:gets) do 
          ['', '   ', 'X', ''][call += 1]
        end
        contact.process

        results = Contact.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(1)
      end

      it "lets you add new phone numbers" do
        results = Contact.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(2)

        contact = ContactList.new(['update', '1'])

        call = -1 
        allow(STDIN).to receive_message_chain(:gets) do 
          ['', '   ', '', '(604)555-0000', '(604)555-9999', '   '][call += 1]
        end
        contact.process

        results = Contact.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(4)
      end
    end

    context "program is executed with 'destroy' argument" do
      it "reports success if contact is removed from the database" do
        results = Contact.connection.exec('SELECT count(*) FROM contacts');
        expect(results.values[0][0].to_i).to eq(2)

        expect { ContactList.new(['destroy', '1']).process }.to output("Contact destroyed\n").to_stdout

        results = Contact.connection.exec('SELECT count(*) FROM contacts');
        expect(results.values[0][0].to_i).to eq(1)

        expect { ContactList.new(['destroy', '2']).process }.to output("Contact destroyed\n").to_stdout

        results = Contact.connection.exec('SELECT count(*) FROM contacts');
        expect(results.values[0][0].to_i).to eq(0)
      end
     
      it "doesn't barf if contact doesn't exist" do
        expect { ContactList.new(['destroy', '-1']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['destroy', '0']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['destroy', '3']).process }.to output("That contact doesn't exist\n").to_stdout
        expect { ContactList.new(['destroy', 'junk']).process }.to output("That contact doesn't exist\n").to_stdout
      end
    end
  end
end
