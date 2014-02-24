module TradingCore
  class ChartQuote < ActiveRecord::Base
    belongs_to :security
  end
end