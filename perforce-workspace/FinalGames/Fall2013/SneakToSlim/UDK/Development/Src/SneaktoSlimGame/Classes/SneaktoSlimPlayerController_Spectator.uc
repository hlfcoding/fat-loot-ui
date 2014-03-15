class SneaktoSlimPlayerController_Spectator extends SneaktoslimPlayerController
	config(Game);


simulated state Spectate extends PlayerWalking
{
	simulated event BeginState(Name prevState)
	{
		Pawn.GroundSpeed = 0;
		Pawn.SetHidden(true);
		Pawn.SetCollisionType(ECollisionType.COLLIDE_NoCollision);
	}

	simulated event EndState(Name nextState)
	{
		Pawn.GroundSpeed = SneaktoSlimPawn(Pawn).FLWalkingSpeed;
		Pawn.SetHidden(false);
		Pawn.SetCollisionType(ECollisionType.COLLIDE_BlockAll);
	}

	exec function changeSpectateTarget()
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

		teamNumSpectatingAs = SneaktoSlimPawn_Spectator(Pawn).playerSpectatingAs.GetTeamNum();
		if(teamNumSpectatingAs < maxTeamNum)
			teamNumToSpectateAs = teamNumSpectatingAs + 1;
		else
			teamNumToSpectateAs = 0;

		if(teamNumToSpectateAs == self.Pawn.GetTeamNum())
		{
			if(teamNumSpectatingAs < maxTeamNum)
				teamNumToSpectateAs++;
			else
				teamNumToSpectateAs = 0;
		}

		foreach WorldInfo.AllActors(class'SneaktoSlimPawn', playerPawn)
		{		
			if( playerPawn.GetTeamNum() == teamNumToSpectateAs) 
			{
				`log("Spectating as player: " $ playerPawn.Name, true, 'Ravi');
				SneaktoSlimPawn_Spectator(Pawn).playerSpectatingAs = playerPawn;				
				break;
			}
		}
	}

Begin:	
}

simulated function updateLocationToSpectate()
{
	if(SneaktoSlimPawn_Spectator(Pawn).playerSpectatingAs != none)
	{
		Pawn.SetLocation( SneaktoSlimPawn_Spectator(Pawn).playerSpectatingAs.Location );
	}
}



DefaultProperties
{
}
