module DataStreamer
  class Base
    def initialize(account)
      @account = account
    end

    def stream_quotes(symbols, callback)
      raise NotImplementedError
    end

    def date
      raise NotImplementedError
    end

    def add_securities(securities)
      securities = [security].flatten

      # TODO
      # ...
    end
  end
end