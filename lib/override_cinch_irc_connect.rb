module Cinch
  class IRC
    alias_method :connect_original, :connect

    def connect
      if @bot.config.fd > 0
        begin
          @socket              = Socket.for_fd(@bot.config.fd)
          @socket              = Net::BufferedIO.new(@socket)
          @socket.read_timeout = @bot.config.timeouts.read
          @queue               = MessageQueue.new(@socket, @bot)
          true
        rescue ArgumentError
          connect_original
        end
      else
        connect_original
      end
    end
  end
end
