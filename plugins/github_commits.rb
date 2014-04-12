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

  helper :snake_case_repository_name do |name|
    name.gsub(/[^a-zA-Z0-9]+/, '_').downcase
  end

  helper :channels_for_repository do |repository|
    config['repositories'][repository] || []
  end

  post '/github_commit' do
    payload  = JSON.parse(request.body.read)
    event    = request.env['HTTP_X_GITHUB_EVENT']
    renderer = ReadableGithubWebhooks::Renderer.new(payload)

    repository        = snake_case_repository_name(renderer.owner_and_repository)
    relevant_channels = channels_for_repository(repository)

    if renderer.can_render?(event)
      bot.info 'received %s event for %s, broadcasting to %s' % [
        event,
        repository,
        relevant_channels * ', '
      ]

      if event.eql?('push')
        unless payload['commits'].empty?
          broadcast_to(relevant_channels, renderer.render('push'))
        end
      else
        broadcast_to(relevant_channels, renderer.render(event))
      end
    else
      bot.info 'received unsupported %s event for %s' % [
        event,
        repository
      ]
    end

    204
  end
end
