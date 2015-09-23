module Polipus
  module Storage

    def self.mongo2_store(mongo = nil, collection = COLLECTION, except = [])
      require 'polipus/storage/mongo2_store'
      mongo ||= Mongo::Client.new(['127.0.0.1:27017'], database: 'polipus')
      fail 'First argument must be an instance of Mongo::DB' unless mongo.is_a?(Mongo::Client)
      self::Mongo2Store.new(mongo: mongo, collection: collection, except: except)
    end
  end
end
