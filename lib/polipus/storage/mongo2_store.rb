# encoding: UTF-8
require 'mongo'
require 'zlib'
require 'thread'

module Polipus
  module Storage
    class Mongo2Store < Base
      BINARY_FIELDS = %w(body headers data)
      def initialize(options = {})
        @mongo      = options[:mongo]
        @collection = options[:collection]
        #@mongo.create_collection(@collection)
        begin
          @mongo[@collection].ensure_index(:uuid, unique: true, dropDups: true, background: true)
        rescue Exception
        end

        @compress_body = options[:compress_body] ||= true
        @except = options[:except] ||= []
        @semaphore = Mutex.new
      end

      def add(page)
        @semaphore.synchronize do
          obj = page.to_hash
          @except.each { |e| obj.delete e.to_s }
          obj['uuid'] = uuid(page)
          obj['body'] = Zlib::Deflate.deflate(obj['body']) if @compress_body && obj['body']
          BINARY_FIELDS.each do |field|
            obj[field] = BSON::Binary.new(obj[field]) unless obj[field].nil?
          end
          @mongo[@collection].insert_one(obj)

          obj['uuid']
        end
      end

      def exists?(page)
        @semaphore.synchronize do
          doc = @mongo[@collection].find(uuid: uuid(page)).projection(_id: 1).limit(1).first
          !doc.nil?
        end
      end

      def get(page)
        @semaphore.synchronize do
          data = @mongo[@collection].find(uuid: uuid(page)).limit(1).first
          return load_page(data) if data
        end
      end

      def remove(page)
        @semaphore.synchronize do
          @mongo[@collection].remove(uuid: uuid(page))
        end
      end

      def count
        @mongo[@collection].count
      end

      def each
        @mongo[@collection].find({}, timeout: false) do |cursor|
          cursor.each do |doc|
            page = load_page(doc)
            yield doc['uuid'], page
          end
        end
      end

      def get_by_request_id(request_id)
        @semaphore.synchronize do
          pages = []
          documents = @mongo[@collection].find('user_data.request_id' => request_id)
          documents.each do |doc|
            pages << load_page(doc)
          end
          pages
        end
      end

      def clear
        @mongo[@collection].drop
      end

      private

      def load_page(hash)
        BINARY_FIELDS.each do |field|
          hash[field] = hash[field].data unless hash[field].nil?
        end
        hash['body'] = Zlib::Inflate.inflate(hash['body']).force_encoding("ISO-8859-1").encode("UTF-8") if @compress_body && hash['body'] && !hash['body'].empty?
        page = Page.from_hash(hash)
        if page.fetched_at.nil?
          page.fetched_at = hash['_id'].generation_time.to_i
        end
        page
      end
    end
  end
end