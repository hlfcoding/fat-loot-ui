class SneaktoSlimGFxHUD extends GFxMoviePlayer;

var int lastPlayerHealth, healthBarLength;
var float screenSizeX, screenSizeY;
var GFxObject HealthBar, InvisibilityIcon, PowerupBackdrop, PowerupTimerBackdrop, CountdownText;
var GFxObject player1Score, player2Score, player3Score, player4Score, PromptText, TutorialText, TimeUpText;
var GFxObject SpottedIcon, ClothIcon, ThunderIcon, TeaIcon, SuperSprintIcon, CurseIcon, TimerText, blackCurtain;
var array<GFxObject> allFlashObjects;
var bool isHUDSet;
var bool flashCurtain, increaseAlpha;

function Init(optional LocalPlayer player)
{
	//local GFxObject HudMovieSize;
	super.Init(player);
	Start();
	Advance(0.0f);

	lastPlayerHealth = 100;

	HealthBar = GetVariableObject("_root.stamina_bar");
	TutorialText = GetVariableObject("_root.TutorialText");
	TutorialText.GetObject("TutorialText").SetText("");
	if(SneaktoSlimPlayerController(GetPC()).PlayerInput.bUsingGamepad)
		TutorialText.GetObject("SkipLineText").SetText("Press 'B' to skip");
	else
		TutorialText.GetObject("SkipLineText").SetText("Press 'space' to skip");
	TutorialText.SetBool("visible", false);
	InvisibilityIcon = GetVariableObject("_root.InvisibilityIcon");
	ClothIcon = GetVariableObject("_root.Cloth_Icon");
	ThunderIcon = GetVariableObject("_root.Thunder_Icon");
	TeaIcon = GetVariableObject("_root.TeaIcon"); 
	SuperSprintIcon = GetVariableObject("_root.SpeedBoost");
	CurseIcon = GetVariableObject("_root.CurseIcon");  
	PowerupBackdrop = GetVariableObject("_root.PowerUpBackdrop");
	PowerupTimerBackdrop = GetVariableObject("_root.PowerUpBackGround");
	CountdownText = GetVariableObject("_root.CountdownText");
	PromptText = GetVariableObject("_root.PromptText");
	blackCurtain = GetVariableObject("_root.BlackCurtain");
	blackCurtain.SetInt("x", 0);
	blackCurtain.SetInt("y", 0);
	SpottedIcon = GetVariableObject("_root.warning_sign");
	player1Score = GetVariableObject("_root.scoreboard_one");
	player1Score.GetObject("Coin").SetBool("visible", false);
	player1Score.ActionScriptVoid("init");
	player2Score = GetVariableObject("_root.scoreboard_two");
	player2Score.GetObject("Coin").SetBool("visible", false);
	player2Score.ActionScriptVoid("init");
	player3Score = GetVariableObject("_root.scoreboard_three");
	player3Score.GetObject("Coin").SetBool("visible", false);
	player3Score.ActionScriptVoid("init");
	player4Score = GetVariableObject("_root.scoreboard_four");
	player4Score.GetObject("Coin").SetBool("visible", false);
	player4Score.ActionScriptVoid("init");
	TimerText = GetVariableObject("_root.TimerText");
	TimerText.ActionScriptVoid("init");
	TimerText.SetBool("isOn", false);
	TimeUpText = GetVariableObject("_root.TimeUpText");

	//Adds all objects to array for when screen size is changed
	allFlashObjects.AddItem(HealthBar);
	allFlashObjects.AddItem(InvisibilityIcon);
	allFlashObjects.AddItem(ClothIcon);
	allFlashObjects.AddItem(ThunderIcon);
	allFlashObjects.AddItem(TeaIcon);
	allFlashObjects.AddItem(SuperSprintIcon);
	allFlashObjects.AddItem(CurseIcon);
	allFlashObjects.AddItem(PowerupBackdrop);
	allFlashObjects.AddItem(PowerupTimerBackdrop);
	allFlashObjects.AddItem(CountdownText);
	allFlashObjects.AddItem(PromptText);
	allFlashObjects.AddItem(TutorialText);
	allFlashObjects.AddItem(SpottedIcon);
	allFlashObjects.AddItem(blackCurtain);
	allFlashObjects.AddItem(player1Score);
	allFlashObjects.AddItem(player2Score);
	allFlashObjects.AddItem(player3Score);
	allFlashObjects.AddItem(player4Score);
	allFlashObjects.AddItem(TimerText);
	allFlashObjects.AddItem(TimeUpText);

	//Hardcode original flash size size
	screenSizeX = 1280;
	screenSizeY = 720;
	//TODO? Create square in flash as background
	//HudMovieSize = self.GetVariableObject("Stage");
	//`log("Movie Dimensions: " @ int(HudMovieSize.GetFloat("width")) @ "x" @ int(HudMovieSize.GetFloat("height")));

	healthBarLength = GetVariableObject("_root.stamina_bar.currentBar").GetInt("width");
	isHUDSet = false;
	flashCurtain = false;
	increaseAlpha = true;
}

//Turns on/off appropriate head images on the energy bar
function setHealthBarHead(string character)
{
	//"FatLady"
	//"GinsengBaby"
	//"Rabbit"
	//"Shorty"
	if(character == "FatLady")
	{
		HealthBar.GetObject("lady_head").SetBool("visible", true);	
		HealthBar.GetObject("bunny_head").SetBool("visible", false);	
		HealthBar.GetObject("shorty_head").SetBool("visible", false);	
		HealthBar.GetObject("baby_head").SetBool("visible", false);	
		isHUDSet = true;
	}
	if(character == "Shorty")
	{
		HealthBar.GetObject("lady_head").SetBool("visible", false);	
		HealthBar.GetObject("bunny_head").SetBool("visible", false);	
		HealthBar.GetObject("shorty_head").SetBool("visible", true);	
		HealthBar.GetObject("baby_head").SetBool("visible", false);	
		isHUDSet = true;
	}
	if(character == "Rabbit")
	{
		HealthBar.GetObject("lady_head").SetBool("visible", false);	
		HealthBar.GetObject("bunny_head").SetBool("visible", true);	
		HealthBar.GetObject("shorty_head").SetBool("visible", false);	
		HealthBar.GetObject("baby_head").SetBool("visible", false);	
		isHUDSet = true;
	}
	if(character == "GinsengBaby")
	{
		HealthBar.GetObject("lady_head").SetBool("visible", false);	
		HealthBar.GetObject("bunny_head").SetBool("visible", false);	
		HealthBar.GetObject("shorty_head").SetBool("visible", false);	
		HealthBar.GetObject("baby_head").SetBool("visible", true);	
		isHUDSet = true;
	}
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
	//if(lastPlayerHealth != SneaktoSlimPawn(player.Pawn).v_energy)
	//{
		lastPlayerHealth = SneaktoSlimPawn(player.Pawn).v_energy;
		//Sets healthbar's custom variable which the script uses to change its own color
		HealthBar.SetInt("currentHealth", lastPlayerHealth);   
		//Scales according to width size
		//GetVariableObject("_root.stamina_bar.currentBar").SetInt("width", (lastPlayerHealth * healthBarLength /100));
	//}

	if(flashCurtain)
	{
		if(increaseAlpha)
		{
			blackCurtain.SetFloat("alpha", (blackCurtain.GetFloat("alpha") + 0.05));
			if(blackCurtain.GetFloat("alpha") >= 1.0)
			{
				flashCurtain = false;
			}
		}
		else
		{
			blackCurtain.SetFloat("alpha", (blackCurtain.GetFloat("alpha") - 0.05));
			if(blackCurtain.GetFloat("alpha") <= 0.0)
			{
				flashCurtain = false;
			}
		}
	}
}

DefaultProperties
{ 
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.HUD'
	//bGammaCorrection = false
}
