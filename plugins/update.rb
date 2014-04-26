require 'open3'

class Update
  include Cinch::Plugin

  match "update"

  def execute(m)
    def do_command(channel, command, quiet=false)
      Open3.popen3(command) do |stdin, stdout_io, stderr_io, wait_thr|
        stdout = stdout_io.readlines
        stderr = stderr_io.readlines
        stdout.each { |line| channel.send line if !quiet } 
        stderr.each { |line| channel.send line } 

        wait_thr.value.exitstatus == 0
      end
    end

    if m.channel.opped? m.user
      has_pulled = do_command m.channel, 'git pull --no-stat --ff-only origin master'
      has_updated_bundle = do_command m.channel, 'bundle update', true if has_pulled
      m.channel.send has_updated_bundle ? 'Your bundle is updated!' : 'Could not update your bundle'
      Process.kill('HUP', Process.pid) if has_updated_bundle
    end
  end
end
