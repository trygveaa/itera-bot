module Cinch
  class IRC
    alias_method :connect_original, :connect
    alias_method :parse_original,   :parse

    def connect
      if @bot.config.fd > 0
        begin
          @socket              = Socket.for_fd(@bot.config.fd)
          @socket              = Net::BufferedIO.new(@socket)
          @socket.read_timeout = @bot.config.timeouts.read
          @queue               = MessageQueue.new(@socket, @bot)

          ENV['IRC_REGISTRATION'].to_s.split("\n").each { |line| parse_original(line) }
          ENV['IRC_CHANNELS'].to_s.split("\n").each do |channel|
            parse_original(":#{ENV['IRC_BOT_MASK']} JOIN :#{channel}")
            @bot.irc.socket.write("NAMES #{channel}\r\n")
          end

          true
        rescue ArgumentError, Errno::EBADF
          ENV.delete('IRC_REGISTRATION')
          connect_original
        end
      else
        connect_original
      end
    end

    def parse(input)
      match = input.match(/(^:\S+ )?(\S+)/)
      _, command = match.captures
      if ('001'..'005').to_a.include?(command)
        ENV['IRC_REGISTRATION'] = "#{ENV['IRC_REGISTRATION']}\n#{input}"
      end

      parse_original(input)
    end
  end
end
