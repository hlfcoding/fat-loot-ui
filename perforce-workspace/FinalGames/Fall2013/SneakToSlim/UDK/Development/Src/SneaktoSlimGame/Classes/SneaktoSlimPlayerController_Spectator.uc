class SneaktoSlimPlayerController_Spectator extends PlayerController
	config(Game);

var SneaktoSlimPawn playerSpectatingAs;
var float yawOfPlayerSpectatingAs;
var float playerInputATurnOfPlayerSpectatingAs;
var float zOfPlayerSpectatingAs;
var int rotationsSetNum; //while this var is less than ROTATIONS_TO_BE_SET, spectator's yaw is set to player's yaw
var float ROTATION_SET_FREQUENCY;
var int ROTATIONS_TO_BE_SET;
var float correctiveYaw;

replication
{
	if(bNetDirty && Role == ROLE_Authority)
		yawOfPlayerSpectatingAs, zOfPlayerSpectatingAs, playerInputATurnOfPlayerSpectatingAs;
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
		Pawn.GroundSpeed = 0;		
	}

	simulated event EndState(Name nextState)
	{
		Pawn.GroundSpeed = SneaktoSlimPawn_Spectator(Pawn).SpectatorWalkingSpeed;		
		ClearTimer('updateLocationAndRotation');
		ClearTimer('setRotationFlag');
	}

	simulated function PlayerMove( float DeltaTime )
	{				
		//if(rotationsSetNum >= ROTATIONS_TO_BE_SET)
		//	UpdateRotationUsingOtherInput(DeltaTime);		
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

	SetTimer(0.05, true, 'updateLocationAndRotation');
	//SetTimer(ROTATION_SET_FREQUENCY, true, 'setRotationFlag');
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
	//local Vector behindPlayer;
	local Vector playerServerLoc;
	//local Vector distance;
	//distance.X = 50;
	//distance.Y = 50;
	

	if(playerSpectatingAs != none)
	{
		//`log(playerSpectatingAs.Name);
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
			if(true || rotationsSetNum < ROTATIONS_TO_BE_SET)
			{
				self.SetRotation(playerRotation);					
				//correctiveYaw = normalizeYaw(playerRotation.Yaw) - self.Rotation.Yaw - playerInputATurnOfPlayerSpectatingAs;
				//`log("Corrective yaw is: " $ correctiveYaw);
				rotationsSetNum++;
			}
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
	
	// Calculate Delta to be applied on ViewRotation
	DeltaRot.Yaw = playerInputATurnOfPlayerSpectatingAs;
	if(correctiveYaw != 0)
	{
		DeltaRot.Yaw = DeltaRot.Yaw  + correctiveYaw;	
		correctiveYaw = 0;
	}

	ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );	
	ViewRotation.Yaw = normalizeYaw(ViewRotation.Yaw);
	//`log("my yaw = " $ ViewRotation.Yaw);
	SetRotation(ViewRotation);

	ViewShake( deltaTime );

	NewRotation = ViewRotation;
	NewRotation.Roll = Rotation.Roll;

	if ( Pawn != None )
		Pawn.FaceRotation(NewRotation, deltatime);
}

simulated function float normalizeYaw(float yaw)
{
	//local int quotient;
	//quotient = yaw / 65536;
	//if(quotient >= 1 || quotient <= -1)
	//	yaw = yaw - quotient * 65536;	

	//if( yaw >= 32768 )
	//	yaw = 32768 - 65536;

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

DefaultProperties
{
	ROTATION_SET_FREQUENCY = 1
	ROTATIONS_TO_BE_SET = 1
	Physics=PHYS_None	
}
