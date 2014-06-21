Feature: VFxxx
	Scenario: bla bla bla
		Given the Switch HighBeamCmd at level 1
		And setting time marker 1
		When after 10 secs starting from time marker 1
		Then the output Signal HighBeam should be 0

		Scenario: Lampade esterne
		Given the Switch LowBeamCmd at level 1
		And setting time marker 1
		When after 1 secs starting from time marker 1
		Given the Switch LowBeamCmd at level 1
		And setting time marker 1
		When after 10 secs starting from time marker 1
		Then the output Signal LowBeam should be 1
		Given the Switch LowBeamCmd at level 0
		And setting time marker 1
		When after 10 secs starting from time marker 1
		Then the output Signal LowBeam should be 0

	Scenario: blu blu blu
		Given the Switch HighBeamCmd at level 0
		Then the output Signal HighBeam should be 0

	Scenario: conclusivo
		Given the Switch HighBeamCmd at level 0
		And the Switch LowBeamCmd at level 0
		