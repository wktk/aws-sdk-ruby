require 'thread'
require 'socket'

module Aws
  module ClientSideMonitoring
    class Publisher
      attr_reader :agent_port

      def initialize(opts = {})
        @agent_port = opts[:agent_port]
        @mutex = Mutex.new
      end

      def agent_port=(value)
        @mutex.synchronize do
          @agent_port = value
        end
      end

      def publish(request_metrics)
        send_datagram(request_metrics.api_call.to_json)
        request_metrics.api_call_attempts.each do |attempt|
          send_datagram(attempt.to_json)
        end
      end

      def send_datagram(msg)
        if @agent_port
          # Should I consider reuse of sockets?
          socket = UDPSocket.new
          begin
            socket.connect("127.0.0.1", @agent_port)
            socket.send(msg, 0)
          rescue Errno::ECONNREFUSED
            # Drop on the floor?
          end
        end
      end
    end
  end
end
