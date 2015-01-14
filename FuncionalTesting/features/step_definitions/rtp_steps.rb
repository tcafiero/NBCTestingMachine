# encoding: utf-8
#begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'
require 'rspec/expectations'

Given /^the Signal (.+) at level (.+)$/ do |a, b|
#	$rack=Rack.new
	$rack.send($dictionary[a][0], $dictionary[a][1], b.to_i)
end

Given /^setting time marker (.+)$/ do |a|
#	$timer=Timer.new
	$timer.marker(a.to_i)
end

When /^after (.+) secs starting from time marker (.+)$/ do |a, b|
#	$timer=Timer.new
	$timer.from_marker(b.to_i,a.to_i)
end


Then /^the output Signal (.+) should be (.+)$/ do |a, expected|
#	$rack=Rack.new
#	expect($rack.send('status', $dictionary[a][1]).to_i).to eq(expected.to_i)
	expect($rack.send('status', $dictionary[a][1])).to eq(expected)
end
