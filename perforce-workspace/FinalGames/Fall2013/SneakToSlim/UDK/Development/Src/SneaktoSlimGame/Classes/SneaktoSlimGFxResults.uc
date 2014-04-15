class SneaktoSlimGFxResults extends GFxMoviePlayer;

var array<GFxObject> allFlashObjects;
var GFxObject blackCurtain;
var float screenSizeX, screenSizeY;

function Init(optional LocalPlayer player)
{
	//local GFxObject HudMovieSize;
	super.Init(player);
	Start();
	Advance(0.0f);

	blackCurtain = GetVariableObject("_root.BlackCurtain");

	allFlashObjects.AddItem(blackCurtain);

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
		blackCurtain.SetFloat("alpha", (blackCurtain.GetFloat("alpha") - 0.01));
}

DefaultProperties
{ 
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.ResultsScreen'
	//bGammaCorrection = false
}
