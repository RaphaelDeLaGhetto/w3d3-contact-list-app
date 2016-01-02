require 'phone_number'

describe PhoneNumber do
  context 'class methods' do

    describe '.search'do
      it 'finds the contacts that match the phone_number provided' do
        records = PhoneNumber.search('(604)555-1234') 
        expect(records.count).to eq(1)
        expect(records[0].id).to eq(1)
        expect(records[0].name).to eq("Khurram Virani")
        expect(records[0].email).to eq("kvirani@lighthouselabs.ca")
        records = PhoneNumber.search('1234') 
        expect(records.count).to eq(1)
        expect(records[0].id).to eq(1)
        expect(records[0].name).to eq("Khurram Virani")
        expect(records[0].email).to eq("kvirani@lighthouselabs.ca")
        records = PhoneNumber.search('555-4321') 
        expect(records.count).to eq(1)
        expect(records[0].id).to eq(2)
        expect(records[0].name).to eq("Don Burks")
        expect(records[0].email).to eq("don@lighthouselabs.ca")
        records = PhoneNumber.search('604') 
        expect(records.count).to eq(2)
        expect(records[0].id).to eq(1)
        expect(records[0].name).to eq("Khurram Virani")
        expect(records[0].email).to eq("kvirani@lighthouselabs.ca")
        expect(records[1].id).to eq(2)
        expect(records[1].name).to eq("Don Burks")
        expect(records[1].email).to eq("don@lighthouselabs.ca")
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
  end
end
