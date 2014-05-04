class SneaktoSlimPlayerController_Spectator extends PlayerController
	config(Game);

var SneaktoSlimPawn playerSpectatingAs;
var float yawOfPlayerSpectatingAs;
var float playerInputATurnOfPlayerSpectatingAs;
var float zOfPlayerSpectatingAs;
var int rotationsSetNum; //while this var is less than ROTATIONS_TO_BE_SET, spectator's yaw is set to player's yaw
var int ROTATIONS_TO_BE_SET;
var float LOCATION_UPDATE_FREQUENCY;
var float correctiveYaw;
var float YAW_ERROR_THRESHOLD;

replication
{
	if(bNetDirty && Role == ROLE_Authority)
		yawOfPlayerSpectatingAs, zOfPlayerSpectatingAs, playerInputATurnOfPlayerSpectatingAs;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	SetTimer(0.05, false, 'doPostProcessing');
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
		correctiveYaw = 0;
		rotationsSetNum = 0;
		Pawn.GroundSpeed = 0;		
	}

	simulated event EndState(Name nextState)
	{
		Pawn.GroundSpeed = SneaktoSlimPawn_Spectator(Pawn).SpectatorWalkingSpeed;		
		ClearTimer('updateLocationAndRotation');		
	}

	simulated function PlayerMove( float DeltaTime )
	{				
		if(rotationsSetNum >= ROTATIONS_TO_BE_SET)
			UpdateRotationUsingOtherInput(DeltaTime);		
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

simulated function setRotationFlag()
{
	rotationsSetNum = 0;
}

simulated function changePlayerSpectatingAs(int teamNumToSpectateAs)
{
	local SneaktoSlimPawn playerPawn;	

	rotationsSetNum = 0;
	correctiveYaw = 0;
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
	local int deltaMultiplier;
	local float targetMinusCurrentYaw;
	//local Vector behindPlayer;
	local Vector playerServerLoc;	

	if(playerSpectatingAs != none)
	{
		playerServerLoc = playerSpectatingAs.Location;
		if(Role == ROLE_Authority)
		{
			yawOfPlayerSpectatingAs = SneakToSlimPlayerController(playerSpectatingAs.Controller).Rotation.Yaw;
			playerInputATurnOfPlayerSpectatingAs = SneakToSlimPlayerController(playerSpectatingAs.Controller).playerInputATurn;
			zOfPlayerSpectatingAs = playerSpectatingAs.Location.Z;			
		}
		else
		{
			playerServerLoc.Z = zOfPlayerSpectatingAs;
			playerRotation.Yaw = normalizeYaw(yawOfPlayerSpectatingAs); 
			if(rotationsSetNum < ROTATIONS_TO_BE_SET)
			{
				self.SetRotation(playerRotation);				
				rotationsSetNum++;
			}
			targetMinusCurrentYaw = playerRotation.Yaw - self.Rotation.Yaw;

			if( abs(targetMinusCurrentYaw) < YAW_ERROR_THRESHOLD )
				deltaMultiplier = 0;
			else				
			{
				targetMinusCurrentYaw = normalizeYaw(targetMinusCurrentYaw);
				if(targetMinusCurrentYaw <= 65536/2)
					deltaMultiplier = 1;
				else
					deltaMultiplier = -1;
			}
			correctiveYaw = deltaMultiplier * YAW_ERROR_THRESHOLD;
		}
		//behindPlayer = playerSpectatingAs.Location - distance;//vector(playerRotation) * 120;
		//behindPlayer.Z -= 30;		
		Pawn.SetLocation(playerServerLoc);
	}
}

simulated function UpdateRotationUsingOtherInput( float DeltaTime )
{
	local Rotator	DeltaRot, newRotation, ViewRotation;

	ViewRotation = Rotation;
	if (Pawn!=none)
	{
		Pawn.SetDesiredRotation(ViewRotation);
	}
	
	if( (playerInputATurnOfPlayerSpectatingAs > 0 && correctiveYaw > 0) ||
		(playerInputATurnOfPlayerSpectatingAs < 0 && correctiveYaw < 0) )	
		DeltaRot.Yaw = playerInputATurnOfPlayerSpectatingAs  + correctiveYaw;
	else
		DeltaRot.Yaw = playerInputATurnOfPlayerSpectatingAs;
	
	ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );	
	ViewRotation.Yaw = normalizeYaw(ViewRotation.Yaw);
	SetRotation(ViewRotation);

	ViewShake( deltaTime );

	NewRotation = ViewRotation;
	NewRotation.Roll = Rotation.Roll;

	if ( Pawn != None )
		Pawn.FaceRotation(NewRotation, deltatime);
}

simulated function float normalizeYaw(float yaw)
{
	if(yaw < 0)
		yaw = 65536 + yaw;

	if(yaw > 65536)
		yaw = yaw - 65536;

	return yaw;
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

DefaultProperties
{
	YAW_ERROR_THRESHOLD = 250
	LOCATION_UPDATE_FREQUENCY = 0.04
	ROTATIONS_TO_BE_SET = 2
	Physics=PHYS_None	
}
