#!/usr/bin/env ruby

require 'cinch'
require 'yaml'

require_relative 'lib/override_cinch_irc_connect'

require_relative 'plugins/http_server'
require_relative 'plugins/github_commits'
require_relative 'plugins/op'

config_file = File.join(File.dirname(__FILE__), 'config.yml')

raise "No configuration file found!" unless File.exists?(config_file)

config = YAML.load_file(config_file)

Signal.trap('HUP') do
  ENV['IRC_SERVER_FD'] = @bot.irc.socket.fileno.to_s
  exec $0, *ARGV, {@bot.irc.socket => @bot.irc.socket}
end

@bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = config['nick']
    c.server          = config['server']
    c.channels        = config['channels']
    c.fd              = ENV['IRC_SERVER_FD'].to_i
    c.plugins.plugins = [GithubCommits, OP]

    c.plugins.options[GithubCommits] = config['plugins']['github_commits']
    c.plugins.options[OP]            = config['plugins']['op']
  end
end

@bot.start
