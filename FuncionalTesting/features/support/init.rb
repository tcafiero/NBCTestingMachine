require 'socket'      # Sockets are in standard library
require 'yaml'

class Rack

def initialize
end

def switch(*args)
  $s.puts "CommandSwitch %d %d \n" % args
end

def selectorA(*args)
  $s.puts "CommandSelectorA %d %d \n" % args
end

def status(*args)
  $s.puts "RequestStatus %d \n" % args
  value=$s.gets
  return value.split(' ').last
end
end

class Timer
 def marker(i)
  $marker[i] = Time.now
 end
 
 def from_marker(which, delay)
  remainder=delay-(Time.now-$marker[which])
  if remainder > 0
    sleep(remainder)
  end
 end
 
end

$dictionary = YAML.load_file('dictionary.yml')


$marker=Array.new(10)
$rack=Rack.new
$timer=Timer.new

hostname = 'localhost'
port = 7777

$s = TCPSocket.open(hostname, port)
#puts "%s\r\n" % $s.gets.chomp
puts "%s\r\n" % $s.gets


at_exit do
$s.close
end
