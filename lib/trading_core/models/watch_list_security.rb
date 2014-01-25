module TradingCore
  class WatchListSecurity < ActiveRecord::Base
    belongs_to :watch_list
    belongs_to :security

    def self.all_symbols
      select('DISTINCT securities.symbol').joins(:security).map(&:symbol)
    end
  end
end