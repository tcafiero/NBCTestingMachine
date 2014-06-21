require 'socket'      # Sockets are in standard library

hostname = 'localhost'
port = 7777

Before do
sleep(2)
end

After do
end

def Switch(*args)
  $s.puts "CommandSwitch %d %d \n" % args
end

def SelectorA(*args)
  $s.puts "CommandSelectorA %d %d \n" % args
end

def Status(*args)
  $s.puts "RequestStatus %d \n" % args
  value=$s.gets.split(' ')
  return value.last.to_i
end

$marker=Array.new(10)
class Timer
 def self.marker(i)
  $marker[i] = Time.now
 end
 
 def self.from_marker(which, delay)
  remainder=delay-(Time.now-$marker[which])
  if remainder > 0
    sleep(remainder)
  end
 end
 
end
