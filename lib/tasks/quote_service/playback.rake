require 'rack'
require './lib/quote_service/generated'

namespace :quote_service do
  
  task :playback do
    service = Rack::Builder.app do
      use Rack::Stream
      run QuoteService::Playback.new
    end
        
    Rack::Handler::Thin.run(service, { :Port => API_CONFIG['simulation']['playback']['port'] })
  end
  
end