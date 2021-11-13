#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bcrypt'
require 'dotenv'
require 'json'
require 'jwt'
require 'sequel'
require 'sinatra'

Dotenv.load

DB = Sequel.postgres(host: ENV['host'], user: ENV['user'], password: ENV['password'], database: ENV['database'])

DB.create_table?(:users) do
  primary_key :id
  String :username, unique: true, null: false
  String :email, unique: true, null: false
  String :password, unique: true, null: false
end

DB.create_table?(:energy) do
  foreign_key :user_id, :users
  Float :energy_level
  DateTime :timestamp
end

set :port, 4000

get '/' do
  'Hello There!'
end

post '/signUp' do
  data = JSON.parse(request.body.read)
  username = data['username']
  email = data['email']
  password = data['password']
  users = DB[:users]
  users.insert(username: username, email: email, password: BCrypt::Password.create(password))
  200
end

post '/login' do
  data = JSON.parse(request.body.read)
  username = data['username']
  password = data['password']
  users = DB[:users]
  user = users.where(username: username).first
  payload = { 'user_id': user[:id] }
  token = JWT.encode payload, nil, 'none'
  response = token
  response = 403 unless BCrypt::Password.new(user[:password]) == password
  response
end

get '/validate' do
  data = params['jwt']
  puts data
  puts JWT.decode data, nil, false
  200
end
