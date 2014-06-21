# encoding: utf-8
#begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'
require 'rspec/expectations'

Given /^the Switch (.+) at level (.+)$/ do |a, b|
	Switch($dictionary[a], b.to_i)
end

Given /^the Selector Type:A (.+) at position (.+)$/ do |a, b|
	SelectorA($dictionary[a], b.to_i)
end

Given /^setting time marker (.+)$/ do |a|
	Timer.marker(a.to_i)
end

When /^after (.+) secs starting from time marker (.+)$/ do |a, b|
	Timer.from_marker(b.to_i,a.to_i)
end


Then /^the output Signal (.+) should be (.+)$/ do |a, expected|
	expect(Status($dictionary[a])).to eq(expected.to_i)
end
