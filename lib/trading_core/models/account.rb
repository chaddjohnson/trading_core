require 'trading_core/trading_api/simulation'
require 'date'

module TradingCore
  class Account < ActiveRecord::Base
    attr_accessible :balance
    serialize :account_data
    
    has_many :positions
    has_many :watch_lists

    def api
      # TODO Make this dependent on a database setting for the account.
      @api ||= begin
        case account_api
          when 'simulation'
            require 'trading_core/trading_api/simulation'
            TradingApi::Simulation.new(self, account_data)
          when 'tradeking'
            require 'trading_core/trading_api/tradeking'
            TradingApi::Tradeking.new(account_data)
        end
      end
    end

    def streamer
      # TODO Make this dependent on a database setting for the account.
      @streamer ||= begin
        case account_streamer
          when 'generated'
            require 'trading_core/quote_streamer/generated'
            QuoteStreamer::Generated.new(self)
          when 'playback'
            require 'trading_core/quote_streamer/playback'
            quote_streamer = QuoteStreamer::Playback.new(self)
            quote_streamer.set_date(playback_date || Date.today.to_s)
            quote_streamer.set_playback_rate(25)
            quote_streamer
          when 'tradeking'
            require 'trading_core/quote_streamer/tradeking'
            QuoteStreamer::Tradeking.new(self)
        end
      end
    end
    
    def open_position(symbol, investment, price)
      TradingCore::Position.open(self, symbol, investment, price)

      # Broadcast a position add.
      notify_observers({
        :type => TradingApi.types[:position_add],
        :data => {
          
        }
      })
    end
    
    def adjust_balance(amount)
      self.update_attributes({ :balance => self.balance + amount })

      # Trigger an account update event.
      api.notify_observers({
        :type => TradingApi.types[:account_update],
        :data => { :balance => self.balance }
      })
    end
    
    def open_positions(symbol)
      positions.where(:sold_at => nil)
    end
    
    def sell(symbol, shares, price = nil)
      positions = open_positions(symbol).order('shares DESC')
      
      # Determine if this account owns enough shares of the symbol. If not, raise an error.
      share_count = positions.sum(:shares)
      if share_count < shares
        raise TradingApi::TradingError, "Unable to sell #{shares} shares as there are only #{share_count} owned shares for symbol #{symbol}"
      end    
      
      positions = positions.to_a
      profit_loss = 0.0
      
      sell_price = api.quote(symbol)
      
      # Sell as many shares as possible, considering all open positions,
      # starting with the position having the highest number of shares.
      i = 0
      position_count = positions.length
      while shares > 0 && i < position_count && i < 20
        # Default to sharing all shares for the position.
        sell_shares = position[0].shares
        
        # Make sure to only sell the requested number of shares if the
        # position has more shares than are being sold.
        if position[0].shares > shares
          sell_shares = shares
        end
        
        # Sell and trigger a position update event.
        position.sell(sell_shares)
        shares -= sell_shares
        api.notify_observers({
          :type => TradingApi.types[:position_update],
          :data => {
            # use id? does Tradeking provide holding ids?
          }
        })

        # Create a history item and trigger a history creation event.
        history = account.add_history(self.security.symbol, shares, position.bought_at, position.buy_price, api.time, sell_price)
        profit_loss += history.profit_loss
        api.notify_observers({
          :type => TradingApi.types[:history_add],
          :data => history.attributes
        })

        # Keep track of iterations to prevent an infinite loop.
        i += 1
      end
      
      # Update the account balance.
      adjust_balance(profit_loss)
    end
    
    def add_history(symbol, shares, bought_at, buy_price, sold_at, sell_price)
      security = TradingCore::Security.where(:symbol => symbol).first
      commission = 4.95 * 2
      profit_loss = ((shares * sell_price) - (shares * buy_price)) - commission
      History.create({
        :account_id  => self.id,
        :security_id => security.id,
        :shares      => shares,
        :commission  => commission,
        :bought_at   => bought_at,
        :buy_price   => buy_price,
        :sold_at     => sold_at,
        :sell_price  => sell_price,
        :profit_loss => profit_loss
      })
    end
  end
end