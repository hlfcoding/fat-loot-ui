class SneaktoSlimPawn_Spectator extends SneaktoSlimPawn;

var SneaktoSlimPawn playerSpectatingAs;

exec function startSpectating()
{
	local SneaktoSlimPawn playerPawn;
	
	foreach WorldInfo.AllActors(class'SneaktoSlimPawn', playerPawn)
	{		
		//if(SneaktoSlimPlayerController(playerPawn.Controller).IsInState('Spectate'))
		//	continue; //don't spectate from another spectator's point of view!

		if( playerPawn.Name != self.Name) 
		{
			`log("Spectating as player: " $ playerPawn.Name, true, 'Ravi');
			playerSpectatingAs = playerPawn;	
			SneaktoSlimPlayerController(self.Controller).attemptToChangeState('Spectate');
			SneaktoSlimPlayerController(self.Controller).GoToState('Spectate');
			break;
		}
	}	
}

event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if( self.Controller.IsInState('Spectate') )
	{
		SneaktoSlimPlayerController_Spectator(self.Controller).updateLocationToSpectate();
	}
}

//function disableCollision()
//{
//	self.SetHidden(true);
//	self.SetCollisionType(ECollisionType.COLLIDE_NoCollision);
//}

simulated event PostBeginPlay()
{   
	self.mySkelComp.SetScale(0); //don't show fat lady model
    Super.PostBeginPlay();

	//settimer(5,false,'disableCollision');
}


DefaultProperties
{
}
