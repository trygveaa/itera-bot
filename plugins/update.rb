require 'open3'

class Update
  include Cinch::Plugin

  match "update"

  def execute(m)
    def do_command(channel, command, quiet=false)
      IO.popen(command, err: [:child, :out]) do |stdout|
        stdout.each do |line|
          channel.send line
        end
      end
      $?.exitstatus == 0
    end

    if m.channel.opped? m.user
      has_pulled = do_command m.channel, 'git pull --no-stat --ff-only origin master'
      has_updated_bundle = do_command m.channel, 'bundle update', true if has_pulled
      m.channel.send has_updated_bundle ? 'Your bundle is updated!' : 'Could not update your bundle'
      Process.kill('HUP', Process.pid) if has_updated_bundle
    end
  end
end
