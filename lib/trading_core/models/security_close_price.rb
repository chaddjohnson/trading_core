module TradingCore
  class SecurityClosePrice < ActiveRecord::Base
    belongs_to :security

    attr_accessible :security_id, :date, :price
  end
end