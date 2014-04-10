#!/usr/bin/env ruby

require 'cinch'
require 'yaml'

require_relative 'plugins/http_server'
require_relative 'plugins/github_commits'
require_relative 'plugins/op'

config_file = File.join(File.dirname(__FILE__), 'config.yml')

raise "No configuration file found!" unless File.exists?(config_file)

config = YAML.load_file(config_file)

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = config['nick']
    c.server          = config['server']
    c.channels        = config['channels']
    c.plugins.plugins = [GithubCommits, OP]

    c.plugins.options[GithubCommits] = config['plugins']['github_commits']
    c.plugins.options[OP]            = config['plugins']['op']
  end
end

bot.start
