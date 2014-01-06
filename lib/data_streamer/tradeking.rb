require './lib/data_streamer/base'

module DataStreamer
  class Tradeking < Base
    def stream_quotes(symbols, callback)
      symbols = [symbols].flatten
      last_connection_error_time = nil
      connection_error_time = nil
      error_count = 0
      previous_data = ''
      symbol_data = {}
      
      @account.api.quotes(symbols).each do |quote|
        symbol_data[quote['symbol']] = quote
      end

      # (Re)connect if
      #   1) there has never been an error;
      #   2) there are three or less consecutive errors; or
      #   3) the last error happened more than one minute ago.
      #while !last_connection_error_time || error_count <= 10 || Time.now - last_connection_error_time > 60
        EventMachine.run do
          http = stream(symbols).get
          http.stream do |data|
            json_data = nil
            data = data.gsub("\n", '')
            
            if previous_data
              begin
                json_data = JSON.parse(previous_data + data)
              rescue => error
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
                  :ask_price => quote['ask'].to_f,
                  :bid_price => quote['bid'].to_f
                })
              end
              
              # Update trade data.
              if trade
                next if !symbol_data[trade['symbol']]

                symbol = trade['symbol']
                change = (trade['last'].to_f - symbol_data[symbol]['previous_close'].to_f).round(2)
                change_percent = (((trade['last'].to_f / symbol_data[symbol]['previous_close'].to_f) - 1) * 100).round(2)
                change_percent = change_percent == 0 ? 0.0 : change_percent
                symbol_data[trade['symbol']].merge!({
                  :last_price     => trade['last'].to_f,
                  :change         => change,
                  :change_percent => change_percent,
                  :volume         => trade['cvol'].to_i
                })
              end
              
              next if !symbol
              
              callback.call(symbol_data[symbol])
              error_count = 0
            rescue => error
              puts "ERROR: #{error.message}"
              previous_data = data
            end
          end
        
          http.errback do
            puts "HTTP ERROR: #{http.error}"
  
            error_count += 1
            last_connection_error_time = connection_error_time
            connection_error_time = Time.now
          end
        
          trap("INT")  { puts 'INT'; http.close; EM.stop }
          trap("TERM") { puts 'TERM'; http.close; EM.stop }
        end
      #end
    end
    
    def date
      # TODO
    end

    private

    def stream(symbols)
      conn = EventMachine::HttpRequest.new("https://stream.tradeking.com/v1/market/quotes.json?symbols=#{symbols.join(',')}")
      conn.use EventMachine::Middleware::OAuth, @account.account_data
      conn
    end
  end
end