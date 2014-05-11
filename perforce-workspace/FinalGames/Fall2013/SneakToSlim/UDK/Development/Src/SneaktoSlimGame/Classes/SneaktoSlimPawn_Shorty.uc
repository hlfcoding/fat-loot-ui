class SneaktoSlimPawn_Shorty extends SneaktoSlimPawn;

var() float SHORTY_DASH_SPEED; //Speed at which Shorty starts dashing. He decelerates over time
var() float MAX_DASH_TIME;     //Max duration Shorty can Dash in one sprint
var() int DASH_ENERGY_CONSUMPTION_RATE; 
var() float DASH_CHARGE_VS_MOVE_DURATION_FACTOR; //Duration charge key is pressed VS duration Shorty dashes
var() float MIN_FIRECRACKER_CHARGE_TIME; //Player must hold the activate button at least this long to trigger a throw
var() float MAX_FIRECRACKER_CHARGE_TIME; //Charging more than this has no effect. The peak distance is reached by this charge time
var() int FIRECRACKER_SPEED_MULTIPLIER; //Firecracker launch velocity is ChargeTime * Multiplier
var() vector FIRECRACKER_THROW_DIRECTION; //Relative to where player is looking, what direction must the firecracker be thrown
var() int FIRECRACKER_EXPLOSION_DETECT_RADIUS; //The area in which guards will react to, and investigate the firecracker
var() int FIRECRACKER_EXPLOSION_AFFECT_RADIUS; //The area in which players will be stunned
var int DASH_ACCELERATION;
var int NORMAL_ACCELERATION;
var ParticleSystemComponent shortySprintParticleComp;

simulated event PostBeginPlay()
{   
	self.mySkelComp.SetScale(0); //don't show fat lady model
	FIRECRACKER_SPEED_MULTIPLIER = 2.6 * 250 / MAX_FIRECRACKER_CHARGE_TIME;
    Super.PostBeginPlay();
}

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

			if(SneaktoSlimPlayerController_Shorty(Self.Controller).IsInState('Exhausted'))
			{
				SneaktoSlimPlayerController_Shorty(Self.Controller).attempttochangestate('HoldingTreasureExhausted');//to server
				SneaktoSlimPlayerController_Shorty(Self.Controller).gotostate('HoldingTreasureExhausted');//local
			}
			else
			{
				SneaktoSlimPlayerController_Shorty(Self.Controller).attempttochangestate('HoldingTreasureWalking');//to server
				SneaktoSlimPlayerController_Shorty(Self.Controller).gotostate('HoldingTreasureWalking');//local
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
			SneaktoSlimPlayerController_Shorty(Self.Controller).DropTreasure();
		}
	}
}

event Bump (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitNormal)
{		
	local SneaktoSlimPawn victim;

	super.Bump(Other, OtherComp, HitNormal);

	if(SneaktoSlimPlayerController_Shorty(Controller) == None)
		return;

	if( SneaktoSlimPlayerController_Shorty(Controller).IsInState('Dashing') )
	{
		SneaktoSlimPlayerController_Shorty(Controller).StopDashing();
		if (SneaktoSlimPawn(Other) != none)         //If the belly-bump recipient is another Player...
		{
			victim = SneaktoSlimPawn(Other);
			if(victim.isGotTreasure)
			{            
				victim.dropTreasure(Normal(vector(self.rotation)));
			}
			checkOtherFLBuff(victim);

			if(SneaktoSlimPlayerController(victim.Controller) == None)
				return;

			if (SneaktoSlimPlayerController(victim.Controller).GetStateName() != 'InBellyBump')     //if the victim isn't belly-bumping too...
			{
				victim.knockBackVector = Other.Location - self.Location;
				victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.					
				SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//already done by server, no need to call server again
			}
			else if (SneaktoSlimPlayerController(victim.Controller).GetStateName() == 'InBellyBump') //if the victim is belly-bumping too...
			{
				victim.knockBackVector = Other.Location - self.Location;
				victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.
				SneaktoSlimPlayerController(self.Controller).GoToState('BeingBellyBumped');//as above
				SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//as above					
				self.knockBackVector = self.Location - Other.Location;
				self.knockBackVector.Z = 0;					
			}
		}
	}	
}

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

server reliable function listRoles()
{
	local Actor tempA;
	local int index;
	foreach AllActors(class 'Actor', tempA)
	{
		index = InStr( string(tempA.Name), "Sneak" );
		if(  index >= 0 )
			`log("Actor: " $ tempA.Name $ ", RemoteRole: " $ tempA.RemoteRole);
	}
}

simulated function toggleSprintParticle(bool flag)
{
	shortySprintParticleComp.SetActive(flag);
}

//event Tick(float DeltaTime)
//{
//	//`log(self.Controller.GetStateName());
//	//`log(self.GroundSpeed);
//	`log(self.v_energy);
//}

DefaultProperties
{
	FLWalkingSpeed=200.0
	FLSprintingSpeed=400.0
	GroundSpeed=200.0;

	Begin Object Class=SkeletalMeshComponent Name=ShortySkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.Shorty.Shorty_skeletal'
		AnimSets(0)=AnimSet'FLCharacter.Shorty.Shorty_Anims'
		AnimTreeTemplate = AnimTree'FLCharacter.Shorty.Shorty_AnimTree'		
		Translation=(Z=-52.0)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false		
	End Object

	Begin Object Class=ParticleSystemComponent Name=shortyChargeSmoke
        Template=ParticleSystem'flparticlesystem.shortySprintParticle'
		Translation=(Z=-42.0)
        bAutoActivate=false		
	End Object

	shortySprintParticleComp = shortyChargeSmoke

	Components.Add(shortyChargeSmoke)
	
	Components.Add(ShortySkeletalMesh)
	Mesh = ShortySkeletalMesh

	//Begin Object Name=CollisionCylinder
	//	CollisionRadius=15.000000
    //    CollisionHeight=48.000000
    //End Object
	//CylinderComponent=CollisionCylinder

	Begin Object Class=PointLightComponent Name=MyPointlightBack
	  bEnabled=true
	  bCastCompositeShadow = true;
	  bAffectCompositeShadowDirection =true;
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Normal ;
	  Radius=15.000000
	  Brightness=.3
	  LightColor=(R=235,G=235,B=110)
	  Translation=(X=-5, Z=-20)
	End Object
	Components.Add(MyPointlightBack)

	Begin Object Class=PointLightComponent Name=MyPointlightFront
	  bEnabled=true
	  bCastCompositeShadow = true;
	  bAffectCompositeShadowDirection =true;
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Normal ;
	  Radius=15.000000
	  Brightness=.3
	  LightColor=(R=235,G=235,B=110)
	  Translation=(X=5, Z=-20)
	End Object
	Components.Add(MyPointlightFront)

	NORMAL_ACCELERATION = 500;
	DASH_ACCELERATION = 4000;
	SHORTY_DASH_SPEED = 800;
	MAX_DASH_TIME = 1.5;
	DASH_ENERGY_CONSUMPTION_RATE = 40;
	DASH_CHARGE_VS_MOVE_DURATION_FACTOR = 1;
	MIN_FIRECRACKER_CHARGE_TIME = 0.2;
	MAX_FIRECRACKER_CHARGE_TIME = 0.6;	
	FIRECRACKER_THROW_DIRECTION=(X=0,Y=0,Z=0.65)
	FIRECRACKER_EXPLOSION_DETECT_RADIUS = 1000
	FIRECRACKER_EXPLOSION_AFFECT_RADIUS = 100

	characterName = "Shorty";

	//Material'FLCharacter.GinsengBaby.GinsengBaby_material_0'
}
