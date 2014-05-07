class StepError < StandardError; end

class Update
  include Cinch::Plugin

  match("update", method: :update)
  match("reload", method: :reload)

  PULL = 'git pull --no-stat --ff-only origin master'
  BUNDLE = 'bundle check || bundle update'

  def update(m)
    def invoke_command(user, command)
      IO.popen(command, err: [:child, :out]) do |stdout|
        stdout.each do |line|
          user.send line
        end
      end
      raise StepError if $?.exitstatus != 0
    end

    if m.channel.opped? m.user
      begin
        invoke_command(m.user, PULL)
        invoke_command(m.user, BUNDLE)
        m.channel.send 'I updated myself, reloading now.'
        Process.kill('HUP', Process.pid)
      rescue StepError
        m.channel.send 'I could not update myself.'
      end

    end
  end

  def reload(m)
    m.channel.send 'Reloading now.'
    Process.kill('HUP', Process.pid)
  end
end
