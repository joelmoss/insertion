# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :email
    t.integer :age
    t.timestamps null: false
  end

  create_table :posts, force: true do |t|
    t.string :title
    t.text :body
    t.integer :user_id
    t.timestamps null: false
  end
end
