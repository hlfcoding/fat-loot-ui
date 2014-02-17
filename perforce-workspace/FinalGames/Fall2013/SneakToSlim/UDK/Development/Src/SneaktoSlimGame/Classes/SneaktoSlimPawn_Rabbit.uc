class SneaktoSlimPawn_Rabbit extends SneaktoSlimPawn;

//REPLICATE IN OTHER PAWNS WITH ACCORDING LOGIC
event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	local SneaktoSlimSpawnPoint playerBase;
	playerBase = SneaktoSlimSpawnPoint(Other);	

	if(playerBase != none)
	{	
		`log("Pawn touching SpawnPoint");
		if (SneaktoSlimPlayerController(self.Controller).IsInState('HoldingTreasureExhausted'))
		{
			SneaktoSlimPlayerController(self.Controller).attemptToChangeState('Exhausted');
			SneaktoSlimPlayerController(self.Controller).GoToState('Exhausted');//local
		}
		if (SneaktoSlimPlayerController(self.Controller).IsInState('HoldingTreasureWalking'))
		{
			SneaktoSlimPlayerController(self.Controller).attemptToChangeState('PlayerWalking');
			SneaktoSlimPlayerController(self.Controller).GoToState('PlayerWalking');//local
		}
	}		
}

event Landed (Object.Vector HitNormal, Actor FloorActor)
{   
	//Fixes continuous jumping issue
	//To better resolve problem check where Velocity.Z keeps getting set
	local SneaktoSlimPlayerController_Rabbit c;

	c = SneaktoSlimPlayerController_Rabbit(self.Controller);
	c.bPressedJump = true;
}

DefaultProperties
{
	characterName = "Rabbit";
}
