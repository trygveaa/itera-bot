require 'json'
require 'readable_github_webhooks'

class GithubCommits
  include Cinch::HTTPServer

  helper :broadcast_to do |channels, message|
    bot.channels.select { |c|
      channels.include?(c.name)
    }.each { |c|
      c.send(message, true)
    }
  end

  helper :snake_case_repository_name do |payload|
    identifier = '%s_%s' % [
      payload['repository']['owner']['name'],
      payload['repository']['name']
    ]

    identifier.gsub(/[^a-zA-Z0-9]+/, '_').downcase
  end

  helper :channels_for_repository do |repository|
    config['repositories'][repository] || []
  end

  post '/github_commit' do
    payload  = JSON.parse(request.body.read)
    event    = request.env['HTTP_X_GITHUB_EVENT']
    renderer = ReadableGithubWebhooks::Renderer.new(payload)

    repository        = snake_case_repository_name(payload)
    relevant_channels = channels_for_repository(repository)

    if event.eql? 'push'
      if payload['created']
        broadcast_to(relevant_channels, renderer.render('create'))
      elsif payload['deleted']
        broadcast_to(relevant_channels, renderer.render('delete'))
      end

      unless payload['commits'].empty?
        broadcast_to(relevant_channels, renderer.render('push'))
      end
    end

    204
  end
end
