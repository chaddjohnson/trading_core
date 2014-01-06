require './lib/data_streamer/playback'

namespace :test do
  namespace :streaming do

    task :playback, [:securities, :date, :rate] do |t, args|
      if !args[:date]
        puts 'No date specified'
        next
      end

      if !args[:securities]
        puts 'No securities specified'
        return
      end

      account = Account.where(:token => '02a802ea14021c90749ca3e57e77d854').first
      streamer = DataStreamer::Playback.new(account)
      streamer.set_date(args[:date])
      streamer.set_playback_rate((args[:rate] || 1).to_i)
      callback = lambda { |data| puts data.to_json }
      streamer.stream_quotes(args[:securities].split(','), callback)
    end
    
  end
end