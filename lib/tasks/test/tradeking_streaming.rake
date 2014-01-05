require './lib/data_streamer/tradeking'

namespace :test do

  task :tradeking_streaming do
    account = Account.where(:token => '02a802ea14021c90749ca3e57e77d854').first
    streamer = DataStreamer::Tradeking.new(account, account.account_data)
    callback = lambda { |data| puts data }
    streamer.stream_quotes(['FB'], callback)
  end

end