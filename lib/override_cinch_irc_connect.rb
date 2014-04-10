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
        rescue ArgumentError
        end
      end

      if @socket
        connect_success = true
      else
        connect_success = connect_original
      end

      if connect_success
        @socket.io.close_on_exec = false
        ENV['IRC_SERVER_FD'] = @socket.io.fileno.to_s
      end

      connect_success
    end
  end
end
