class SneaktoSlimPawn_Spectator extends Pawn;
var Vector spawnLocation;
var float SpectatorWalkingSpeed;

event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);	
}

simulated event PostBeginPlay()
{   
	spawnLocation = self.Location;
	GroundSpeed=SpectatorWalkingSpeed;
	//`log("=============================================================================", true, 'Ravi');
	Super.PostBeginPlay();
}

DefaultProperties
{
	//ControllerClass=class'SneaktoSlimPlayerController_Spectator'
	bCollideWorld = false
	bCollideActors = false
	SpectatorWalkingSpeed=550.0

	Begin Object Class=SkeletalMeshComponent Name=SpectatorSkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.lady.new_lady_skeletalmesh'		
		AnimSets(0)=AnimSet'FLCharacter.lady.new_lady_Anims'		
		AnimTreeTemplate = AnimTree'FLCharacter.lady.lady_AnimTree'		
		Translation=(Z=-48.0)
		bOwnerNoSee=false		
		CastShadow=false
		Scale=0
	End Object

	Components.Add(SpectatorSkeletalMesh)	
	Mesh = SpectatorSkeletalMesh
}
