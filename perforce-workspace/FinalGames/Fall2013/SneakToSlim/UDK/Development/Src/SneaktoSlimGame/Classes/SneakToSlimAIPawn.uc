class SneakToSlimAIPawn extends Pawn placeable;
var DynamicLightEnvironmentComponent LightEnvironment;
var SkeletalMeshComponent aiSkelComp;

var repnotify string aiState;

var () array<NavigationPoint> MyNavigationPoints;
var () float ChaseSpeed; //speed when chasing player
var () float MaxChaseStamina; //Max energy of guard
var () float ChaseStaminaConsumptionRate; //Stamina depletion per second when chasing
var () float ChaseStaminaRegenerationRate; //Stamina increase per second when not chasing
var () float PatrolSpeed; //normal walking speed
var () float DetectAngle; //catches player if angle between (AI forward line of sight) and (AI to player line) is within this
var () float DetectDistance; //AI starts tracking player if he is within this distance
var () float CatchDistance; //if AI is within this distance of player, player is "caught" and sent back to base
var () float HoldTime; //Amount of time AI holds the player before sending to base
var () float DetectReactionTime; //number of seconds AI waits before following a player or investigating a noise
var () float MaxInvestigationDistance; //AI will investigate an event if distance is less than this, else it will ignore the event.
var () float lightRadius;
var () float rotationAngle;
var () float rotationDuration;
var () float pauseTime;
var () float accelerationSpeed;
var () float MinInvestigationDistance;
var SpotLightComponent Flashlight;
var StaticMeshComponent lantern;

var float LOCATION_SEND_FREQUENCY;
var float LOCATION_SET_FREQUENCY;
var int NUM_INTERPOLATION_UPDATES;
var Rotator customRotation;
var Vector customLocation;
var Vector currentDestination;
var Vector customVelocity;
var int interpolationCounter;

simulated event PostBeginPlay()
{
    SetPhysics(PHYS_Walking);
    GroundSpeed = PatrolSpeed;   
    lightRadius = 250;  
    Super.PostBeginPlay();
    self.aiSkelComp.AttachComponentToSocket(lantern,'lantern');

	NUM_INTERPOLATION_UPDATES = LOCATION_SEND_FREQUENCY / LOCATION_SET_FREQUENCY;
    if(Role == ROLE_Authority)
	{
		setTimer(LOCATION_SEND_FREQUENCY, true, 'sendCustomLocation');
	}
	if(Role == ROLE_SimulatedProxy)
	{
		setTimer(LOCATION_SET_FREQUENCY, true, 'interpolateLocation');
	}
}

replication {
	if(bNetDirty) aiState;

	if(bNetDirty && Role == ROLE_Authority) //send from server to other clients
		customLocation, customRotation, customVelocity;
}

function sendCustomLocation()
{
	if(Role == ROLE_Authority)
	{
		customLocation = self.Location;
		customRotation = self.Rotation;		
		customVelocity = self.Velocity;
	}
}

simulated function interpolateLocation()
{
	local Vector moveStep;

	if(Role == ROLE_SimulatedProxy)
	{
		self.SetRotation(customRotation);
		self.Velocity = customVelocity;

		if( interpolationCounter == 0)
			currentDestination = customLocation;
				
		if( VSize(currentDestination - self.Location) > 10 ) //don't move very short distances
		{
			moveStep = (currentDestination - self.Location) / (NUM_INTERPOLATION_UPDATES - interpolationCounter);
			self.SetLocation(self.Location + moveStep);
		}
		interpolationCounter += 1;	
		if(interpolationCounter >= NUM_INTERPOLATION_UPDATES)
			interpolationCounter = 0;		
	}
}

function AddLatern()
{
  if(self.Mesh.GetSocketByName('lantern') != None)
		self.Mesh.AttachComponentToSocket(lantern,'lantern');
}


function controlAIAnimation
(
	name nodeName, 
	name	AnimName,
	float	Rate,
	bool playOrStop,
	optional	float	BlendInTime,
	optional	float	BlendOutTime,
	optional	bool	bLooping,
	optional	bool	bOverride
)
{
	local AnimNodePlayCustomAnim customNode;	
	local SneaktoSlimPawn onePawn;
	local SneaktoSlimPawn_Spectator specPawn;

	customNode = AnimNodePlayCustomAnim(self.aiSkelComp.FindAnimNode(nodeName));
	if(customNode == None)
	{
		`log("Invalid custom node name", false, 'Ravi');
		return;
	}
	//Play animation
	if(playOrStop == true)
	{
		customNode.PlayCustomAnim(AnimName, Rate, BlendInTime, BlendOutTime, bLooping, bOverride);
	}
	else
	{
		customNode.StopCustomAnim(BlendOutTime);
	}	

	//If I am the server, then call all the client to play or stop the animation
	if(Role == ROLE_Authority)
	{
		ForEach WorldInfo.AllActors(class'SneaktoSlimPawn', onePawn)
		{
			onePawn.clientPlayerPlayAIAnimation(self, nodename, AnimName, Rate, playOrStop, BlendInTime, BlendOutTime, bLooping, bOverride);
		}

		ForEach WorldInfo.AllActors(class'SneaktoSlimPawn_Spectator', specPawn)
		{
			//specPawn.clientPlayerPlayAIAnimation(self, nodename, AnimName, Rate, playOrStop, BlendInTime, BlendOutTime, bLooping, bOverride);
		}
	}
}



DefaultProperties
{
	Begin Object Class=SpotLightComponent Name=MyFlashlight
	  bEnabled=true
	  bCastCompositeShadow = true;
	  bAffectCompositeShadowDirection =true;
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Normal ;
	  Radius=250.000000
	  Brightness=10.0
	  LightColor=(R=235,G=235,B=110)
	End Object
	Components.Add(MyFlashlight)
	Flashlight=MyFlashlight

	Begin Object Class=PointLightComponent Name=MyPointlight
	  bEnabled=true
	  bCastCompositeShadow = true;
	  bAffectCompositeShadowDirection =true;
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Normal ;
	  Radius=64.000000
	  Brightness=1.0
	  LightColor=(R=235,G=235,B=110)
	End Object
	Components.Add(MyPointlight)

	Begin Object Name=CollisionCylinder
        CollisionHeight=+44.000000
		CollisionRadius=15.000000
    End Object
 
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment	

	Begin Object Class=SkeletalMeshComponent Name=AISkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.Guard.Guard'
		AnimSets(0)=AnimSet'FLCharacter.Guard.Guard_Anims'
		AnimTreeTemplate = AnimTree'FLCharacter.Guard.Guard_AnimTree'		
		
		Translation=(Z=-48.75)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false		
	End Object




	Begin Object Class=StaticMeshComponent   Name=MyGuardLatern
		StaticMesh=StaticMesh'FLCharacter.guard.Lanturn'
		LightEnvironment=MyLightEnvironment
		CastShadow=true		
	End Object
	lantern = MyGuardLatern

	aiSkelComp = AISkeletalMesh
	Components.Add(AISkeletalMesh)

	ControllerClass=class'SneakToSlimAIController'
    bJumpCapable=false
    bCanJump=false

	aiState = "Patrol"
	PatrolSpeed = 150.0
	rotationAngle = 19658.4
	rotationDuration = 1.0
	pauseTime = 1.0
	accelerationSpeed = 25.0;
	ChaseSpeed = 300.0	
	CatchDistance = 120.0
	DetectAngle = 60.0 
	DetectDistance = 1000.0
	DetectReactionTime = 0.0
	HoldTime = 2
	MaxInvestigationDistance = 2000.0
	MinInvestigationDistance = 50.0
	bNoEncroachCheck = false     //Enables pawns to move even when overlapping	
	lightRadius = 400
	MaxChaseStamina = 100
	ChaseStaminaConsumptionRate = 30
	ChaseStaminaRegenerationRate = 10

	LOCATION_SEND_FREQUENCY = 0.075
	LOCATION_SET_FREQUENCY = 0.015
	bUpdateSimulatedPosition = false
	interpolationCounter = 0

	bCanStepUpOn = false

	MaxStepHeight = 25
}


