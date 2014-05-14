class SneaktoSlimPawn_Results extends GamePawn; 
	//DLLBind(DllTest);

var DynamicLightEnvironmentComponent LightEnvironment;
var bool disableControlsOnce;
var int playerIndex;

//dllimport final function killTheServer(out string s);

event PostBeginPlay()
{	
	local SaveGameState sgs;
	local int count;
	local PathNode node;
	local ResultsDummyPawn dummy;
	local int highestScore;
	local vector spawnOffset, dir;
	local float rotationOffset;
	local Rotator tempRotator;
	local array<int> ranks;

	super.PostBeginPlay();

	highestScore = 0;

	sgs = new class 'SaveGameState';

	class'Engine'.static.BasicLoadObject(sgs, "GameResults.bin", true, 1);

	playerIndex = sgs.playerIndex;

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

	ranks = determineRanks(sgs.scoreBoard);
	switch(sgs.scoreBoard.Length)
	{
		case 2: spawnOffset = vect(0,100,0);
				break;
		case 3: spawnOffset = vect(0,50,0);				
				break;
		default: spawnOffset = vect(0,0,0);
				 break;
	}

	foreach WorldInfo.AllActors(class 'PathNode', node)
	{
		if(node.Tag == 'player1')
		{
			if(sgs.characterType[0] == "GinsengBaby")
				dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[0]),(node.Location + vect(0,-3,0) + spawnOffset), node.Rotation,);
			else
				dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[0]),(node.Location + spawnOffset), node.Rotation,);

			tempRotator = dummy.Rotation;
			rotationOffset = ATan((self.Location.Y - dummy.Location.Y)/(dummy.Location.X - self.Location.X));
			tempRotator.Yaw = dummy.Rotation.Yaw - int(rotationOffset*RadToUnrRot);
			dummy.SetRotation(tempRotator);

			dir = dummy.Location - self.Location;
			dir.Z = 0;
			dir = Normal(dir);
			dir = dir * -1;
			dummy.SetLocation(dummy.Location + (dir * (4 - ranks[0]) * (200/Cos(rotationOffset)) / 3));

			`log("Player " $ (playerIndex+1) $ " has score " $ sgs.scoreBoard[0] $ "/" $ highestScore);
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
			node.SetLocation(node.Location + spawnOffset);
			dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[1]),(node.Location + spawnOffset), node.Rotation,);

			tempRotator = dummy.Rotation;
			rotationOffset = ATan((self.Location.Y - dummy.Location.Y)/(dummy.Location.X - self.Location.X));
			tempRotator.Yaw = dummy.Rotation.Yaw - int(rotationOffset*RadToUnrRot);
			dummy.SetRotation(tempRotator);

			dir = dummy.Location - self.Location;
			dir.Z = 0;
			dir = Normal(dir);
			dir = dir * -1;
			dummy.SetLocation(dummy.Location + (dir * (4 - ranks[1]) * (200/Cos(rotationOffset)) / 3));

			`log("Player " $ (playerIndex+1) $ " has score " $ sgs.scoreBoard[0] $ "/" $ highestScore);
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
			node.SetLocation(node.Location + spawnOffset);
			dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[2]),(node.Location + spawnOffset), node.Rotation,);

			tempRotator = dummy.Rotation;
			rotationOffset = ATan((self.Location.Y - dummy.Location.Y)/(dummy.Location.X - self.Location.X));
			tempRotator.Yaw = dummy.Rotation.Yaw - int(rotationOffset*RadToUnrRot);
			dummy.SetRotation(tempRotator);

			dir = dummy.Location - self.Location;
			dir.Z = 0;
			dir = Normal(dir);
			dir = dir * -1;
			dummy.SetLocation(dummy.Location + (dir * (4 - ranks[2]) * (200/Cos(rotationOffset)) / 3));

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
			if(sgs.characterType[3] == "GinsengBaby")
				dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[3]),(node.Location + vect(0,3,0)), node.Rotation,);
			else
				dummy = Spawn(class 'SneaktoSlimGame.ResultsDummyPawn',,name(sgs.characterType[3]),node.Location, node.Rotation,);

			tempRotator = dummy.Rotation;
			rotationOffset = ATan((self.Location.Y - node.Location.Y)/(node.Location.X - self.Location.X));
			tempRotator.Yaw = dummy.Rotation.Yaw - int(rotationOffset*RadToUnrRot);
			dummy.SetRotation(tempRotator);

			dir = node.Location - self.Location;
			dir.Z = 0;
			dir = Normal(dir);
			dir = dir * -1;
			dummy.SetLocation(dummy.Location + (dir * (4 - ranks[3]) * (200/Cos(rotationOffset)) / 3));

			if(sgs.scoreBoard[3] == highestScore)
				dummy.hasWon = true;
			else
				dummy.hasWon = false;
			dummy.characterType = sgs.characterType[3];
			dummy.score = sgs.scoreBoard[3];
			dummy.updateMesh(3);
		}
	}

	/*for(count = 0; count < sgs.characterType.Length; count++)
	{
		`log("Results Screen: Player " $ (count + 1) $ " Type = " $ sgs.characterType[count] $ " Score = " $ sgs.scoreBoard[count]);
	}*/
	disableControlsOnce = true;

	SetTimer(1, false, 'showAllScores');
	SetTimer(1, false, 'updateAllAnimations');
	SetTimer(2, false, 'showContinueText');
}

function array<int> determineRanks(array<int> scoreBoard)
{
	local int ranks[4];
	local array<int> result;
	local int highestScore, count, count2, rankValue;

	highestScore = -1;
	//Gets highest score
	for(count = 0; count < scoreBoard.Length; count++)
	{
		if(scoreBoard[count] > highestScore)
		{
			highestScore = scoreBoard[count];
		}
	}

	if(highestScore == 0)
	{
		ranks[0] = 2;
		ranks[1] = 2;
		ranks[2] = 2;
		ranks[3] = 2;
	}
	else
	{
		rankValue = 1;
		for(count2 = highestScore; count2 >= 0; count2--)
		{
			for(count = 0; count < scoreBoard.Length; count++)
			{
				if(scoreBoard[count] == count2)
				{
					ranks[count] = rankValue;
				}
			}
			rankValue++;
		}
	}
	result.AddItem(ranks[0]);
	result.AddItem(ranks[1]);
	result.AddItem(ranks[2]);
	result.AddItem(ranks[3]);
	return result;
}

function showContinueText()
{
	SneaktoSlimHUD_ResultsScreen(SneaktoSlimPlayerController_Results(self.Controller).myHUD).FlashResults.continueText.SetBool("visible", true);
}

function showAllScores()
{
	local ResultsDummyPawn dummyPawn;
	SneaktoSlimHUD_ResultsScreen(SneaktoSlimPlayerController_Results(self.Controller).myHUD).showAllScores();

	foreach WorldInfo.AllPawns(class 'ResultsDummyPawn', dummyPawn)
	{
		if(dummyPawn.playerColorIndex == playerIndex)
		{
			if(dummyPawn.hasWon)
			{
				`log("Player " $ (playerIndex+1) $ " was WON");
				PlaySound(SoundCue'flsfx.globalAnnouncement.winning');
			}
			else
			{
				`log("Player " $ (playerIndex+1) $ " was LOST");
				//clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Losing');
				PlaySound(SoundCue'flsfx.globalAnnouncement.Losing');
			}
		}
	}
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
		SneaktoSlimPlayerController_Results(self.Controller).PlayerCamera.SetFOV(SneaktoSlimPlayerController_Results(self.Controller).PlayerCamera.GetFOVAngle() - 20);
		PlayerController(self.Controller).IgnoreLookInput(true);
		PlayerController(self.Controller).IgnoreMoveInput(true);
		disableControlsOnce = false;
	}
}

exec function returnToMainMenu()
{
	if(SneaktoSlimHUD_ResultsScreen(SneaktoSlimPlayerController_Results(self.Controller).myHUD).FlashResults.continueText.GetBool("visible"))
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
