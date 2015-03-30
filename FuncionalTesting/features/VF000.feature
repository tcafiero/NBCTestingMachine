
Feature: VF000
	Scenario: Compiled from VF000.json
		Given setting time marker 1
		When after 0 secs starting from time marker 1
		Given the Signal KeySts at level 1
		Given the Signal ComfortEnable at level 0
		Given the Signal FollowMeCmd at level 0
 		Then the output Signal PosLightFollowMeCmd should be 0
		Given setting time marker 1
		When after 2 secs starting from time marker 1
		Given the Signal ComfortEnable at level 1
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 5 secs starting from time marker 1
		
# check signal ON
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
# check signal OFF		
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 0
# again
# check signal ON
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
# check signal OFF		
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 0
# again
# check signal ON
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
# check signal OFF		
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 0
# again
# check signal ON
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
# check signal OFF		
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 0
# again
# check signal ON
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
# check signal OFF		
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 0
# again
# check signal ON
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
# check signal OFF		
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 0
# again
# check signal ON
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
# check signal OFF		
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 0
# again
# check signal ON
		Given the Signal FollowMeCmd at level 1
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 1
# check signal OFF		
		Given the Signal FollowMeCmd at level 0
		Given setting time marker 1
		When after 1 secs starting from time marker 1
 		Then the output Signal PosLightFollowMeCmd should be 0
	
