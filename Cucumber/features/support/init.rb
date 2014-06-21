require 'socket'      # Sockets are in standard library
require 'yaml'

$dictionary = YAML.load_file('dictionary.yml')

hostname = 'localhost'
port = 7777

$s = TCPSocket.open(hostname, port)
puts $s.gets
sleep(2)

at_exit do
sleep(5)
$s.close
end
