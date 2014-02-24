require 'trading_core/quote_streamer/base'
require 'fiber'

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

    def stream_quotes(symbols, &block)
      return if @streaming
      @streaming = true

      symbols = [symbols].flatten
      @symbols.concat(symbols).uniq!
      previous_quote = nil
      previous_close_prices = {}

      @symbols.each do |symbol|
        previous_close_prices[symbol] = TradingCore::Quote.previous_close_price(symbol, @date)
      end

      quotes_fiber = Fiber.new {
        # Use find_each to batch process data rather than load everything into memory at once.
        TradingCore::Quote.by_date(@date).by_symbols(@symbols).order(:created_at).find_each(:batch_size => 500) do |quote|
          if !previous_quote
            previous_quote = quote
            next
          end

          if !quote
            timer.cancel
            next
          end

          previous_close_prices[previous_quote.security.symbol] = previous_quote.last_price.to_f if !previous_close_prices[previous_quote.security.symbol]

          change = (previous_quote.last_price.to_f - previous_close_prices[previous_quote.security.symbol]).round(2)
          change_percent = (((previous_quote.last_price.to_f / previous_close_prices[previous_quote.security.symbol]) - 1) * 100).round(2)
          change_percent = change_percent == 0 ? 0.0 : change_percent

          yield ({
            'symbol'            => previous_quote.security.symbol,
            'last_price'        => previous_quote.last_price.to_f,
            'ask_price'         => previous_quote.ask_price.to_f,
            'bid_price'         => previous_quote.bid_price.to_f,
            'previous_close'    => previous_close_prices[previous_quote.security.symbol],
            'change'            => change,
            'change_percent'    => change_percent,
            'trade_volume'      => previous_quote.trade_volume,
            'cumulative_volume' => previous_quote.cumulative_volume,
            'average_volume'    => previous_quote.average_volume,
            'timestamp'         => previous_quote.created_at.strftime('%Y-%m-%d %H:%M:%S')
          }) if block_given?

          # Wait the number of seconds between this quote and the next quote
          delay = (quote.created_at.to_i - previous_quote.created_at.to_i) * @playback_rate
          previous_quote = quote
          sleep(delay)

          Fiber.yield
        end
      }

      timer = EventMachine.add_periodic_timer(0.001) do
        quotes_fiber.resume
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