Feature: Head Lamp Switch
	Scenario: ParkPosition
		Given the Signal HDLMPSW at level 2
		Given setting time marker 1
		When after 1 secs starting from time marker 1		
		Then the output Signal ParkTail should be 1

	Scenario: OFF Position
		Given the Signal HDLMPSW at level 4
		Given setting time marker 1
		When after 1 secs starting from time marker 1
		Then the output Signal ParkTail should be 0
