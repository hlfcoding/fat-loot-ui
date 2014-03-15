class SneaktoSlimGFxMap extends GFxMoviePlayer;

var float screenSizeX, screenSizeY;
var GFxObject Map, playerIcon, demoTime, winnerDisplayText, winnerDisplayBackground, minimapText;
var MiniMap miniMap;
var Texture2D mapTexture;
var vector player2DScreenPoint;
var String mapName, mapPath;
var array<GFxObject> allFlashObjects;
var float flashMapX, flashMapY, flashMapWidth, flashMapHeight, scaleFactorX, scaleFactorY;
var array<Texture2D> minimaps;
var bool isHUDSet;

function Init(optional LocalPlayer player)
{
	super.Init(player);
	Start();
	Advance(0.0f);

	minimapText = GetVariableObject("_root.Minimap_text");
	if(SneaktoSlimPlayerController(GetPC()).PlayerInput.bUsingGamepad)
		minimapText.SetText("Press 'B'");
	else
		minimapText.SetText("Click 'm'");
	Map = GetVariableObject("_root.Minimap");
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
	allFlashObjects.AddItem(minimapText);
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
	isHUDSet = false;
	scaleFactorX = 1;
	scaleFactorY = 1;
}

//Turns on/off appropriate head images on the energy bar
function setMiniMapHead(string character)
{
	//"FatLady"
	//"GinsengBaby"
	//"Rabbit"
	//"Shorty"
	if(character == "FatLady")
	{
		playerIcon.GetObject("lady_head").SetBool("visible", true);	
		playerIcon.GetObject("bunny_head").SetBool("visible", false);	
		playerIcon.GetObject("shorty_head").SetBool("visible", false);	
		playerIcon.GetObject("baby_head").SetBool("visible", false);	
		isHUDSet = true;
	}
	if(character == "Shorty")
	{
		playerIcon.GetObject("lady_head").SetBool("visible", false);	
		playerIcon.GetObject("bunny_head").SetBool("visible", false);	
		playerIcon.GetObject("shorty_head").SetBool("visible", true);	
		playerIcon.GetObject("baby_head").SetBool("visible", false);	
		isHUDSet = true;
	}
	if(character == "Rabbit")
	{
		playerIcon.GetObject("lady_head").SetBool("visible", false);	
		playerIcon.GetObject("bunny_head").SetBool("visible", true);	
		playerIcon.GetObject("shorty_head").SetBool("visible", false);	
		playerIcon.GetObject("baby_head").SetBool("visible", false);	
		isHUDSet = true;
	}
	if(character == "GinsengBaby")
	{
		playerIcon.GetObject("lady_head").SetBool("visible", false);	
		playerIcon.GetObject("bunny_head").SetBool("visible", false);	
		playerIcon.GetObject("shorty_head").SetBool("visible", false);	
		playerIcon.GetObject("baby_head").SetBool("visible", true);	
		isHUDSet = true;
	}
}

function bool setMapTexture()
{
	local Texture2D icon;
	local int mapIndex;

	//Hides minimap for all levels that aren't these
	if(!(mapName == "demoday" || mapName == "fltemplemap" || mapName == "flmist"))
	{
		Map.SetBool("visible", false);
		playerIcon.SetBool("visible", false);
		GetVariableObject("_root").GetObject("Minimap_text").SetBool("visible", false);
		return false;
	}

	if(mapTexture == NONE)
	{
		//Sets player icon image
		/*icon = Texture2D 'Test.player_icon_image';
		if(icon == NONE)
			return false;
		SetExternalTexture("player_icon_image", icon);*/
	//	if(!(InStr(mapPath, "demoday") != -1 || InStr(mapPath, "fltemplemap") != -1))
			//return false;
		if(InStr(mapPath, "demoday") != -1)
			mapIndex = 0 ;
		else if(InStr(mapPath, "fltemplemap") != -1)
			mapIndex = 1;
		else if(InStr(mapPath, "flmist") != -1)
			mapIndex = 2;
		else 
			return false;

		//Sets minimap image texture
		mapTexture = minimaps[mapIndex];
		if(mapTexture == NONE)
			return false;
		SetExternalTexture("map_image", mapTexture);
	}
	return true;
}

//Called in HUD class' tick and passes in the canvas size
function scaleObjects(float x, float y)
{
	local GFxObject flashObj;

	if(x != screenSizeX && y != screenSizeY)
	{
		scaleFactorX = x/screenSizeX;
		scaleFactorY = y/screenSizeY;

		if(scaleFactorX < 1)
			scaleFactorX = 1;
		if(scaleFactorY < 1)
			scaleFactorY = 1;

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

		//Same as fltemplemap but extra calculations for map margins are considered
		if(mapName == "demoday")
		{
			if(!miniMap.isOn)
			{
				Map.SetFloat("width", flashMapWidth*scaleFactorX);
				Map.SetFloat("height", flashMapHeight*scaleFactorY);
				Map.SetFloat("x", screenSizeX - (flashMapWidth+10)*scaleFactorX);
				Map.SetFloat("y", screenSizeY - (flashMapHeight+10)*scaleFactorY);

				/*`log("x " $ Map.GetFloat("x"));
				`log("x prime " $ (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")));
				`log("W " $ Map.GetFloat("width"));
				`log("W prime " $ (Map.GetFloat("width")*70/150));
				`log("A ratio " $ 1 - (screenSizeX - player2DScreenPoint.X)/screenSizeX);*/

				//Passes player relative location to its controller for tracking/metric purposes
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint.X *= Map.GetFloat("width");   
				player2DScreenPoint.Y *= Map.GetFloat("height"); 

				transformedX = screenSizeX - Map.GetFloat("width") + player2DScreenPoint.X;
				transformedY = screenSizeY - Map.GetFloat("height") + player2DScreenPoint.Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - 70*scaleFactorX - 40*scaleFactorX + Map.GetFloat("x")) + (70*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - 117*scaleFactorY - 18*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.SetFloat("x", transformedX-(10*scaleFactorX));
				playerIcon.SetFloat("y", transformedY-(10*scaleFactorY));
			}
			else
			{
				Map.SetFloat("width", screenSizeX);
				Map.SetFloat("height", screenSizeY);
				Map.SetFloat("x", 0);
				Map.SetFloat("y", 0);
			
				//Passes player relative location to its controller for tracking/metric purposes
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				//Scales values to match screen size
				player2DScreenPoint.X *= screenSizeX;   
				player2DScreenPoint.Y *= screenSizeY; 
				transformedX = player2DScreenPoint.X;
				transformedY = player2DScreenPoint.Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((player2DScreenPoint.X - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((player2DScreenPoint.Y - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.SetFloat("x", transformedX);
				playerIcon.SetFloat("y", transformedY);
			}
		}
		//Same as demoday but extra calculations for map margins are ignored
		else if(mapName == "fltemplemap")
		{
			if(!miniMap.isOn)
			{
				Map.SetFloat("width", flashMapWidth*scaleFactorX);
				Map.SetFloat("height", flashMapHeight*scaleFactorY);
				Map.SetFloat("x", screenSizeX - (flashMapWidth+10)*scaleFactorX);
				Map.SetFloat("y", screenSizeY - (flashMapHeight+10)*scaleFactorY);

				/*`log("x " $ Map.GetFloat("x"));
				`log("x prime " $ (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")));
				`log("W " $ Map.GetFloat("width"));
				`log("W prime " $ (Map.GetFloat("width")*70/150));
				`log("A ratio " $ 1 - (screenSizeX - player2DScreenPoint.X)/screenSizeX);*/

				//Passes player relative location to its controller for tracking/metric purposes
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint.X *= Map.GetFloat("width");   
				player2DScreenPoint.Y *= Map.GetFloat("height"); 

				transformedX = screenSizeX - Map.GetFloat("width") + player2DScreenPoint.X;
				transformedY = screenSizeY - Map.GetFloat("height") + player2DScreenPoint.Y;

				/*//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - 70*scaleFactorX - 40*scaleFactorX + Map.GetFloat("x")) + (70*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - 117*scaleFactorY - 18*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));*/

				playerIcon.SetFloat("x", transformedX-(10*scaleFactorX));
				playerIcon.SetFloat("y", transformedY-(10*scaleFactorY));
			}
			else
			{
				Map.SetFloat("width", screenSizeX);
				Map.SetFloat("height", screenSizeY);
				Map.SetFloat("x", 0);
				Map.SetFloat("y", 0);

				//Passes player relative location to its controller for tracking/metric purposes
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				//Scales values to match screen size
				player2DScreenPoint.X *= screenSizeX;   
				player2DScreenPoint.Y *= screenSizeY; 
				transformedX = player2DScreenPoint.X;
				transformedY = player2DScreenPoint.Y;

				/*//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((player2DScreenPoint.X - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((player2DScreenPoint.Y - Map.GetFloat("y"))/Map.GetFloat("height")));*/

				playerIcon.SetFloat("x", transformedX);
				playerIcon.SetFloat("y", transformedY);
			}
		}
		//Same as demoday but extra calculations for map margins are ignored
		else if(mapName == "flmist")
		{
			if(!miniMap.isOn)
			{
				Map.SetFloat("width", flashMapWidth*scaleFactorX);
				Map.SetFloat("height", flashMapHeight*scaleFactorY);
				Map.SetFloat("x", screenSizeX - (flashMapWidth+10)*scaleFactorX);
				Map.SetFloat("y", screenSizeY - (flashMapHeight+10)*scaleFactorY);

				/*`log("x " $ Map.GetFloat("x"));
				`log("x prime " $ (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")));
				`log("W " $ Map.GetFloat("width"));
				`log("W prime " $ (Map.GetFloat("width")*70/150));
				`log("A ratio " $ 1 - (screenSizeX - player2DScreenPoint.X)/screenSizeX);*/

				//Passes player relative location to its controller for tracking/metric purposes
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint.X *= Map.GetFloat("width");   
				player2DScreenPoint.Y *= Map.GetFloat("height"); 

				transformedX = screenSizeX - Map.GetFloat("width") + player2DScreenPoint.X;
				transformedY = screenSizeY - Map.GetFloat("height") + player2DScreenPoint.Y;

				/*//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - 70*scaleFactorX - 40*scaleFactorX + Map.GetFloat("x")) + (70*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - 117*scaleFactorY - 18*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));*/

				playerIcon.SetFloat("x", transformedX-(10*scaleFactorX));
				playerIcon.SetFloat("y", transformedY-(10*scaleFactorY));
			}
			else
			{
				Map.SetFloat("width", screenSizeX);
				Map.SetFloat("height", screenSizeY);
				Map.SetFloat("x", 0);
				Map.SetFloat("y", 0);

				//Passes player relative location to its controller for tracking/metric purposes
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				//Scales values to match screen size
				player2DScreenPoint.X *= screenSizeX;   
				player2DScreenPoint.Y *= screenSizeY; 
				transformedX = player2DScreenPoint.X;
				transformedY = player2DScreenPoint.Y;

				/*//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((player2DScreenPoint.X - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((player2DScreenPoint.Y - Map.GetFloat("y"))/Map.GetFloat("height")));*/

				playerIcon.SetFloat("x", transformedX);
				playerIcon.SetFloat("y", transformedY);
			}
		}
		//else
			//`log("Scaleform map conversions not set to this map");
	}
}

DefaultProperties
{ 
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.MiniMap'
	//bGammaCorrection = false
	minimaps[0] = Texture2D'sneaktoslimimages.DemoDayTopDownMap'
	minimaps[1] = Texture2D'sneaktoslimimages.fltempleTopDownMap'
	minimaps[2] = Texture2D'sneaktoslimimages.flmistTopDownMap'
}
