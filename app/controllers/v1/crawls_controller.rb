module V1
  class CrawlsController < ::ApplicationController

    def create
      url = normalize(params[:url]) || nil
      request_id = params[:request_id] || request.uuid
      @crawl = Crawl.new(
          url: url,
          request_id: request_id
      )
      if valid_url?(url)
        @crawl.queued!
        render status: :accepted, json: {status: 'in_progress', request_id: request_id, url: url}
      else
        @crawl.failed!
        render status: :unprocessable_entity, json: {status: 'failed', error: 'Invalid URL'}
      end

    end

    def show
      request_id = params[:request_id]
      @crawl = Crawl.find_by_request_id(request_id)
      head status: :not_found and return if @crawl.nil?

      if @crawl.completed?
        mongo = Mongo::Client.new(['127.0.0.1:27017'], database: 'crawler')
        store = Polipus::Storage.mongo2_store(mongo, 'pages')
        pages = store.get_by_request_id(request_id)
        render status: :ok, json: pages
      else
        render status: :ok, json: {status: @crawl.status, request_id: request_id}
      end

    end

    private

    def normalize(url)
      url
    end

    def valid_url?(url)
      url.present?
    end

  end
end
