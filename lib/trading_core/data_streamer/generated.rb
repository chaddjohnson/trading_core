require './lib/data_streamer/base'

module DataStreamer
  class Generated < Base
    def initialize(account)
      super(account)
      @streaming = false
      @symbols = []
    end

    def stream_quotes(symbols, callback)
      symbols = [symbols].flatten

      return if @streaming
      @streaming = true

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

              trade_volume = Random.rand(100..2000)
    
              quote['ask_price'] = (quote['ask_price'] * change_factor).round(2)
              quote['bid_price'] = (quote['ask_price'] * change_factor).round(2)
              quote['last_price'] = (((quote['ask_price'] - quote['bid_price']) / 2) + quote['bid_price']).round(2)
              quote['trade_volume'] = trade_volume
              quote['cumulative_volume'] += trade_volume
              quote['timestamp'] = Time.now.getutc.strftime('%Y-%m-%d %H:%M:%S')

              callback.call(quote)
            end
            
            sleep(Random.rand(0.0..0.025))
          end
        end
      end
    end

    def stop
      EventMachine.stop_event_loop
    end
  end
end