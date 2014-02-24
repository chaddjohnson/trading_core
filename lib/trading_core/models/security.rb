module TradingCore
  class Security < ActiveRecord::Base
    has_many :quotes
    has_many :watch_list_securities
    has_many :close_prices, :class_name => 'SecurityClosePrice'
    has_many :chart_quotes

    def chart_data
      chart_quotes.order(:created_at).select('last_price', 'bid_price', 'ask_price', 'trade_volume', 'created_at').raw
    end

    def close_price(date)
      close_prices.where(:date => date).first
    end
  end
end