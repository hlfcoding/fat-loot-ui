class SneaktoSlimPawn_Rabbit extends SneaktoSlimPawn;

var int NORMAL_ACCELERATION;
var int TELEPORT_ACCELERATION;
var int TELEPORT_SPEED;

simulated event ReplicatedEvent(name VarName)
{
	local SneaktoSlimPawn pa;
	super.ReplicatedEvent(VarName);
	if( VarName == 'isGotTreasure')
	{

		if(self.isGotTreasure == true)
		{
			foreach WorldInfo.AllPawns(class 'SneaktoSlimPawn', pa)
			{
				pa.showCharacterHasTreasure(self.GetTeamNum());
			}

			`log("authority"$ self.Role);
			`log(self.Mesh.GetSocketByName('treasureSocket'));
			if (self.Mesh.GetSocketByName('treasureSocket') != None){
				self.Mesh.AttachComponentToSocket(treasureComponent , 'treasureSocket');
				self.Mesh.AttachComponentToSocket(treasureLightComponent , 'treasureSocket');
			}	

			if(self.Role == ROLE_SimulatedProxy)
			{
				foreach WorldInfo.AllPawns(class 'SneaktoSlimPawn', pa)
				{
					if(pa.Role == ROLE_AutonomousProxy)
					{
						if(pa.mistNum == self.mistNum)
						{
							self.treasureComponent.SetHidden(false);
							self.SetTreasureParticleEffectActive(true); 
						}
						else
						{
							self.treasureComponent.SetHidden(true);
							self.SetTreasureParticleEffectActive(false); 
						}
					}
				}
			}
			else if(self.Role == ROLE_AutonomousProxy)
				SetTreasureParticleEffectActive(true);

			if(SneaktoSlimPlayerController_Rabbit(Self.Controller).IsInState('Exhausted'))
			{
				SneaktoSlimPlayerController_Rabbit(Self.Controller).attempttochangestate('HoldingTreasureExhausted');//to server
				SneaktoSlimPlayerController_Rabbit(Self.Controller).gotostate('HoldingTreasureExhausted');//local
			}
			else
			{
				SneaktoSlimPlayerController_Rabbit(Self.Controller).attempttochangestate('HoldingTreasureWalking');//to server
				SneaktoSlimPlayerController_Rabbit(Self.Controller).gotostate('HoldingTreasureWalking');//local
			}


		}
		else
		{
			foreach WorldInfo.AllPawns(class 'SneaktoSlimPawn', pa)
			{
				pa.showCharacterLostTreasure(self.GetTeamNum());
			}

			if (self.Mesh.IsComponentAttached(treasureComponent)){
				self.Mesh.DetachComponent(treasureComponent);
				self.Mesh.DetachComponent(treasureLightComponent);
			}				
			if(self.mistNum == 0)
				self.changeCharacterMaterial(self,self.GetTeamNum(),"Character");
			else
				self.changeCharacterMaterial(self,self.GetTeamNum(),"Invisible");
			self.SetTreasureParticleEffectActive(false);			
			SneaktoSlimPlayerController_Rabbit(Self.Controller).DropTreasure();
		}
	}
}

simulated event PostBeginPlay()
{   
	self.mySkelComp.SetScale(0); //don't show fat lady model
    Super.PostBeginPlay();
}

//REPLICATE IN OTHER PAWNS WITH ACCORDING LOGIC
event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	local SneaktoSlimSpawnPoint playerBase;
	playerBase = SneaktoSlimSpawnPoint(Other);	

	if(playerBase != none && playerBase.teamID == self.GetTeamNum())
	{	
		//`log("Pawn touching SpawnPoint");
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

//simulated function callClientRoarParticle(int teamNumber)
//{
//	local sneakToSlimPawn current;
	
//	if(role == role_authority)
//		foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
//		{
//			`log("callClientRoarParticle" $ current.GetTeamNum());
//			current.clientRoarParticle(teamNumber);
//		}
//}

//reliable client function clientRoarParticle(int teamNumber)
//{
//	local sneakToSlimPawn current;
	
//	foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
//	{
//		`log("clientRoarParticle" $ current.GetTeamNum());
//		if(current.GetTeamNum() == teamNumber)
//		{
//			WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'flparticlesystem.SonicBeam',current.Location);
//			//PlaySound(SoundCue'flsfx.Player_Hit_Cue');
//		}
			
//	}
//}

//event Landed (Object.Vector HitNormal, Actor FloorActor)
//{   
//	//Fixes continuous jumping issue
//	//To better resolve problem check where Velocity.Z keeps getting set
//	local SneaktoSlimPlayerController_Rabbit c;

//	c = SneaktoSlimPlayerController_Rabbit(self.Controller);
//	c.bPressedJump = true;
//}

//event Tick(float DeltaTime)
//{
////	`log(self.Controller.GetStateName());
////	`log(self.GroundSpeed);
//	`log(self.v_energy);
//}

DefaultProperties
{
	Begin Object Class=SkeletalMeshComponent Name=RabbitSkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.Rabbit.rabbit_skeletal'
		AnimSets(0)= AnimSet'FLCharacter.Rabbit.Rabbit_Animsets'
		AnimTreeTemplate = AnimTree'FLCharacter.Rabbit.rabbit_AnimTree'
		Translation=(Z=-52.0)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false	

		bEnableClothSimulation = true
		bClothAwakeOnStartup= true
	//	ClothExternalForce = (X=0.000000,Y=0.000000,Z=-100.000000)
	//	ClothWind = (X=0.000000,Y=0.0,Z=20.000000)
		ClothForceScale =1.000000
		MinDistanceForClothReset=128.000000

		PhysicsAsset(0) = PhysicsAsset'FLCharacter.Rabbit.rabbit_skeletal_Physics'
		bHasPhysicsAssetInstance = true
		BlockRigidBody=True
		RBCollideWithChannels = (Default=True,Nothing=False,Pawn=False,Vehicle=False,Water=False,GameplayPhysics=True,EffectPhysics=True,Untitled1=False,Untitled2=False,Untitled3=False,Untitled4=False,Cloth=True,FluidDrain=False,SoftBody=False,FracturedMeshPart=False,BlockingVolume=True,DeadPawn=False,Clothing=False,ClothingCollision=False)
	End Object

	//Begin Object Name=CollisionCylinder
	//	CollisionRadius=18.000000
    //    CollisionHeight=48.000000
    //End Object
	//CylinderComponent=CollisionCylinder

	Components.Add(RabbitSkeletalMesh)
	Mesh = RabbitSkeletalMesh

	NORMAL_ACCELERATION = 500;
	TELEPORT_ACCELERATION = 10000;
	TELEPORT_SPEED = 5000;

	characterName = "Rabbit";
}
