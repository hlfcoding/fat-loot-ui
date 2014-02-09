class SneaktoSlimPawn_Rabbit extends SneaktoSlimPawn;

//REPLICATE IN OTHER PAWNS WITH ACCORDING LOGIC
event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	local SneaktoSlimSpawnPoint base;
	base = SneaktoSlimSpawnPoint(Other);	

	if(base != none)
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

DefaultProperties
{
}
