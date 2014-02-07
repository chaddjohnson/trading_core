require 'trading_core/quote_streamer/base'
require 'date'
require 'time'

module QuoteStreamer
  class Tradeking < Base
    def initialize(account)
      super(account)

      @streaming = false
      @symbols = []
      @stopping = false
    end

    def stream_quotes(symbols, &block)
      EventMachine.add_periodic_timer(1) do
        start_streaming_quotes(symbols, &block) if !@streaming && market_is_active
      end
    end

    def stop
      puts 'Streaming stopped'
      @streaming = false
      @stopping = true
      @http.close
    end

    def live?
      true
    end

    private

    def start_streaming_quotes(symbols, &block)
      return if @streaming
      @streaming = true

      symbols = [symbols].flatten
      @symbols.concat(symbols).uniq!

      previous_data = ''
      symbol_data = {}
      
      @account.api.quotes(symbols).each do |quote|
        symbol_data[quote['symbol']] = quote
      end

      @http.close if @http
      @http = nil
      @http = stream(symbols).get
      @http.stream do |data|
        self.stop if !market_is_active

        json_data = nil
        data = data.gsub("\n", '')
        
        begin
          # Don't try to combine previous data and current data if the current data is
          # potentially a full JSON literal.
          previous_data = '' if data[0] == '{'

          json_data = JSON.parse(previous_data + data)
          previous_data = ''
        rescue => error
          # Only track data for combination with the next data chunk if the current
          # data is potentially a full JSON literal.
          if data[0] == '{'
            previous_data = data
          else
            previous_data = ''
          end

          next
        end
        
        begin
          next if json_data['status'] && json_data['status'] == 'connected'

          quote = json_data['quote']
          trade = json_data['trade']
          
          symbol = nil

          # Update quote data.
          if quote
            next if !symbol_data[quote['symbol']]
            
            symbol = quote['symbol']
            symbol_data[quote['symbol']].merge!({
              'ask_price' => quote['ask'].to_f,
              'bid_price' => quote['bid'].to_f
            })
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
          })

          yield symbol_data[symbol] if block_given?
        rescue => error
        end
      end

      @http.errback do
        @streaming = false

        if !@stopping
          puts "HTTP ERROR: #{@http.error}"
          @http.close
          sleep 1
          puts 'Reconnecting to Tradeking...'
          start_streaming_quotes(@symbols, &block)
        else
          @stopping = false
        end
      end
    end

    def stream(symbols, attempts = 0)
      begin
        attempts += 1
        url = "https://stream.tradeking.com/v1/market/quotes.json?symbols=#{symbols.join(',')}"
        @conn = nil
        @conn = EventMachine::HttpRequest.new(url)
        @conn.use EventMachine::Middleware::OAuth, @account.account_data
        puts 'Connected to Tradeking'

        return @conn
      rescue => error
        sleep 1
        puts "Attempting reconnect..."
        return stream(symbols, attempts) if attempts <= 20
      end

      return @conn
    end

    def market_is_active
      Time.now.getutc.to_i >= Time.parse("#{Date.today} 09:00:00 UTC").to_i && Time.now.getutc.to_i <= Time.parse("#{Date.today} 23:30:00 UTC").to_i
    end
  end
end