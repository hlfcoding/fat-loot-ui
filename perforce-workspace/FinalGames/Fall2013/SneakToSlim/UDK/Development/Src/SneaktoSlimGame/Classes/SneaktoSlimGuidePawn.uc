class SneaktoSlimGuidePawn extends Pawn
	placeable;

var GuideTrigger guideTrigger;
var vector teleportLocation;
var Rotator teleportRotation;

//Ideally one pawn can be placed in each room and with an appropriate tag given in editor, 
//we won't have to do much scripting to keep a single pawn following the player throughout the level
simulated event PostBeginPlay()
{	
	//local SneaktoSlimPawn_FatLady lady;
	//local SneakToSlimPlayerController_FatLady pc;

	super.PostBeginPlay();

	//Spawns a guide trigger and writes pawns tag to it
    guideTrigger = Spawn(class'GuideTrigger');
	guideTrigger.guideController = Spawn(class 'SneaktoSlimGuideController');
	guideTrigger.guideController.Pawn = self;
	self.Controller = guideTrigger.guideController;
	guideTrigger.Tag = self.Tag;

	/*lady = Spawn(class 'SneaktoSlimPawn_FatLady',,,self.Location + vect(50, 50, 0));
	lady.isGotTreasure = true;
	pc = Spawn(class 'SneaktoSlimPlayerController_FatLady');
	pc.Pawn = lady;
	lady.Controller = pc;
	pc.GotoState('HoldingTreasure');*/
}

function teleport()
{
	self.SetLocation(teleportLocation);
	self.SetRotation(teleportRotation);
	self.Controller.SetLocation(teleportLocation);
	self.Controller.SetRotation(teleportRotation);
}

function playPoofAnimation(vector newLocation, Rotator newRotation)
{
	//playerPlayOrStopCustomAnim('customVanish', 'Vanish', 1.f, true, 0.1f, 0.1f, false, true);
	local AnimNodePlayCustomAnim customNode;
	local float timeLeft;

	teleportLocation = newLocation;
	teleportRotation = newRotation;

	customNode = AnimNodePlayCustomAnim(self.Mesh.FindAnimNode('customVanish'));
	customNode.PlayCustomAnim('Vanish', 1, 0.1f, 0.1f, false, true);
	timeLeft = 1;
	SetTimer(timeLeft, false, 'teleport');
}

event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if(guideTrigger != NONE)
	{
		guideTrigger.SetLocation(self.Location);    //Keeps trigger attached to guide when it moves
	}
}

DefaultProperties
{
	//ControllerClass=class'SneaktoSlimGuideController'

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		bDynamic = TRUE
	End Object
	Components.Add(MyLightEnvironment)
	//LightEnvironment=MyLightEnvironment

	Begin Object Class=SkeletalMeshComponent Name=GuideSkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.Shorty.Shorty_skeletal'		
		AnimSets(0)=AnimSet'FLCharacter.Shorty.Shorty_Anims'
		AnimTreeTemplate = AnimTree'FLCharacter.Shorty.Shorty_AnimTree'	
		Translation=(Z=-48.0)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
	End Object

	Components.Add(GuideSkeletalMesh)
	Mesh = GuideSkeletalMesh

	Begin Object Class=CylinderComponent NAME=MyMesh
		CollisionRadius=15.000000
        CollisionHeight=44.000000 
	End Object

    //set collision component
    CollisionComponent=MyMesh
	Components.Add(MyMesh)

	bCollideActors=true
	bBlockActors=true
	bNoEncroachCheck = true 
}
