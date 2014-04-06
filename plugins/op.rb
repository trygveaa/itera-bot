class OP
  include Cinch::Plugin

  match "op"

  def execute(m)
    if m.channel? && config['operators'].include?(m.user.nick)
      m.channel.op(m.user.nick)
    end
  end
end