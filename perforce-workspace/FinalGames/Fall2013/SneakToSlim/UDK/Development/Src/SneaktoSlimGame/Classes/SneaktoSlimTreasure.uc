class SneaktoSlimTreasure extends Trigger;

var SneaktoSlimPawn tempUser;
var vector beginPosition;
var StaticMeshComponent myMesh;
var repNotify float myX;
var repNotify float myY;
var repNotify float myZ;
var repNotify bool TreasureOut;
var DynamicLightEnvironmentComponent LightEnvironment;
var Array<Vector> SpawnPoints;
var Array<SneaktoSlimTreasureSpawnPoint> SpawnPointsReference;
var int CurrentSpawnPointIndex;
var float treasureVelocity;
var bool TreasureIsMoving;
var Vector treasureTargetLocation;
var float TreasureResetTime;

replication {
	if (bNetDirty)
		myX,myY,myZ, CurrentSpawnPointIndex,TreasureOut;
}

simulated event ReplicatedEvent(name VarName) 
{
	local vector newLocation;
	if(VarName == 'myX'){
	    newLocation.X = myX;
	    newLocation.Y = myY;
	    newLocation.Z = myZ;
	    self.SetLocation(newLocation);
	}
	if(VarName == 'TreasureOut'){
		if(!TreasureOut){
            ResetTreasure();
		}
	}
}

simulated function StartResetTreasure(){
	setTimer(TreasureResetTime,false,'ResetTreasure');
}

simulated function StopResetTreasure(){
	clearTimer('ResetTreasure');
}

simulated function ResetTreasure(){
	local int index;
	local SneakToSlimTreasureSpawnPoint TSP;
	local int TSPnum;

	if(self.bHidden ==true){
		return;
	}
	foreach AllActors(class'SneakToSlimTreasureSpawnPoint',TSP)
	{
		TSPnum++;
	}
	index = Rand(TSPnum);
	foreach AllActors(class'SneakToSlimTreasureSpawnPoint',TSP)
	{
		if(TSP.BoxIndex == index){
            TSP.MyTreasure = self;
			self.CurrentSpawnPointIndex = index;
			TSP.isHaveTreasure = true;
			self.SetLocation(TSP.Location);
			self.TreasureOut = false;
			self.ShutDown();
		}
	}
}

reliable Server function ServerSetToLocationPoint(int Index)
{
	self.SetLocation(SpawnPoints[Index]);
	`Log("alex: ServerSetToLocationPointCalled"@SpawnPoints.Length);
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
    //`Log("Andy:: Info: Controller Started");

	beginPosition = self.Location;
	myX = self.Location.X;
	myY = self.Location.Y;
	myZ = self.Location.Z;

	`log(beginPosition);
}


simulated function giveTreasure(SneaktoSlimPawn User, SneaktoSlimTreasureSpawnPoint treasureChest){
     User.getTreasure(self, treasureChest);
}

event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	local SneakToSlimPawn current;
    super.Touch(Other, OtherComp, HitLocation, HitNormal);
	tempUser = SneaktoSlimPawn(Other);
	if(tempUser != none)
	{
		foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
		{
			//`log("clientRoarParticle" $ current.GetTeamNum());
			current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Treasure_Stolen_Cue');
			
		}
		tempUser.getTreasure(self, NONE);
	}
}
 
event UnTouch(Actor Other)
{
    super.UnTouch(Other);
}

exec simulated function turnOn()
{
	// Shut down physics
	//SetPhysics(PHYS_None);
	SetPhysics(PHYS_None);
	// shut down collision
	SetCollision(true, true);
	if (CollisionComponent != None)
	{
		CollisionComponent.SetBlockRigidBody(true);
	}

	// shut down rendering
	SetHidden(false);
	// and ticking
	SetTickIsDisabled(false);

	ForceNetRelevant();

	if (RemoteRole != ROLE_None)
	{
		// force replicate flags if necessary
		SetForcedInitialReplicatedProperty(Property'Engine.Actor.bCollideActors', (bCollideActors == default.bCollideActors));
		SetForcedInitialReplicatedProperty(Property'Engine.Actor.bBlockActors', (bBlockActors == default.bBlockActors));
		SetForcedInitialReplicatedProperty(Property'Engine.Actor.bHidden', (bHidden == default.bHidden));
		SetForcedInitialReplicatedProperty(Property'Engine.Actor.Physics', (Physics == default.Physics));
	}
}

function bool UsedBy(Pawn User)
{
   `log("Treasure usedBy"@User.Name, true,'Lu');

   return true;
}

function setBeingTracked()
{
	//self.myMesh.SetMaterial(0,Material'FLCharacter.lady.Tracked');
	self.myMesh.SetDepthPriorityGroup(ESceneDepthPriorityGroup(SDPG_Foreground)) ;
}

function releaseBeingTracked()
{
	//self.myMesh.SetMaterial(0,Material'FLCharacter.lady.unTracked');
	self.myMesh.SetDepthPriorityGroup(ESceneDepthPriorityGroup(SDPG_World)) ;
}


exec function myFunction()
{
   `log("myFunction");
	self.ShutDown();

    return;
}

simulated function movetoDropLocation(Vector TargetLocation)
{
	treasureTargetLocation = TargetLocation;
	`log("treasureMoveToLocation" @treasureTargetLocation);
	TreasureIsMoving = true;
	`log("treasure is not ticking" @self.bTickIsDisabled);
	`log("treasure is moving" @TreasureIsMoving);
}



//simulated function treasureMoving()
//{
//	local Vector vdirection;
//	vdirection = treasureTargetLocation - self.Location;
//	`log("treasureCurrentLocation" @self.Location);
//	`log("movingDirection" @vdirection);
//	if (VSize(vdirection)>treasureVelocity)
//	{
//		`log("treasure is moving!" @ VSize(vdirection));
//		vDirection = Normal(vDirection);
//		self.SetLocation(self.Location + vdirection * treasureVelocity);
//		vdirection = treasureTargetLocation - self.Location;
//		SetTimer(0.05, true,'treasureMoving');
//	}
//	else
//	{
//		self.SetLocation(treasureTargetLocation);
//	}
//}

simulated event Tick(float DeltaTime)
{
	local Vector vdirection;
	if (TreasureIsMoving)
	{
		vdirection = treasureTargetLocation - self.Location;
		`log("treasureCurrentLocation" @self.Location);
		`log("movingDirection" @vdirection);
		if (VSize(vdirection)>treasureVelocity*DeltaTime)
		{
			//`log("treasure is moving!" @ VSize(vdirection));
			vDirection = Normal(vDirection);
			self.SetLocation(self.Location + vdirection * treasureVelocity*DeltaTime);
			vdirection = treasureTargetLocation - self.Location;
		}
		else
		{
			self.SetLocation(treasureTargetLocation);
			TreasureIsMoving = false;
			SetCollision(true, true);
		}
	}
}

DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
        StaticMesh= StaticMesh'FLInteractiveObject.treasure.Tresure'
		Scale=1.0
		//Translation=(Z=-48.0)
		bUsePrecomputedShadows=True
		LightEnvironment=MyLightEnvironment
    End Object
 
    CollisionComponent=MyStaticMeshComponent 
	myMesh = MyStaticMeshComponent;
 
	Components.Remove(Sprite)

    Components.Add(MyStaticMeshComponent)

	Begin Object Class=ParticleSystemComponent Name=TreasureEffectCompoent
        Template=ParticleSystem'flparticlesystem.treasureMovingEffect'
        bAutoActivate=true
	End Object

	Components.Add(TreasureEffectCompoent)



	//Begin Object Class=pointlightcomponent Name=TreasurePointLight
 //     Translation = (Z = -22.0)
	//  bEnabled = true
	//  bCastCompositeShadow = true
	//  bAffectCompositeShadowDirection = true
	//  CastShadows = true;
	//  CastStaticShadows = true;
	//  CastDynamicShadows = true;
	//  LightShadowMode = LightShadow_Normal
	//  Radius=512.000000
	//  Brightness=10.0000	 
	//  LightColor=(R=255,G=255,B=0)
 //     bRenderLightShafts = true
	//  LightmassSettings = (LightSourceRadius = 32.0)
	//End Object
	//Components.Add(TreasurePointLight)

    bBlockActors=false
    bHidden=false
	bNoDelete=false// if this is set to true we can never spawn it using spawn point

	RemoteRole=ROLE_AutonomousProxy
	bAlwaysRelevant=true
	CurrentSpawnPointIndex = 255;
    TreasureOut = false;
	treasureVelocity = 500.0
	TreasureResetTime = 10;
}
