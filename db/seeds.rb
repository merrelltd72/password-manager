# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# User.create!(username: "tyron", email: "tyron@example.com", password: "password")
# User.create!(username: "merrell", email: "merrell@example.com", password: "password")

Category.create!(category_type: "Personal")
Category.create!(category_type: "Work")
Category.create!(category_type: "Shared")

Account.create!(user_id: "1", category_id: 1, web_app_name: "Facebook", url: "www.facebook.com", username: "stud_t", password: "password", notes: "This is a journey into Facebook")
Account.create!(user_id: "2", category_id: 1, web_app_name: "World of Warcraft", url: "www.battle.net", username: "that_t", password: "password", notes: "This is a journey into WoW")
Account.create!(user_id: "1", category_id: 2, web_app_name: "LinkedIn", url: "www.linkedin.com", username: "mrt", password: "password", notes: "This is a journey into LinkedIn")
Account.create!(user_id: "1", category_id: 3, web_app_name: "Home Cooking", url: "www.homecooking.com", username: "thets", password: "password", notes: "This is a journey into Home Cooking")
Account.create!(user_id: "2", category_id: 3, web_app_name: "Delta Airlines", url: "www.delta.com", username: "stuck_t", password: "password", notes: "This is a journey into Delta Airline")
Account.create!(user_id: "1", category_id: 1, web_app_name: "Steam", url: "www.steam.com", username: "clean_t", password: "password", notes: "This is a journey into Steam")
Account.create!(user_id: "2", category_id: 2, web_app_name: "GitHub", url: "www.github.com", username: "submit_t", password: "password", notes: "This is a journey into GitHub")