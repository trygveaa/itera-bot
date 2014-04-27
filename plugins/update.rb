require 'open3'

class StepError < StandardError; end

class Update
  include Cinch::Plugin

  match("update", method: :update)
  match("reload", method: :reload)

  def update(m)
    def invoke_command(user, command)
      IO.popen(command, err: [:child, :out]) do |stdout|
        stdout.each do |line|
          user.send line
        end
      end
      $?.exitstatus == 0
    end

    if m.channel.opped? m.user
      begin
        invoke_command(m.user, 'git pull --no-stat --ff-only origin master') or raise StepError
        invoke_command(m.user, 'bundle update') or raise StepError
        m.channel.send 'I updated myself, please do !reload..'
      rescue StepError
        m.channel.send 'I could not update myself'
      end

    end
  end

  def reload(m)
    Process.kill('HUP', Process.pid)
  end
end
