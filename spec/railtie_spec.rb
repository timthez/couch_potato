require 'spec_helper'
require 'yaml'

module Rails
  def self.env
    'test'
  end

  class Railtie
    def self.initializer(*args)
    end
  end

  def self.root
    RSpec::Mocks::Double.new join: ''
  end

  def self.logger
    RSpec::Mocks::Double.new warn: nil
  end
end

require 'couch_potato/railtie'

describe "railtie" do
  before(:all) do
    @database_name = CouchPotato::Config.database_name
    @default_language = CouchPotato::Config.default_language
  end

  after(:all) do
    CouchPotato::Config.database_name = @database_name
    CouchPotato::Config.default_language = @default_language
  end

  before(:each) do
    allow(File).to receive_messages(exist?: true)
  end

  context 'when the yml file does not exist' do
    before(:each) do
      allow(File).to receive_messages(exist?: false)
    end

    it 'does not configure the database' do
      expect(CouchPotato::Config).not_to receive(:database_name=)

      CouchPotato.rails_init
    end
  end

  context 'yaml file contains only database names' do
    it "should set the database name from the yaml file" do
      allow(File).to receive_messages(:read => "test: test_db")

      expect(CouchPotato::Config).to receive(:database_name=).with('test_db')

      CouchPotato.rails_init
    end
  end

  context 'yaml file contains more configuration' do
    before(:each) do
      allow(File).to receive_messages(:read => "test: \n  database: test_db\n  default_language: :erlang")
    end

    it "set the database name from the yaml file" do
      expect(CouchPotato::Config).to receive(:database_name=).with('test_db')

      CouchPotato.rails_init
    end

    it 'sets the default language from the yaml file' do
      expect(CouchPotato::Config).to receive(:default_language=).with(:erlang)

      CouchPotato.rails_init
    end
  end

  it "should process the yml file with erb" do
    allow(File).to receive_messages(:read => "test: \n  database: <%= 'db' %>")

    expect(CouchPotato::Config).to receive(:database_name=).with('db')

    CouchPotato.rails_init
  end
end
