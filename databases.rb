#!/usr/bin/env ruby
# frozen_string_literal: true

require "pry"
require "pg"
require "logger"
require "yaml"

# Class controlling db connections
class Database
  attr_accessor :name,
                :connection

  def initialize(input_array)
    @name = input_array["name"]
    @host = input_array["host"]
    @port = input_array["port"]
    @database = input_array["database"]
    @username = input_array["user"]
    @password = input_array["password"]
    @options = input_array["options"]
    @connection = nil

    @@all << self
  end

  def connect_to_database
    @connection = PG::Connection.new(@host, @port, @options, nil, @database, @username, @password) if @connection.nil?
  end

  class << self
    @@all = []

    def load_from_yaml
      LOGGER.info "Building database array"
      databases = YAML.load_file("databases.yml")["databases"]
      databases.each { |d| Database.new(d) }
    end

    def all
      @@all
    end

    def each
      @@all.each { |action| yield action }
    end
  end
end
