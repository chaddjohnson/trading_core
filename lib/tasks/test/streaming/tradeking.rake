require './lib/data_streamer/tradeking'

namespace :test do
  namespace :streaming do

    task :tradeking, [:securities] do |t, args|
      if !args[:securities]
        puts 'No securities specified'
        next
      end

      account = Account.where(:token => '02a802ea14021c90749ca3e57e77d854').first
      streamer = DataStreamer::Tradeking.new(account)
      callback = lambda { |data| puts data }
      streamer.stream_quotes(args[:securities].split(','), callback)
    end
    
  end
end