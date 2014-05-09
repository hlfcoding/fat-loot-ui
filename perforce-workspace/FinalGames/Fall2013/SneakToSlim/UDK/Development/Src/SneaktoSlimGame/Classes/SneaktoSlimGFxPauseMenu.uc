class SneaktoSlimGFxPauseMenu extends GFxMoviePlayer;

var array<GFxObject> allFlashObjects;
var GFxObject background, resume_button, quit_button, mouse_cursor;
var float screenSizeX, screenSizeY;

function Init(optional LocalPlayer player)
{
	super.Init(player);
	Start();
	Advance(0.0f);

	`log("Using Gamepad: (STSGFxPause init) " $ SneaktoSlimPawn(SneaktoSlimPlayerController(GetPC()).Pawn).getIsUsingXboxController());
	if(SneaktoSlimPawn(SneaktoSlimPlayerController(GetPC()).Pawn).getIsUsingXboxController())
	{
		GetVariableObject("_root.mouse").SetBool("visible", false);
	}
	else
	{
		mouse_cursor = GetVariableObject("_root.mouse");
	}
	quit_button = GetVariableObject("_root.quit");
	resume_button = GetVariableObject("_root.resume");
	background = GetVariableObject("_root.background");

	//Adds all objects to array for when screen size is changed
	allFlashObjects.AddItem(resume_button);
	allFlashObjects.AddItem(quit_button);
	allFlashObjects.AddItem(background);
	allFlashObjects.AddItem(mouse_cursor);

	//Hardcode original flash size size
	screenSizeX = 1280;
	screenSizeY = 720;
	//TODO? Create square in flash as background
	//HudMovieSize = self.GetVariableObject("Stage");
	//`log("Movie Dimensions: " @ int(HudMovieSize.GetFloat("width")) @ "x" @ int(HudMovieSize.GetFloat("height")));
}

//Called in HUD class' tick and passes in the canvas size
function scaleObjects(float x, float y)
{
	local GFxObject flashObj;

	if(x != screenSizeX && y != screenSizeY)
	{
		//Changes objects size and dimensions to match new screen size
		foreach allFlashObjects(flashObj)
		{
			flashObj.SetFloat("width", flashObj.GetFloat("width")/screenSizeX * x);
			flashObj.SetFloat("height", flashObj.GetFloat("height")/screenSizeY * y);
			flashObj.SetFloat("x", flashObj.GetFloat("x")/screenSizeX * x);
			flashObj.SetFloat("y", flashObj.GetFloat("y")/screenSizeY * y);
		}
		screenSizeX = x;
		screenSizeY = y;
	}
}

//When resume button in flash is clicked actionscript calls this method which 
//toggles the pause menu like pressing the 'ESC' key in player controller 
function resumeIsClicked()
{
	local SneaktoSlimPlayerController player; 

	player = SneaktoSlimPlayerController(GetPC());
	player.togglePauseMenu();
}

//TODO
function quitIsClicked()
{
	local SneaktoSlimPlayerController player; 

	player = SneaktoSlimPlayerController(GetPC());

	if(player == None)
		return;

	player.prepForQuit();
	SneaktoSlimPawn(player.Pawn).QuitCurrentGame();
}

function TickMap(float DeltaTime)
{
	local SneaktoSlimPlayerController player; 
	local GFxObject root;

	player = SneaktoSlimPlayerController(GetPC());

	if(player == None)
		return;

	root = GetVariableObject("_root");
	if(!SneaktoSlimPlayerController(GetPC()).pauseMenuOn)
	{
		root.SetBool("visible", false);
	}
	else
	{
		root.SetBool("visible", true);
	}
}

DefaultProperties
{
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.PauseMenu'
}
