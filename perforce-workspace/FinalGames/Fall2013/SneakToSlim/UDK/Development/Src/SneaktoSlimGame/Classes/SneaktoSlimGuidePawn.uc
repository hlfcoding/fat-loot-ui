class SneaktoSlimGuidePawn extends Pawn
	placeable;

//Dialogue Trees that hold tutorial text
var array<string> HowToMoveDialoguePC, TreasureDialoguePC, SpectateDialoguePC, GuardsDialoguePC, TeleporterDialoguePC, VaseDialoguePC, ShelfDialoguePC, 
				  InteractableObjectsDialoguePC, FirstCheckPointDialoguePC, SecondCheckPointDialoguePC, FinalDialoguePC, AbilitiesDialoguePC;
var array<string> HowToMoveDialogueXbox, TreasureDialogueXbox, SpectateDialogueXbox, GuardsDialogueXbox, TeleporterDialogueXbox, VaseDialogueXbox, ShelfDialogueXbox, 
				  InteractableObjectsDialogueXbox, FirstCheckPointDialogueXbox, SecondCheckPointDialogueXbox, FinalDialogueXbox, AbilitiesDialogueXbox;
var array<string> currentDialogue;
var string currentState;
var SneaktoSlimPawn talkingTo;
var int timeBetweenLines;
var bool isActive;
var bool isUsingXboxController;
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

	timeBetweenLines = 5;
	isActive = false;
	isUsingXboxController = false;

	//Add Text script for different vars associated with a state
	//HowToMoveDialoguePC.AddItem("");      //This text is loaded before client HUD is initialized
	HowToMoveDialoguePC.AddItem("Ah, good, you made it inside.");
	HowToMoveDialoguePC.AddItem("Welcome to the Academy of the Snatching Hand, premiere thief school!");
	HowToMoveDialoguePC.AddItem("Time for your training to start!");
	HowToMoveDialoguePC.AddItem("What your standing on right now is your HOME BASE.");
	HowToMoveDialoguePC.AddItem("You know it’s yours because it clearly matches your wardrobe color palette.");
	HowToMoveDialoguePC.AddItem("The HOME BASE is essential to any thief.");
	HowToMoveDialoguePC.AddItem("Any treasure you bring back here will be sent back to your vault, safe and sound.");
	HowToMoveDialoguePC.AddItem("Of course, to steal treasure, you’re going to have to get to it.");
	HowToMoveDialoguePC.AddItem("Use your MOUSE to look around and the WASD keys to move.");
	HowToMoveDialoguePC.AddItem("Come TALK to me over by that glowing CHEST.");
	//Xbox controller text
	HowToMoveDialogueXbox.AddItem("");      //This text is loaded before client HUD is initialized
	HowToMoveDialogueXbox.AddItem("Ah, good, you made it inside.");
	HowToMoveDialogueXbox.AddItem("Welcome to the Academy of the Snatching Hand, premiere thief school!");
	HowToMoveDialogueXbox.AddItem("Time for your training to start!");
	HowToMoveDialogueXbox.AddItem("What your standing on right now is your HOME BASE.");
	HowToMoveDialogueXbox.AddItem("You know it’s yours because it clearly matches your wardrobe color palette.");
	HowToMoveDialogueXbox.AddItem("The HOME BASE is essential to any thief.");
	HowToMoveDialogueXbox.AddItem("Any treasure you bring back here will be sent back to your vault, safe and sound.");
	HowToMoveDialogueXbox.AddItem("Of course, to steal treasure, you’re going to have to get to it.");
	HowToMoveDialogueXbox.AddItem("Use the RIGHT THUMB STICK to look around and the LEFT THUMB STICK to move.");
	HowToMoveDialogueXbox.AddItem("Come TALK to me over by that glowing CHEST.");
	
	TreasureDialoguePC.AddItem("Good job kid, you walked down a hallway (slow clap).");
	TreasureDialoguePC.AddItem("Practice this skill, you will need it in the heists to come.");
	TreasureDialoguePC.AddItem("The TREASURE you seek rests in PEDESTALS like these.");
	TreasureDialoguePC.AddItem("You can tell it’s in there because of the glowing golden aura.");
	TreasureDialoguePC.AddItem("How gauche, I think it looks rather tacky.");
	TreasureDialoguePC.AddItem("Walk up the stand and press 'E' to take the TREASURE ...");
	TreasureDialoguePC.AddItem("... now, take it to your HOME BASE.");
	TreasureDialoguePC.AddItem("I’ll meet you there.");
	TreasureDialogueXbox.AddItem("Good job kid, you walked down a hallway (slow clap).");
	TreasureDialogueXbox.AddItem("Practice this skill, you will need it in the heists to come.");
	TreasureDialogueXbox.AddItem("The TREASURE you seek rests in PEDESTALS like these.");
	TreasureDialogueXbox.AddItem("You can tell it’s in there because of the glowing golden aura.");
	TreasureDialogueXbox.AddItem("How gauche, I think it looks rather tacky.");
	TreasureDialogueXbox.AddItem("Walk up the stand and press 'A' to take the TREASURE ...");
	TreasureDialogueXbox.AddItem("... now, take it to your HOME BASE.");
	TreasureDialogueXbox.AddItem("I’ll meet you there.");

	GuardsDialoguePC.AddItem("Nice! The TREASURE has been sent back to your personal vault.");
	GuardsDialoguePC.AddItem("Look before you, the PEDESTAL has its TREASURE back.");
	GuardsDialoguePC.AddItem("These rich jerks replace their TREASURE right away from their vaults!");
	GuardsDialoguePC.AddItem("More for us, I guess!");
	GuardsDialoguePC.AddItem("Now, if thieving was this easy, everyone would be doing it.");
	GuardsDialoguePC.AddItem("Most palaces have GUARDS to protect their TREASURES. There’s one now!");
	GuardsDialoguePC.AddItem("Sneak past the GUARD and retrieve another TREASURE.");
	GuardsDialoguePC.AddItem("Sneak in the shadows and avoid their line of sight.");
	GuardsDialoguePC.AddItem("If a GUARD catches you ...");
	GuardsDialoguePC.AddItem("... you’ll be sent back to your HOME BASE and...");
	GuardsDialoguePC.AddItem("... they'll confiscate your TREASURE.");
	GuardsDialoguePC.AddItem("TALK to me once your ready to continue.");
	GuardsDialogueXbox = GuardsDialoguePC;

	//"Okay, now let me tell you this. Your not alone."
	//"There are other thieves to look out for."
	//"You’re going to have to fight them for the palace’s treasure!"
	//“Every character has their own special abilities."
	//"These draw on your internal ENERGY. Use them too much, and you’ll get EXHAUSTED.”
	//"In this case, your character Lady Qianxin can ..."
	//"SPRINT by holding RIGHT CLICK on the mouse and ..."
	//"BELLY BUMP by clicking the LEFT MOUSE button."
	//"Look, one of your fellow students has ‘volunteered’ to help you practice your BUMPING skills"
	//"Once you feel you have mastered the arts of Moving, Stealing, Sneaking and Fighting. Get out there and start thieving!"
	//"When your done, press 'ESC' and quit to return to the main menu."
	AbilitiesDialoguePC.AddItem("You can activate different abilities by clicking on the mouse.");
	AbilitiesDialoguePC.AddItem("Each character has different abilities, but for now ...");
	AbilitiesDialoguePC.AddItem("As the fat lady, you can run by holding the right mouse button and ...");
	AbilitiesDialoguePC.AddItem("clicking the left mouse button will perform a belly bump.");
	AbilitiesDialoguePC.AddItem("Attacking others will stun them and knock off any treasure their holding.");
	AbilitiesDialoguePC.AddItem("Try it on the other player in the room or ...");
	AbilitiesDialoguePC.AddItem("explore the area to see how different interactable objects work.");
	AbilitiesDialoguePC.AddItem("When your done, press 'ESC' and quit to return to the main menu.");
	AbilitiesDialogueXbox.AddItem("You can activate different abilities by pressing left or right trigger buttons");
	AbilitiesDialogueXbox.AddItem("Each character has different abilities, but for now ...");
	AbilitiesDialogueXbox.AddItem("As the fat lady, you can run by holding the LT button and ...");
	AbilitiesDialogueXbox.AddItem("pressing the RT button will perform a belly bump.");
	AbilitiesDialogueXbox.AddItem("Attacking others will stun them and knock off any treasure their holding.");
	AbilitiesDialogueXbox.AddItem("Try it on the other player in the room or ...");
	AbilitiesDialogueXbox.AddItem("explore the area to see how different interactable objects work.");
	AbilitiesDialogueXbox.AddItem("When your done, press 'Start' and quit to return to the main menu.");
	
	//State isn't used but set to keep things from accidently activating 
	changeToTutorialState('WaitOnFirstLoad');

	//Sets timer that automatically scrolls through currentDialogue every five seconds
	SetTimer(timeBetweenLines, true, 'readNextDialogueEntry');
	PauseTimer(true, 'readNextDialogueEntry');

	//Spawns a guide trigger and writes pawns tag to it
    guideTrigger = Spawn(class'GuideTrigger');
	guideTrigger.Tag = self.Tag;
	guideTrigger.guidePawn = self;
}

//Timer function that reads arrays associated with a state
simulated function readNextDialogueEntry()
{
	local string entry;
	local int count;
	local PathNode node;
	local SneaktoSlimAIPawn aiPawn;
	local SneaktoSlimPawn_FatLady lady;
	local SneaktoSlimPlayerController_FatLady pclady;
	local SneaktoSlimTreasureSpawnPoint treasurePoint;

	//Stops if all dialogue has been read
	if(currentDialogue.Length == 0)
	{
		isActive = false;
		talkingTo.hideTutorialTextObject();
		PauseTimer(true, 'readNextDialogueEntry');

		if(currentState == "HowToMove")
		{
			foreach WorldInfo.AllActors(class'PathNode', node)
			{
				if(string(node.Tag) == "TreasureBase")
				{
					playPoofAnimation(node.Location, self.Rotation);
				}
			}
			if(string(guideTrigger.Tag) == "HowToMove")
				guideTrigger.Tag = 'ExplainTreasure';
		}

		//Moves guard by treasure to home base and switches its dialogue and state
		if(currentState == "ExplainTreasure")
		{
			foreach WorldInfo.AllActors(class'PathNode', node)
			{
				if(string(node.Tag) == "HomeBase")
				{
					playPoofAnimation(node.Location, node.Rotation);
				}
			}
 			if(string(guideTrigger.Tag) == "ExplainTreasure")
				guideTrigger.Tag = 'ExplainGuards';
		}
		return;
	}

	if(currentState == "ExplainGuards" && currentDialogue.Length == 4)
	{
		foreach WorldInfo.AllPawns(class 'SneakToSlimAIPawn', aiPawn)
		{
			foreach WorldInfo.AllActors(class'PathNode', node)
			{
				if(string(node.Name) == "PathNode_4")
				{
					aiPawn.SetLocation(node.Location);
				}
			}
		}
		if(string(guideTrigger.Tag) == "ExplainGuards")
			guideTrigger.Tag = 'ExplainAbilities';
	}
	if(currentState == "ExplainAbilities" && currentDialogue.Length == 8)
	{
		foreach WorldInfo.AllActors(class'PathNode', node)
		{
			if(string(node.Tag) == "Test")
			{
				count = 0;
				foreach WorldInfo.AllPawns(class'SneaktoSlimPawn_FatLady', lady)
					count++;

				if(count == 1)
				{
					lady = Spawn(class 'SneaktoSlimPawn_FatLady',,,node.Location);
					pclady = Spawn(class 'SneaktoSlimPlayerController_FatLady',,,node.Location, node.Rotation);
					lady.Controller = pclady;
					pclady.Pawn = lady;
					lady.SetRotation(node.Rotation);
					foreach WorldInfo.AllActors(class 'SneaktoSlimTreasureSpawnPoint', treasurePoint);
					lady.isGotTreasure = true;
					pclady.GotoState('HoldingTreasure');
					pclady.changeAnimTreeToTreasure();
					treasurePoint.MyTreasure.giveTreasure(lady,treasurePoint);
				}
			}
		}
	}

	//If the state name matches a predetermined keyword the currentDialogue array is read and displayed
	if(currentState == "HowToMove" || currentState == "ExplainTreasure" || currentState == "ExplainAbilities" || 
	   currentState == "ExplainGuards" || currentState == "ExplainInteractableObjects" || 
	   currentState == "ExplainVase" || currentState == "ExplainTeleporter" || currentState == "ExplainShelf" || 
	   currentState == "FirstCheckPoint" || currentState == "SecondCheckPoint" || currentState == "Final")
	{
		entry = currentDialogue[0];
		currentDialogue.Remove(0, 1);
		talkingTo.displayTutorialText(entry);
		//`log(entry);

		//Sets timer for HowToMove to activate read loop every five seconds instead of two after first line is read
		/*if(currentState == "HowToMove" && self.timeBetweenLines == 1 && currentDialogue.Length == 8)
		{
			self.timeBetweenLines = 5;
			ClearTimer('readNextDialogueEntry');
			SetTimer(timeBetweenLines, true, 'readNextDialogueEntry');
		}*/
		if(currentState == "HowToMove" && currentDialogue.Length == 1)
		{
			SneaktoSlimPlayerController(talkingTo.Controller).IgnoreLookInput(false);
			SneaktoSlimPlayerController(talkingTo.Controller).IgnoreMoveInput(false);
		}
	}
}

simulated function activateGuide()
{
	local SneaktoSlimGuideController guide;

	//Deactivates all other guide controllers
	foreach WorldInfo.AllControllers(class'SneaktoSlimGuideController', guide)
	{
		guide.isActive = false;
		guide.ClearTimer('readNextDialogueEntry');
		guide.SetTimer(guide.timeBetweenLines, true, 'readNextDialogueEntry');
		guide.PauseTimer(true, 'readNextDialogueEntry');
	}

	//Activates this guide's dialogue
	isActive = true;
	PauseTimer(false, 'readNextDialogueEntry');
	readNextDialogueEntry();
}

//Can be called by object such as a door to switch to a specific tutorial
//Can also be called by this pawn's trigger when player interacts with this guide
simulated function changeToTutorialState(name stateName)
{
	//Checks what current state is
	currentState = string(stateName);
	`log("I'm in state " $ currentState);

	//Does stuff specific to state
	//Aside from "default" and "Wait on FirstLoad",
	//each case sets the appropriate dialogue array to be the current and starts timer
	switch(currentState)
	{
		case "HowToMove":
			SneaktoSlimPlayerController(talkingTo.Controller).IgnoreLookInput(true);
			SneaktoSlimPlayerController(talkingTo.Controller).IgnoreMoveInput(true);
			self.isUsingXboxController = SneaktoSlimPlayerController(talkingTo.Controller).PlayerInput.bUsingGamepad;       //Will return false since controller isn't set immediately when in debug mode
			if(isUsingXboxController)
				currentDialogue = HowToMoveDialogueXbox;
			else
				currentDialogue = HowToMoveDialoguePC;
			activateGuide();
			break;
		case "ExplainTreasure":
			self.isUsingXboxController = SneaktoSlimPlayerController(talkingTo.Controller).PlayerInput.bUsingGamepad;       //Double check, not needed.
			if(isUsingXboxController)
				currentDialogue = TreasureDialogueXbox;
			else
				currentDialogue = TreasureDialoguePC;
			activateGuide();
			break;
		case "ExplainAbilities":
			if(isUsingXboxController)
				currentDialogue = AbilitiesDialogueXbox;
			else
				currentDialogue = AbilitiesDialoguePC;
			activateGuide();
			break;
		case "ExplainGuards":
			if(isUsingXboxController)
				currentDialogue = GuardsDialogueXbox;
			else
				currentDialogue = GuardsDialoguePC;
			activateGuide();
			break;
		/*case "ExplainInteractableObjects":
			currentDialogue = InteractableObjectsDialogue;
			activateGuide();
			break;
		case "ExplainTeleporter":
			currentDialogue = TeleporterDialogue;
			activateGuide();
			break;
		case "ExplainVase":
			currentDialogue = VaseDialogue;
			activateGuide();
			break;
		case "ExplainShelf":
			currentDialogue = ShelfDialogue;
			activateGuide();
			break;
		case "FirstCheckPoint":
			currentDialogue = FirstCheckPointDialogue;
			activateGuide();
			break;
		case "SecondCheckPoint":
			currentDialogue = SecondCheckPointDialogue;
			activateGuide();
			break;
		case "Final":
			currentDialogue = FinalDialogue;
			activateGuide();
			break;*/
		case "WaitOnFirstLoad":
			`log("Guide is up and waiting.");
			break;
		default:
			`log("State Not Recognized");
			break;
	}
}

simulated function teleport()
{
	self.SetLocation(teleportLocation);
	self.SetRotation(teleportRotation);
}

simulated function playPoofAnimation(vector newLocation, Rotator newRotation)
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

	//If I am the server, then call all the client to play or stop the animation
	if(Role == ROLE_Authority)
	{
		SneaktoSlimPawn_FatLady(talkingTo).playGuidePoofAnimation();
	}
}

simulated event Tick(float DeltaTime)
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
