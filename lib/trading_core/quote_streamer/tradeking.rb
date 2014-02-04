require 'trading_core/quote_streamer/base'
require 'date'

module QuoteStreamer
  class Tradeking < Base
    def initialize(account)
      super(account)

      @streaming = false
      @symbols = []
    end

    def stream_quotes(symbols, &block)
      begin
        return if @streaming
        @streaming = true

        symbols = [symbols].flatten
        @symbols.concat(symbols).uniq!

        previous_data = ''
        data_end_index = nil
        symbol_data = {}
        
        @account.api.quotes(symbols).each do |quote|
          symbol_data[quote['symbol']] = quote
        end

        @http.close if @http
        @http = stream(symbols).get(:timeout => 0)
        @http.stream do |data|
          json_data = nil
          data = data.gsub("\n", '')
          
          if previous_data
            begin
              json_data = JSON.parse(previous_data + data)
              data_end_index = json_data.index('}}{')
              if data_end_index
                previous_data = json_data[(data_end_index+2)..-1]
                json_data = json_data[0..(data_end_index+1)]
              end
            rescue => error
              # TODO Maybe put a "next" here?
            end
          end

          previous_data = '' if !data_end_index
          data_end_index = nil
          
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
            previous_data = data
          end
        end

        @http.errback do
          @streaming = false
          @http.close
          puts "HTTP ERROR: #{@http.error}"

          sleep 1
          puts 'Reconnecting to Tradeking...'
          stream_quotes(@symbols, &block)
        end
      ensure
        @http.close
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

    def stream(symbols, attempts = 0)
      begin
        attempts += 1
        url = "https://stream.tradeking.com/v1/market/quotes.json?symbols=#{symbols.join(',')}"
        conn = EventMachine::HttpRequest.new(url, :connect_timeout => 0, :inactivity_timeout => 0)
        conn.use EventMachine::Middleware::OAuth, @account.account_data
        puts 'Connected to Tradeking'

        return conn
      rescue => error
        sleep 1
        puts "Attempting reconnect..."
        return stream(symbols, attempts) if attempts <= 10
      end

      return conn
    end
  end
end