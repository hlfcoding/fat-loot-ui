class SneaktoSlimPawn_GinsengBaby extends SneaktoSlimPawn;

var() int BurstRadius; // Radius of AOE of Burst
var() int BurstPower;  // How far do victims get pushed
var() int EnergyNeededForBurst;  //Energy consumed by one Burst

//simulated event Tick(float DeltaTime)
//{
//	if(self.Controller.GetStateName() == 'Burrow')
//	{
//		self.v_energy -= 0.02;
//		if(self.v_energy <= 0.1)
//			self.Controller.GotoState('PlayerWalking');
//	}
//}

simulated function BabyBurst()
{
	local SneaktoSlimPawn victim;

	if(self.v_energy < EnergyNeededForBurst)
	{
		`log(self.Name $ " doesn't have enough energy for Burst", true, 'Ravi');
		return;
	}
	self.v_energy -= EnergyNeededForBurst; //Use the energy and then push nearby players

	foreach OverlappingActors(class'SneaktoSlimPawn', victim, BurstRadius, self.Location)
	{		
		if(victim == self)
			continue; // don't attack self!
		
		if(victim.isGotTreasure)
		{            
			victim.dropTreasure();
		}
		checkOtherFLBuff(victim);

		if(victim.Controller == none)
			continue;

		if (SneaktoSlimPlayerController(victim.Controller).GetStateName() != 'InBellyBump')     //if the victim isn't belly-bumping too...
		{
			victim.knockBackVector = normal(victim.Location - self.Location) * BurstPower;
			victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.					
			SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//already done by server, no need to call server again
		}
		else if (SneaktoSlimPlayerController(victim.Controller).GetStateName() == 'InBellyBump') //if the victim is belly-bumping too...
		{
			victim.knockBackVector = victim.Location - self.Location;
			victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.
			SneaktoSlimPlayerController(self.Controller).GoToState('BeingBellyBumped');//as above
			SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//as above					
			self.knockBackVector = self.Location - victim.Location;
			self.knockBackVector.Z = 0;					
		}
	}	
}

reliable server function meshTranslation(int zValue, int teamNum)
{
	local sneaktoslimpawn CurrentPawn;
	sneaktoslimplayercontroller_ginsengbaby(self.Controller).myOffset.X = 0;
	sneaktoslimplayercontroller_ginsengbaby(self.Controller).myOffset.Y = 0;
	sneaktoslimplayercontroller_ginsengbaby(self.Controller).myOffset.Z = zValue;
	ForEach AllActors(class 'sneaktoslimpawn', CurrentPawn)
	{
		CurrentPawn.clientMeshTranslation(zValue, teamNum);
	}
}

//reliable client function clientMeshTranslation(int zValue)
//{
//	ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
//	{
//		if(CurrentPawn.Class == 'sneaktoslimpawn_ginsengbaby' && CurrentPawn.GetTeamNum() == self.GetTeamNum())
//		if(CurrentPawn.GetTeamNum() == meshNum)
//		{
//			if(CurrentPawn.Role == ROLE_AutonomousProxy)
//			{
//				CurrentPawn.Mesh.SetTranslation(sneaktoslimplayercontroller_ginsengbaby(CurrentPawn.Controller).myOffset);
//			}
//			else if (CurrentPawn.Role == ROLE_SimulatedProxy)
//			{
//				CurrentPawn.Mesh.SetTranslation(sneaktoslimplayercontroller_ginsengbaby(CurrentPawn.Controller).myOffset);
//			}
//		}
//	}
//}

DefaultProperties
{
	BurstRadius = 100
	BurstPower = 23
	EnergyNeededForBurst = 10
}
