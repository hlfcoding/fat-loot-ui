class SneaktoSlimPawn_GinsengBaby extends SneaktoSlimPawn;

var() int MIN_BURST_RADIUS; // Minimum Radius of AOE of Burst
var() int MAX_BURST_RADIUS; // Maximum Radius of AOE of Burst
var() float MIN_BURST_CHARGE_TIME; //Player must hold the activate button at least this long to trigger a Burst
var() float MAX_BURST_CHARGE_TIME; //Charging more than this will set burst radius to be MaxBurstRadius
var() int BurstPower;  // How far do victims get pushed
var() int EnergyNeededForBurst;  //Energy consumed by one Burst
var SkeletalMeshComponent gbSkelMesh;
var ParticleSystemComponent dustEffect;
//var Array<MaterialInstanceConstant> teamMaterial;

simulated event PostBeginPlay()
{   
	self.mySkelComp.SetScale(0.0); //don't show fat lady model	
	Super.PostBeginPlay();
	//teamMaterial[0] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	//teamMaterial[1] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	//teamMaterial[2] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	//teamMaterial[3] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	//self.Mesh.SetMaterial(1, teamMaterial[self.GetTeamNum()]);
}

simulated function BabyBurst(float chargeTime)
{
	local SneaktoSlimPawn victim;
	local float burstRadius;
	
	if(self.v_energy < EnergyNeededForBurst)
	{
		`log(self.Name $ " Doesn't have enough energy for Burst", true, 'Ravi');
		return;
	}
	self.v_energy -= EnergyNeededForBurst; //Use the energy and then push nearby players

	burstRadius = calculateBurstRadius(chargeTime);
	`log(self.Name $ " Effective Burst radius: " $ burstRadius, true, 'Ravi');

	foreach OverlappingActors(class'SneaktoSlimPawn', victim, burstRadius, self.Location)
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

simulated function float calculateBurstRadius(float chargeTime)
{
	local float burstRadius;
	if(chargeTime < MIN_BURST_CHARGE_TIME)
	{
		//`log(self.Name $ " Not charged enough for burst", true, 'Ravi');
		return 0;
	}
	chargeTime = FMin(chargeTime, MAX_BURST_CHARGE_TIME); //upper limit
	burstRadius = MIN_BURST_RADIUS + (chargeTime - MIN_BURST_CHARGE_TIME)  * (MAX_BURST_RADIUS - MIN_BURST_RADIUS) / (MAX_BURST_CHARGE_TIME - MIN_BURST_CHARGE_TIME);

	return burstRadius;
}

reliable server function meshTranslation(bool downOrUp, int teamNum)
{
	local sneaktoslimpawn CurrentPawn;
	ForEach AllActors(class 'sneaktoslimpawn', CurrentPawn)
	{
		CurrentPawn.clientMeshTranslation(downOrUp, teamNum);
	}
}

function toggleDustParticle(bool flag)
{
	dustEffect.SetActive(flag);
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
	FLWalkingSpeed=250.0
	GroundSpeed=250.0;

	MIN_BURST_RADIUS = 50
	MAX_BURST_RADIUS = 150
	MIN_BURST_CHARGE_TIME = 0.2
	MAX_BURST_CHARGE_TIME = 2.0
	BurstPower = 23
	EnergyNeededForBurst = 10
	
	Begin Object Class=SkeletalMeshComponent Name=GBSkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.GinsengBaby.GinsengBaby_skeletal'	
		AnimSets(0)=AnimSet'FLCharacter.GinsengBaby.GinsengBaby_animsets'
		AnimTreeTemplate = AnimTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree'	
		Translation=(Z=-50.0)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false		
	End Object

	Components.Add(GBSkeletalMesh)
	gbSkelMesh = GBSkeletalMesh
	Mesh = GBSkeletalMesh

	Begin Object Class=ParticleSystemComponent Name=UGdust
		Template=ParticleSystem'flparticlesystem.UGWalkingDust'
		bAutoActivate=false
		Translation=(Z=-50.0)
	End Object

	dustEffect = UGdust
	Components.Add(UGdust)

	characterName = "GinsengBaby";
	
	//teamMaterial[0] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	//teamMaterial[1] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	//teamMaterial[2] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	//teamMaterial[3] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
}
