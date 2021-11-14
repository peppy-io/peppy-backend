#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bcrypt'
require 'dotenv'
require 'json'
require 'jwt'
require 'multi_json'
require 'sequel'
require 'sinatra'
require "sinatra/cors"

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
  String :event
end

set :port, 4000

set :allow_origin, "*"
set :allow_methods, "GET,POST"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"
set :allow_credentials, true

helpers do
  # gets <token> from:
  #   {"Authorization": <token>}
  def authorized?
    # token = request.env['access_token']
    token = request.env['HTTP_AUTHORIZATION']
    token.nil? ? false : true
  end

  def extract_user_id
    token = request.env['HTTP_AUTHORIZATION']
    begin
      payload = JWT.decode token, nil, false
      payload[0]['user_id']
    rescue Error
      # handle error
      halt 400
    end
  end
end

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

post '/log' do
  unless authorized?
    halt 403, 'Unauthorized'
  end
  user_id = extract_user_id
  data = JSON.parse(request.body.read)
  energy_level = data['energy_level']
  event = data['event']
  timestamp = DateTime.parse(data['timestamp'])
  energy = DB[:energy]
  energy.insert(user_id: user_id, energy_level: energy_level, timestamp: timestamp, event: event)
  200
end

get '/energyLevels/day' do
  unless authorized?
    halt 403, 'Unauthorized'
  end
  user_id = extract_user_id
  date = DateTime.now
  upper_limit = DateTime.new(date.year, date.month, date.day)
  upper_limit = upper_limit.new_offset(date.zone.to_str)
  lower_limit = DateTime.new(date.year, date.month, date.day + 1)
  lower_limit = lower_limit.new_offset(date.zone.to_str)
  DB[:energy]
    .where(user_id: user_id)
    .where { (timestamp < Time.new(upper_limit.to_s)) && (timestamp >= Time.new(lower_limit.to_s)) }
    .map { |e| e.to_json }
end

get '/energyLevels/month' do
  unless authorized?
    halt 403, 'Unauthorized'
  end
  user_id = extract_user_id
  date = DateTime.now
  upper_limit = DateTime.new(date.year, date.month)
  upper_limit = upper_limit.new_offset(date.zone.to_str)
  lower_limit = DateTime.new(date.year, date.month + 1)
  lower_limit = lower_limit.new_offset(date.zone.to_str)
  DB[:energy]
    .where(user_id: user_id)
    .where { (timestamp < Time.new(upper_limit.to_s)) && (timestamp >= Time.new(lower_limit.to_s)) }
    .map { |e| e.to_json }
end

get '/energyLevels' do
  unless authorized?
    halt 403, 'Unauthorized'
  end
  user_id = extract_user_id
  date = DateTime.now
  upper_limit = DateTime.new(date.year)
  upper_limit = upper_limit.new_offset(date.zone.to_str)
  lower_limit = DateTime.new(date.year + 1)
  lower_limit = lower_limit.new_offset(date.zone.to_str)
  puts Time.new(upper_limit.to_s)
  puts Time.new(lower_limit.to_s)
  DB[:energy]
    .where(user_id: user_id)
    .map { |e| e.to_json }
end
