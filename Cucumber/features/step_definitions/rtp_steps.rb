# encoding: utf-8
#begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'
require 'rspec/expectations'

Given /^the Switch (.+) at level (.+)$/ do |a, b|
	Switch(a, b)
end

Then /^the output Signal (.+) should be (.+)$/ do |signal, expected|
	expect(Status(signal)).to eq(expected.to_i)
end

Given /^the SingleBlock (.+) (.+) (.+) (.+)$/ do |a, b, c, d|
	@a = a.hex
	@b = b.hex
	@c = c.hex
	@d = d.hex
end

When /^the StateMachine receive the Block$/ do
	RadioText.StreamReceived(@a,@b,@c,@d)
end

Then /^the output should be (.*) (\d*)$/ do |expected_rt, expected_rtp|
		RadioText.Text.should==expected_rt
		RadioText.Plus.should==expected_rtp
		RadioText.Text=""
		RadioText.Plus=""
end