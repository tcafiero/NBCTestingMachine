require 'socket'      # Sockets are in standard library


Before do
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

class Timer
 def self.marker(i)
  @marker[i] = Time.now
 end
 
 def self.from_marker(which, delay)
  remainder=delay-(Time.now-@marker[which])
	if remainder > 0
		sleep(remainder)
 end
 
end
