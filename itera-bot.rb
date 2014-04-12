#!/usr/bin/env ruby

require 'cinch'
require 'yaml'

require_relative 'lib/override_cinch_irc'

config_file = File.join(File.dirname(__FILE__), 'config.yml')

raise "No configuration file found!" unless File.exists?(config_file)

config = YAML.load_file(config_file)

config['plugins'].each do |plugin_config|
  require_relative "plugins/#{plugin_config[0]}"
end

def list_plugins(plugins)
  plugin_objects = [] 
  plugins.each do |plugin_config|
    plugin = get_plugin(plugin_config[0])
    plugin_objects.push(plugin) if plugin
  end
  return plugin_objects
end

def get_plugin(plugin_name)
  return GithubCommits if plugin_name == 'github_commits'
  return OP if plugin_name == 'op'
end

Signal.trap('HUP') do
  ENV['IRC_SERVER_FD'] = @bot.irc.socket.fileno.to_s
  exec 'ruby', $0, *ARGV, {@bot.irc.socket => @bot.irc.socket}
end

@bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = config['nick']
    c.server          = config['server']
    c.channels        = config['channels']
    c.fd              = ENV['IRC_SERVER_FD'].to_i
    c.plugins.plugins = list_plugins(config['plugins']) 

    config['plugins'].each do |plugin_config|
      plugin = get_plugin(plugin_config[0])
      c.plugins.options[plugin] = plugin_config[1] if plugin
    end
  end
end

@bot.start
