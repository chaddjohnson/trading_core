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
      callback = lambda do |data|
        return if !@clients[data['symbol']]

        # Build the response and send it to each client subscribed to the symbol.
        response_data = {
          :type => TradingApi.types[:stream_quotes],
          :data => data
        }.to_json
        @clients[data['symbol']].each do |client|
          client.send(response_data)
        end

        # Record history (only in live mode).
        Quote.create({
          :security_id       => @securities[data['symbol']].id,
          :last_price        => data['last_price'].to_f,
          :bid_price         => data['previous_close'].to_f,
          :ask_price         => data['change'].to_f,
          :date              => data['change_percent'],
          :timestamp         => data['trade_volume'],
          :trade_volume      => data['cumulative_volume'].to_i,
          :cumulative_volume => data['change_percent'].to_i,
          :average_volume    => data['change_percent'].to_i,
          :created_at        => data['change_percent'],
        }) if @quote_streamer.live?
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