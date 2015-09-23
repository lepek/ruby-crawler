require 'polipus'
require 'mongo'
require 'polipus/plugins/cleaner'

class CrawlWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :crawl

  def perform(url, request_id)
    mongo = Mongo::Client.new(['127.0.0.1:27017'], database: 'crawler')

    # Override some default options
    options = {
        # Redis connection
        redis_options: {
            host: 'localhost',
            db: 5,
            driver: 'hiredis'
        },

        # Page storage: pages is the name of the collection where
        # pages will be stored
        storage: Polipus::Storage.mongo2_store(mongo, 'pages'),

        # Use your custom user agent
        user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9) AppleWebKit/537.71 (KHTML, like Gecko) Version/7.0 Safari/537.71',

        # Use 5 threads
        workers: 5,

        # Queue overflow settings:
        #  * No more than 5000 elements on the Redis queue
        #  * Exceeded Items will stored on Mongo into 'crawler_queue_overflow' collection
        #  * Check cycle is done every 60 sec
        #queue_items_limit: 5000,
        #queue_overflow_adapter: Polipus::QueueOverflow.mongo2_queue(mongo, 'crawler_queue_overflow'),
        #queue_overflow_manager_check_time: 60,

        # Logs goes to the stdout
        logger: Logger.new(STDOUT)
    }
    starting_urls = [url]

    #Polipus::Plugin.register Polipus::Plugin::Cleaner, reset: true

    Polipus.crawler('test-crawl', starting_urls, options) do |crawler|

      crawler.on_crawl_start do
        Crawl.find_by_request_id(request_id).update_attributes!(
            status: :in_progress
        )
      end

      # Adding some metadata to a page
      # The metadata will be stored on mongo
      crawler.on_before_save do |page|
        page.user_data.request_id = request_id
      end

      crawler.on_crawl_end do
        crawl = Crawl.find_by_request_id(request_id)
        crawl.update_attributes!(
          status: :completed,
          elapsed_time: (Time.now - crawl.created_at).to_f * 1000.0
        )
      end

    end

  end
end