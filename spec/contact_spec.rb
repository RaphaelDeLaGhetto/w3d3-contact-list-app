require 'contact'

describe Contact do
  context 'class methods' do
    describe '.search'do
      it 'finds the contacts that match the search term provided' do
        records = Contact.search('khurram') 
        expect(records.count).to eq(1)
        expect(records[0].id).to eq(1)
        expect(records[0].name).to eq("Khurram Virani")
        expect(records[0].email).to eq("kvirani@lighthouselabs.ca")
        records = Contact.search('kvirani') 
        expect(records.count).to eq(1)
        expect(records[0].id).to eq(1)
        expect(records[0].name).to eq("Khurram Virani")
        expect(records[0].email).to eq("kvirani@lighthouselabs.ca")
        records = Contact.search('don') 
        expect(records.count).to eq(1)
        expect(records[0].id).to eq(2)
        expect(records[0].name).to eq("Don Burks")
        expect(records[0].email).to eq("don@lighthouselabs.ca")
        records = Contact.search('LIGHTHOUSE') 
        expect(records.count).to eq(2)
        expect(records[0].id).to eq(1)
        expect(records[0].name).to eq("Khurram Virani")
        expect(records[0].email).to eq("kvirani@lighthouselabs.ca")
        expect(records[1].id).to eq(2)
        expect(records[1].name).to eq("Don Burks")
        expect(records[1].email).to eq("don@lighthouselabs.ca")
      end 

      it "doesn't barf if the search term doesn't match" do
        records = Contact.search('daniel') 
        expect(records.count).to eq(0)
        records = Contact.search('')
        expect(records.count).to eq(0)
        records = Contact.search('    ')
        expect(records.count).to eq(0)
        records = Contact.search
        expect(records.count).to eq(0)
      end 
    end
  end
end
