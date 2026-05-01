require "httparty"

module Telegem
  module Plugins
    class Translate
      def initialize(word, from, to)
        @word = word
        @from = from
        @to = to
        start_translating
      end 

      def start_translating
        url = "https://zen-drx-api.onrender.com/api/translate"
        options = {
          body: {
            word: @word,
            from: @from,
            to: @to
          }.to_json,
          headers: {
            'Content-Type' => 'application/json'
          }
        }
        response = HTTParty.post(url, options)
        if response.success?
          translation = response.parsed_response["translation"]
           {
             error: "false",
             translation: translation
           }
        else 
          {
            error: "an error occurred",
            code: "#{response.code}"
          }
        end 
      end 
    end 
  end
end 
          
            
