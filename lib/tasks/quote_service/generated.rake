require 'rack'
require './lib/quote_service/generated'

namespace :quote_service do
  
  task :generated do
    service = Rack::Builder.app do
      use Rack::Stream
      run QuoteService::Generated.new
    end
        
    Rack::Handler::Thin.run(service, { :Port => API_CONFIG['simulation']['generated']['port'] })
  end
  
end