class SneaktoSlimPlayerController_Spectator extends PlayerController
	config(Game);

var SneaktoSlimPawn playerSpectatingAs;
var int rotationsSetNum; //while this var is less than ROTATIONS_TO_BE_SET, spectator's yaw is set to player's yaw
var int ROTATIONS_TO_BE_SET;
var float LOCATION_UPDATE_FREQUENCY;
var MiniMap myMap;
var bool uiOn, pauseMenuOn;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	SetTimer(0.05, false, 'doPostProcessing');
	SetTimer(0.5, false, 'changeToDefaultState');

	myMap = Spawn(class'SneaktoSlimGame.MiniMap',,,self.Location,,,);
	uiOn = true;
	pauseMenuOn = false;	
}

exec function OnPressFirstSkill() 
{	
	if(!IsInState('SpectateAndMove'))
	{		
		ServerGotoState('SpectateAndMove');
		GotoState('SpectateAndMove');
	}
}

reliable server function ServerGotoState(name state)
{
	GotoState(state);
}

simulated state SpectateAndMove extends PlayerWalking
{
	simulated event BeginState(Name prevState)
	{		
		Pawn.GroundSpeed = SneaktoSlimPawn_Spectator(Pawn).SpectatorWalkingSpeed;
	}

	simulated event EndState(Name nextState)
	{
		Pawn.GroundSpeed = SneaktoSlimPawn_Spectator(Pawn).SpectatorWalkingSpeed;
		ClearTimer('updateLocationAndRotation');		
	}

	exec function OnPressSecondSkill()
	{
		changeToSprintSpeed();		
	}

	exec function OnReleaseSecondSkill()
	{
		changeToWalkSpeed();		
	}

	exec function SpecatorSwitchToPlayer1()
	{
		`log(Name $ " switching to player 1", true, 'Ravi');
		serverChangePlayerSpectatingAs(0);
		changePlayerSpectatingAs(0);
	}

	exec function SpecatorSwitchToPlayer2()
	{
		`log(Name $ " switching to player 2", true, 'Ravi');
		serverChangePlayerSpectatingAs(1);
		changePlayerSpectatingAs(1);
	}

	exec function SpecatorSwitchToPlayer3()
	{
		`log(Name $ " switching to player 3", true, 'Ravi');
		serverChangePlayerSpectatingAs(2);
		changePlayerSpectatingAs(2);
	}

	exec function SpecatorSwitchToPlayer4()
	{
		`log(Name $ " switching to player 4", true, 'Ravi');
		serverChangePlayerSpectatingAs(3);
		changePlayerSpectatingAs(3);
	}

	exec function OnPressFirstSkill()
	{	
		local int teamNumSpectatingAs;
		local int teamNumToSpectateAs;
		local SneaktoSlimPawn playerPawn;
		local int maxTeamNum;

		maxTeamNum = 0;
		foreach WorldInfo.AllActors(class'SneaktoSlimPawn', playerPawn)
		{		
			maxTeamNum = MAX(maxTeamNum, playerPawn.GetTeamNum());
		}
		teamNumSpectatingAs = playerSpectatingAs.GetTeamNum();
		if(teamNumSpectatingAs < maxTeamNum)
			teamNumToSpectateAs = teamNumSpectatingAs + 1;
		else
			teamNumToSpectateAs = 0;

		serverChangePlayerSpectatingAs(teamNumToSpectateAs);
		changePlayerSpectatingAs(teamNumToSpectateAs);
	}

Begin:		
	`log(Name $ " In SpectateAndMove state", true, 'Ravi');
	changePlayerSpectatingAs(0);

	SetTimer(LOCATION_UPDATE_FREQUENCY, true, 'updateLocationAndRotation');		
}

simulated function changePlayerSpectatingAs(int teamNumToSpectateAs)
{
	local SneaktoSlimPawn playerPawn;	

	rotationsSetNum = 0;	
	foreach WorldInfo.AllActors(class'SneaktoSlimPawn', playerPawn)
	{		
		if( playerPawn.GetTeamNum() == teamNumToSpectateAs) 
		{
			`log(Name $ "Spectating as player: " $ playerPawn.Name, true, 'Ravi');
			playerSpectatingAs = playerPawn;				
			break;
		}
	}
}

simulated function updateLocationAndRotation()
{
	local Vector behindPlayer;
	
	if(playerSpectatingAs != none && rotationsSetNum < ROTATIONS_TO_BE_SET)
	{
		behindPlayer = playerSpectatingAs.Location - vector(playerSpectatingAs.Rotation) * 130;
		behindPlayer.Z -= 35;
		self.SetRotation(playerSpectatingAs.Rotation);
		Pawn.SetLocation(behindPlayer);			
		rotationsSetNum++; // set location and rotation for each player limited number of times
	}
}

reliable server function serverChangePlayerSpectatingAs(int teamNumToSpectateAs)
{
	changePlayerSpectatingAs(teamNumToSpectateAs);
}

reliable server function changeToSprintSpeed()
{
	Pawn.GroundSpeed = SneaktoSlimPawn_Spectator(Pawn).SpectatorSprintingSpeed;
}

reliable server function changeToWalkSpeed()
{
	Pawn.GroundSpeed = SneaktoSlimPawn_Spectator(Pawn).SpectatorWalkingSpeed;
}

function doPostProcessing()
{
	// To fix custom post processing chain when not running in editor or PIE.
	local localPlayer LP;

	LP = LocalPlayer(self.Player); 
	if(LP != None) 
	{ 
		LP.RemoveAllPostProcessingChains(); 
		LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
		if(self.myHUD != None)
		{
			self.myHUD.NotifyBindPostProcessEffects();
		}
	} 
}

simulated function changeToDefaultState()
{
	ServerGotoState('SpectateAndMove');
	GotoState('SpectateAndMove');  
}

//When player clicks 'M' their minimap is turned on/off
exec function toggleMap()
{
	//Checks if map exists and pause menu isn't on
	if(myMap != NONE && !pauseMenuOn)
	{
		myMap.toggleMap();
		if(myMap.isOn)
		{
			SneaktoSlimPawn_Spectator(self.Pawn).disablePlayerMovement();
			self.IgnoreLookInput(true);
		}
		else
		{
			SneaktoSlimPawn_Spectator(self.Pawn).enablePlayerMovement();
			self.IgnoreLookInput(false);
		}
	}	
}

exec function ToggleUIHUD()
{
	uiOn = !uiOn;
}

//When press 'ESC' key the pause menu field is active and disables/enables player movement
//Other classes like STSHUD and STSGFxPauseMenu check this field during their ticks
exec function togglePauseMenu()
{
	//Checks if map is not used
	if(myMap != NONE)
	{
		if(!myMap.isOn)
		{
			//`log("Pause Menu activated");
			pauseMenuOn = !pauseMenuOn;

			if(pauseMenuOn)
			{
				SneaktoSlimPawn_Spectator(self.Pawn).disablePlayerMovement();
				IgnoreLookInput(true);
			}
			else
			{
				SneaktoSlimPawn_Spectator(self.Pawn).enablePlayerMovement();
				IgnoreLookInput(false);
			}
		}
	}
}

DefaultProperties
{
	LOCATION_UPDATE_FREQUENCY = 0.03
	ROTATIONS_TO_BE_SET = 5
	rotationsSetNum = 0
	Physics=PHYS_None	
}
