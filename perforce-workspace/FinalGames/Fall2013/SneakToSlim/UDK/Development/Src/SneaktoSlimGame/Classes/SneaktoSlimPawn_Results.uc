class SneaktoSlimPawn_Results extends GamePawn 
	DLLBind(DllTest);

var DynamicLightEnvironmentComponent LightEnvironment;
var bool disableControlsOnce;

dllimport final function killTheServer(out string s);

event PostBeginPlay()
{	
	local SaveGameState sgs;
	local int count;
	local PathNode node;
	local ResultsDummyPawn dummy;
	local int highestScore;

	super.PostBeginPlay();

	highestScore = 0;

	sgs = new class 'SaveGameState';

	class'Engine'.static.BasicLoadObject(sgs, "GameResults.bin", true, 1);

	//Gets highest score
	for(count = 0; count < sgs.scoreBoard.Length; count++)
	{
		if(sgs.scoreBoard[count] > highestScore)
		{
			highestScore = sgs.scoreBoard[count];
		}
	}

	//Makes it so its counts everyone as a since if tie is with score 0
	if(highestScore == 0)
		highestScore = 1;

	foreach WorldInfo.AllActors(class 'PathNode', node)
	{
		if(node.Tag == 'player1')
		{
			dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[0]),node.Location, node.Rotation,);
			if(sgs.scoreBoard[0] == highestScore)
				dummy.hasWon = true;
			else
				dummy.hasWon = false;
			dummy.characterType = sgs.characterType[0];
			dummy.score = sgs.scoreBoard[0];
			dummy.updateMesh(0);
		}
		if(node.Tag == 'player2' && sgs.scoreBoard.Length > 1)
		{
			dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[1]),node.Location, node.Rotation,);
			if(sgs.scoreBoard[1] == highestScore)
				dummy.hasWon = true;
			else
				dummy.hasWon = false;
			dummy.characterType = sgs.characterType[1];
			dummy.score = sgs.scoreBoard[1];
			dummy.updateMesh(1);
		}
		if(node.Tag == 'player3' && sgs.scoreBoard.Length > 2)
		{
			dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[2]),node.Location, node.Rotation,);
			if(sgs.scoreBoard[2] == highestScore)
				dummy.hasWon = true;
			else
				dummy.hasWon = false;
			dummy.characterType = sgs.characterType[2];
			dummy.score = sgs.scoreBoard[2];
			dummy.updateMesh(2);
		}
		if(node.Tag == 'player4' && sgs.scoreBoard.Length > 3)
		{
			dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[3]),node.Location, node.Rotation,);
			if(sgs.scoreBoard[3] == highestScore)
				dummy.hasWon = true;
			else
				dummy.hasWon = false;
			dummy.characterType = sgs.characterType[3];
			dummy.score = sgs.scoreBoard[3];
			dummy.updateMesh(3);
		}
	}

	for(count = 0; count < sgs.characterType.Length; count++)
	{
		`log("Results Screen: Player " $ (count + 1) $ " Type = " $ sgs.characterType[count] $ " Score = " $ sgs.scoreBoard[count]);
	}
	disableControlsOnce = true;

	SetTimer(3, false, 'updateAllAnimations');
}

function updateAllAnimations()
{
	local ResultsDummyPawn dummy;

	foreach WorldInfo.AllPawns(class 'ResultsDummyPawn', dummy)
	{
		dummy.playAnimation();
	}
}

event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if(self.Controller != NONE && disableControlsOnce)
	{
		PlayerController(self.Controller).IgnoreLookInput(true);
		PlayerController(self.Controller).IgnoreMoveInput(true);
		disableControlsOnce = false;
	}
}

exec function returnToMainMenu()
{
	ConsoleCommand("open sneaktoslimmenu_landingpage?Character=Menu");
}

DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		bDynamic = TRUE
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object Class=SkeletalMeshComponent Name=InitialSkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.lady.new_lady_skeletalmesh'		
		AnimSets(0)=AnimSet'FLCharacter.lady.new_lady_Anims'		
		AnimTreeTemplate = AnimTree'FLCharacter.lady.lady_AnimTree_copy'		
		Translation=(Z=-48.0)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false		
	End Object

    Components.Add(InitialSkeletalMesh)	
	Mesh = InitialSkeletalMesh	

	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+0044.000000
	End Object
	CylinderComponent=CollisionCylinder
}
