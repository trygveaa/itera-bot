#!/usr/bin/env ruby

require 'cinch'
require 'yaml'

require_relative 'lib/override_cinch_irc'
require_relative 'lib/string_helpers'

config_file = File.join(File.dirname(__FILE__), 'config.yml')

raise "No configuration file found!" unless File.exists?(config_file)

config = YAML.load_file(config_file)

config['plugins'].each do |name, plugin_config|
  require_relative "plugins/#{name}"
end

Signal.trap('HUP') do
  queue = @bot.irc.instance_variable_get(:@queue).instance_variable_get(:@queues_to_process)

  until queue.empty?
      sleep 1
  end

  ENV['IRC_BOT_MASK']  = @bot.mask.to_s
  ENV['IRC_CHANNELS']  = @bot.channels.join("\n")
  ENV['IRC_SERVER_FD'] = @bot.irc.socket.fileno.to_s
  exec 'ruby', $0, *ARGV, {@bot.irc.socket => @bot.irc.socket}
end

@bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = config['nick']
    c.server          = config['server']
    c.channels        = config['channels']
    c.fd              = ENV['IRC_SERVER_FD'].to_i
    c.plugins.plugins = config['plugins'].keys.map(&:constantize)

    config['plugins'].each do |name, plugin_config|
      c.plugins.options[name.constantize] = plugin_config
    end
  end
end

@bot.start
