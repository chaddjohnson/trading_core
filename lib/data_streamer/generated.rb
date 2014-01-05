require './lib/data_streamer/base'

module DataStreamer
  class Generated < Base
    def stream_quotes(symbols, callback)
      quotes = @account.api.quotes(symbols)

      EventMachine.run do
        EventMachine.add_periodic_timer(0.02) do
          quotes.each do |quote|
            change_factor = 1
            
            if (Random.rand(0..3) == 3)
              if (Random.rand(0..100) >= 50)
                change_factor = 1.00025
              else
                change_factor = 0.99975
              end
    
              quote['ask_price'] = (quote['ask_price'] * change_factor).round(2)
              quote['bid_price'] = (quote['ask_price'] * change_factor).round(2)
              quote['last_price'] = (((quote['ask_price'] - quote['bid_price']) / 2) + quote['bid_price']).round(2)
              quote['volume'] += 100

              callback.call(quote)
            end
            
            sleep(Random.rand(0.0..0.025))
          end
        end
      end
    end

    def date
      # TODO
    end
  end
end