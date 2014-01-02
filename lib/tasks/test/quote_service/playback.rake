namespace :test do
  
  namespace :quote_service do

    task :playback do
      EventMachine.run do
        conn = EventMachine::HttpRequest.new(API_CONFIG['simulation']['playback']['url'])
    
        http = conn.get
        http.stream do |data|
          puts data
        end
      end
    end

  end
  
end