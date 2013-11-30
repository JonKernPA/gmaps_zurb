# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    latitude 1.5
    longitude 1.5
    address "MyString"
    description "MyString"
    title "MyString"
  end
end
