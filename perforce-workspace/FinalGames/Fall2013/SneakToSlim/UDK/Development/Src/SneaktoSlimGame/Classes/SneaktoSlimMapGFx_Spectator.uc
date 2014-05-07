class SneaktoSlimMapGFx_Spectator extends GFxMoviePlayer;

var float screenSizeX, screenSizeY;
var GFxObject Map, playerIcon, demoTime, winnerDisplayText, winnerDisplayBackground, minimapText, rect, MapBackground;
var MiniMap miniMap;
var Texture2D mapTexture;
var vector player2DScreenPoint[4];
var String mapName, mapPath;
var array<GFxObject> allFlashObjects;
var float flashMapX, flashMapY, flashMapWidth, flashMapHeight, scaleFactorX, scaleFactorY;
var array<Texture2D> minimaps;
var float mouseRotation[4], faceRotation[4], playerIconWidth, playerIconHeight;
var int originalRectSize;
var bool isHUDSet, scalePlayerIcon;

function Init(optional LocalPlayer player)
{
	super.Init(player);
	Start();
	Advance(0.0f);

	minimapText = GetVariableObject("_root.Minimap_text");
	minimapText.SetBool("visible", false);
	if(SneaktoSlimPlayerController(GetPC()).PlayerInput.bUsingGamepad)
		minimapText.SetText("Press 'B'");
	else
		minimapText.SetText("Click 'm'");
	Map = GetVariableObject("_root.Minimap");
	MapBackground = GetVariableObject("_root.MiniMapBackground");
	MapBackground.SetFloat("alpha", 0.75);
	flashMapX = Map.GetFloat("x");
	flashMapY = Map.GetFloat("y");
	flashMapHeight = Map.GetFloat("height");
	flashMapWidth = Map.GetFloat("width");
	playerIcon = GetVariableObject("_root.player_icon");
	rect = GetVariableObject("_root.Rect");
	rect.SetBool("visible", false);
	originalRectSize = rect.GetInt("width");
	demoTime = GetVariableObject("_root.DemoTimeText");
	demoTime.setBool("isOn", false);
	winnerDisplayText = GetVariableObject("_root.WinnerDisplayText");
	winnerDisplayText.setBool("isOn", false);
	winnerDisplayBackground = GetVariableObject("_root.WinnerDisplayBackground");
	winnerDisplayBackground.setBool("isOn", false);

	//Adds all objects to array for when screen size is changed
	allFlashObjects.AddItem(Map);
	allFlashObjects.AddItem(MapBackground);
	allFlashObjects.AddItem(minimapText);
	//allFlashObjects.AddItem(playerIcon);
	allFlashObjects.AddItem(rect);
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
	scalePlayerIcon = false;
	scaleFactorX = 1;
	scaleFactorY = 1;
}

//Turns on/off appropriate head images
function setMiniMapHead(int playerIndex)
{
	local SneaktoSlimPlayerController player; 

	//Spectator
	if(playerIndex == 4)
	{
		playerIcon.SetFloat("x", 0);
		playerIcon.SetFloat("y", 0);
		playerIcon.GetObject("player1").SetBool("visible", false);	
		playerIcon.GetObject("player2").SetBool("visible", false);	    
		playerIcon.GetObject("player3").SetBool("visible", false);	    
		playerIcon.GetObject("player4").SetBool("visible", false);	
		isHUDSet = true;
	}

	player = SneaktoSlimPlayerController(GetPC());

	if(player == None)
		return;

	if(playerIndex == 0)
	{
		playerIcon.GetObject("player1").SetBool("visible", true);
		playerIcon.GetObject("player2").SetBool("visible", false);	   
		playerIcon.GetObject("player3").SetBool("visible", false);	    
		playerIcon.GetObject("player4").SetBool("visible", false);
		isHUDSet = true;
	}
	if(playerIndex == 1)
	{
		playerIcon.GetObject("player1").SetBool("visible", false);
		playerIcon.GetObject("player2").SetBool("visible", true);	    
		playerIcon.GetObject("player3").SetBool("visible", false);	   
		playerIcon.GetObject("player4").SetBool("visible", false);
		isHUDSet = true;
	}
	if(playerIndex == 2)
	{
		playerIcon.GetObject("player1").SetBool("visible", false);	
		playerIcon.GetObject("player2").SetBool("visible", false);	    
		playerIcon.GetObject("player3").SetBool("visible", true);	   
		playerIcon.GetObject("player4").SetBool("visible", false);	
		isHUDSet = true;
	}
	if(playerIndex == 3)
	{
		playerIcon.GetObject("player1").SetBool("visible", false);	
		playerIcon.GetObject("player2").SetBool("visible", false);	    
		playerIcon.GetObject("player3").SetBool("visible", false);	    
		playerIcon.GetObject("player4").SetBool("visible", true);	
		isHUDSet = true;
	}
}

function bool setMapTexture()
{
	//local Texture2D icon;
	local int mapIndex;

	//Hides minimap for all levels that aren't these
	if(!(mapName == "demoday" || mapName == "fltemplemaptopplatform" || mapName == "flmist"))
	{
		Map.SetBool("visible", false);
		MapBackground.SetBool("visible", false);
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
		else if(InStr(mapPath, "fltemplemaptopplatform") != -1)
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

function setFountainPoint(vector loc)
{
	local vector result;
	local float transformedX, transformedY;

	if(mapName == "demoday")
	{
		if(!miniMap.isOn)
		{
			loc.X *= Map.GetFloat("width");   
			loc.Y *= Map.GetFloat("height"); 

			transformedX = screenSizeX - Map.GetFloat("width") + loc.X;
			transformedY = screenSizeY - Map.GetFloat("height") + loc.Y;

			//Map specify conversion to scale point to ignore image margins
			transformedX = (Map.GetFloat("width") - 70*scaleFactorX - 40*scaleFactorX + Map.GetFloat("x")) + (70*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
			transformedY = (Map.GetFloat("height") - 117*scaleFactorY - 18*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));

			result.X = transformedX-(10*scaleFactorX);
			result.y = transformedY-(10*scaleFactorY);
		}
		else
		{
			//Scales values to match screen size
			loc.X *= screenSizeX;   
			loc.Y *= screenSizeY; 

			//Map specify conversion to scale point to ignore image margins
			result.X = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((loc.X - Map.GetFloat("x"))/Map.GetFloat("width")));
			result.Y = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((loc.Y - Map.GetFloat("y"))/Map.GetFloat("height")));
		}
	}
	else if(mapName == "fltemplemaptopplatform")
	{
		if(!miniMap.isOn)
		{
			loc.X *= Map.GetFloat("width");   
			loc.Y *= Map.GetFloat("height"); 

			transformedX = screenSizeX - Map.GetFloat("width") + loc.X;
			transformedY = screenSizeY - Map.GetFloat("height") + loc.Y;

			//Map specify conversion to scale point to ignore image margins
			transformedX = (Map.GetFloat("width") - 134*scaleFactorX - 8*scaleFactorX + Map.GetFloat("x")) + (134*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
			transformedY = (Map.GetFloat("height") - 134*scaleFactorY - 8*scaleFactorY + Map.GetFloat("y")) + (134*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));

			result.X = transformedX-(10*scaleFactorX);
			result.y = transformedY-(10*scaleFactorY);
		}
		else
		{
			//Scales values to match screen size
			loc.X *= screenSizeY;   
			loc.Y *= screenSizeY; 

			//Map specify conversion to scale point to ignore image margins
			result.X = (Map.GetInt("width") - (Map.GetInt("width") * 134/150) - (Map.GetInt("width")*8/150)) + ((Map.GetInt("width")*134/150) * (loc.X / Map.GetInt("width")));
			result.Y = (Map.GetInt("height") - (Map.GetInt("height") * 134/150) - (Map.GetInt("height")*8/150)) + ((Map.GetInt("height")*134/150) * (loc.Y / Map.GetInt("height")));
			result.X += ((screenSizeX - screenSizeY) / 2);
		}
	}
	else if(mapName == "flmist")
	{
		if(!miniMap.isOn)
		{
			loc.X *= Map.GetFloat("width");   
			loc.Y *= Map.GetFloat("height"); 

			transformedX = screenSizeX - Map.GetFloat("width") + loc.X;
			transformedY = screenSizeY - Map.GetFloat("height") + loc.Y;

			//Map specify conversion to scale point to ignore image margins
			transformedX = (Map.GetFloat("width") - 120*scaleFactorX - 15*scaleFactorX + Map.GetFloat("x")) + (120*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
			transformedY = (Map.GetFloat("height") - 120*scaleFactorY - 15*scaleFactorY + Map.GetFloat("y")) + (120*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));

			result.X = transformedX-(10*scaleFactorX);
			result.y = transformedY-(10*scaleFactorY);
		}
		else
		{
			//Scales values to match screen size
			loc.X *= screenSizeX;   
			loc.Y *= screenSizeY; 

			//Map specify conversion to scale point to ignore image margins
			result.X = (Map.GetInt("width") - (Map.GetInt("width") * 120/150) - (Map.GetInt("width")*15/150)) + ((Map.GetInt("width")*120/150) * (loc.X/Map.GetInt("width")));
			result.Y = (Map.GetInt("height") - (Map.GetInt("height") * 120/150) - (Map.GetInt("height")*15/150)) + ((Map.GetInt("height")*120/150) * (loc.Y/Map.GetInt("height")));
			//result.X += ((screenSizeX - screenSizeY) / 2);
		}
	}
	rect.SetFloat("x", result.X);
	rect.SetFloat("y", result.Y);

	//Causes rect to continuously spin
	rect.SetFloat("rotation", (rect.GetFloat("rotation") + 2));
	if(rect.GetInt("rotation") >= 360)
		rect.SetInt("rotation", 0);

	if(rect.GetInt("width") > originalRectSize && !miniMap.isOn)
	{
		`log("Width: " $ rect.GetInt("width") $ " | Height: " $ rect.GetInt("height"));
		if(rect.GetInt("width") - 60 >= originalRectSize)
		{
			rect.SetInt("width", (rect.GetInt("width") - 17));
			rect.SetInt("height", (rect.GetInt("height") - 17));
		}
		else
		{
			rect.SetInt("width", originalRectSize);
			rect.SetInt("height", originalRectSize);
		}
	}
}

function TickMap(float DeltaTime)
{
	local SneaktoSlimPlayerController_Spectator player; 
	local float transformedX[4], transformedY[4];
	local GFxObject root;

	player = SneaktoSlimPlayerController_Spectator(GetPC());

	if(player == None)
		return;

	/*root = GetVariableObject("_root");
	if(!SneaktoSlimPlayerController(GetPC()).uiOn)
	{
		root.SetBool("visible", false);
	}
	else
	{
		root.SetBool("visible", true);
	}*/

	if(miniMap != NONE)
	{
		if(!setMapTexture())
			return;
		//Map.SetBool("isOn", miniMap.isOn);
		//playerIcon.SetBool("isOn", miniMap.isOn);
	
		playerIcon.GetObject("player1").SetFloat("rotation", mouseRotation[0]);
		playerIcon.GetObject("player2").SetFloat("rotation", mouseRotation[1]);
		playerIcon.GetObject("player3").SetFloat("rotation", mouseRotation[2]);
		playerIcon.GetObject("player4").SetFloat("rotation", mouseRotation[3]);

		if(mapName == "demoday")
		{
			if(!miniMap.isOn)
			{
				//Reverts icon scale to be original size on first loop minimap is off, once
				if(scalePlayerIcon)
				{
					playerIcon.GetObject("player1").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player1").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player2").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player2").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player3").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player3").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player4").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player4").SetFloat("height", playerIconHeight);
					scalePlayerIcon = false;
				}

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
				//player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint[0].X *= Map.GetFloat("width");   
				player2DScreenPoint[0].Y *= Map.GetFloat("height"); 
				player2DScreenPoint[1].X *= Map.GetFloat("width");   
				player2DScreenPoint[1].Y *= Map.GetFloat("height");
				player2DScreenPoint[2].X *= Map.GetFloat("width");   
				player2DScreenPoint[2].Y *= Map.GetFloat("height");
				player2DScreenPoint[3].X *= Map.GetFloat("width");   
				player2DScreenPoint[3].Y *= Map.GetFloat("height");

				transformedX[0] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[0].X;
				transformedY[0] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[0].Y;
				transformedX[1] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[1].X;
				transformedY[1] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[1].Y;
				transformedX[2] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[2].X;
				transformedY[2] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[2].Y;
				transformedX[3] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[3].X;
				transformedY[3] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[3].Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX[0] = (Map.GetFloat("width") - 69*scaleFactorX - 35*scaleFactorX + Map.GetFloat("x")) + (69*scaleFactorX * ((transformedX[0] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[0] = (Map.GetFloat("height") - 117*scaleFactorY - 17*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY[0] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[1] = (Map.GetFloat("width") - 69*scaleFactorX - 35*scaleFactorX + Map.GetFloat("x")) + (69*scaleFactorX * ((transformedX[1] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[1] = (Map.GetFloat("height") - 117*scaleFactorY - 17*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY[1] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[2] = (Map.GetFloat("width") - 69*scaleFactorX - 35*scaleFactorX + Map.GetFloat("x")) + (69*scaleFactorX * ((transformedX[2] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[2] = (Map.GetFloat("height") - 117*scaleFactorY - 17*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY[2] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[3] = (Map.GetFloat("width") - 69*scaleFactorX - 35*scaleFactorX + Map.GetFloat("x")) + (69*scaleFactorX * ((transformedX[3] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[3] = (Map.GetFloat("height") - 117*scaleFactorY - 17*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY[3] - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.GetObject("player1").SetFloat("x", transformedX[0] - playerIcon.GetFloat("x"));
				playerIcon.GetObject("player1").SetFloat("y", transformedY[0] - playerIcon.GetFloat("y"));
				playerIcon.GetObject("player2").SetFloat("x", transformedX[1] - playerIcon.GetFloat("x"));
				playerIcon.GetObject("player2").SetFloat("y", transformedY[1] - playerIcon.GetFloat("y"));
				playerIcon.GetObject("player3").SetFloat("x", transformedX[2] - playerIcon.GetFloat("x"));
				playerIcon.GetObject("player3").SetFloat("y", transformedY[2] - playerIcon.GetFloat("y"));
				playerIcon.GetObject("player4").SetFloat("x", transformedX[3] - playerIcon.GetFloat("x"));
				playerIcon.GetObject("player4").SetFloat("y", transformedY[3] - playerIcon.GetFloat("y"));
			}
			else
			{
				//Scales icon to be bigger on first loop minimap is on, once
				if(!scalePlayerIcon)
				{
					self.originalRectSize = self.originalRectSize * 4;
					rect.SetInt("width", originalRectSize);
					rect.SetInt("height", originalRectSize);

					playerIconWidth = playerIcon.GetObject("player1").GetFloat("width");
					playerIconHeight = playerIcon.GetObject("player1").GetFloat("height");
					playerIcon.GetObject("player1").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player1").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player2").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player2").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player3").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player3").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player4").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player4").SetFloat("height", playerIconHeight * 4);
					scalePlayerIcon = true;
				}

				Map.SetFloat("width", screenSizeX);
				Map.SetFloat("height", screenSizeY);
				Map.SetFloat("x", 0);
				Map.SetFloat("y", 0);
			
				//Passes player relative location to its controller for tracking/metric purposes
				//player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				//Scales values to match screen size
				player2DScreenPoint[0].X *= screenSizeX;   
				player2DScreenPoint[0].Y *= screenSizeY; 
				player2DScreenPoint[1].X *= screenSizeX;   
				player2DScreenPoint[1].Y *= screenSizeY; 
				player2DScreenPoint[2].X *= screenSizeX;   
				player2DScreenPoint[2].Y *= screenSizeY; 
				player2DScreenPoint[3].X *= screenSizeX;   
				player2DScreenPoint[3].Y *= screenSizeY; 
				transformedX[0] = player2DScreenPoint[0].X;
				transformedY[0] = player2DScreenPoint[0].Y;
				transformedX[1] = player2DScreenPoint[1].X;
				transformedY[1] = player2DScreenPoint[1].Y;
				transformedX[2] = player2DScreenPoint[2].X;
				transformedY[2] = player2DScreenPoint[2].Y;
				transformedX[3] = player2DScreenPoint[3].X;
				transformedY[3] = player2DScreenPoint[3].Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX[0] = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((player2DScreenPoint[0].X - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[0] = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((player2DScreenPoint[0].Y - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[1] = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((player2DScreenPoint[1].X - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[1] = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((player2DScreenPoint[1].Y - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[2] = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((player2DScreenPoint[2].X - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[2] = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((player2DScreenPoint[2].Y - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[3] = (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")) + ((Map.GetFloat("width")*70/150) * ((player2DScreenPoint[3].X - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[3] = (Map.GetFloat("height") - (Map.GetFloat("height") * 117/150) - (Map.GetFloat("height")*18/150) + Map.GetFloat("y")) + ((Map.GetFloat("height")*117/150) * ((player2DScreenPoint[3].Y - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.GetObject("player1").SetFloat("x", transformedX[0] - playerIcon.GetFloat("x"));
				playerIcon.GetObject("player1").SetFloat("y", transformedY[0] - playerIcon.GetFloat("y"));
				playerIcon.GetObject("player2").SetFloat("x", transformedX[1] - playerIcon.GetFloat("x"));
				playerIcon.GetObject("player2").SetFloat("y", transformedY[1] - playerIcon.GetFloat("y"));
				playerIcon.GetObject("player3").SetFloat("x", transformedX[2] - playerIcon.GetFloat("x"));
				playerIcon.GetObject("player3").SetFloat("y", transformedY[2] - playerIcon.GetFloat("y"));
				playerIcon.GetObject("player4").SetFloat("x", transformedX[3] - playerIcon.GetFloat("x"));
				playerIcon.GetObject("player4").SetFloat("y", transformedY[3] - playerIcon.GetFloat("y"));
			}
		}
		else if(mapName == "fltemplemaptopplatform")
		{
			if(!miniMap.isOn)
			{
				//Reverts icon scale to be original size on first loop minimap is off, once
				if(scalePlayerIcon)
				{
					playerIcon.GetObject("player1").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player1").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player2").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player2").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player3").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player3").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player4").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player4").SetFloat("height", playerIconHeight);
					scalePlayerIcon = false;
				}

				Map.SetFloat("width", flashMapWidth*scaleFactorX);
				Map.SetFloat("height", flashMapHeight*scaleFactorY);
				Map.SetFloat("x", screenSizeX - (flashMapWidth+10)*scaleFactorX);
				Map.SetFloat("y", screenSizeY - (flashMapHeight+10)*scaleFactorY);
				MapBackground.SetFloat("width", flashMapWidth*scaleFactorX);
				MapBackground.SetFloat("height", flashMapHeight*scaleFactorY);
				MapBackground.SetFloat("x", screenSizeX - (flashMapWidth+10)*scaleFactorX);
				MapBackground.SetFloat("y", screenSizeY - (flashMapHeight+10)*scaleFactorY);

				/*`log("x " $ Map.GetFloat("x"));
				`log("x prime " $ (Map.GetFloat("width") - (Map.GetFloat("width") * 70/150) - (Map.GetFloat("width")*40/150) + Map.GetFloat("x")));
				`log("W " $ Map.GetFloat("width"));
				`log("W prime " $ (Map.GetFloat("width")*70/150));
				`log("A ratio " $ 1 - (screenSizeX - player2DScreenPoint.X)/screenSizeX);*/

				//Passes player relative location to its controller for tracking/metric purposes
				//player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint[0].X *= Map.GetFloat("width");   
				player2DScreenPoint[0].Y *= Map.GetFloat("height"); 
				player2DScreenPoint[1].X *= Map.GetFloat("width");   
				player2DScreenPoint[1].Y *= Map.GetFloat("height"); 
				player2DScreenPoint[2].X *= Map.GetFloat("width");   
				player2DScreenPoint[2].Y *= Map.GetFloat("height"); 
				player2DScreenPoint[3].X *= Map.GetFloat("width");   
				player2DScreenPoint[3].Y *= Map.GetFloat("height"); 

				transformedX[0] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[0].X;
				transformedY[0] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[0].Y;
				transformedX[1] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[1].X;
				transformedY[1] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[1].Y;
				transformedX[2] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[2].X;
				transformedY[2] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[2].Y;
				transformedX[3] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[3].X;
				transformedY[3] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[3].Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX[0] = (Map.GetFloat("width") - 134*scaleFactorX - 8*scaleFactorX + Map.GetFloat("x")) + (134*scaleFactorX * ((transformedX[0] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[0] = (Map.GetFloat("height") - 134*scaleFactorY - 8*scaleFactorY + Map.GetFloat("y")) + (134*scaleFactorY * ((transformedY[0] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[1] = (Map.GetFloat("width") - 134*scaleFactorX - 8*scaleFactorX + Map.GetFloat("x")) + (134*scaleFactorX * ((transformedX[1] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[1] = (Map.GetFloat("height") - 134*scaleFactorY - 8*scaleFactorY + Map.GetFloat("y")) + (134*scaleFactorY * ((transformedY[1] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[2] = (Map.GetFloat("width") - 134*scaleFactorX - 8*scaleFactorX + Map.GetFloat("x")) + (134*scaleFactorX * ((transformedX[2] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[2] = (Map.GetFloat("height") - 134*scaleFactorY - 8*scaleFactorY + Map.GetFloat("y")) + (134*scaleFactorY * ((transformedY[2] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[3] = (Map.GetFloat("width") - 134*scaleFactorX - 8*scaleFactorX + Map.GetFloat("x")) + (134*scaleFactorX * ((transformedX[3] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[3] = (Map.GetFloat("height") - 134*scaleFactorY - 8*scaleFactorY + Map.GetFloat("y")) + (134*scaleFactorY * ((transformedY[3] - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.GetObject("player1").SetFloat("x", transformedX[0] - (10*scaleFactorX));
				playerIcon.GetObject("player1").SetFloat("y", transformedY[0] - (10*scaleFactorY));
				playerIcon.GetObject("player2").SetFloat("x", transformedX[1] - (10*scaleFactorX));
				playerIcon.GetObject("player2").SetFloat("y", transformedY[1] - (10*scaleFactorY));
				playerIcon.GetObject("player3").SetFloat("x", transformedX[2] - (10*scaleFactorX));
				playerIcon.GetObject("player3").SetFloat("y", transformedY[2] - (10*scaleFactorY));
				playerIcon.GetObject("player4").SetFloat("x", transformedX[3] - (10*scaleFactorX));
				playerIcon.GetObject("player4").SetFloat("y", transformedY[3] - (10*scaleFactorY));
			}
			else
			{
				//Scales icon to be bigger on first loop minimap is on, once
				if(!scalePlayerIcon)
				{
					self.originalRectSize = self.originalRectSize * 4;
					rect.SetInt("width", originalRectSize);
					rect.SetInt("height", originalRectSize);

					playerIconWidth = playerIcon.GetObject("player1").GetFloat("width");
					playerIconHeight = playerIcon.GetObject("player1").GetFloat("height");
					playerIcon.GetObject("player1").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player1").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player2").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player2").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player3").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player3").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player4").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player4").SetFloat("height", playerIconHeight * 4);
					scalePlayerIcon = true;
				}

				Map.SetInt("width", screenSizeY);
				Map.SetInt("height", screenSizeY);
				Map.SetFloat("x", (screenSizeX - screenSizeY) / 2);
				Map.SetFloat("y", 0);
				MapBackground.SetInt("width", screenSizeX);
				MapBackground.SetInt("height", screenSizeY);
				MapBackground.SetFloat("x", 0);
				MapBackground.SetFloat("y", 0);

				//Passes player relative location to its controller for tracking/metric purposes
				//player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				//Scales values to match screen size
				player2DScreenPoint[0].X *= screenSizeY;   
				player2DScreenPoint[0].Y *= screenSizeY; 
				player2DScreenPoint[1].X *= screenSizeY;   
				player2DScreenPoint[1].Y *= screenSizeY; 
				player2DScreenPoint[2].X *= screenSizeY;   
				player2DScreenPoint[2].Y *= screenSizeY; 
				player2DScreenPoint[3].X *= screenSizeY;   
				player2DScreenPoint[3].Y *= screenSizeY; 
				transformedX[0] = player2DScreenPoint[0].X;
				transformedY[0] = player2DScreenPoint[0].Y;
				transformedX[1] = player2DScreenPoint[1].X;
				transformedY[1] = player2DScreenPoint[1].Y;
				transformedX[2] = player2DScreenPoint[2].X;
				transformedY[2] = player2DScreenPoint[2].Y;
				transformedX[3] = player2DScreenPoint[3].X;
				transformedY[3] = player2DScreenPoint[3].Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX[0] = (Map.GetInt("width") - (Map.GetInt("width") * 134/150) - (Map.GetInt("width")*8/150)) + ((Map.GetInt("width")*134/150) * (player2DScreenPoint[0].X/Map.GetInt("width")));
				transformedY[0] = (Map.GetInt("height") - (Map.GetInt("height") * 134/150) - (Map.GetInt("height")*8/150)) + ((Map.GetInt("height")*134/150) * (player2DScreenPoint[0].Y/Map.GetInt("height")));
				transformedX[1] = (Map.GetInt("width") - (Map.GetInt("width") * 134/150) - (Map.GetInt("width")*8/150)) + ((Map.GetInt("width")*134/150) * (player2DScreenPoint[1].X/Map.GetInt("width")));
				transformedY[1] = (Map.GetInt("height") - (Map.GetInt("height") * 134/150) - (Map.GetInt("height")*8/150)) + ((Map.GetInt("height")*134/150) * (player2DScreenPoint[1].Y/Map.GetInt("height")));
				transformedX[2] = (Map.GetInt("width") - (Map.GetInt("width") * 134/150) - (Map.GetInt("width")*8/150)) + ((Map.GetInt("width")*134/150) * (player2DScreenPoint[2].X/Map.GetInt("width")));
				transformedY[2] = (Map.GetInt("height") - (Map.GetInt("height") * 134/150) - (Map.GetInt("height")*8/150)) + ((Map.GetInt("height")*134/150) * (player2DScreenPoint[2].Y/Map.GetInt("height")));
				transformedX[3] = (Map.GetInt("width") - (Map.GetInt("width") * 134/150) - (Map.GetInt("width")*8/150)) + ((Map.GetInt("width")*134/150) * (player2DScreenPoint[3].X/Map.GetInt("width")));
				transformedY[3] = (Map.GetInt("height") - (Map.GetInt("height") * 134/150) - (Map.GetInt("height")*8/150)) + ((Map.GetInt("height")*134/150) * (player2DScreenPoint[3].Y/Map.GetInt("height")));

				playerIcon.GetObject("player1").SetFloat("x", transformedX[0] + Map.GetFloat("x"));
				playerIcon.GetObject("player1").SetFloat("y", transformedY[0]);
				playerIcon.GetObject("player2").SetFloat("x", transformedX[1] + Map.GetFloat("x"));
				playerIcon.GetObject("player2").SetFloat("y", transformedY[1]);
				playerIcon.GetObject("player3").SetFloat("x", transformedX[2] + Map.GetFloat("x"));
				playerIcon.GetObject("player3").SetFloat("y", transformedY[2]);
				playerIcon.GetObject("player4").SetFloat("x", transformedX[3] + Map.GetFloat("x"));
				playerIcon.GetObject("player4").SetFloat("y", transformedY[3]);
			}
		}
		else if(mapName == "flmist")
		{
			//`log("Size: " $ originalRectSize);
			if(!miniMap.isOn)
			{
				//Reverts icon scale to be original size on first loop minimap is off, once
				if(scalePlayerIcon)
				{
					playerIcon.GetObject("player1").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player1").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player2").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player2").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player3").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player3").SetFloat("height", playerIconHeight);
					playerIcon.GetObject("player4").SetFloat("width", playerIconWidth);
					playerIcon.GetObject("player4").SetFloat("height", playerIconHeight);
					scalePlayerIcon = false;
				}

				Map.SetFloat("width", flashMapWidth*scaleFactorX);
				Map.SetFloat("height", flashMapHeight*scaleFactorY);
				Map.SetFloat("x", screenSizeX - (flashMapWidth+10)*scaleFactorX);
				Map.SetFloat("y", screenSizeY - (flashMapHeight+10)*scaleFactorY);
				MapBackground.SetFloat("width", flashMapWidth*scaleFactorX);
				MapBackground.SetFloat("height", flashMapHeight*scaleFactorY);
				MapBackground.SetFloat("x", screenSizeX - (flashMapWidth+10)*scaleFactorX);
				MapBackground.SetFloat("y", screenSizeY - (flashMapHeight+10)*scaleFactorY);

				//Passes player relative location to its controller for tracking/metric purposes
				//player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint[0].X *= Map.GetFloat("width");   
				player2DScreenPoint[0].Y *= Map.GetFloat("height"); 
				player2DScreenPoint[1].X *= Map.GetFloat("width");   
				player2DScreenPoint[1].Y *= Map.GetFloat("height"); 
				player2DScreenPoint[2].X *= Map.GetFloat("width");   
				player2DScreenPoint[2].Y *= Map.GetFloat("height"); 
				player2DScreenPoint[3].X *= Map.GetFloat("width");   
				player2DScreenPoint[3].Y *= Map.GetFloat("height"); 

				transformedX[0] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[0].X;
				transformedY[0] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[0].Y;
				transformedX[1] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[1].X;
				transformedY[1] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[1].Y;
				transformedX[2] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[2].X;
				transformedY[2] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[2].Y;
				transformedX[3] = screenSizeX - Map.GetFloat("width") + player2DScreenPoint[3].X;
				transformedY[3] = screenSizeY - Map.GetFloat("height") + player2DScreenPoint[3].Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX[0] = (Map.GetFloat("width") - 120*scaleFactorX - 15*scaleFactorX + Map.GetFloat("x")) + (120*scaleFactorX * ((transformedX[0] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[0] = (Map.GetFloat("height") - 120*scaleFactorY - 15*scaleFactorY + Map.GetFloat("y")) + (120*scaleFactorY * ((transformedY[0] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[1] = (Map.GetFloat("width") - 120*scaleFactorX - 15*scaleFactorX + Map.GetFloat("x")) + (120*scaleFactorX * ((transformedX[1] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[1] = (Map.GetFloat("height") - 120*scaleFactorY - 15*scaleFactorY + Map.GetFloat("y")) + (120*scaleFactorY * ((transformedY[1] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[2] = (Map.GetFloat("width") - 120*scaleFactorX - 15*scaleFactorX + Map.GetFloat("x")) + (120*scaleFactorX * ((transformedX[2] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[2] = (Map.GetFloat("height") - 120*scaleFactorY - 15*scaleFactorY + Map.GetFloat("y")) + (120*scaleFactorY * ((transformedY[2] - Map.GetFloat("y"))/Map.GetFloat("height")));
				transformedX[3] = (Map.GetFloat("width") - 120*scaleFactorX - 15*scaleFactorX + Map.GetFloat("x")) + (120*scaleFactorX * ((transformedX[3] - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY[3] = (Map.GetFloat("height") - 120*scaleFactorY - 15*scaleFactorY + Map.GetFloat("y")) + (120*scaleFactorY * ((transformedY[3] - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.GetObject("player1").SetFloat("x", transformedX[0] - (10*scaleFactorX));
				playerIcon.GetObject("player1").SetFloat("y", transformedY[0] - (10*scaleFactorY));
				playerIcon.GetObject("player2").SetFloat("x", transformedX[1] - (10*scaleFactorX));
				playerIcon.GetObject("player2").SetFloat("y", transformedY[1] - (10*scaleFactorY));
				playerIcon.GetObject("player3").SetFloat("x", transformedX[2] - (10*scaleFactorX));
				playerIcon.GetObject("player3").SetFloat("y", transformedY[2] - (10*scaleFactorY));
				playerIcon.GetObject("player4").SetFloat("x", transformedX[3] - (10*scaleFactorX));
				playerIcon.GetObject("player4").SetFloat("y", transformedY[3] - (10*scaleFactorY));
			}
			else
			{
				//Scales icon to be bigger on first loop minimap is on, once
				if(!scalePlayerIcon)
				{
					playerIconWidth = playerIcon.GetObject("player1").GetFloat("width");
					playerIconHeight = playerIcon.GetObject("player1").GetFloat("height");
					playerIcon.GetObject("player1").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player1").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player2").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player2").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player3").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player3").SetFloat("height", playerIconHeight * 4);
					playerIcon.GetObject("player4").SetFloat("width", playerIconWidth * 4);
					playerIcon.GetObject("player4").SetFloat("height", playerIconHeight * 4);
					scalePlayerIcon = true;
				}

				Map.SetInt("width", screenSizeY);
				Map.SetInt("height", screenSizeY);
				Map.SetFloat("x", (screenSizeX - screenSizeY) / 2);
				Map.SetFloat("y", 0);
				MapBackground.SetInt("width", screenSizeX);
				MapBackground.SetInt("height", screenSizeY);
				MapBackground.SetFloat("x", 0);
				MapBackground.SetFloat("y", 0);

				//Passes player relative location to its controller for tracking/metric purposes
				//player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				//Scales values to match screen size
				player2DScreenPoint[0].X *= screenSizeY;   
				player2DScreenPoint[0].Y *= screenSizeY; 
				player2DScreenPoint[1].X *= screenSizeY;   
				player2DScreenPoint[1].Y *= screenSizeY; 
				player2DScreenPoint[2].X *= screenSizeY;   
				player2DScreenPoint[2].Y *= screenSizeY; 
				player2DScreenPoint[3].X *= screenSizeY;   
				player2DScreenPoint[3].Y *= screenSizeY; 
				transformedX[0] = player2DScreenPoint[0].X;
				transformedY[0] = player2DScreenPoint[0].Y;
				transformedX[1] = player2DScreenPoint[1].X;
				transformedY[1] = player2DScreenPoint[1].Y;
				transformedX[2] = player2DScreenPoint[2].X;
				transformedY[2] = player2DScreenPoint[2].Y;
				transformedX[3] = player2DScreenPoint[3].X;
				transformedY[3] = player2DScreenPoint[3].Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX[0] = (Map.GetInt("width") - (Map.GetInt("width") * 120/150) - (Map.GetInt("width")*15/150)) + ((Map.GetInt("width")*120/150) * (player2DScreenPoint[0].X/Map.GetInt("width")));
				transformedY[0] = (Map.GetInt("height") - (Map.GetInt("height") * 120/150) - (Map.GetInt("height")*15/150)) + ((Map.GetInt("height")*120/150) * (player2DScreenPoint[0].Y/Map.GetInt("height")));
				transformedX[1] = (Map.GetInt("width") - (Map.GetInt("width") * 120/150) - (Map.GetInt("width")*15/150)) + ((Map.GetInt("width")*120/150) * (player2DScreenPoint[1].X/Map.GetInt("width")));
				transformedY[1] = (Map.GetInt("height") - (Map.GetInt("height") * 120/150) - (Map.GetInt("height")*15/150)) + ((Map.GetInt("height")*120/150) * (player2DScreenPoint[1].Y/Map.GetInt("height")));
				transformedX[2] = (Map.GetInt("width") - (Map.GetInt("width") * 120/150) - (Map.GetInt("width")*15/150)) + ((Map.GetInt("width")*120/150) * (player2DScreenPoint[2].X/Map.GetInt("width")));
				transformedY[2] = (Map.GetInt("height") - (Map.GetInt("height") * 120/150) - (Map.GetInt("height")*15/150)) + ((Map.GetInt("height")*120/150) * (player2DScreenPoint[2].Y/Map.GetInt("height")));
				transformedX[3] = (Map.GetInt("width") - (Map.GetInt("width") * 120/150) - (Map.GetInt("width")*15/150)) + ((Map.GetInt("width")*120/150) * (player2DScreenPoint[3].X/Map.GetInt("width")));
				transformedY[3] = (Map.GetInt("height") - (Map.GetInt("height") * 120/150) - (Map.GetInt("height")*15/150)) + ((Map.GetInt("height")*120/150) * (player2DScreenPoint[3].Y/Map.GetInt("height")));

				playerIcon.GetObject("player1").SetFloat("x", transformedX[0] + Map.GetFloat("x"));
				playerIcon.GetObject("player1").SetFloat("y", transformedY[0]);
				playerIcon.GetObject("player2").SetFloat("x", transformedX[1] + Map.GetFloat("x"));
				playerIcon.GetObject("player2").SetFloat("y", transformedY[1]);
				playerIcon.GetObject("player3").SetFloat("x", transformedX[2] + Map.GetFloat("x"));
				playerIcon.GetObject("player3").SetFloat("y", transformedY[2]);
				playerIcon.GetObject("player4").SetFloat("x", transformedX[3] + Map.GetFloat("x"));
				playerIcon.GetObject("player4").SetFloat("y", transformedY[3]);
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
	minimaps[1] = Texture2D'sneaktoslimimages.fltemplemaptopplatformTopDownMap'
	minimaps[2] = Texture2D'sneaktoslimimages.flmistTopDownMap'
}
