require 'phone_number'

describe PhoneNumber do
  context 'class methods' do

    describe '.all'do
      it 'returns a formatted list of all phone_numbers belonging to a contact' do
        expect(PhoneNumber.all(1)).to eq([['1', '(604)555-1234']])
        expect(PhoneNumber.all(2)).to eq([['2', '(604)555-4321']])
        PhoneNumber.connection.exec("INSERT INTO phone_numbers (number, contact_id) VALUES ('(604)266-1234', 2)");
        expect(PhoneNumber.all(2)).to eq([['2', '(604)555-4321'], ['3', '(604)266-1234']])
        PhoneNumber.connection.exec("DELETE FROM phone_numbers WHERE contact_id = 1");
        expect(PhoneNumber.all(1)).to eq([])
      end
    end 

    describe '.create'do
      before(:each) do
        @number = '(604)266-1234'
        @contact_id = 1 
      end

      it 'responds with OK' do
        response = PhoneNumber.create(@number, @contact_id)
        expect(response.result_status).to eq(PG::Constants::PGRES_COMMAND_OK)
      end

      it 'adds a new phone_number to the database' do
        results = PhoneNumber.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(2)

        phone_number = PhoneNumber.create(@number, @contact_id)

        results = PhoneNumber.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(3)
      end
    end 

    describe '.find'do
      # This is a bit brittle in that it assumes the IDs will start at 1
      it 'finds the phone_number with the given id' do
        record = PhoneNumber.find(1) 
        expect(record.id).to eq("1")
        expect(record.number).to eq("(604)555-1234")
        expect(record.contact_id).to eq("1")
        record = PhoneNumber.find(2) 
        expect(record.id).to eq("2")
        expect(record.number).to eq("(604)555-4321")
        expect(record.contact_id).to eq("2")
      end 

      it "doesn't barf if the given id is out of range" do
        record = PhoneNumber.find(0) 
        expect(record).to eq(nil)
        record = PhoneNumber.find(3) 
        expect(record).to eq(nil)
        record = PhoneNumber.find('junk') 
        expect(record).to eq(nil)
      end
    end 

    describe '.search'do
      it 'finds the contacts that match the phone_number provided' do
        records = PhoneNumber.search('(604)555-1234') 
        expect(records.count).to eq(1)
        expect(records[0][0]).to eq("1")
        expect(records[0][1]).to eq("Khurram Virani")
        expect(records[0][2]).to eq("kvirani@lighthouselabs.ca")
        records = PhoneNumber.search('1234') 
        expect(records.count).to eq(1)
        expect(records[0][0]).to eq("1")
        expect(records[0][1]).to eq("Khurram Virani")
        expect(records[0][2]).to eq("kvirani@lighthouselabs.ca")
        records = PhoneNumber.search('555-4321') 
        expect(records.count).to eq(1)
        expect(records[0][0]).to eq("2")
        expect(records[0][1]).to eq("Don Burks")
        expect(records[0][2]).to eq("don@lighthouselabs.ca")
        records = PhoneNumber.search('604') 
        expect(records.count).to eq(2)
        expect(records[0][0]).to eq("1")
        expect(records[0][1]).to eq("Khurram Virani")
        expect(records[0][2]).to eq("kvirani@lighthouselabs.ca")
        expect(records[1][0]).to eq("2")
        expect(records[1][1]).to eq("Don Burks")
        expect(records[1][2]).to eq("don@lighthouselabs.ca")
      end 

      it "doesn't barf if the search term doesn't match" do
        records = PhoneNumber.search('555-5555') 
        expect(records.count).to eq(0)
        records = PhoneNumber.search('')
        expect(records.count).to eq(0)
        records = PhoneNumber.search('    ')
        expect(records.count).to eq(0)
        records = PhoneNumber.search
        expect(records.count).to eq(0)
      end 
    end

    describe '.connection' do
      it 'returns a postgres connect object' do
        conn = PhoneNumber.connection 
        expect(conn).to be_a(PG::Connection)
      end
    end
  end

  context 'instance methods' do
    before(:each) do
      @phone_number = PhoneNumber.new('(604)555-0000', '1')
    end

    describe '#save' do
      it 'inserts new data into the database' do
        expect(@phone_number.class.connection).to receive(:exec_params).
          with("INSERT INTO phone_numbers (number, contact_id) VALUES ($1, $2)", ['(604)555-0000', '1']).once
        @phone_number.save
      end

      it 'updates existing data in the database' do
        @phone_number.save
        results = PhoneNumber.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(3)

        phone_number = PhoneNumber.find(3)
        expect(phone_number.id).to eq('3')
        expect(phone_number.number).to eq('(604)555-0000')
        expect(phone_number.contact_id).to eq('1')

        phone_number.number = '(604)555-9999'
        phone_number.save

        results = PhoneNumber.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(3)

        phone_number = PhoneNumber.find(3)
        expect(phone_number.id).to eq('3')
        expect(phone_number.number).to eq('(604)555-9999')
        expect(phone_number.contact_id).to eq('1')
      end
    end

    describe '#destroy' do
      it 'makes the correct database query' do
        phone_number = PhoneNumber.find(2)
        expect(phone_number.class.connection).to receive(:exec_params).
          with("DELETE FROM phone_numbers WHERE id = $1::int", ['2']).once
        phone_number.destroy
      end

      it 'removes phone_number from the database' do
        @phone_number.save
        results = PhoneNumber.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(3)

        phone_number = PhoneNumber.find(3)
        expect(phone_number.destroy.result_status).to eq(PG::Constants::PGRES_COMMAND_OK)

        results = PhoneNumber.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(2)

        phone_number = PhoneNumber.find(1)
        expect(phone_number.destroy.result_status).to eq(PG::Constants::PGRES_COMMAND_OK)

        results = PhoneNumber.connection.exec('SELECT count(*) FROM phone_numbers');
        expect(results.values[0][0].to_i).to eq(1)
      end
    end
  end
end
