module TradingCore
  class Quote < ActiveRecord::Base
    belongs_to :security

    def self.by_date(date)
       where(:date => date)
    end

    def self.by_symbols(symbols)
      securities = TradingCore::Security.where(:symbol => symbols)
      where(:security_id => securities.map(&:id))
    end

    def self.previous_close_price(symbol, date)
      security = TradingCore::Security.where(:symbol => symbol).first
      security.close_price(date).try(:price)
    end
  end
end