module TradingCore
  class WatchList < ActiveRecord::Base
    has_many :watch_list_securities
    belongs_to :account
  end
end