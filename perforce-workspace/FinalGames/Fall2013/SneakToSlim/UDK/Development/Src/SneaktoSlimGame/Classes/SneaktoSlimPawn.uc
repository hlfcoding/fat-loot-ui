/**
 * Copyright 1998-2013 Epic Games, Inc. All Rights Reserved.
 */
class SneaktoSlimPawn extends GamePawn
	config(Game) placeable;

var DynamicLightEnvironmentComponent LightEnvironment;
var MaterialInstanceConstant Mat;   //-----------------------------------------------------------------//
var bool bInvulnerable;
var float InvulnerableTimer;
var bool playerHasFan;
var SneakToSlimMovingTreasure SpawnedProjectile;
//var SkeletalMeshComponent Mesh;
var vector meshTranslationOffset;


var AnimNodePlayCustomAnim sprintNode;
var AnimNodePlayCustomAnim bellyBumpNode;
var AnimNodePlayCustomAnim bumpingNode;
var AnimNodePlayCustomAnim bumpReadyNode;
var AnimNodePlayCustomAnim bumpLandNode;
var AnimNodePlayCustomAnim vanishNode;
var AnimNodePlayCustomAnim tiredNode;
var AnimNodePlayCustomAnim stunNode;
var AnimNodePlayCustomAnim hitNode;
var AnimNodePlayCustomAnim treasureWalkNode;
var AnimNodePlayCustomAnim searchNode;
var SkeletalMeshComponent mySkelComp;
var SkeletalMeshComponent AISkelComp;
var Array<Vector> TreasureSpawnPointLocations;
var Array<MaterialInstanceConstant> teamMaterial;
var Array<MaterialInstanceConstant> teamMaterialGB;
var string characterName;
var bool isHost;

//Player metrics
var int totalTimesCaught;
var int totalTimesVasesUsed;
var int totalTimesBellyBumpUsed;
var int totalTimesSprintActivate;
var int totalTimesPowerupsUsed;
var int totalTimesTreasureGot;
var int bellyBumpMisses;
var int bellyBumpHits;

struct HUDMessage
{
	var string sMeg;
	var float MsgTimer;
};

var array<HUDMessage>  arrMsg;
struct HUDStaticMessage
{
	var string triggerPromtText;
	var string eqGotten;
	var string stringCountDown;
};

var HUDStaticMessage staticHUDmsg;

enum enumBuff {
  bBuffed,
  bUsingBuffed
};

var bool bInvisibletoAI; //if true, AIPawn cannot detect this pawn. used in SneakToSlim.setVisibleSneaktoSlimPawns

var int bBuffed;
var byte bUsingBuffed[3];//should not be used anymore
var float BuffedTimer;
var float BuffedTimerDefault[3];// record the countdonw of buffs

var() float v_energy;         // ANDY: naming v_xyz for variables (health, energy, speed, etc), and s_xyz for states (weak, high, drunk, etc)
var int s_energized;
var repnotify bool isGotTreasure;
//var float CamOffsetDistance; //distance to offset the camera from the player in unreal units
//var float CamMinDistance, CamMaxDistance;
//var float CamZoomTick; //how far to zoom in/out per command
//var float CamHeight; //how high cam is relative to pawn
//var float CamZoomHeightTick; //just another variable i need for new zooming mechanic
var int playerScore;

var() float FLWalkingSpeed;
var() float FLSprintingSpeed;
var() float FLExhaustedSpeed;

//var bool bIsDashing;        //Xu: Whether the pawn is currently dashing
var float DashDuration;     //Xu: How long the pawn will dash for
var bool bIsHitWall;
var float HitWallDuration;
var float PerDashEnergy;
var float PerSpeedEnergy;
var float FanRange;
var float FanAngle;
var bool CheatingMode;
var RepNotify float CSpeed;
var bool bOOM; //ANDY: bObjectOfMomentum, aka BOOM! to check if the pawn is under impact momentum from belly-bump.
var vector knockBackVector; //Xu: used in BeingBellyBumped

var SneakToSlimTreasureParticle treasureEffect;
var ParticleSystemComponent treasureMovingEffectComp;
var vector treasureLocation;
var SneaktoSlimTreasure myTreasure;
var SneaktoSlimCloth myCloth;

var  RepNotify int colorIndex;

var bool hiddenInVase;  //Nick: player is in a vase? set true when player activates vase
var vaseTrigger vaseIMayBeUsing;
var float stunTime;     //Nick: set when a player is stun (eg. 2 secs if caught in broken vase)
var repnotify bool invincible;                      //Can be set to make player immune to guards
var float invincibleTime;                           //After player moves when sent to spawn point, they'll still be invincible for this long
var bool canMoveAfterBeingReturnedToSpawnPoint;     //Makes sure "resume play/movement" is only called after being sent to spawn point

var repnotify Name replicateAnimName;

/////////////
var repnotify bool isChangeMesh ;
var repnotify bool isSetSPcolor;
var repnotify int transparentNum;
var repnotify int disguiseNum;
var repnotify int endDisguiseNum;
var () float PreBumpDelay;
var repnotify int invisibleNum;
var repnotify int endinvisibleNum;
var repnotify int mistNum;

var bool bPreDash;
var() float energyRegenerateRate;
var() int PlayerBaseRadius;
var () bool underLight;
var int playerCount;

var StaticMeshComponent treasureComponent;
var PointLightComponent treasureLightComponent;


replication {   //ARRANGE THESE ALPHABETICALLY
	if (bNetDirty || bNetOwner)
		bBuffed, // only keep copy in server
		//bIsDashing, //shoule not use this anymore when using states
		bOOM,
		bUsingBuffed, // only keep copy in server //shoule not use this anymore when using states
		//myTreasure,
		colorIndex,       //Updates energy reading for each pawn's own respective value
		CSpeed,
		invincible,         //Makes player invincible for short time after being caught by guard
		isChangeMesh,
		isGotTreasure, //shoule not use this anymore when using states
        isSetSPcolor,
		//isStunned,    //shoule not use this anymore when using states
		playerScore,    //Enable scores to update change on each client's screen
		replicateAnimName,
		s_energized,
		stunTime,
		//v_energy,
		transparentNum,
		disguiseNum,
		endDisguiseNum,
		invisibleNum,
		endinvisibleNum,
		mistNum;
}

simulated event PostBeginPlay()
{
	`log("PostBeginPlay====================");
	if(Role == ROLE_Authority)
		`log("I am running on the server!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	else
		`log("I am running on the client!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	
    SetSpawnPointColor();
	setTimer(0.3,false,'ServerRemindTreasureLocation');
	setTimer(0.3,false,'ServerInitLight');
}

simulated exec function EnterMist(){
	`log("Enter Mist!!!!!!!!!!!!!!");
	removePowerUp();
	//self.bInvisibletoAI = true;
	self.mistNum = 1;//need to be set to mistTrigger num
}

simulated exec function ExitMist(){
	`log("Exit Mist!!!!!!!!!!!!!!");
	//self.endinvisibleNum = self.GetTeamNum();
	//self.bInvisibletoAI = false;
	self.mistNum = 0;
}

reliable client function removePowerUp()
{
	self.hideCountdownTimer();
	BuffedTimer = 0;
	inputStringToCenterHUD(0);
	`log("buff end "); 
	`log(bUsingBuffed[0]);
	if(bUsingBuffed[0] == 1)
	{
		`log('remove power-ups');
		SneaktoSlimPlayerController(self.Controller).attemptToChangeState('EndInvisible');
		SneaktoSlimPlayerController(self.Controller).GoToState('EndInvisible');
	}
	if(bUsingBuffed[1] == 1)
	{
		`log('remove power-ups');
		SneaktoSlimPlayerController(self.Controller).attemptToChangeState('EndDisguised');
		SneaktoSlimPlayerController(self.Controller).GoToState('EndDisguised');
	}
}

unreliable server function incrementBumpCount()
{
	 totalTimesBellyBumpUsed++;
}

unreliable server function incrementBellyBumpHits()
{
	 self.bellyBumpHits++;
}

unreliable server function incrementBellyBumpMisses()
{
	 self.bellyBumpMisses++;
}

unreliable server function incrementPowerupCount()
{
	 self.totalTimesPowerupsUsed++;
}

unreliable server function int getBBHitCount()
{
	//`log("Client Hit count: " $ bellyBumpHits);
	return self.bellyBumpHits;
}

unreliable server function int getBBMissCount()
{
	//`log("Client miss count: " $ bellyBumpMisses);
	return self.bellyBumpMisses;
}

unreliable server function recordCatchStats()
{
	SneaktoSlimPlayerController(self.Controller).recordCatchStats();
}

unreliable server function incrementSprintCount()
{
	 totalTimesSprintActivate++;
}

reliable Server function ServerInitLight()
{
	local SneaktoSlimLightContainer Container;
	foreach DynamicActors(class'SneaktoSlimLightContainer',Container)
	{
		if(Container!=none)
		{
			if(!Container.IsOn)
			{
				ClientInitLightOff(Container);
			}
		}
	}
}

reliable Client function ClientInitLightOff(SneaktoSlimLightContainer Container)
{
	Container.LightMesh.StaticMeshComponent.SetMaterial(0,Container.TurnOffTexture);
}

//Can be set by playercontroller but is currently not used
unreliable client function setPlayerCount(int num)
{
	playerCount = num;
}

exec function skipLine()
{
	local SneaktoSlimGuideController guide;

	foreach WorldInfo.AllControllers(class'SneaktoSlimGuideController', guide)
	{
		guide.skipLine();
	}
}

reliable client function hideTutorialTextObject()
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		myFlashHUD.TutorialText.GetObject("TutorialText").SetText("");
		myFlashHUD.TutorialText.SetBool("visible", false);
	}

}

reliable client function displayTutorialText(String text)
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		myFlashHUD.TutorialText.GetObject("TutorialText").SetText(text);
		myFlashHUD.TutorialText.SetBool("visible", true);
	}
}

reliable client function showDemoTime(String text)
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		text = "Time - " $ text;
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		myFlashHUD.TimerText.SetBool("isOn", true);
		myFlashHUD.TimerText.GetObject("time_text").SetText(text);
	}
}

reliable client function showWinnerText()
{
	local SneaktoSlimGFxMap myFlashMap;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashMap = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashMap;
		myFlashMap.winnerDisplayText.SetBool("isOn", true);
		myFlashMap.demoTime.SetBool("isOn", false);
	}
}

//Shows powerup icon when nearbyTrigger calls this
unreliable client function showPromptUI(String text)
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		myFlashHUD.PromptText.SetBool("isOn", true);
		myFlashHUD.PromptText.GetObject("PromptText").SetText(text);
	}
}

//Hides powerup icon when nearbyTrigger calls this
unreliable client function hidePromptUI()
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		myFlashHUD.PromptText.GetObject("PromptText").SetText("");
		myFlashHUD.PromptText.SetBool("isOn", false);
	}
}

//Tells flash hud to turn on coin symbol on player's scoreboard
reliable client function showCharacterHasTreasure(int playerIndex)
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		switch (playerIndex)
		{
			case 0: myFlashHUD.player1Score.GetObject("Coin").SetBool("visible", true);
					break;
			case 1: myFlashHUD.player2Score.GetObject("Coin").SetBool("visible", true);
					break;
			case 2: myFlashHUD.player3Score.GetObject("Coin").SetBool("visible", true);
					break;
			case 3: myFlashHUD.player4Score.GetObject("Coin").SetBool("visible", true);
					break;
		}
	}
}

//Tells flash hud to turn off coin symbol on player's scoreboard
reliable client function showCharacterLostTreasure(int playerIndex)
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		switch (playerIndex)
		{
			case 0: myFlashHUD.player1Score.GetObject("Coin").SetBool("visible", false);
					break;
			case 1: myFlashHUD.player2Score.GetObject("Coin").SetBool("visible", false);
					break;
			case 2: myFlashHUD.player3Score.GetObject("Coin").SetBool("visible", false);
					break;
			case 3: myFlashHUD.player4Score.GetObject("Coin").SetBool("visible", false);
					break;
		}
	}
}

exec function stopAllTheLoopAnimation()
{
	playerPlayOrStopCustomAnim('customStun','stun',1.f,false);
	playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false);
	playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',1.f,false);
	playerPlayOrStopCustomAnim('customTreasureIdle','Treasure_Idle',1.f,false);
}

//Shows powerup icon when nearbyTrigger calls this
reliable client function showPowerupUI(int num)
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		if(num == 1)
		{
			myFlashHUD.InvisibilityIcon.SetBool("isOn", true);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", true);
			myFlashHUD.InstructionText.SetBool("isOn", true);
			myFlashHUD.CountdownText.SetBool("isOn", true);
		}
		if(num == 2)
		{
			myFlashHUD.ClothIcon.SetBool("isOn", true);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", true);
			myFlashHUD.InstructionText.SetBool("isOn", true);
			myFlashHUD.CountdownText.SetBool("isOn", true);
		}
		if(num == 3)
		{
			myFlashHUD.ThunderIcon.SetBool("isOn", true);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", true);
			myFlashHUD.InstructionText.SetBool("isOn", true);
			myFlashHUD.CountdownText.SetBool("isOn", true);
		}
		if(num == 4)
		{
			myFlashHUD.TeaIcon.SetBool("isOn", true);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", true);
			myFlashHUD.InstructionText.SetBool("isOn", true);
			myFlashHUD.CountdownText.SetBool("isOn", true);
		}
		if(num == 5)
		{
			myFlashHUD.SuperSprintIcon.SetBool("isOn", true);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", true);
			myFlashHUD.InstructionText.SetBool("isOn", true);
			myFlashHUD.CountdownText.SetBool("isOn", true);
		}
	}
}

//Hidess powerup icon when nearbyTrigger calls this
reliable client function hidePowerupUI(int num)
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		if(num == 1)
		{
			myFlashHUD.InvisibilityIcon.SetBool("isOn", false);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", false);
			myFlashHUD.InstructionText.SetBool("isOn", false);
			//setTimer(1,false,'SyncTreasure');
		}
		if(num == 2)
		{
			myFlashHUD.ClothIcon.SetBool("isOn", false);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", false);
			myFlashHUD.InstructionText.SetBool("isOn", false);
			//setTimer(1,false,'SyncTreasure');
		}
		if(num == 3)
		{
			myFlashHUD.ThunderIcon.SetBool("isOn", false);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", false);
			myFlashHUD.InstructionText.SetBool("isOn", false);
			//setTimer(1,false,'SyncTreasure');
		}
		if(num == 4)
		{
			myFlashHUD.TeaIcon.SetBool("isOn", false);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", false);
			myFlashHUD.InstructionText.SetBool("isOn", false);
		}
		if(num == 5)
		{
			myFlashHUD.SuperSprintIcon.SetBool("isOn", false);
			myFlashHUD.PowerupBackdrop.SetBool("isOn", false);
			myFlashHUD.InstructionText.SetBool("isOn", false);
		}
	}
}

exec simulated function SyncTreasure(){
    ServerSyncTreasure();
}

server reliable function ServerSyncTreasure(){
	local SneaktoSlimPawn TempPawn;
	local SneaktoSlimTreasureSpawnPoint TempBox;
	local SneaktoSlimTreasure TempTreasure;
	foreach AllActors(class'SneaktoSlimTreasure',TempTreasure)
    {
        `log("Treasure_____________________________________"@TempTreasure.CurrentSpawnPointIndex);
    }
	foreach AllActors(class'SneaktoSlimTreasureSpawnPoint',TempBox)
	{
		`log("Box_____________________________________"@TempBox.BoxIndex);
	}
    foreach AllActors(class'SneaktoSlimPawn',TempPawn)
	{
		TempPawn.ClientSyncTreasure();  
	}
}

client reliable function ClientSyncTreasure()
{
	local SneaktoSlimTreasure TempTreasure;
	local SneaktoSlimTreasureSpawnPoint TempBox;
	local int BoxIndex;
    foreach AllActors(class'SneaktoSlimTreasure',TempTreasure)
    {
        
    	BoxIndex = TempTreasure.CurrentSpawnPointIndex;
        `log("Treasure_____________________________________"@BoxIndex);
    }
	foreach AllActors(class'SneaktoSlimTreasureSpawnPoint',TempBox){
		`log("Box_____________________________________"@TempBox.BoxIndex);
		if(BoxIndex == TempBox.BoxIndex){
			TempBox.SetParticalEffectActive(true);
		}
	}

}

server reliable function ServerRemindTreasureLocation()
{
	local SneaktoSlimTreasure Tre;
	foreach AllActors(class'SneaktoSlimTreasure',Tre)
	{
		if(Tre!=none)
		{
			//self.ClientTurnBackTreasure(Tre,Tre.Location);
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////START MAP/TEAM-COLOUR CODE

//Called by AIPawn when player is caught and free vase without destroying it
function freeVaseFromPawn()
{
	if(vaseIMayBeUsing != none)
		vaseIMayBeUsing.setFree();
}

exec function SetSpawnPointColor()
{
	Local SneaktoSlimSpawnPoint Current; 
	//`log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",true,'David');
    
	if (Role < ROLE_Authority)
	{	
		serverSetColor();
	}
	else if (Role == ROLE_Authority)
	{	
		isSetSPcolor = true;

		ForEach class'WorldInfo'.static.GetWorldInfo().AllActors(class 'SneaktoSlimSpawnPoint', Current)
		{
			`log("Server:crruent"@current.Name,true,'David');
    		Current.SetColor();
		}
	}
}

reliable server function ServerSetColor()
{
	isSetSPcolor = true;
}

exec function changePlayerColorIndex(int newColorIndex)
{
	serverSetColorIndex(newColorIndex);
}

reliable server function serverSetColorIndex(int newColorIndex)
{
	colorIndex = newColorIndex;
}

exec function showTeam()
{
	`log("my Team is:"@self.GetTeamNum(),true,'Lu');
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////END MAP/TEAM-COLOUR CODE

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////START ANIMATION/GRAPHIC CODE

// TODO: Should ues a AnimTree
function customPlayAnim(Name animName)
{
	replicateAnimName = animName;

	Mesh.PlayAnim(animName,,true,false);

	if (Role < ROLE_Authority)
	{
		ServerPlayAnim(animName);
	}
}

function ChangeMesh(bool _isChangeMesh)
{
	isChangeMesh = _isChangeMesh;
}

reliable client function ClientPlayAnim(Name animName)
{
	Mesh.PlayAnim(animName,,true,false);
}

reliable server function ServerPlayAnim(Name animName)
{
	customPlayAnim(animName);
}

simulated event Destroyed()
{
  Super.Destroyed();

  sprintNode = None;
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	//ready to retire theses line
	sprintNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customSprint'));
	bellyBumpNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customBumping'));
	bumpingNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customBumping'));
	bumpReadyNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customBumpReady'));
	bumpLandNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customLand'));
	vanishNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customVanish'));
	tiredNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customTired'));
	stunNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customStun'));
	hitNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customHit'));
	treasureWalkNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customTreasureWalk'));
	searchNode = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('customSearch'));
	//	
}

exec function letshidden()
{
	self.SetHidden(true);
}

simulated function toggleTiredAnimation(bool animMustPlay)
{
	if (tiredNode == None)
	{
		return;
	}

	if (animMustPlay == true)
	{
		if (!tiredNode.bIsPlayingCustomAnim)
		{
  			tiredNode.PlayCustomAnim('Tired', 1.f, 0.1f, 0.1f, true, true);
		}
	}
	else
	{
		if (tiredNode.bIsPlayingCustomAnim)
		{
				tiredNode.StopCustomAnim(0.1f);
		}
	}
}

//Player will now move but still be invincible until time out
exec function makePlayerMoveAfterClickingKey()
{
	//Ensures key is only used when spawned at base
	if(canMoveAfterBeingReturnedToSpawnPoint)
	{
		self.canMoveAfterBeingReturnedToSpawnPoint = false;
		SetTimer(invincibleTime, false, 'serverRemoveInvinciblity');
		enablePlayerMovement();
	}
}

//Server will set this pawn to be not invincible 
reliable server function serverRemoveInvinciblity()
{
	local SneaktoSlimPawn getpawn;
	
	foreach WorldInfo.AllPawns(class'SneaktoSlimPawn', getpawn)
	{
		if(getPawn == self)
		{
			getpawn.invincible = false;
		}
	}
}

event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime)
{
	super.OnAnimEnd(SeqNode, PlayedTime, ExcessTime);	
}

simulated event ReplicatedEvent(name VarName)
{
	Local SneaktoSlimSpawnPoint Current;
	Local SneaktoSlimpawn CurrentPawn;

	`log("enter replicated event" $ self.GetTeamNum());
	if ( VarName == 'replicateAnimName')
	{
		ClientPlayAnim(replicateAnimName);
	}

	if(VarName == 'invincible')
	{
		if(invincible == true)
		{
			disablePlayerMovement();
			self.canMoveAfterBeingReturnedToSpawnPoint = true;
			`log("press 'i' to resume play");
		}
	}

	
	if( VarName == 'isSetSPcolor')	
	{
        ForEach class'WorldInfo'.static.GetWorldInfo().AllActors(class 'SneaktoSlimSpawnPoint', Current)
        {
            `log("client:function current"@current.Name,true,'David');
    	    Current.SetColor();
        }
	}
	if(VarName == 'colorIndex')
	{
		self.changeCharacterMaterial(self,self.colorIndex,"Character");
	}
	if(VarName == 'transparentNum')
	{
		if(transparentNum >= 0)
		{
			transparentNum = -1;

			foreach AllActors(class 'sneaktoslimpawn', CurrentPawn)
			{
				if(CurrentPawn.GetTeamNum() == transparentNum)
				{
					//transparent
				}
			}
		}
	}
	if(VarName == 'disguiseNum')
	{
		if(disguiseNum >= 0 && self.mistNum == 0)
		{	
			ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
			{
				if(CurrentPawn.GetTeamNum() == disguiseNum)
				{
					CurrentPawn.DetachComponent(CurrentPawn.Mesh);
					CurrentPawn.ReattachComponent(CurrentPawn.AISkelComp);
				}
			}
			serverResetDisguiseNum();
		}
	}
	if(VarName == 'endDisguiseNum')
	{
		`log("endDisguiselog");
		if(endDisguiseNum >= 0)
		{	
			ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
			{
				if(CurrentPawn.GetTeamNum() == endDisguiseNum)
				{
					CurrentPawn.DetachComponent(CurrentPawn.AISkelComp);
					CurrentPawn.ReattachComponent(CurrentPawn.Mesh);					
				}
			}
			serverResetEndDisguiseNum();
		}
	}
	if(VarName == 'invisibleNum')
	{
		if(invisibleNum >= 0 && self.mistNum == 0)
		{	
			ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
			{
				if(CurrentPawn.GetTeamNum() == invisibleNum)
				{
					if(CurrentPawn.Role == ROLE_AutonomousProxy)
					{
						CurrentPawn.changeCharacterMaterial(currentPawn,currentPawn.GetTeamNum(),"Invisible");
						//CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.Character.invisibleMaterial');
						//CurrentPawn.Mesh.SetMaterial(1, Material'FLCharacter.Character.invisibleMaterial');
					}
					else if (CurrentPawn.Role == ROLE_SimulatedProxy)
					{
						//CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.Character.invisibleMaterial');
						//CurrentPawn.Mesh.SetMaterial(1, Material'FLCharacter.Character.invisibleMaterial');
						//CurrentPawn.changeCharacterMaterial(currentPawn,currentPawn.GetTeamNum(),"Invisible");
						CurrentPawn.SetHidden(true);
						//CurrentPawn.Mesh.SetOnlyOwnerSee(true);
					}
				}
			}
			
		}
		serverResetInvisibleNum();
	}
	if(VarName == 'endinvisibleNum')
	{
		//`log("fuck you all");
		if(endinvisibleNum >= 0)
		{	
			ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
			{
				if(CurrentPawn.GetTeamNum() == endinvisibleNum)
				{
					if(CurrentPawn.Role == ROLE_AutonomousProxy)
					{
						
						 //MaterialInstanceConstant(DynamicLoadObject("FLCharacter.lady.lady_material_" $ currentPawn.GetTeamNum(), class'MaterialInstanceConstant'));
						//CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
						//CurrentPawn.Mesh.SetMaterial(1,  MaterialInstanceConstant(DynamicLoadObject("FLCharacter.lady.lady_material_" $ currentPawn.GetTeamNum(), class'MaterialInstanceConstant')));
						//CurrentPawn.Mesh.SetMaterial(1,teamMaterial[currentPawn.GetTeamNum()]);

						CurrentPawn.changeCharacterMaterial(currentPawn,currentPawn.GetTeamNum(),"Character");
						//CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
						//CurrentPawn.Mesh.SetMaterial(1,teamMaterial[currentPawn.GetTeamNum()]);


					}
					else if (CurrentPawn.Role == ROLE_SimulatedProxy)
					{
						CurrentPawn.SetHidden(false);
					}
				}
			}
			
		}
		
		if (self.mistNum != 0)
			self.changeCharacterMaterial(self,self.GetTeamNum(),"Invisible");

		serverResetEndInvisibleNum();
	}

	if(VarName == 'mistNum')
	{
		//enter mist
		if(self.mistNum != 0)
		{
			if (SneaktoSlimPlayerController(Self.Controller).IsInState('InvisibleExhausted') || SneaktoSlimPlayerController(Self.Controller).IsInState('InvisibleWalking'))
			{
				SneaktoSlimPlayerController(Self.Controller).attemptToChangeState('EndInvisible');
				SneaktoSlimPlayerController(Self.Controller).GotoState('EndInvisible');
			}
			else if (SneaktoSlimPlayerController(Self.Controller).IsInState('DisguisedExhausted') || SneaktoSlimPlayerController(Self.Controller).IsInState('DisguisedWalking'))
			{
				SneaktoSlimPlayerController(Self.Controller).attemptToChangeState('EndDisguised');
				SneaktoSlimPlayerController(Self.Controller).GotoState('EndDisguised');
			}


			//If I am the client owner, I will check all the other players' status
			if(self.Role == ROLE_AutonomousProxy)
			{
				ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
				{

					if(CurrentPawn.mistNum == self.mistNum)
					{
						CurrentPawn.Mesh.SetHidden(false);
						//CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.Character.invisibleMaterial');
						//CurrentPawn.Mesh.SetMaterial(1, Material'FLCharacter.Character.invisibleMaterial');
						changeCharacterMaterial(CurrentPawn,CurrentPawn.GetTeamNum(),"Invisible");
						if(CurrentPawn.isGotTreasure == true)
						{
							CurrentPawn.treasureComponent.SetHidden(false);
							CurrentPawn.treasureMovingEffectComp.SetActive(true);
							//CurrentPawn.treasureComponent.SetMaterial(0, Material'FLCharacter.Character.invisibleMaterial');
						}
					}
					else if(CurrentPawn.mistNum != 0 && CurrentPawn.mistNum != self.mistNum)
					{
						CurrentPawn.Mesh.SetHidden(true);
						if(CurrentPawn.isGotTreasure == true)
						{
							CurrentPawn.treasureComponent.SetHidden(true);
							CurrentPawn.treasureMovingEffectComp.SetActive(false);
						}
					}
					else if(CurrentPawn.mistNum == 0)
					{
						CurrentPawn.Mesh.SetHidden(false);
						if(CurrentPawn.isGotTreasure == true)
						{
							CurrentPawn.treasureComponent.SetHidden(false);
							CurrentPawn.treasureMovingEffectComp.SetActive(true);
						}
					}
				}
			}
			//If I am the simulated guest, I will find the client owner, compare to him and decide whether I should hide or transparent
			else if(self.Role == ROLE_SimulatedProxy)
			{
				ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
				{
					//find the client owner
					if(CurrentPawn.Role == ROLE_AutonomousProxy)
					{
						if(CurrentPawn.mistNum == self.mistNum)
						{
							self.Mesh.SetHidden(false);
							//self.Mesh.SetMaterial(0, Material'FLCharacter.Character.invisibleMaterial');
							//self.Mesh.SetMaterial(1, Material'FLCharacter.Character.invisibleMaterial');
							self.changeCharacterMaterial(self,self.GetTeamNum(),"Invisible");
							if(self.isGotTreasure == true)
							{
								self.treasureComponent.SetHidden(false);
								self.treasureMovingEffectComp.SetActive(true);
								//self.treasureComponent.SetMaterial(0, Material'FLCharacter.Character.invisibleMaterial');
							}
						}
						else
						{
							self.Mesh.SetHidden(true);
							if(self.isGotTreasure == true)
							{
								self.treasureComponent.SetHidden(true);
								self.treasureMovingEffectComp.SetActive(false);
							}
						}
					}
				}
			}
		}
		//quit mist
		else if(self.mistNum == 0)
		{
			//If I am the client owner, I will check all the other players' status
			if(self.Role == ROLE_AutonomousProxy)
			{
				ForEach WorldInfo.AllActors(class 'sneaktoslimpawn', CurrentPawn)
				{
					if(CurrentPawn.mistNum == self.mistNum)
					{
						CurrentPawn.Mesh.SetHidden(false);
						//CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.GinsengBaby.GinsengBaby_material_0');

						changeCharacterMaterial(CurrentPawn,CurrentPawn.GetTeamNum(),"Character");
						if(CurrentPawn.isGotTreasure == true)
						{
							CurrentPawn.treasureComponent.SetHidden(false);
							CurrentPawn.treasureMovingEffectComp.SetActive(true);
							//CurrentPawn.treasureComponent.SetMaterial(0, Material'FLCharacter.Character.invisibleMaterial');
						}
						//`log('FLCharacter.lady.lady_material_' $ '1');
						//CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
						//CurrentPawn.Mesh.SetMaterial(1,  MaterialInstanceConstant(DynamicLoadObject("FLCharacter.lady.lady_material_" $ currentPawn.GetTeamNum(), class'MaterialInstanceConstant')));
						//CurrentPawn.Mesh.SetMaterial(1,  Material  ("FLCharacter.lady.lady_material_" $ currentPawn.GetTeamNum()));
						
					}
					else if(CurrentPawn.mistNum != 0)
					{
						CurrentPawn.Mesh.SetHidden(true);
						if(CurrentPawn.isGotTreasure == true)
						{
							CurrentPawn.treasureComponent.SetHidden(true);
							CurrentPawn.treasureMovingEffectComp.SetActive(false);
						}
					}
				}
			}
			//I am the simulated guest
			else if(self.Role == ROLE_SimulatedProxy)
			{
				self.Mesh.SetHidden(false);

				//self.Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
				//self.Mesh.SetMaterial(1,  MaterialInstanceConstant(DynamicLoadObject("FLCharacter.lady.lady_material_" $ self.GetTeamNum(), class'MaterialInstanceConstant')));
				self.changeCharacterMaterial(self,self.GetTeamNum(),"Character");
				if(self.isGotTreasure == true)
				{
					self.treasureComponent.SetHidden(false);
					self.treasureMovingEffectComp.SetActive(true);
				}

			}
		}
	}

	Super.ReplicatedEvent(VarName);
}


reliable server function serverResetInvisibleNum()
{
	InvisibleNum = -1;
}

reliable server function serverResetEndInvisibleNum()
{
	endinvisibleNum = -1;
}

reliable server function serverResetDisguiseNum()
{
	disguiseNum = -1;
}

reliable server function serverResetEndDisguiseNum()
{
	endDisguiseNum = -1;
}

exec function detachball()
{
	`log(treasureComponent);
	serverdetachball();
	//self.Mesh.DetachComponent(treasureComponent);
}

reliable server function serverdetachball()
{
	`log(treasureComponent);
	//self.Mesh.DetachComponent(treasureComponent);
}

simulated function simulatedDrawPlayerColor()
{
	local string materialName;
	local MaterialInstanceConstant baseMaterial;

	//materialName = "FLCharacter.lady.lady_material_";
	//materialName $= self.colorIndex;	
	//baseMaterial = MaterialInstanceConstant(DynamicLoadObject(materialName, class'MaterialInstanceConstant'));
	
	//self.Mesh.SetMaterial(1,baseMaterial);

	self.changeCharacterMaterial(self,self.GetTeamNum(),"Character");
	`log("simulated get team"@self.GetTeamNum());
}

function setBeingTracked()
{
	self.Mesh.SetDepthPriorityGroup(ESceneDepthPriorityGroup(SDPG_Foreground)) ;
}

function releaseBeingTracked()
{
	self.Mesh.SetDepthPriorityGroup(ESceneDepthPriorityGroup(SDPG_World)) ;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////END ANIMATION/GRAPHIC CODE

function SneaktoSlimPawn GetPawnInstance()
{
	local SneaktoSlimPawn PawnInstance;
	Foreach WorldInfo.AllPawns(class'SneaktoSlimPawn', PawnInstance)
		{
			return PawnInstance;
		}
}

/////////////////////////////////////////////////////////////////////START STUN CODE
reliable client function disablePlayerMovement()
{	
	SneaktoslimPlayerController(self.Controller).IgnoreMoveInput(TRUE);
}

reliable client function enablePlayerMovement()
{	
	SneaktoslimPlayerController(self.Controller).IgnoreMoveInput(FALSE);
}
/////////////////////////////////////////////////////////////////////END STUN CODE

/////////////////////////////////////////////////////////////////////START BELLY-BUMP CODE

//Function to call when the button on screen is pressed


simulated function callClientBumpParticle(int teamNumber)
{
	local sneakToSlimPawn current;
	
	if(role == role_authority)
		foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
		{
			`log("callClientBumpParticle" $ current.GetTeamNum());
			current.clientBumpParticle(teamNumber);
		}
}

reliable client function clientBumpParticle(int teamNumber)
{
	local sneakToSlimPawn current;
	
	foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
	{
		`log("clientBumpParticle" $ current.GetTeamNum());
		if(current.GetTeamNum() == teamNumber)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'flparticlesystem.hitEffect',current.Location);
			PlaySound(SoundCue'flsfx.Player_Hit_Cue');
		}
			
	}
}

simulated function callClientRoarParticle(int teamNumber)
{
	local sneakToSlimPawn current;
	
	//if(role == role_authority)
		foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
		{
			`log("callClientRoarParticle" $ current.GetTeamNum());
			current.clientRoarParticle(teamNumber);
		}
}

reliable client function clientRoarParticle(int teamNumber)
{
	local sneakToSlimPawn current;
	
	foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
	{
		`log("clientRoarParticle" $ current.GetTeamNum());
		if(current.GetTeamNum() == teamNumber)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'flparticlesystem.SonicBeam',current.Location, current.Rotation);
			//PlaySound(SoundCue'flsfx.Player_Hit_Cue');
		}
			
	}
}

simulated function CallToggleSprintParticle(bool flag, byte teamNum)
{
	local SneakToSlimPawn current;
	foreach worldinfo.allactors(class 'SneakToSlimPawn', current)
	{
		current.SetSprintParticle(flag, teamNum);
	}
}

unreliable client function SetSprintParticle(bool flag,byte teamNum)
{

	local SneakToSlimPawn current;
	foreach worldinfo.allactors(class 'SneakToSlimPawn', current)
	{
		if (current.GetTeamNum() == teamNum)
		{
			SneakToSlimPawn_Shorty(current).toggleSprintParticle(flag);
		}
	}
}

simulated function CallToggleDustParticle(bool flag, byte teamNum)
{
	local SneakToSlimPawn current;
	foreach worldinfo.allactors(class 'SneakToSlimPawn', current)
	{
		current.setDustParticle(flag, teamNum);
	}
}

unreliable client function setDustParticle(bool flag, byte teamNum)
{
	local SneakToSlimPawn current;
	foreach worldinfo.allactors(class 'SneakToSlimPawn', current)
	{
		if (current.GetTeamNum() == teamNum)
		{
			SneakToSlimPawn_GinsengBaby(current).toggleDustParticle(flag);
		}
	}
}

simulated function showBumpParticle()
{
	WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'flparticlesystem.hitEffect',self.Location);
}

//Works when two pawns bump
event Bump (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitNormal)
{
	//local Vector knockBackVector;
	//local vector dropLocation;
	///////////////////////////////`Log("Collision",true, 'Nick P');
	//Account for only 1 collision every "InvulnerableTimer" seconds
	if(!bInvulnerable)
	{
		bInvulnerable = true;
		SetTimer(InvulnerableTimer, false, 'EndInvulnerable');
	}
	//`log(self.GetTeamNum(), true, 'Lu');
}

event EncroachedBy(Actor Other)
{
    //PLEASE DON'T REMOVE THIS EMPTY EVENT. NEED FOR IMPACT REACTION. --ANDY
}



function EndInvulnerable()
{
	bInvulnerable = false;
}

/////////////////////////////////////////////////////////////////////END BELLY-BUMP CODE


/////////////////////////////////////////////////////////////////////START TREASURE-RELATED CODE

reliable server function getTreasure(SneaktoSlimTreasure wildTreasure, SneaktoSlimTreasureSpawnPoint treasureChest){
	self.isGotTreasure = true;

	self.totalTimesTreasureGot++;
	SneaktoSlimPlayerController(self.Controller).recordBetweenTreasureTime();

	treasureEffect = Spawn(class'SneakToSlimTreasureParticle');

	if (treasureChest != NONE)
	{		
		treasureEffect.SetLocation(treasureChest.Location + vect(0,0,100));
	}
	else
	{		
		treasureEffect.SetLocation(wildTreasure.Location);
	}

	treasureEffect.particleStartMoving(self.Location);
	self.myTreasure = wildTreasure;
	wildTreasure.ShutDown();	
	clientGetTreasure(wildTreasure, treasureChest);

}

reliable client function clientGetTreasure(SneaktoSlimTreasure wildTreasure, SneaktoSlimTreasureSpawnPoint treasureChest){
	self.isGotTreasure = true;
	
	treasureEffect = Spawn(class'SneakToSlimTreasureParticle');

	if (treasureChest != NONE)
	{
		treasureEffect.SetLocation(treasureChest.Location + vect(0,0,100));
	}
	else
	{
		treasureEffect.SetLocation(wildTreasure.Location);
	}

	treasureEffect.particleStartMoving(self.Location);	
	self.myTreasure = wildTreasure;
	wildTreasure.ShutDown();

	//bTreasureParticleIsMoving = true;
}


simulated function SetTreasureParticleEffectActive(bool flag){	
	if (flag)
	{
		if (self.Mesh.GetSocketByName('treasureSocket') != None){
			self.Mesh.AttachComponentToSocket(treasureMovingEffectComp , 'treasureSocket');
		}
	}
	else
	{
		if (self.Mesh.IsComponentAttached(treasureComponent)){
			self.Mesh.DetachComponent(treasureMovingEffectComp);
		}
	}
	treasureMovingEffectComp.SetActive(flag);
}


function vector RandomTreasureLocation(vector PawnLocation){  
	local int x;
	local int y;
	local int signX;
	local int signY;
	local vector treasureLoc;
	local vector ZTestStart;
	local vector ZTestEnd;
	signX = Rand(2);
	signY = Rand(2);
	x = Rand(50);
	y = Rand(50);
	if(signX == 1){
	    treasureLoc.X = PawnLocation.X+x;
	}
	else{
		treasureLoc.X = PawnLocation.X-x;
	}
	if(signY ==1){
	    treasureLoc.Y = PawnLocation.Y+y;
	}
	else{
		treasureLoc.Y = PawnLocation.Y-y;
	}
    
	treasureLoc.Z = 100;
	
	return treasureLoc;
	
}

reliable server function ServerMovingTreasure(vector TreasureMovingDirection){
    MovingTreasure(myTreasure,TreasureMovingDirection);
}

simulated function MovingTreasure(SneakToSlimTreasure RealTreasure, vector TreasureMovingDirection){
	SpawnedProjectile = Spawn(class'SneakToSlimMovingTreasure', Self,,self.location );
	SpawnedProjectile.MyPawn = self;
	SpawnedProjectile.Speed = 500;
	SpawnedProjectile.Init(TreasureMovingDirection);
	
}

reliable client simulated function ClientMovingTreasure(vector TreasurDestination){
	local SneakToSlimTreasure currenttreasure;
	
	foreach allActors(class 'SneakToSlimTreasure', currenttreasure)
	{
		`log("ther is atreasue client" $ currenttreasure);	
		currenttreasure.turnOn();	
		currenttreasure.SetLocation(TreasurDestination);
	}

}

simulated function dropTreasure(vector bumpNormal){
	local sneaktoslimpawn current;
	local vector DropTreasureLocation;
	local vector hitLocation;
	local vector hitNormal;	
    local vector DropCenterLocation;
	local vector ZTestStart;
	local vector ZTestEnd;
	local vector TreasureMovingDirection;
	local vector ThrowDirection;
	ThrowDirection.X =0.1;
	ThrowDirection.Y =0.1;
	ThrowDirection.Z = 1;
	TreasureMovingDirection = Normal(bumpNormal + ThrowDirection);
	`log("drop simulate");
	`log("drop name:"@self.Name);
    DropCenterLocation = self.Location;
    ZTestStart = DropCenterLocation;
	ZTestEnd = DropCenterLocation;
    ZTestStart.Z = 10000;
	ZTestEnd.Z = -10000;
	
    

	if(isGotTreasure == true)
	{
		isGotTreasure = false;
		if(Role == Role_Authority){
	         MovingTreasure(myTreasure,TreasureMovingDirection);
        }
		
		
	}

	
}




exec function ExecTreasureLocation()
{
	local vector myOffset;
	myOffset.X = 0;
	myOffset.Y = 0;
	myOffset.Z = 0;
	myTreasure.SetLocation(myOffset);
}

reliable client function TreasurePointRecord(Array<SneakToSlimTreasureSpawnPoint> TSRList)
{
	local int i;
	for(i=0;i<=TSRList.Length-1;i++)
	{
		TreasureSpawnPointLocations[i]=TSRList[i].Location;
	}
}

server reliable function ServerResetTreasure(){
	local int index;
	local SneakToSlimTreasureSpawnPoint TSP;
	local int TSPnum;
	foreach AllActors(class'SneakToSlimTreasureSpawnPoint',TSP)
	{
		TSPnum++;
	}
	index = Rand(TSPnum);
	foreach AllActors(class'SneakToSlimTreasureSpawnPoint',TSP)
	{
		if(TSP.BoxIndex == index){
            TSP.MyTreasure = myTreasure;
			myTreasure.CurrentSpawnPointIndex = index;
			TSP.isHaveTreasure = true;
			myTreasure.SetLocation(TSP.Location);
			myTreasure = none;
		}
	}
}

server reliable function ServerTurnBackTreasure(){
	local int index;
	local SneakToSlimTreasureSpawnPoint TSP;
	local int TSPnum;
	foreach AllActors(class'SneakToSlimTreasureSpawnPoint',TSP)
	{
		TSPnum++;
	}
	index = Rand(TSPnum);
	playerScore++;
	foreach AllActors(class'SneakToSlimTreasureSpawnPoint',TSP)
	{
		if(TSP.BoxIndex == index){
            TSP.MyTreasure = myTreasure;
			myTreasure.CurrentSpawnPointIndex = index;
			TSP.isHaveTreasure = true;
			`log("treasure move to location" @ TSP.Location);
			myTreasure.SetLocation(TSP.Location);
			myTreasure = none;
		}
	}
	//return index;
}

simulated function LostTreasure(){
	if(isGotTreasure == true){
	    isGotTreasure = false;
	    ServerResetTreasure();
	}
	
	
}

simulated function turnBackTreasure(){
	if(isGotTreasure == true){
	    isGotTreasure = false;
	    `log("turnBackTreasure");	
	    SneaktoSlimPlayerController(self.Controller).recordHoldTreasureTime();
	    ServerTurnBackTreasure();
	}
	
	
}

function setTreasureLocation(vector newLocation)
{
	treasureLocation = newLocation;
}

/////////////////////////////////////////////////////////////////////END TREASURE-RELATED CODE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////END CHARACTER: STUN, SPEED UP/DOWN, BELLY-BUMP, ENERGY-CHECK, TREASURE CODE



reliable server function checkServerFLBuff(enumBuff _eb, bool _boo)
{	
	`log("[Server] "$ Name $ " press 'use buff' key " $ _eb $" "$ _boo  $ " " $ bBuffed);
	
	if(self.bBuffed == 1) //buff 1 is invis
	{		
		updateStaticHUDeq("");
		//Pawn calls itself as a client to update UI
		self.hidePowerupUI(self.bBuffed);
	}

	if(self.bBuffed == 2) //buff 2 is disguise
	{
		self.hidePowerupUI(self.bBuffed);		
		updateStaticHUDeq("");
	}
	if(self.bBuffed == 3) //buff 3 is thunder fan
	{
		self.hidePowerupUI(self.bBuffed);		
		updateStaticHUDeq("");
	}
	if(self.bBuffed == 4) //buff 4 is energy tea
	{
		self.hidePowerupUI(self.bBuffed);		
		updateStaticHUDeq("");
	}
}

reliable server function checkOtherFLBuff(SneakToSlimPawn _other)
{
	if(_other.bBuffed== 2 || _other.bUsingBuffed[1] == 1) 
	{
		_other.bBuffed= 0;
		_other.bUsingBuffed[1] = 0;
		_other.myCloth.turnOn();
	}
}

reliable server function setServerFLBuff(enumBuff _eb, int _buffnumber)
{	
	`log("[Server] "$ Name $ " set " $ _eb $" " $  bBuffed);
	bBuffed = _buffnumber;
}

//Activates when falling pawn lands on a floor
event Landed (Object.Vector HitNormal, Actor FloorActor)
{   
	//Fixes continuous jumping issue
	//To better resolve problem check where Velocity.Z keeps getting set
	local SneaktoSlimPlayerController c;

	c = SneaktoSlimPlayerController(Controller);
	c.bPressedJump = false;
	if(c.GetStateName() == 'BeingBellyBumped')
		c.GoToState('PlayerWalking');	
}

//Sets flash object to be visible when tick method tells it to and sets current time to object
unreliable client function showCountdownTimer(int number)
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		myFlashHUD.CountdownText.SetBool("isOn", true);
		myFlashHUD.CountdownText.SetInt("number", number);
	}
}

//Sets flash object to be invisible when tick method tells it to
reliable client function hideCountdownTimer()
{
	if(self.Controller != none)
	{
		if(SneaktoSlimPlayerController(self.Controller).uiOn)
		{
			if(SneaktoSlimPlayerController(self.Controller).myHUD != NONE)
				SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD.CountdownText.SetBool("isOn", false);
		}
	}
}

//Sets flash object is be visible when AINavMesh tells its chaseTarget to.
reliable client function showSpottedIcon()
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
	myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
	myFlashHUD.SpottedIcon.SetBool("isOn", true);
	}
}

//Sets flash object to be invisible when AINavMesh tells its chaseTarget to.
reliable client function hideSpottedIcon()
{
	local SneaktoSlimGFxHUD myFlashHUD;

	if(SneaktoSlimPlayerController(self.Controller).uiOn)
	{
		myFlashHUD = SneaktoSlimHUD(SneaktoSlimPlayerController(self.Controller).myHUD).FlashHUD;
		myFlashHUD.SpottedIcon.SetBool("isOn", false);
	}
}

//unreliable server function serverCheckBBuffed()
//{
//	`log("sever" $ bBuffed);
//	clientCheckBBuffed(bBuffed);
//}

//unreliable client function clientCheckBBuffed(int bBuffed)
//{
//	`log("server" $ bBuffed $"client" $ bBuffed);
//	self.bBuffed = bBuffed;
//}

event Tick(float DeltaTime)
{	
	//`log("dis num" $ self.disguiseNum $ "end dis num" $ self.endDisguiseNum $ "bbuffed" $ self.bBuffed);
	//Nick: updates map's location to match player's location (if on)

	//serverCheckBBuffed();

	//`log(self.bBuffed);
	//`log(sneaktoslimgamereplicationinfo(worldinfo.GRI).ServerGameTime);
	//`log(sneaktoslimgamereplicationinfo(worldinfo.GRI).wuliya);

	if(SneaktoSlimPlayerController(self.Controller).myMap != NONE)
	{
		//if(SneaktoSlimPlayerController(self.Controller).myMap.isOn)
			SneaktoSlimPlayerController(self.Controller).myMap.playerLocation = Location;
	}
	
	/// check when usr having buff
	if(bUsingBuffed[0] == 1)
	//if(self.Controller.IsInState('InvisibleSprinting') || self.Controller.IsInState('InvisibleExhausted')  || self.Controller.IsInState('InvisibleWalking') )//for test purpose
	{
		//using buff
		 BuffedTimer += DeltaTime;

		//Passes current countdown time to itself as client
		self.showCountdownTimer(int(BuffedTimerDefault[0]-BuffedTimer));
		
		if(BuffedTimer >= BuffedTimerDefault[0])
		{
			self.hideCountdownTimer();
			BuffedTimer = 0;
			inputStringToCenterHUD(0);
			`log("buff end ");
			//beInvisable(false, false, false);  
			SneaktoSlimPlayerController(self.Controller).attemptToChangeState('EndInvisible');
			SneaktoSlimPlayerController(self.Controller).GoToState('EndInvisible');

			//bUsingBuffed[0] = 0;
			//inputStringToHUD("end invis");
		}
	}
	//if(self.Controller.IsInState('DisguisedSprinting') || self.Controller.IsInState('DisguisedExhausted')  || self.Controller.IsInState('DisguisedWalking') )//for test purpose
	else if(bUsingBuffed[1] == 1)
	{
		 BuffedTimer += DeltaTime;
		 self.showCountdownTimer(int(BuffedTimerDefault[1]-BuffedTimer));

		//inputStringToCenterHUD(BuffedTimerDefault[1] - BuffedTimer);

		if(BuffedTimer >= BuffedTimerDefault[1])
		{
			self.hideCountdownTimer();
			BuffedTimer = 0;
			inputStringToCenterHUD(0);
			`log("buff end ");
			//beInvisable(false, false, false);  
			SneaktoSlimPlayerController(self.Controller).attemptToChangeState('EndDisguised');
			SneaktoSlimPlayerController(self.Controller).GoToState('EndDisguised');
			//bUsingBuffed[1] = 0;
		}
	}
	else if(bUsingBuffed[2] == 1)
	{
		self.hideCountdownTimer();
		BuffedTimer = 0;
	}
	else
	{
		self.hideCountdownTimer();
		BuffedTimer = 0;
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

simulated exec function showCountDown(float DeltaTime)
{
	if(self.Controller.IsInState('InvisibleSprinting') || self.Controller.IsInState('InvisibleExhausted')  || self.Controller.IsInState('InvisibleWalking') )
	{
		//using buff
		 BuffedTimer += DeltaTime;		
	}

	if(self.Controller.IsInState('InvisibleSprinting') || self.Controller.IsInState('InvisibleExhausted')  || self.Controller.IsInState('InvisibleSprinting') )
	{
		BuffedTimer += DeltaTime;
		inputStringToCenterHUD(BuffedTimerDefault[1] - BuffedTimer);
		if(BuffedTimer >= BuffedTimerDefault[1])
		{
			BuffedTimer = 0;
			inputStringToCenterHUD(0);
			`log("buff end ");
			myCloth.turnOn();
			//beInvisable(false, false, false);  
			inputStringToHUD("cloth out");
		}
	}
}

simulated exec function beInvisable(bool _boo, bool _selfInvis, bool _aiInvis)
{
	if(_boo){//actually being invis to player and AI
		//self.Mesh.MotionBlurInstanceScale = 0;
		//DetachComponent(Mesh);
		if(!hiddenInVase)
			self.SetHidden(_selfInvis);
		self.bInvisibletoAI = _aiInvis;
	}else{
		//self.Mesh.MotionBlurInstanceScale = 1;
		//AttachComponent(Mesh); 
		if(!hiddenInVase)
			self.SetHidden(false);
		self.bInvisibletoAI = false;
	}
}



simulated function GetClosestWall()
{
	local StaticMeshActor Wall;
	local float Distance;

	foreach OverlappingActors (class'StaticMeshActor', Wall, 100)
	{
		if(Wall!=none)
		{
			Distance=VSize(Wall.Location-Location);
			if(Distance>0)
				`Log("find one:"@Distance,true,'alex');
		}
	}//find the mesh with distance less than 50
}

event HitWall (Object.Vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{	
	if(self.Controller.GetStateName() == 'BeingBellyBumped')
	{
		//StunPlayer(2);
		sneaktoslimplayercontroller(self.Controller).changeEveryoneState('Stunned');		
	}
	super.HitWall(HitNormal, Wall, WallComp);	
}

function DeactivateHitWall()
{
	bIsHitWall = false;
}

exec function whosyourdaddy()   //NOT IMPLEMENTED FOR NETWORKED MODE
{
	local SneaktoSlimPawn PawnInstance;
	if (Role == Role_Authority)
	{
		if (!self.CheatingMode)
		{
			self.CheatingMode = true;
			self.PerDashEnergy = 1;
			self.PerSpeedEnergy = 0.01;
		}
		else
		{
			self.CheatingMode = false;
			self.PerDashEnergy = 10;
			self.PerSpeedEnergy = 1;
		}
	}
	else
	{
		//local SneaktoSlimPawn PawnInstance;
		PawnInstance = GetPawnInstance();
		if (!PawnInstance.CheatingMode)
		{
			PawnInstance.CheatingMode = true;
			PawnInstance.PerDashEnergy = 1;
			PawnInstance.PerSpeedEnergy = 0.01;
		}
		else
		{
			PawnInstance.CheatingMode = false;
			PawnInstance.PerDashEnergy = 10;
			PawnInstance.PerSpeedEnergy = 1;
		}
	}
}

//Function to stop Guards from following players
exec function dontFollowPlayers()
{
	self.serverDontFollowPlayers();
}

server reliable function serverDontFollowPlayers()
{
	local SneakToSlimAINavMeshController guard;

	foreach AllActors(class'SneakToSlimAINavMeshController', guard)
	{
		guard.stopSeeingPlayers();
	}
}

//Function to make Guards follow players
exec function followPlayers()
{
	self.serverFollowPlayers();
}

server reliable function serverFollowPlayers()
{
	local SneakToSlimAINavMeshController guard;

	foreach AllActors(class'SneakToSlimAINavMeshController', guard)
	{
		guard.resumeSeeingPlayers();
	}
}

exec function PlayerRestart()
{	
	self.ServerPlayerRestart();
}

client reliable function ClientRestartInGame()
{
	PlayerController(self.Controller).ClientIgnoreMoveInput(true);
	SetTimer(1,false,'ClientIgnoreMoveInputRecover');
}

server reliable function ServerPlayerRestart()
{
	local SneaktoSlimPawn ResetPawn;
	local SneaktoSlimSpawnPoint SpawnPoint;
	local SneaktoSlimTreasureSpawnPoint TreasureSpawnPoint;
	local SneaktoSlimTreasure GameTreasure;
	local Array<SneaktoSlimTreasureSpawnPoint> TreasureSpawnPointArray;
	local Vector NewLocation;
	local bool HasReturnedFromPlayer;
	local bool HasResetTreasure;

	HasReturnedFromPlayer=false;
	HasResetTreasure=false;
	foreach DynamicActors(class'SneaktoSlimPawn',ResetPawn)
	{
		if(ResetPawn!=none)
		{
			foreach DynamicActors(class'SneaktoSlimSpawnPoint',SpawnPoint)
			{
				if(SpawnPoint.teamID==ResetPawn.PlayerReplicationInfo.Team.TeamIndex)
				{
					ResetPawn.SetLocation(SpawnPoint.Location+vect(50,50,0));
					if(ResetPawn.isGotTreasure)
					{
						HasReturnedFromPlayer=true;
						ResetPawn.turnBackTreasure();
					}
					ResetPawn.playerScore=0;
					ResetPawn.ClientRestartInGame();
				}
			}
		}
	}

	if(HasReturnedFromPlayer==false)
	{
		foreach DynamicActors(class'SneaktoSlimTreasure',GameTreasure)
		{
			if(GameTreasure!=none)
			{
				foreach DynamicActors(class'SneaktoSlimTreasureSpawnPoint',TreasureSpawnPoint)
				{
					if(TreasureSpawnPoint!=none)
					{
						TreasureSpawnPointArray.AddItem(TreasureSpawnPoint);
						if(TreasureSpawnPoint.Location==GameTreasure.Location)
							HasResetTreasure=true;
					}
				}

				if(!HasResetTreasure)
				{
					NewLocation=TreasureSpawnPointArray[Rand(TreasureSpawnPointArray.Length)].Location;
					GameTreasure.SetLocation(NewLocation);
					foreach DynamicActors(class'SneaktoSlimPawn',ResetPawn)
					{
						if(ResetPawn!=none)
						{
							//ResetPawn.ClientTurnBackTreasure(GameTreasure,NewLocation);
						}
					}
				}
			}
		}
	}
}

function ClientIgnoreMoveInputRecover()
{
	PlayerController(self.Controller).ClientIgnoreMoveInput(false);
	`Log("input recover has been called");
}

//start to use buff
reliable client function inputStringToHUD(string _msg, float _timer = 0)
{
	local HUDmessage newMsg;

	newMsg.sMeg = _msg;
	newMsg.MsgTimer = -_timer;

	arrMsg.InsertItem(0, NewMsg);
}

reliable client function inputStringToCenterHUD(int _msg)// used in countdown , also clean eq MSG
{
	if(_msg > 0)
	{
		staticHUDmsg.stringCountDown = string(_msg);
	}
	else
		staticHUDmsg.stringCountDown = "";
}

reliable client function updateStaticHUDeq(string _msgs)// used in countdown
{
	`log("client update eqGotten to " $ _msgs);
	staticHUDmsg.eqGotten = _msgs;
}

reliable client function updateStaticHUDPromtText(string _msgs)// used in countdown
{
	`log("client update triggerPromtText to " $ _msgs);
	staticHUDmsg.triggerPromtText = _msgs;
}

exec function playAnAnimation()
{
	bellyBumpNode.PlayCustomAnim('bumping', 2.f, 0.1f, 0.1f, false, true);
}

Server Reliable function ServerToggleLight()
{
	Local SneakToSlimLightContainer container;

	foreach DynamicActors(class'SneakToSlimLightContainer',container)
	{
		if(container!=none&&Vsize2d(container.Location-self.Location)<200)
		{
			container.ServerToggleLight();
			`Log("my light "@container.Light@" has been toggled",true,'alex');
		}
	}
}

Client reliable function ClientChangeLightIntensity(Spotlight Spotlight1, Pointlight Pointlight1, StaticMeshActor LightMesh, float SpotlightBrightness, float PointlightBrightness, Material NewMaterial)
{
	Spotlight1.LightComponent.SetLightProperties(SpotlightBrightness);
	Pointlight1.LightComponent.SetLightProperties(PointlightBrightness);
	Spotlight1.LightComponent.UpdateColorAndBrightness();
	Pointlight1.LightComponent.UpdateColorAndBrightness();
	LightMesh.StaticMeshComponent.SetMaterial(0,NewMaterial);
}


exec function ShowLightBrightness()
{
	ClientShowLightBrightness();
}

Client Reliable function ClientShowLightBrightness()
{
	local Spotlight spotlight;

	foreach AllActors(class'Spotlight',spotlight)
	{
		if(spotlight!=none)
		{
			`Log("Spotlight:"@spotlight@":"@spotlight.LightComponent.Brightness);
		}
	}

	`Log("has called client show function");
}

exec function ToggleLight()
{
	ServerToggleLight();
}


reliable server function serverResetBBuffed()
{
	bBuffed= 0;
}

///////////////////////////////////////////////////temporary trash can 
simulated function name GetDefaultCameraMode(PlayerController RequestedBy)
{
    return 'ThirdPerson';  
}

//only update pawn rotation while moving
simulated function FaceRotation(rotator NewRotation, float DeltaTime)
{
	// Do not update Pawn's rotation if no accel
	if (Normal(Acceleration)!=vect(0,0,0))
	{
		if ( Physics == PHYS_Ladder )
		{
			NewRotation = OnLadder.Walldir;
		}
		else if ( (Physics == PHYS_Walking) || (Physics == PHYS_Falling) )
		{
			NewRotation = rotator((Location + Normal(Acceleration))-Location);
			NewRotation.Pitch = 0;
		}
		NewRotation = RLerp(Rotation,NewRotation,0.1,true);
		SetRotation(NewRotation);
	}
}

//
//!!!!!!!!!!!!!!!!!!!!!!!!!!!PLEASE DON'T DELETE THIS FUNCTION. MIGHT NEED IT IN THE FUTURE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! -- ANDY
//
//orbit cam, follows player controller rotation
//simulated function bool CalcCamera( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
//{
//	local vector HitLoc,HitNorm, End, Start, vecCamHeight;

//	vecCamHeight = vect(0,0,0);
//	vecCamHeight.Z = CamHeight;
//	Start = Location;
//	End = (Location+vecCamHeight)-(Vector(Controller.Rotation) * CamOffsetDistance);  //cam follow behind player controller
//	out_CamLoc = End;

//	//trace to check if cam running into wall/floor
//	if(Trace(HitLoc,HitNorm,End,Start,false,vect(12,12,12))!=none)
//	{
//		out_CamLoc = HitLoc + vecCamHeight;
//	}
	
//	//camera will look slightly above player
//   out_CamRot=rotator((Location + vecCamHeight) - out_CamLoc);
//   return true;
//}

exec function callServer()
{
	`log("I am client");
	callServer1();
}

reliable server function callServer1()
{
	`log("I am server1");
	callServer2();
}

reliable server function callServer2()
{
	`log("I am server2");
}

///////////////////////////////////////////////////end temporary trash can 
exec function callPlay()
{
	servercallPlay();
	playerPlayOrStopCustomAnim('customVanish', 'Vanish',1.0f,true, 0,0,true,false);
}

reliable server function servercallPlay()
{
	playerPlayOrStopCustomAnim('customVanish', 'Vanish',1.0f,true, 0,0,true,false);
}

exec function callStop()
{
	servercallStop();
	playerPlayOrStopCustomAnim('customVanish', 'Vanish',1.0f,false, 0,0,true,false);
}

reliable server function servercallStop()
{
	playerPlayOrStopCustomAnim('customVanish', 'Vanish',1.0f,false, 0,0,true,false);
}

simulated function myGetCustomAnimNodeSequence(name nodeName)
{
	local AnimNodePlayCustomAnim customNode;
	local AnimNodeSequence mySequence;


	customNode = AnimNodePlayCustomAnim(Mesh.FindAnimNode(nodeName));
	mySequence = customNode.GetCustomAnimNodeSeq();

	//return mySequence;
}


simulated function playerPlayOrStopCustomAnim
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
	
	//find the custom Node
	customNode = AnimNodePlayCustomAnim(self.Mesh.FindAnimNode(nodeName));
	if(customNode == None)
	{
		`log("Invalid custom node name",false,'Lu');
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
			onePawn.clientPlayerPlayCustomAnim(self, nodename, AnimName, Rate, playOrStop, BlendInTime, BlendOutTime, bLooping, bOverride);
		}
	}

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


//This function is used for manage material switching.
simulated function changeCharacterMaterial(SneaktoSlimPawn currentPawn, int teamID, string materialType)
{

	local string materialName;


	if(teamID == 255)
		return;

	if(materialType == "Character")
	{
		if(currentPawn.characterName == "FatLady")
		{
			CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
			CurrentPawn.Mesh.SetMaterial(1,  MaterialInstanceConstant(DynamicLoadObject("FLCharacter.lady.lady_material_" $ teamID, class'MaterialInstanceConstant')));
		}
		else if(currentPawn.characterName == "GinsengBaby")
		{
			CurrentPawn.Mesh.SetMaterial(0, MaterialInstanceConstant(DynamicLoadObject("FLCharacter.GinsengBaby.GinsengBaby_material_" $ teamID, class'MaterialInstanceConstant')));
			CurrentPawn.Mesh.SetMaterial(1, MaterialInstanceConstant(DynamicLoadObject("FLCharacter.GinsengBaby.GinsengBaby_material_" $ teamID, class'MaterialInstanceConstant')));
		}
		else if(currentPawn.characterName == "Rabbit")
		{
			`log("Rabbit material"$ teamID);
			CurrentPawn.Mesh.SetMaterial(0, MaterialInstanceConstant(DynamicLoadObject("FLCharacter.Rabbit.Rabbit_material_" $ teamID, class'MaterialInstanceConstant')));
		}
		else if(currentPawn.characterName == "Shorty")
		{
			CurrentPawn.Mesh.SetMaterial(0, MaterialInstanceConstant(DynamicLoadObject("FLCharacter.Shorty.Shorty_material_" $ teamID, class'MaterialInstanceConstant')));
		}
		else
		{
			materialName = "FLCharacter." $ currentPawn.characterName $ "." $ currentPawn.characterName $ "_material_" $ teamID;
			CurrentPawn.Mesh.SetMaterial(0,  Material(DynamicLoadObject(materialName, class'Material')));
			CurrentPawn.Mesh.SetMaterial(1,  Material(DynamicLoadObject(materialName, class'Material')));
		}
	}
	else if(materialType == "Guards")
	{
		
	}
	else if(materialType == "Invisible")
	{
		//materialName = "FLCharacter.lady.lady_material_" $  teamID;
		//`log("change invisible material");
		CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.Character.invisibleMaterial');
		CurrentPawn.Mesh.SetMaterial(1, Material'FLCharacter.Character.invisibleMaterial');
	}
	//MaterialInstanceConstant(DynamicLoadObject("FLCharacter.lady.lady_material_" $ currentPawn.GetTeamNum(), class'MaterialInstanceConstant'));
	//CurrentPawn.Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
	//CurrentPawn.Mesh.SetMaterial(1,  MaterialInstanceConstant(DynamicLoadObject("FLCharacter.lady.lady_material_" $ currentPawn.GetTeamNum(), class'MaterialInstanceConstant')));
	//CurrentPawn.Mesh.SetMaterial(1,teamMaterial[currentPawn.GetTeamNum()]);
}

unreliable client function ClientCreateExplosion(vector loc)
{
			WorldInfo.MyEmitterPool.SpawnEmitter(
			ParticleSystem'flparticlesystem.fireCracker', 
			loc, 
			rot(0,0,0), 
			None);
}

exec function QuitCurrentGame()
{
	ConsoleCommand("disconnect");
	ConsoleCommand("open sneaktoslimmenu_landingpage?Character=Menu");
}

exec function serverQuit()
{
	HostQuitGame();
}

reliable server function HostQuitGame()
{
	ConsoleCommand("exit");
}

exec function saysometing()
{
	`log("fuck you fuck me");
}

defaultproperties
{
	bJumpCapable = false;

	bBuffed = 0;
	bUsingBuffed[0] = 0;
	bUsingBuffed[1] = 0;

	BuffedTimerDefault[0] = 10.0; // buff invis period
	BuffedTimerDefault[1] = 20.0; // buff disguise period
	BuffedTimer = 0.0;
	bInvisibletoAI = false;

	//bIsDashing = false;
	DashDuration = 0.1f;
	bIsHitWall = false;
	HitWallDuration = 0.05;
	PerDashEnergy = 13;
	PerSpeedEnergy = 1.3f;
	CheatingMode = false;
	disguiseNum = -1;
	endDisguiseNum = -1;
	invisibleNum = -1;
	endinvisibleNum = -1;
	mistNum = 0;

	bOOM = false;

	CamHeight = 42.0
	CamMinDistance = 40.0
	CamMaxDistance = 350.0
	CamOffsetDistance=200.0
	CamZoomTick=8.0
	CamZoomHeightTick = 1.6
	InvulnerableTimer = 0.2 //One second

	isHost = false;

	isGotTreasure=false;
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		bDynamic = TRUE
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object Class=AnimNodeSequence Name=TestWalkAnimSeq 
	End Object

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

	mySkelComp = InitialSkeletalMesh
    teamMaterial[0] = MaterialInstanceConstant 'FLCharacter.lady.lady_material_0'
	teamMaterial[1] = MaterialInstanceConstant 'FLCharacter.lady.lady_material_1'
	teamMaterial[2] = MaterialInstanceConstant 'FLCharacter.lady.lady_material_2'
	teamMaterial[3] = MaterialInstanceConstant 'FLCharacter.lady.lady_material_3'
	teamMaterialGB[0] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	teamMaterialGB[1] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	teamMaterialGB[2] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';
	teamMaterialGB[3] = MaterialInstanceConstant'NodeBuddies.Materials.NodeBuddy_Red1_INST';

	Begin Object Class=SkeletalMeshComponent Name=AISkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.Guard.Guard'
		AnimSets(0)=AnimSet'FLCharacter.Guard.Guard_Anims'
		AnimTreeTemplate = AnimTree'FLCharacter.Guard.Guard_AnimTree'		
		Translation=(Z=-52.0)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false		
	End Object

	AISkelComp = AISkeletalMesh
    Components.Add(InitialSkeletalMesh)	
	Mesh = InitialSkeletalMesh	

	Begin Object Name=CollisionCylinder
		CollisionRadius=22.000000
        CollisionHeight=48.000000
    End Object
	CylinderComponent=CollisionCylinder

	FLWalkingSpeed=150.0
	FLSprintingSpeed=350.0
	FLExhaustedSpeed=75.0

	GroundSpeed=150.0;
	AccelRate = 500;
	JumpZ = 300.0
	v_energy = 100;
	s_energized = 0;
	
	bAlwaysRelevant = true;     //Need for all pawns to see each others scores
	playerScore = 0;
	bDirectHitWall=True;
	bForceMaxAccel = False;
	isChangeMesh = False;
	isSetSPcolor = False;
	bNoEncroachCheck = true     //Enables pawns to move even when overlapping

	colorIndex = -1;

	FanRange = 1000;
	FanAngle = 120;

	energyRegenerateRate = 1.0f
	PreBumpDelay=0.1;
	bPreDash = false;
	PlayerBaseRadius = 250;
	underLight = false;
	playerHasFan = true;	
	invincibleTime = 3.0
	meshTranslationOffset = (X=0, Y=0, Z=-80)
	
	MaxStepHeight = 25
	
	Begin Object Class=ParticleSystemComponent Name=particle_1
        Template=ParticleSystem'flparticlesystem.treasureMovingEffect'
        bAutoActivate=false		
	End Object
	treasureMovingEffectComp = particle_1
	Components.Add(particle_1)
	
	Begin Object Class=StaticMeshComponent   Name=SneakToSlimPawnTreasureMesh
		StaticMesh=StaticMesh'FLInteractiveObject.treasure.Tresure'
		LightEnvironment=MyLightEnvironment
		CastShadow=true
	End Object


	Begin Object Class=Pointlightcomponent Name=TreasurePointLight
      Translation = (X=-5, Y= -10, Z=0)
	  bEnabled = true
	  bCastCompositeShadow = True
	  bAffectCompositeShadowDirection = false
	  CastShadows = True;
	  CastStaticShadows = false;
	  CastDynamicShadows = True;
	  LightShadowMode = LightShadow_Normal
	  Radius=96.000000
	  Brightness=5.0000	 
	  LightColor=(R=255,G=255,B=0)
      bRenderLightShafts = true
	  LightmassSettings = (LightSourceRadius = 128.0)
	End Object

	treasureComponent=SneakToSlimPawnTreasureMesh; 
	treasureLightComponent = TreasurePointLight;	
}
