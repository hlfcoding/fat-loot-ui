class SneakToSlimCloth extends ITrigger;

var SneaktoSlimPawn tempUser;
var vector beginPosition;
var StaticMeshComponent myMesh;

var repNotify float myX;
var repNotify float myY;
var repNotify float myZ;

var Array<Vector> SpawnPoints;


replication {
	if (bNetDirty)
		myX,myY,myZ;
}



simulated event ReplicatedEvent(name VarName) 
{
	local vector newLocation;
	newLocation.X = myX;
	newLocation.Y = myY;
	newLocation.Z = myZ;
	self.SetLocation(newLocation);
}

reliable Server function ServerSetToLocationPoint(int Index)
{
	self.SetLocation(SpawnPoints[0]);
//	`Log("alex: ServerSetToLocationPointCalled"@SpawnPoints.Length);
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

	beginPosition = self.Location;
	myX = self.Location.X;
	myY = self.Location.Y;
	myZ = self.Location.Z;
	//`log("cloth is created");

}

event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
    super.Touch(Other, OtherComp, HitLocation, HitNormal);

	//`log("Cloth touched" $ self.GetPhysicsName());

	if(string(Other.Class) == "SneaktoSlimPawn")
	{
		tempUser = SneaktoSlimPawn(Other);
		tempUser.bBuffed = 2;
		tempUser.inputStringToHUD("get Cloth, press Shift to use");
		tempUser.myCloth = self;
		//`log(tempUser $ " get " $ tempUser.bBuffed);
		//tempUser.ChangeMesh(true);
		//tempUser.getTreasure(self);


		//tempUser.staticHUDmsg.eqGotten = eqGottenText; //local only
		tempUser.updateStaticHUDeq( eqGottenText);
		//`log("server tell client to do updateStaticHUDeq");
		self.ShutDown();

	}
}
 
event UnTouch(Actor Other)
{
    super.UnTouch(Other);
    //`log(Other.Name $ " leave " $ self.GetPhysicsName());
}

reliable server function turnOn()
{
	//`log(name $ " on");
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


DefaultProperties
{
	displayName = "Cloth";
	PromtText = "pick up Cloth";
	PromtTextXbox = "pick up Cloth"
	eqGottenText = "[Buff] Cloth"

	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
        StaticMesh=StaticMesh'EngineMeshes.Sphere'
		Scale=0.1
		bUsePrecomputedShadows=True
    End Object
 
    CollisionComponent=MyStaticMeshComponent 
	myMesh = MyStaticMeshComponent;
 
    Components.Add(MyStaticMeshComponent)
    bBlockActors=true
    bHidden=false
	bNoDelete=false// if this is set to true we can never spawn it using spawn point

	RemoteRole=ROLE_AutonomousProxy
	bAlwaysRelevant=true
}
