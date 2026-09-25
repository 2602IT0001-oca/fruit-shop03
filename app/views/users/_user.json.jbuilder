json.extract! user, :id, :name, :age, :password, :email, :created_at, :updated_at
json.url user_url(user, format: :json)
