ActiveRecord::Schema.define do
  create_table :contacts, force: true do |t|
    t.string     :name
    t.string     :email
  end
end
