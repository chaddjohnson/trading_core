require 'rack/stream'
require './lib/trading_api/tradeking'

module QuoteService
  class Generated
    include Rack::Stream::DSL
    
    stream do
      after_open do
        puts 'connection opened'
        
        api = Account.find_by_token(API_CONFIG['simulation']['account_token']).api
        quotes = api.quotes(['AMZN','VIPS','FB','AAPL','OAS','HTCH','HXM','EXPE','SWI','TSYS','ZNGA','OUTR','CRUS','TPX','BAS','NTGR','DECK','SMTC','TGI','VRTX','DLR','EVC','SLT','MTSN','HSOL'])
        
        @timer = EventMachine.add_periodic_timer(0.01) do
          quotes.each do |quote|
            change_factor = 1
            
            if (Random.rand(0..3) == 3)
              if (Random.rand(0..100) >= 50)
                change_factor = 1.00025
              else
                change_factor = 0.99975
              end
    
              quote['ask_price'] = (quote['ask_price'] * change_factor).round(2)
              quote['bid_price'] = (quote['ask_price'] * change_factor).round(2)
              quote['last_price'] = (((quote['ask_price'] - quote['bid_price']) / 2) + quote['bid_price']).round(2)
              quote['volume'] += 100
  
              data = {
                :quote => {
                  :symbol => quote['symbol'],
                  :ask => quote['ask_price'],
                  :bid => quote['bid_price'],
                },
                :trade => {
                  :symbol => quote['symbol'],
                  :last => quote['last_price'],
                  :cvol => quote['volume']
                }
              }.to_json     
              
              chunk data
            end
            
            sleep(Random.rand(0.0..0.025))
          end
        end
      end
  
      before_close do
        @timer.cancel
        puts 'connection closed'
      end
  
      [200, {'Content-Type' => 'text/plain'}, []]
    end
  end
end