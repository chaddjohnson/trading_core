require 'trading_core/trading_api/base'

module TradingCore
  class ClientDataBroker
    def initialize(quote_streamer, symbols)
      @quote_streamer = quote_streamer
      @securities = {}
      @clients = {}

      # Cache security records for each requested symbol.
      symbols.each do |symbol|
        @securities[symbol] = TradingCore::Security.where(:symbol => symbol).first
      end
    end

    def start
      previous_last_prices = {}

      callback = lambda do |data|
        symbol = data['symbol']

        # Skip major spike quotes.
        previous_last_prices[symbol] ||= data['last_price'].to_f
        next if data['last_price'].to_f / previous_last_prices[symbol] > 1.015
        next if data['last_price'].to_f / previous_last_prices[symbol] < 0.985

        # Build the response and send it to each client subscribed to the symbol.
        response_data = {
          :type => TradingApi.types[:stream_quotes],
          :data => data
        }.to_json
        @clients[symbol].each do |client|
          client.send(response_data)
        end if @clients[symbol]

        # Record history (only in live mode).
        Quote.create({
          :security_id       => @securities[symbol].id,
          :last_price        => data['last_price'].to_f,
          :bid_price         => data['bid_price'].to_f,
          :ask_price         => data['ask_price'].to_f,
          :date              => Date.today,
          :timestamp         => Time.now.getutc,
          :trade_volume      => data['trade_volume'].to_i,
          :cumulative_volume => data['cumulative_volume'].to_i,
          :average_volume    => data['average_volume'].to_i,
        }) if @quote_streamer.live?

        previous_last_prices[symbol] = data['last_price'].to_f
      end

      @quote_streamer.stream_quotes(@securities.values.map(&:symbol), callback)
    end

    def stop
      # TODO
    end

    def add_client(symbol, client)
      @securities[symbol] = TradingCore::Security.where(:symbol => symbol).first if !@securities[symbol]

      @clients[symbol] ||= []
      @clients[symbol] << client
    end
  end
end