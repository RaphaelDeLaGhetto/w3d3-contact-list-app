require 'pg'

# Base functionality for interacting with the contacts database 
class BaseModel

  class << self
    # Get the postgres connection object
    def connection
      @conn = PG.connect(dbname: 'contacts') if @conn.nil?
      @conn
    end
  end
end
