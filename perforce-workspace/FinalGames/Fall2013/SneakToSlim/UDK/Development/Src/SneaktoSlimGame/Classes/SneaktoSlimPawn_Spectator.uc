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

reliable client function changeAnimTree(SneaktoSlimPawn pawnToChangeAnimTree, AnimTree animTreeToChangeTo)
{
	local SneaktoSlimPawn pawnToChangeOn;

	ForEach WorldInfo.AllActors(class'SneaktoSlimPawn', pawnToChangeOn)
    {
		if(pawnToChangeOn == pawnToChangeAnimTree)
		{
			pawnToChangeOn.Mesh.SetAnimTreeTemplate(animTreeToChangeTo);
		}
	}
}

reliable client function clientMeshTranslation(bool downOrUp, int teamNum)
{
	local sneaktoslimpawn CurrentPawn;

	if(downOrUp)
	{
		ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
		{
			if(CurrentPawn.Class == class 'sneaktoslimpawn_ginsengbaby' && CurrentPawn.GetTeamNum() == teamNum)
			{
				CurrentPawn.meshTranslationOffset.Z = -90;
				sneaktoslimpawn_ginsengbaby(CurrentPawn).Mesh.SetTranslation(CurrentPawn.meshTranslationOffset);
			}
		}
	}
	else
	{
		ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
		{
			if(CurrentPawn.Class == class 'sneaktoslimpawn_ginsengbaby' && CurrentPawn.GetTeamNum() == teamNum)
			{
				CurrentPawn.meshTranslationOffset.Z = -48;
				sneaktoslimpawn_ginsengbaby(CurrentPawn).Mesh.SetTranslation(CurrentPawn.meshTranslationOffset);
			}
		}
	}
}

unreliable client function setDustParticle(bool flag, byte teamNum, float radius)
{
	local SneakToSlimPawn current;
	foreach worldinfo.allactors(class 'SneakToSlimPawn', current)
	{
		if (current.GetTeamNum() == teamNum)
		{
			SneakToSlimPawn_GinsengBaby(current).toggleDustParticle(flag, radius);
		}
	}
}

reliable client function bool getIsUsingXboxController()
{
	if(self.Controller != none)
		return SneaktoSlimPlayerController_Spectator(self.Controller).PlayerInput.bUsingGamepad;
	else
		return false;
}


unreliable client function updateTimeUI(int currentTime)
{
	local SneaktoSlimHUDGFX_Spectator myFlashHUD;

	if(self.Controller != none)
	{
		myFlashHUD = SneaktoSlimHUD_Spectator(SneaktoSlimPlayerController_Spectator(self.Controller).myHUD).FlashHUD;
		if(!myFlashHUD.TimerText.GetBool("isOn"))
			myFlashHUD.TimerText.SetBool("isOn", true);
		myFlashHUD.TimerText.SetInt("time", currentTime);
		if(currentTime == 0 && myFlashHUD.TimeUpText.GetInt("x") < myFlashHUD.screenSizeX/2)
			myFlashHUD.TimeUpText.SetInt("x", myFlashHUD.TimeUpText.GetInt("x") + int(myFlashHUD.screenSizeX/16));
		if(currentTime == 0 && myFlashHUD.TimeUpText.GetInt("x") > myFlashHUD.screenSizeX/2)
			myFlashHUD.TimeUpText.SetInt("x", int(myFlashHUD.screenSizeX/2));
		if(currentTime == 0)
		{
			PlayerController(self.Controller).IgnoreLookInput(true);
			PlayerController(self.Controller).IgnoreMoveInput(true);
		}
	}
}

reliable client function GoToResultsScreen()
{
	ConsoleCommand("disconnect");
	ConsoleCommand("open results?Character=Results");
}

reliable client function saveGameResults(int score1, string character1, optional int score2 = -1, optional string character2, optional int score3 = -1, optional string character3, optional int score4 = -1, optional string character4)
{
	local array<int> scores;
	local array<string> names;
	local SaveGameState sgs;
	local int count;

	sgs = new class 'SaveGameState';

	//Values are entered in reverse order since GameInfo loop reads AllPawns in reverse order of being created
	//So: Pawn 1 - FatLady          Pawn 1 - Shorty
	//    Pawn 2 - Rabbit       ->  Pawn 2 - Rabbit
	//    Pawn 3 - Shorty           Pawn 3 - FatLady
	if(score4 != -1)
	{
		scores.AddItem(score4);
		names.AddItem(character4);
	}

	if(score3 != -1)
	{
		scores.AddItem(score3);
		names.AddItem(character3);
	}

	if(score2 != -1)
	{
		scores.AddItem(score2);
		names.AddItem(character2);
	}

	scores.AddItem(score1);
	names.AddItem(character1);

	sgs.scoreBoard = scores;
	sgs.characterType = names;
	sgs.playerIndex = -1;

	class'Engine'.static.BasicSaveObject(sgs, "GameResults.bin", true, 1);
}

reliable client function disablePlayerMovement()
{	
	SneaktoslimPlayerController_Spectator(self.Controller).IgnoreMoveInput(TRUE);
}

reliable client function enablePlayerMovement()
{	
	SneaktoslimPlayerController_Spectator(self.Controller).IgnoreMoveInput(FALSE);
}

exec function QuitCurrentGame()
{
	ConsoleCommand("disconnect");
	ConsoleCommand("open sneaktoslimmenu_landingpage?Character=Menu");
}

DefaultProperties
{
	bJumpCapable = false
	bCollideWorld = false
	bCollideActors = false
	SpectatorWalkingSpeed=300.0
	MaxStepHeight = 25
	bForceFloorCheck = false
	WalkingPhysics=PHYS_Flying
	
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
