module DataStreamer
  class Generated < Base
    def stream_quotes(symbols, callback)
      
    end

    def date
      # TODO
    end

    private

    def connect(*args)
      EventMachine::HttpRequest.new(API_CONFIG['simulation']['generated']['port'])
    end
  end
end