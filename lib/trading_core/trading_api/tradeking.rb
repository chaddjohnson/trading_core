require File.dirname(__FILE__) + '/base'
require 'nokogiri'

module TradingApi
  class Tradeking < Base
    def initialize(credentials)
      @credentials = credentials
    end
  
    def account_info
    end
    
    def history
    end
    
    def positions
      puts api_request("/v1/accounts/#{@credentials[:account_id]}/holdings.xml").body
    end
    
    def orders
    end
    
    def quotes(symbols)
      symbols = [symbols].flatten
      quote_xml = api_request("/v1/market/ext/quotes.xml?symbols=#{symbols.join(',')}&fids=ask,bid,pcls,last,adv_90,vl,chg,pchg,chg_sign").body
      document = Nokogiri::XML(quote_xml)
      quotes = []
      document.xpath('//quotes/quote').each do |quote|
        change_sign = quote.xpath('chg_sign').text == 'd' ? '-' : ''
        quotes << {
          'symbol'            => quote.xpath('symbol').text,
          'last_price'        => quote.xpath('last').text.to_f,
          'ask_price'         => quote.xpath('ask').text.to_f,
          'bid_price'         => quote.xpath('bid').text.to_f,
          'previous_close'    => quote.xpath('pcls').text.to_f,
          'change'            => (change_sign + quote.xpath('chg').text).to_f,
          'change_percent'    => (change_sign + quote.xpath('pchg').text).gsub(' %', '').to_f,
          'average_volume'    => quote.xpath('adv_90').text.to_i,
          'cumulative_volume' => quote.xpath('vl').text.to_i,
          'timestamp'         => Time.now.getutc.strftime('%Y-%m-%d %H:%M:%S')
        }
      end
      
      return quotes
    end

    def news(symbol)
      news_xml = api_request("/v1/market/news/search.xml?symbols=#{symbol}").body
      articles = []
      document = Nokogiri::XML(news_xml)
      document.xpath('//articles/article').each do |article|
        articles << {
          :date     => article.xpath('date').text,
          :headline => article.xpath('headline').text,
          :id       => article.xpath('id').text
        }
      end
      
      return articles
    end
    
    def news_item(id)
      news_xml = api_request("/v1/market/news/#{id}.xml").body
      articles = []
      document = Nokogiri::XML(news_xml)
      article = document.xpath('//article')
      
      return {
        :date     => article.xpath('date').text,
        :headline => article.xpath('headline').text,
        :id       => article.xpath('id').text,
        :story    => article.xpath('story').text
      }
    end
    
    def buy(symbol, investment, price)
    end
    
    def time
      Time.now.getutc
    end
    
    private
  
    def api
      # Set up an OAuth Consumer
      consumer = OAuth::Consumer.new @credentials[:consumer_key], @credentials[:consumer_secret], { :site => 'https://api.tradeking.com' }
      
      # Manually update the access token/secret. Typically this would be done through an OAuth callback when 
      # authenticating other users.
      OAuth::AccessToken.new(consumer, @credentials[:access_token], @credentials[:access_token_secret])
    end

    def api_request(url, attempts = 0)
      begin
        attempts += 1
        puts 'Making API request...'
        return api.get(url)
      rescue => error
        sleep 1
        return api_request(url, attempts) if attempts <= 20
      end

      puts 'Making API request...'
      return api.get(url)
    end
  end
end