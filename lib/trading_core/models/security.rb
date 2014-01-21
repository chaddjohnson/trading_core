class Security < ActiveRecord::Base
  has_many :quotes

  def historical_quotes
    quotes.order(:created_at)
  end
end