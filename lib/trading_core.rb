require 'trading_core/version'
Gem.find_files('trading_core/ext/**/*.rb').each { |path| require path }
Gem.find_files('trading_core/models/**/*.rb').each { |path| require path }

module TradingCore
end