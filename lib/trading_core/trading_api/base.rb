require 'observer'
require 'oauth'
require 'em-http'
require 'em-http/middleware/oauth'
require 'trading_core/trading_api/error'

module TradingApi
  def self.types
    {
      :login           => 1,
      :account_info    => 2,
      :account_update  => 3,
      :quotes          => 4,
      :stream_quotes   => 5,
      :positions       => 6,
      :position_add    => 7,
      :position_update => 8,
      :orders          => 9,
      :order_add       => 10,
      :order_update    => 11,
      :buy             => 12,
      :sell            => 13,
      :history         => 14,
      :history_add     => 15,
      :chart_data      => 16
    }
  end
  
  class Base
    include Observable

    def quotes(symbols)
      raise NotImplementedError
    end
    
    def stream_quotes(symbols, callback)
      raise NotImplementedError
    end
    
    def account_info
      raise NotImplementedError
    end
    
    def history
      raise NotImplementedError
    end
    
    def positions
      raise NotImplementedError
    end
    
    def orders
      raise NotImplementedError
    end
    
    def buy(symbol, investment, price)
      raise NotImplementedError
    end
    
    def time
      raise NotImplementedError
    end
  end
end