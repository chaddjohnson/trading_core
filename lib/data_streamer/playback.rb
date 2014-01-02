module DataStreamer
  class Playback < Base
    def stream_quotes(symbols, callback)
      
    end

    def date
      # TODO
    end

    private

    def connect(*args)
      EventMachine::HttpRequest.new(API_CONFIG['simulation']['playback']['port'])
    end
  end
end