require 'base_model'

describe BaseModel do
  context 'class methods' do
    describe '.connection' do
      it 'returns a postgres connect object' do
        conn = Contact.connection 
        expect(conn).to be_a(PG::Connection)
      end
    end
  end
end
