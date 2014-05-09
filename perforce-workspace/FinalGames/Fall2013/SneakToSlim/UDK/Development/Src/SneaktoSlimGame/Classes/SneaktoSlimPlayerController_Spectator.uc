class SneaktoSlimPlayerController_Spectator extends PlayerController
	config(Game);

var SneaktoSlimPawn playerSpectatingAs;
var float yawOfPlayerSpectatingAs;
var float zOfPlayerSpectatingAs;
var float LOCATION_UPDATE_FREQUENCY;
var MiniMap myMap;
var bool uiOn, pauseMenuOn;

replication
{
	if(bNetDirty && Role == ROLE_Authority)
		yawOfPlayerSpectatingAs, zOfPlayerSpectatingAs;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	SetTimer(0.05, false, 'doPostProcessing');

	myMap = Spawn(class'SneaktoSlimGame.MiniMap',,,self.Location,,,);
	uiOn = true;
	pauseMenuOn = false;
}

reliable server function ServerGotoState(name state)
{
	GotoState(state);
}

exec function OnPressFirstSkill() 
{	
	if(IsInState('FreeMove'))
	{		
		ServerGotoState('FollowPlayer');
		GotoState('FollowPlayer');
	}
	else
	{		
		ServerGotoState('FreeMove');
		GotoState('FreeMove');  
	}
}

simulated state FreeMove extends PlayerWalking
{
Begin:
	`log(Name $ " In FreeMove state", true, 'Ravi');	
}

simulated state FollowPlayer
{
	simulated event BeginState(Name prevState)
	{
		Pawn.GroundSpeed = 0;		
	}

	simulated event EndState(Name nextState)
	{
		Pawn.GroundSpeed = SneaktoSlimPawn_Spectator(Pawn).SpectatorWalkingSpeed;		
		ClearTimer('updateLocationAndRotation');		
	}

	simulated function PlayerMove( float DeltaTime )
	{				
		//UpdateRotation(DeltaTime);
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

	exec function OnPressSecondSkill()
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
	`log(Name $ " In FollowPlayer state", true, 'Ravi');
	changePlayerSpectatingAs(0);

	SetTimer(LOCATION_UPDATE_FREQUENCY, true, 'updateLocationAndRotation');		
}

simulated function changePlayerSpectatingAs(int teamNumToSpectateAs)
{
	local SneaktoSlimPawn playerPawn;	

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
	local Rotator playerRotation;		
	local Vector behindPlayer;
	local Vector playerServerLoc;
	
	if(playerSpectatingAs != none)
	{
		playerServerLoc = playerSpectatingAs.Location;
		if(Role == ROLE_Authority)
		{
			yawOfPlayerSpectatingAs = SneakToSlimPlayerController(playerSpectatingAs.Controller).Rotation.Yaw;			
			zOfPlayerSpectatingAs = playerSpectatingAs.Location.Z;			
		}
		playerServerLoc.Z = zOfPlayerSpectatingAs;
		playerRotation.Yaw = yawOfPlayerSpectatingAs; 
		behindPlayer = playerServerLoc - vector(playerRotation) * 150;
		behindPlayer.Z -= 35;
		self.SetRotation(playerRotation);
		Pawn.SetLocation(behindPlayer);		
	}
}

reliable server function serverChangePlayerSpectatingAs(int teamNumToSpectateAs)
{
	changePlayerSpectatingAs(teamNumToSpectateAs);
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
	LOCATION_UPDATE_FREQUENCY = 0.004
	Physics=PHYS_None	
}
