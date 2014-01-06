require './lib/data_streamer/base'

module DataStreamer
  class Playback < Base
    def initialize(account)
      super(account)
      set_playback_rate(1)
    end

    def set_date(date)
      @date = date
    end

    def set_playback_rate(rate)
      @playback_rate = 1.0 / rate
    end

    def stream_quotes(symbols, callback)
      quotes = Quote.by_date(@date).by_symbols(symbols).order(:created_at)
      symbol_data = {}
      index = 0

      @account.api.quotes(symbols).each do |quote|
        symbol_data[quote['symbol']] = quote

        previous_close_quote = Quote.by_date(@date).by_symbols([quote['symbol']]).order(:created_at).last || quotes.first
        symbol_data[quote['symbol']]['previous_close'] = previous_close_quote.last_price
      end

      EventMachine.run do
        EventMachine.add_periodic_timer(0.001) do
          quote = quotes[index]
          EventMachine.stop if !quote

          change = (quote.last_price.to_f - symbol_data[quote.security.symbol]['previous_close'].to_f).round(2)
          change_percent = (((quote.last_price.to_f / symbol_data[quote.security.symbol]['previous_close'].to_f) - 1) * 100).round(2)
          change_percent = change_percent == 0 ? 0.0 : change_percent

          symbol_data[quote.security.symbol].merge!({
            :last_price     => quote.last_price.to_f,
            :ask_price      => quote.ask_price.to_f,
            :bid_price      => quote.bid_price.to_f,
            :change         => change,
            :change_percent => change_percent,
            :volume         => quote.cumulative_volume
          })

          # Call the callback with the current quote's data.
          callback.call(symbol_data[quote.security.symbol])

          # Wait the number of seconds between this quote and the next quote
          next_quote = quotes[index+1]
          delay = (next_quote.created_at.to_i - quote.created_at.to_i) * @playback_rate
          sleep(delay) if next_quote

          index += 1
        end
      end
    end

    def date
      # TODO
    end
  end
end