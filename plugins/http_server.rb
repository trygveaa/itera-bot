require "forwardable"
require "sinatra"
require "thin"

module Cinch
  module HTTPServer
    def self.included(base)
      base.instance_eval do
        include Cinch::Plugin

        listen_to :connect,    :method => :start_http_server
        listen_to :disconnect, :method => :stop_http_server
      end

      class << base
        extend Forwardable

        delegate [:get, :put, :post, :patch, :delete] => Application

        def helper(name, &block)
          Application.send(:define_method, name, &block)
        end
      end
    end

    class CinchLogging
      def initialize(bot)
        @bot = bot
      end

      def write(str)
        @bot.loggers.info(str)
      end
    end

    class Application < Sinatra::Base
      class << self
        attr_accessor :bot, :config
      end

      def bot
        self.class.bot
      end

      def config
        self.class.config
      end
    end

    def start_http_server(msg)
      host = config['host']
      port = config['port']

      Application.bot    = bot
      Application.config = config

      @server = Thin::Server.new(host,
                                 port,
                                 Application,
                                 signals: false)

      @server.app.use(Rack::CommonLogger, CinchLogging.new(bot))
      @server.start
    end

    def stop_http_server(msg)
      @server.stop!
    end
  end
end