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

    def add_security(security)
      securities = [security].flatten

      # TODO
      # ...
    end

    private

    def connect(*args)
      raise NotImplementedError
    end
  end
end