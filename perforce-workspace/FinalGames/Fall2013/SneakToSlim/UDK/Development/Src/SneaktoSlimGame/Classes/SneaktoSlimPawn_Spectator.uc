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
	Super.PostBeginPlay();
}

reliable client function clientPlayerPlayCustomAnim
(
	SneaktoSlimPawn whoPlayAnim,
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

	ForEach WorldInfo.AllActors(class'SneaktoSlimPawn', onePawn)
    {
		if(onePawn == whoPlayAnim)
		{
			customNode = AnimNodePlayCustomAnim(onePawn.Mesh.FindAnimNode(nodeName));
			if(customNode == None)
			{
				`log("Invalid custom node name",false,'Lu');
				return;
			}
			
			if(playOrStop == true)
				customNode.PlayCustomAnim(AnimName, Rate, BlendInTime, BlendOutTime, bLooping, bOverride);
			else
				customNode.StopCustomAnim(BlendOutTime);
		}
    }
}

//simulated function name GetDefaultCameraMode( PlayerController RequestedBy )
//{
//	return 'ThirdPerson';
//}

DefaultProperties
{
	//ControllerClass=class'SneaktoSlimPlayerController_Spectator'
	bJumpCapable = false
	bCollideWorld = true
	bCollideActors = false
	SpectatorWalkingSpeed=400.0
	MaxStepHeight = 25
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=10.000000
        CollisionHeight=10.000000
    End Object
	CylinderComponent=CollisionCylinder

	Begin Object Class=SkeletalMeshComponent Name=SpectatorSkeletalMesh	

		SkeletalMesh = SkeletalMesh'FLCharacter.lady.new_lady_skeletalmesh'		
		AnimSets(0)=AnimSet'FLCharacter.lady.new_lady_Anims'		
		AnimTreeTemplate = AnimTree'FLCharacter.lady.lady_AnimTree'		
		Translation=(Z=-48.0)			
		CastShadow=false
		Scale=0
	End Object

	Components.Add(SpectatorSkeletalMesh)	
	Mesh = SpectatorSkeletalMesh
}
