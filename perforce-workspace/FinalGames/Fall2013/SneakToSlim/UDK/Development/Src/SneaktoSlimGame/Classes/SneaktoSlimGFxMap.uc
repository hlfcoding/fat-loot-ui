class SneaktoSlimGFxMap extends GFxMoviePlayer;

var float screenSizeX, screenSizeY;
var GFxObject Map, playerIcon, demoTime, winnerDisplayText, winnerDisplayBackground;
var MiniMap miniMap;
var Texture2D mapTexture;
var vector player2DScreenPoint;
var String mapName, mapPath;
var array<GFxObject> allFlashObjects;
var float flashMapX, flashMapY, flashMapWidth, flashMapHeight;

function Init(optional LocalPlayer player)
{
	super.Init(player);
	Start();
	Advance(0.0f);

	Map = GetVariableObject("_root.Map");
	flashMapX = Map.GetFloat("x");
	flashMapY = Map.GetFloat("y");
	flashMapHeight = Map.GetFloat("height");
	flashMapWidth = Map.GetFloat("width");
	playerIcon = GetVariableObject("_root.player_icon");
	demoTime = GetVariableObject("_root.DemoTimeText");
	demoTime.setBool("isOn", false);
	winnerDisplayText = GetVariableObject("_root.WinnerDisplayText");
	winnerDisplayText.setBool("isOn", false);
	winnerDisplayBackground = GetVariableObject("_root.WinnerDisplayBackground");
	winnerDisplayBackground.setBool("isOn", false);

	//Adds all objects to array for when screen size is changed
	allFlashObjects.AddItem(Map);
	allFlashObjects.AddItem(playerIcon);
	allFlashObjects.AddItem(demoTime);
	allFlashObjects.AddItem(winnerDisplayText);
	allFlashObjects.AddItem(winnerDisplayBackground);

	//Hardcode original flash size size
	screenSizeX = 1280;
	screenSizeY = 720;
	//TODO? Create square in flash as background
	//HudMovieSize = self.GetVariableObject("Stage");
	//`log("Movie Dimensions: " @ int(HudMovieSize.GetFloat("width")) @ "x" @ int(HudMovieSize.GetFloat("height")));
}

function bool setMapTexture()
{
	if(mapTexture == NONE)
	{
		mapTexture = Texture2D(DynamicLoadObject(mapPath,class'Texture2D'));
		if(mapTexture == NONE)
			return false;
		SetExternalTexture("DemoDayMap", mapTexture);
	}
	return true;
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

function TickMap(float DeltaTime)
{
	local SneaktoSlimPlayerController player; 
	local float transformedX, transformedY;
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
	{
		root.SetBool("visible", true);
	}

	if(miniMap != NONE)
	{
		if(!setMapTexture())
			return;
		//Map.SetBool("isOn", miniMap.isOn);
		//playerIcon.SetBool("isOn", miniMap.isOn);
		if(!miniMap.isOn)
		{
			Map.SetFloat("width", flashMapWidth);
			Map.SetFloat("height", flashMapHeight);
			Map.SetFloat("x", screenSizeX - flashMapWidth);
			Map.SetFloat("y", screenSizeY - flashMapHeight);

			/*`log("x " $ Map.GetFloat("x"));
			`log("x prime " $ (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")));
			`log("W " $ Map.GetFloat("width"));
			`log("W prime " $ (Map.GetFloat("width")*70/150));
			`log("A ratio " $ 1 - (screenSizeX - player2DScreenPoint.X)/screenSizeX);*/

			transformedX = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * (1 - (screenSizeX - player2DScreenPoint.X)/screenSizeX));
			transformedY = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * (1 - (screenSizeY - player2DScreenPoint.Y)/screenSizeY));

			transformedY -= Map.GetFloat("height")/flashMapHeight*1.5*playerIcon.getFloat("height");

			playerIcon.SetFloat("x", transformedX);
			playerIcon.SetFloat("y", transformedY);
		}
		else
		{
			Map.SetFloat("width", screenSizeX);
			Map.SetFloat("height", screenSizeY);
			Map.SetFloat("x", 0);
			Map.SetFloat("y", 0);
			
			transformedX = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((player2DScreenPoint.X - Map.GetFloat("x"))/Map.GetFloat("width")));
			transformedY = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((player2DScreenPoint.Y - Map.GetFloat("y"))/Map.GetFloat("height")));
			
			transformedY -= Map.GetFloat("height")/flashMapHeight*1.5*playerIcon.getFloat("height");

			playerIcon.SetFloat("x", transformedX);
			playerIcon.SetFloat("y", transformedY);
		}
	}
}

DefaultProperties
{ 
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.MiniMap'
	//bGammaCorrection = false
}
