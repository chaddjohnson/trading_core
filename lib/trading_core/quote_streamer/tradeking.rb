require 'trading_core/quote_streamer/base'
require 'date'

module QuoteStreamer
  class Tradeking < Base
    def initialize(account)
      super(account)

      @streaming = false
      @symbols = []

      @last_connection_error_time = nil
      @connection_error_time = nil
      @error_count = 0
    end

    def stream_quotes(symbols, callback)
      return if @streaming
      @streaming = true

      symbols = [symbols].flatten
      @symbols.concat(symbols).uniq!

      previous_data = ''
      symbol_data = {}
      
      @account.api.quotes(symbols).each do |quote|
        symbol_data[quote['symbol']] = quote
      end

      @http = stream(symbols).get
      @http.stream do |data|
        json_data = nil
        data = data.gsub("\n", '')
        
        if previous_data
          begin
            json_data = JSON.parse(previous_data + data)
          rescue => error
            # TODO Maybe put a "next" here?
          end
        end
        previous_data = ''
        
        begin
          if !json_data
            json_data = JSON.parse(data)
          end

          next if json_data['status'] && json_data['status'] == 'connected'

          quote = JSON.parse(data)['quote']
          trade = JSON.parse(data)['trade']
          
          symbol = nil

          # Update quote data.
          if quote
            next if !symbol_data[quote['symbol']]
            
            symbol = quote['symbol']
            symbol_data[quote['symbol']].merge!({
              'ask_price' => quote['ask'].to_f,
              'bid_price' => quote['bid'].to_f
            })
            symbol_data[quote['symbol']].merge!({
              'timestamp' => Time.at(quote['timestamp'].to_i).strftime('%Y-%m-%d %H:%M:%S')
            }) if quote['timestamp']
          end
          
          # Update trade data.
          if trade
            next if !symbol_data[trade['symbol']]
            next if trade['last'].to_f == 0.0

            symbol = trade['symbol']
            change = (trade['last'].to_f - symbol_data[symbol]['previous_close'].to_f).round(2)
            change_percent = (((trade['last'].to_f / symbol_data[symbol]['previous_close'].to_f) - 1) * 100).round(2)
            change_percent = change_percent == 0 ? 0.0 : change_percent
            symbol_data[trade['symbol']].merge!({
              'last_price'        => trade['last'].to_f,
              'previous_close'    => symbol_data[symbol]['previous_close'].to_f,
              'change'            => change,
              'change_percent'    => change_percent,
              'trade_volume'      => trade['vl'].to_i,
              'cumulative_volume' => trade['cvol'].to_i
            })
          end
          
          next if !symbol

          symbol_data[symbol].merge!({
            'timestamp' => Time.now.getutc.strftime('%Y-%m-%d %H:%M:%S')
          }) if !quote

          callback.call(symbol_data[symbol])
          @error_count = 0
        rescue => error
          previous_data = data
        end
      end

      @http.errback do
        @http.close
        puts "HTTP ERROR: #{@http.error}"

        @error_count += 1
        @last_connection_error_time = @connection_error_time
        @connection_error_time = Time.now

        # Reconnect if
        #   1) there has never been an error; or
        #   2) there are ten or less consecutive errors; or
        #   3) the last error happened more than one minute ago.
        if !@last_connection_error_time || @error_count <= 5 || Time.now.to_i - @last_connection_error_time.to_i > 60
          sleep 1
          puts 'Reconnecting to Tradeking...'
          stream_quotes(@symbols, callback)
        end
      end
    end

    def stop
      @streaming = false
      @http.close
    end

    def live?
      true
    end

    private

    def stream(symbols)
      url = "https://stream.tradeking.com/v1/market/quotes.json?symbols=#{symbols.join(',')}"
      conn = EventMachine::HttpRequest.new(url, :connect_timeout => 0, :inactivity_timeout => 0)
      conn.use EventMachine::Middleware::OAuth, @account.account_data
      puts 'Connected to Tradeking'
      conn
    end
  end
end