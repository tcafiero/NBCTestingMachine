require 'socket'      # Sockets are in standard library

hostname = 'localhost'
port = 7777

$s = TCPSocket.open(hostname, port)

at_exit do
$s.close
end
