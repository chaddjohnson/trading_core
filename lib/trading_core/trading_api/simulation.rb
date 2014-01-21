require './lib/trading_api/tradeking'

module TradingApi
  class Simulation < Tradeking
    def initialize(account, credentials)
      super(credentials)
      @account = account
    end

    def quotes(symbols)
      # Get the current quote if the API time is the same as the current time.
      return super(symbols) if self.time.to_s == Time.now.getutc.to_s
      
      # A time was specified, so return a historical quote
      #SecurityHistory.
    end
    
    def account_info
      
    end
    
    def history
      
    end
    
    def positions
      data = []
      # Position.current.each do |position|
        # data << {
          # :symbol       => position.security.symbol,
          # :cost_basis   => position.cost_basis
          # :market_value => (),
          # :profit_loss  => (),
          # :shares       => position.shares,
          # :last_price   => 
        # }
      # end
      data
    end
    
    def orders
      
    end
    
    def buy(symbol, investment, price)
      # Open a position.
      @account.open_position(symbol, investment, price)
      
      # Adjust account balance by investment amount and trigger an account update event.
      @account.adjust_balance(investment * -1)
    end
    
    def sell(symbol, shares, price)
      @account.sell(symbol, shares, price)
    end
    
    def time
      Time.now.getutc
    end
  end
end