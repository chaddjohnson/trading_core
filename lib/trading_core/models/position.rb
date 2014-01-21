class Position < ActiveRecord::Base
  attr_accessible :account_id, :security_id, :cost_basis, :trade_date, :bought_at,
                  :buy_price, :shares, :commission, :sell_price, :sold_at, :profit_loss
  
  belongs_to :account
  belongs_to :security
  
  def self.current
    where('trade_date = ?', date).where('sold_at IS NULL')
  end

  def self.open(account, symbol, investment, price)
    padded_price = (price * 1.00142857142857).round(2)
    shares = (investment / padded_price).floor
    security = Security.where(:symbol => symbol).first
    
    # Create an order and trigger an order creation event.
# TODO
#    order = account.create_order(..., 'buy' ...)
    api.notify_observers({
      :type => TradingApi.types[:order_add],
      :data => order.attributes
    })
    
    self.create({
      :account_id  => account.id,
      :security_id => security.id,
      :cost_basis  => padded_price * shares,
      :bought_at   => Time.now.getutc,
      :buy_price   => padded_price,
      :shares      => shares
    })
  end
  
  def sell(shares)
    # Create an order and trigger an order creation event.
# TODO
#    order = account.create_order(..., 'sell' ...)
    api.notify_observers({
      :type => TradingApi.types[:order_add],
      :data => order.attributes
    })
    
    # Decrease the number of shares held by this position.
    remaining_shares = self.shares - shares
    raise TradingApi::TradingError "Cannot sell more than #{self.shares} shares of #{self.security.symbol}" if remaining_shares < 0
    self.update_attributes({ :shares => remaining_shares })
  end
end