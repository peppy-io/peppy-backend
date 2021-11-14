#!/usr/bin/env ruby

require 'dotenv'

Dotenv.load

port ENV['port']
workers 3
preload_app!
