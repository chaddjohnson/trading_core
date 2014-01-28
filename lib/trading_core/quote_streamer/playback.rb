require 'trading_core/quote_streamer/base'

module QuoteStreamer
  class Playback < Base
    def initialize(account)
      super(account)
      set_playback_rate(1)

      @streaming = false
      @symbols = []
    end

    def set_date(date)
      @date = date
    end

    def set_playback_rate(rate)
      @playback_rate = 1.0 / rate
    end

    def stream_quotes(symbols, callback)
      return if @streaming
      @streaming = true

      symbols = [symbols].flatten
      @symbols.concat(symbols).uniq!

      quotes = TradingCore::Quote.by_date(@date).by_symbols(@symbols).order(:created_at)
      puts @symbol
      previous_close_prices = {}
      index = 0

      @symbols.each do |symbol|
        previous_close_prices[symbol] = TradingCore::Quote.previous_close(symbol, @date)
      end

      timer = EventMachine.add_periodic_timer(0.001) do
        quote = quotes[index]
        index += 1
        next_quote = quotes[index]

        if !quote
          timer.cancel
          next
        end

        previous_close_prices[quote.security.symbol] = quote.last_price.to_f if !previous_close_prices[quote.security.symbol]

        change = (quote.last_price.to_f - previous_close_prices[quote.security.symbol]).round(2)
        change_percent = (((quote.last_price.to_f / previous_close_prices[quote.security.symbol]) - 1) * 100).round(2)
        change_percent = change_percent == 0 ? 0.0 : change_percent

        callback.call({
          'symbol'            => quote.security.symbol,
          'last_price'        => quote.last_price.to_f,
          'ask_price'         => quote.ask_price.to_f,
          'bid_price'         => quote.bid_price.to_f,
          'previous_close'    => previous_close_prices[quote.security.symbol],
          'change'            => change,
          'change_percent'    => change_percent,
          'trade_volume'      => quote.trade_volume,
          'cumulative_volume' => quote.cumulative_volume,
          'average_volume'    => quote.average_volume,
          'timestamp'         => quote.created_at.strftime('%Y-%m-%d %H:%M:%S')
        })

        if next_quote
          # Wait the number of seconds between this quote and the next quote
          delay = (next_quote.created_at.to_i - quote.created_at.to_i) * @playback_rate
          sleep(delay)
        end
      end
    end

    def stop
      # TODO
      @streaming = false
    end

    def live?
      false
    end
  end
end