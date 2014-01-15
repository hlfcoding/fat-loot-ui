class SneaktoSlimGFxHUD extends GFxMoviePlayer;

var int lastPlayerHealth, healthBarLength;
var float screenSizeX, screenSizeY;
var GFxObject HealthBar, InvisibilityIcon, PowerupBackdrop, InstructionText, CountdownText;
var GFxObject player1Score, player2Score, player3Score, player4Score, PromptText;
var GFxObject SpottedIcon, ClothIcon;
var array<GFxObject> allFlashObjects;

function Init(optional LocalPlayer player)
{
	//local GFxObject HudMovieSize;
	super.Init(player);
	Start();
	Advance(0.0f);

	lastPlayerHealth = 100;

	HealthBar = GetVariableObject("_root.stamina_bar");
	InvisibilityIcon = GetVariableObject("_root.InvisibilityIcon");
	ClothIcon = GetVariableObject("_root.Cloth_Icon");
	PowerupBackdrop = GetVariableObject("_root.PowerUpBackdrop");
	InstructionText = GetVariableObject("_root.HowToUseInstruction");
	CountdownText = GetVariableObject("_root.CountdownText");
	PromptText = GetVariableObject("_root.PromptText");
	SpottedIcon = GetVariableObject("_root.warning_sign");
	player1Score = GetVariableObject("_root.scoreboard_one");
	player1Score.ActionScriptVoid("init");
	player2Score = GetVariableObject("_root.scoreboard_two");
	player2Score.ActionScriptVoid("init");
	player3Score = GetVariableObject("_root.scoreboard_three");
	player3Score.ActionScriptVoid("init");
	player4Score = GetVariableObject("_root.scoreboard_four");
	player4Score.ActionScriptVoid("init");

	//Adds all objects to array for when screen size is changed
	allFlashObjects.AddItem(HealthBar);
	allFlashObjects.AddItem(InvisibilityIcon);
	allFlashObjects.AddItem(ClothIcon);
	allFlashObjects.AddItem(PowerupBackdrop);
	allFlashObjects.AddItem(InstructionText);
	allFlashObjects.AddItem(CountdownText);
	allFlashObjects.AddItem(PromptText);
	allFlashObjects.AddItem(SpottedIcon);
	allFlashObjects.AddItem(player1Score);
	allFlashObjects.AddItem(player2Score);
	allFlashObjects.AddItem(player3Score);
	allFlashObjects.AddItem(player4Score);

	//Hardcode original flash size size
	screenSizeX = 1280;
	screenSizeY = 720;
	//TODO? Create square in flash as background
	//HudMovieSize = self.GetVariableObject("Stage");
	//`log("Movie Dimensions: " @ int(HudMovieSize.GetFloat("width")) @ "x" @ int(HudMovieSize.GetFloat("height")));

	healthBarLength = GetVariableObject("_root.stamina_bar.currentBar").GetInt("width");
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

function TickHud(float DeltaTime)
{
	local SneaktoSlimPlayerController player;
	local GFxObject root;

	player = SneaktoSlimPlayerController(GetPC());

	if(player == None)
		return;

	root = GetVariableObject("_root");
	if(!SneaktoSlimPlayerController(GetPC()).uiOn)
	{
		root.SetBool("visible", false);
	}
	else
		root.SetBool("visible", true);

	//Only updates if health is different
	if(lastPlayerHealth != SneaktoSlimPawn(player.Pawn).v_energy)
	{
		lastPlayerHealth = SneaktoSlimPawn(player.Pawn).v_energy;
		//Sets healthbar's custom variable which the script uses to change its own color
		HealthBar.SetInt("currentHealth", lastPlayerHealth);   
		//Scales according to width size
		GetVariableObject("_root.stamina_bar.currentBar").SetInt("width", (lastPlayerHealth * healthBarLength /100));
	}
}

DefaultProperties
{ 
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.HUD'
	//bGammaCorrection = false
}
