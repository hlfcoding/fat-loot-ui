class SneaktoSlimGuideController extends PlayerController;

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

simulated event PostBeginPlay()
{	
	super.PostBeginPlay();

	timeBetweenLines = 5;
	isActive = false;
	isUsingXboxController = false;

	//Add Text script for different vars associated with a state
	HowToMoveDialoguePC.AddItem("");      //This text is loaded before client HUD is initialized
	HowToMoveDialoguePC.AddItem("How to move.");
	HowToMoveDialoguePC.AddItem("Use the 'A', 'W', 'S', 'D' keys to move.");
	HowToMoveDialoguePC.AddItem("Move the mouse to rotate the camera.");
	HowToMoveDialoguePC.AddItem("See the treasure pedestal in front of you?");
	HowToMoveDialoguePC.AddItem("Talk to the person in front.");
	HowToMoveDialogueXbox.AddItem("");      //This text is loaded before client HUD is initialized
	HowToMoveDialogueXbox.AddItem("How to move.");
	HowToMoveDialogueXbox.AddItem("Use the left thumb stick to move.");
	HowToMoveDialogueXbox.AddItem("Move the right thumb stick to rotate the camera.");
	HowToMoveDialogueXbox.AddItem("See the treasure pedestal in front of you?");
	HowToMoveDialogueXbox.AddItem("Talk to the person in front.");
	
	TreasureDialoguePC.AddItem("Let me explain the purpose of treasure.");
	TreasureDialoguePC.AddItem("Returning collected treasure to your home base scores you a point.");
	TreasureDialoguePC.AddItem("At the end of a match, the player with the most points wins.");
	TreasureDialoguePC.AddItem("Walk up to the pedestal and press 'e' to grab it.");
	TreasureDialogueXbox.AddItem("Let me explain the purpose of treasure.");
	TreasureDialogueXbox.AddItem("Returning collected treasure to your home base scores you a point.");
	TreasureDialogueXbox.AddItem("At the end of a match, the player with the most points wins.");
	TreasureDialogueXbox.AddItem("Walk up to the pedestal and press 'A' to grab it.");

	GuardsDialoguePC.AddItem("Good job. Now try getting the treasure while dealing with the guard");
	GuardsDialoguePC.AddItem("WATCH OUT! for guards at ALL costs!!!");
	GuardsDialoguePC.AddItem("You can't beat these skilled protectors in combat.");
	GuardsDialoguePC.AddItem("Tip: If you are out in the light, guards will have a better chance of spotting you.");
	GuardsDialoguePC.AddItem("Talk to me again to move on to the next lesson.");
	GuardsDialogueXbox = GuardsDialoguePC;

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
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
	/*SpectateDialogue.AddItem("See those characters down there?");
	SpectateDialogue.AddItem("That's what a typical game looks like.");
	SpectateDialogue.AddItem("See if you can notice the small details to play.");
	SpectateDialogue.AddItem("When your done observing, move on to the next room.");

	//Explain interactable objects
	InteractableObjectsDialogue.AddItem("Talk to my sisters to understand how interactable objects function.");
	InteractableObjectsDialogue.AddItem("Or if you want to skip this section, ...");
	InteractableObjectsDialogue.AddItem("just know that pressing 'e' when in close proximity actives them.");

	TeleporterDialogue.AddItem("Teleporters come in pairs of two and ...");
	TeleporterDialogue.AddItem("each teleporter has a pre-determined location set for each map.");
	TeleporterDialogue.AddItem("Press 'e' to use this teleporter.");

	VaseDialogue.AddItem("Use vases to hide from others and mount a sneak attack.");
	VaseDialogue.AddItem("Press 'e' to hide in this vase.");
	VaseDialogue.AddItem("If another player tries to use a vase your hiding in, ...");
	VaseDialogue.AddItem("it'll break and you'll be stunned.");
	VaseDialogue.AddItem("Press 'e' again to exit.");

	ShelfDialogue.AddItem("You can find Power Ups in shelfves like these.");
	ShelfDialogue.AddItem("Press 'e' to search the shelf.");
	ShelfDialogue.AddItem("Check the lower-left side of the screen to see if you've got something.");
	ShelfDialogue.AddItem("If so, press 'shift' to activate it.");
	ShelfDialogue.AddItem("If not try searching again.");

	FirstCheckPointDialogue.AddItem("Now let's practice what you learn.");
	FirstCheckPointDialogue.AddItem("Your first challenge is to sneak past the guard in the next room.");
	FirstCheckPointDialogue.AddItem("If you get caught, you'll be sent back here.");
	FirstCheckPointDialogue.AddItem("Good luck!");

	SecondCheckPointDialogue.AddItem("Good job.");
	SecondCheckPointDialogue.AddItem("Now for your final test.");
	SecondCheckPointDialogue.AddItem("Try to score a point.");
	SecondCheckPointDialogue.AddItem("Use everything you learned to good practice.");
	SecondCheckPointDialogue.AddItem("Good luck!");
	
	FinalDialogue.AddItem("Great job you've completed the tutorial level.");
	FinalDialogue.AddItem("Now your ready to play.");
	FinalDialogue.AddItem("Have fun online and we hope you enjoy your game.");*/
	
	//State isn't used but set to keep things from accidently activating 
	changeToTutorialState('WaitOnFirstLoad');

	//Sets timer that automatically scrolls through currentDialogue every five seconds
	SetTimer(timeBetweenLines, true, 'readNextDialogueEntry');
	PauseTimer(true, 'readNextDialogueEntry');

	//changeToTutorialState('HowToMove');
}

//Since text scrolls every # seconds, this function lets user speed read
exec function skipLine()
{
	//Need to test first
	if(isActive)
	{
		ClearTimer('readNextDialogueEntry');
		SetTimer(timeBetweenLines, false, 'readNextDialogueEntry');
		readNextDialogueEntry();
	}
}

//Timer function that reads arrays associated with a state
function readNextDialogueEntry()
{
	local string entry;
	local int count;
	local PathNode node;
	local GuideTrigger guideTrigger;
	local Rotator rotate;
	local SneaktoSlimAIPawn aiPawn;
	local SneaktoSlimPawn_FatLady lady;
	local SneaktoSlimPlayerController_FatLady pclady;

	//Stops if all dialogue has been read
	if(currentDialogue.Length == 0)
	{
		isActive = false;
		talkingTo.hideTutorialTextObject();
		PauseTimer(true, 'readNextDialogueEntry');

		//Moves guard by treasure to home base and switches its dialogue and state
		if(currentState == "ExplainTreasure")
		{
			foreach WorldInfo.AllActors(class'PathNode', node)
			{
				if(string(node.Tag) == "HomeBase")
				{
					self.Pawn.SetLocation(node.Location);
					rotate.Yaw = self.Pawn.Rotation.Yaw - (90*DegToRad*RadToUnrRot);
					self.SetRotation(rotate);
				}
			}
			foreach WorldInfo.AllActors(class'GuideTrigger', guideTrigger)
			{
				if(string(guideTrigger.Tag) == "ExplainTreasure")
					guideTrigger.Tag = 'ExplainGuards';
			}
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
		foreach WorldInfo.AllActors(class'GuideTrigger', guideTrigger)
		{
			if(string(guideTrigger.Tag) == "ExplainGuards")
				guideTrigger.Tag = 'ExplainAbilities';
		}
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
					pclady = Spawn(class 'SneaktoSlimPlayerController_FatLady',,,node.Location);
					lady.isGotTreasure = true;
					pclady.GotoState('HoldingTreasure');
					lady.Controller = pclady;
					pclady.Pawn = lady;
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
		if(currentState == "HowToMove" && self.timeBetweenLines == 1 && currentDialogue.Length == 4)
		{
			self.timeBetweenLines = 5;
			ClearTimer('readNextDialogueEntry');
			SetTimer(timeBetweenLines, true, 'readNextDialogueEntry');
		}
	}
}
function activateGuide()
{
	local SneaktoSlimGuideController guide;

	//Deactivates all other guide controllers
	foreach WorldInfo.AllControllers(class'SneaktoSlimGuideController', guide)
	{
		guide.isActive = false;
		guide.ClearTimer('readNextDialogueEntry');
		if(guide.currentState != "HowToMove")
			guide.timeBetweenLines = 5;
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
function changeToTutorialState(name stateName)
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
			timeBetweenLines = 1;
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

DefaultProperties
{
}
