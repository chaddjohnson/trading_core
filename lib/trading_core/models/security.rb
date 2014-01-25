module TradingCore
  class Security < ActiveRecord::Base
    has_many :quotes
    has_many :watch_list_securities

    def historical_quotes
      quotes.order(:created_at)
    end
  end
end