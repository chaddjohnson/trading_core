class Quote < ActiveRecord::Base
  belongs_to :security

  def self.by_date(date)
     where(:date => date) \
    .where('created_at BETWEEN ? AND ?', "#{date.to_s} 14:30:00", "#{date.to_s} 21:00:00") \
  end

  def self.by_symbols(symbols)
    securities = Security.where(:symbol => symbols)
    where(:security_id => securities.map(&:id))
  end

  def self.previous_close(symbol, date)
    quote = where('date < ?', date) \
           .where("TIME(`timestamp`) BETWEEN '14:30:00' AND '21:00:00'") \
           .by_symbols(symbol) \
           .order(:created_at) \
           .last
    
    quote.last_price.to_f if quote
    nil
  end
end