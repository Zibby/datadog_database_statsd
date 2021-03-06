#!/usr/bin/env ruby
# frozen_string_literal: true

require "datadog/statsd"
require "pg"
require "yaml"
require "logger"
require "socket"
require "timeout"
require 'pry'

LOGGER = Logger.new(STDOUT).freeze
TIMEOUT = 500 # Time SQL queries can run for before timeing out in seconds
LOGGER.info "Logger initiated"
# Create a stats instance.
STATSD = Datadog::Statsd.new(
  nil,
  nil,
  socket_path: "/var/run/datadog/dsd.socket",
  logger: LOGGER
).freeze

class Monitorables
  attr_accessor :value,
                :query_frequency, # maybe, gets into the relm of redis/delayedjobs
                #                   and having another db to manage (maybe lightsql?)
                :metric_type,
                :tags,
                :blocker

  def initialize(query)
    @name = query["name"]
    @psql_query = query["query"] # should probably rename something :facepalm:
    @metric_type = query["metric_type"].downcase
    db_name = query["database"]
    @database = select_database(db_name)
    @database_name = query["database_name"]

    @@all << self
  end

  def process
    @value = run_query
    send_to_datadog
  end

  def send_to_datadog
    case @value
    when nil
      @blocker = 20
      datadog_event("Got a nil value for #{@name}, holding back for #{@blocker} cycles")
    else
      send(@metric_type)
    end
  end

  def select_database(db_name)
    LOGGER.info "selecting database: #{db_name}"
    databases = YAML.load_file("databases.yml")["databases"]
    databases.select { |db| db["name"] == db_name }.first
  end

  def connect_to_database
    LOGGER.info "connecting to database"
    PG::Connection.new(
      @database["host"],
      @database["port"],
      @database["options"],
      @database["tty"],
      @database["database"],
      @database["user"],
      @database["password"]
    )
  end

  def exec_with_timer
    conn = connect_to_database
    t1 = Time.now.to_i
    result = conn.exec(@psql_query).getvalue(0, 0)
    t2 = Time.now.to_i
    time_taken = t2 - t1
    LOGGER.info "finished query, took #{time_taken}s"
    conn.finish
    result
  end

  def run_query
    LOGGER.info "running query: #{@psql_query}"
    begin
      exec_with_timer
    rescue StandardError => e
      datadog_event(e.message, "error", [@database_name, @name])
    end
  end

  def datadog_event(message, alert_type = "info", tags = [])
    hostname = Socket.gethostname
    STATSD.event("#{hostname} dd-statsd-posgres", message, alert_type: alert_type, tags: tags)
  end

  def gauge
    # LOGGER.info "sending #{@name} = #{@value} as a GAUGE"
    STATSD.gauge(@name, @value)
  end

  def count
    # LOGGER.info "sending #{@name} = #{@value} as a COUNT"
    STATSD.count(@name, @value)
  end

  def should_skip?
    # always skip if enforced
    return true if @metric_type == "skip"

    # do nothing unless theres been a failure before
    return false unless ! @blocker.nil?

    @blocker -= 1
  end

  class << self
    @@all = []

    def all
      @@all
    end

    def load_from_yaml
      YAML.load_file("./queries.yml")["queries"].each do |query|
        new(query)
      end
    end

    def handle_skips(item)
      if item.metric_type == "skip"
        LOGGER.info "skipping because of enforced skip in query.metric_type"
      elsif !item.blocker.nil?
        LOGGER.info "skipping because of past faulure. Skipping for #{item.blocker} runs"
      else
        LOGGER.error "unhandled error"
      end
    end

    def each_do
      count = 0
      @@all.each do |item|
        count += 1
        LOGGER.info "Doing #{count} of #{@@all.count}"
        if item.should_skip?
          handle_skips(item)
          next
        end
        yield item
      end
    end
  end
end

LOGGER.info "Starting"
Monitorables.load_from_yaml

loop do
  LOGGER.info "Kicking off loop"
  Monitorables.each_do { |q| q&.process }

  LOGGER.info "sleeping"
  sleep 60
end
