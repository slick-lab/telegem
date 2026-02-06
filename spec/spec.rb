 # frozen_string_literal: true
require 'spec_helper'
  Rspec.describe Telegem do
    it 'has a version number' do 
      expect(Telegem::VERSION).not_to be nil 
   it 'can create a bot instance' do 
     bot = Telegem.new('test_token')
     expect(bot).to be_a(Telegem::Bot) 
   end 
  end 
  #i will add more test as i understand rspec better 