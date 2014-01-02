namespace :test do
  
  namespace :quote_service do

    task :generated do
      EventMachine.run do
        conn = EventMachine::HttpRequest.new(API_CONFIG['simulation']['generated']['url'])
    
        http = conn.get
        http.stream do |data|
          puts data
        end
      end
    end

  end
  
end