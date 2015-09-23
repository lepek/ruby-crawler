class Crawl < ActiveRecord::Base
  enum status: [:queued, :in_progress, :completed, :failed]

  after_commit :start_crawling, :on => :create, :if => :queued?

  def start_crawling
    CrawlWorker.perform_async(self.url, self.request_id)
  end


end
