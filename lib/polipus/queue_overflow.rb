# encoding: UTF-8
require 'polipus/queue_overflow/manager'
require 'polipus/queue_overflow/worker'
module Polipus
  module QueueOverflow
    def self.mongo2_queue(mongo_db, queue_name, options = {})
      require 'polipus/queue_overflow/mongo2_queue'
      fail 'First argument must be an instance of Mongo::DB' unless mongo_db.is_a?(Mongo::Client)
      self::Mongo2Queue.new mongo_db, queue_name, options
    end

=begin
    def self.mongo2_queue_capped(mongo_db, queue_name, options = {})
      require 'polipus/queue_overflow/mongo_queue_capped'
      fail 'First argument must be an instance of Mongo::DB' unless mongo_db.is_a?(Mongo::Client)
      options[:max] = 1_000_000 if options[:max].nil?
      self::MongoQueueCapped.new mongo_db, queue_name, options
    end
=end
  end
end