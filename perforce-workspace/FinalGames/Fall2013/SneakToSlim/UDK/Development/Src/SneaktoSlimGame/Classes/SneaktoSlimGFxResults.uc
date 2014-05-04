class SneaktoSlimGFxResults extends GFxMoviePlayer;

var array<GFxObject> allFlashObjects;
var GFxObject blackCurtain, continueText;
var GFxObject player1Score, player2Score, player3Score, player4Score;
var float screenSizeX, screenSizeY;

function Init(optional LocalPlayer player)
{
	//local GFxObject HudMovieSize;
	super.Init(player);
	Start();
	Advance(0.0f);

	blackCurtain = GetVariableObject("_root.BlackCurtain");
	blackCurtain.SetInt("x", 0);
	blackCurtain.SetInt("y", 0);
	continueText = GetVariableObject("_root.ContinueText");
	continueText.SetBool("visible", false);

	player1Score = GetVariableObject("_root.scoreboard_one");
	player1Score.ActionScriptVoid("init");
	player1Score.SetBool("isOn", false);
	player2Score = GetVariableObject("_root.scoreboard_two");
	player2Score.ActionScriptVoid("init");
	player2Score.SetBool("isOn", false);
	player3Score = GetVariableObject("_root.scoreboard_three");
	player3Score.ActionScriptVoid("init");
	player3Score.SetBool("isOn", false);
	player4Score = GetVariableObject("_root.scoreboard_four");
	player4Score.ActionScriptVoid("init");
	player4Score.SetBool("isOn", false);

	allFlashObjects.AddItem(blackCurtain);
	allFlashObjects.AddItem(continueText);
	allFlashObjects.AddItem(player1Score);
	allFlashObjects.AddItem(player2Score);
	allFlashObjects.AddItem(player3Score);
	allFlashObjects.AddItem(player4Score);

	screenSizeX = 1280;
	screenSizeY = 720;
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
	local SneaktoSlimPlayerController_Results player;

	player = SneaktoSlimPlayerController_Results(GetPC());

	if(player == None)
		return;

	if(blackCurtain.GetFloat("alpha") > 0)
		blackCurtain.SetFloat("alpha", (blackCurtain.GetFloat("alpha") - 0.03));
}

DefaultProperties
{ 
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.ResultsScreen'
	//bGammaCorrection = false
}
