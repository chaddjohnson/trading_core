module QuoteStreamer
  class Base
    def initialize(account)
      @account = account
    end

    def stream_quotes(symbols, callback, attempts = 0)
      raise NotImplementedError
    end

    def date
      raise NotImplementedError
    end

    def stop
      raise NotImplementedError
    end

    def add_securities(securities)
      securities = [security].flatten

      # TODO
      # ...
    end

    def live?
      railse NotImplementedError
    end
  end
end