class SneaktoSlimGFxMap extends GFxMoviePlayer;

var float screenSizeX, screenSizeY;
var GFxObject Map, playerIcon, demoTime, winnerDisplayText, winnerDisplayBackground, minimapText, rect, MapBackground;
var MiniMap miniMap;
var Texture2D mapTexture;
var vector player2DScreenPoint;
var String mapName, mapPath;
var array<GFxObject> allFlashObjects;
var float flashMapX, flashMapY, flashMapWidth, flashMapHeight, scaleFactorX, scaleFactorY;
var array<Texture2D> minimaps;
var float mouseRotation, faceRotation, playerIconWidth, playerIconHeight;
var int originalRectSize;
var bool isHUDSet, scalePlayerIcon;

function Init(optional LocalPlayer player)
{
	super.Init(player);
	Start();
	Advance(0.0f);

	minimapText = GetVariableObject("_root.Minimap_text");
	minimapText.SetBool("visible", false);
	if(SneaktoSlimPawn(SneaktoSlimPlayerController(GetPC()).Pawn).getIsUsingXboxController())
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
	allFlashObjects.AddItem(playerIcon);
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
	
		playerIcon.SetFloat("rotation", mouseRotation);

		if(mapName == "demoday")
		{
			if(!miniMap.isOn)
			{
				//Reverts icon scale to be original size on first loop minimap is off, once
				if(scalePlayerIcon)
				{
					self.originalRectSize = self.originalRectSize / 4;
					rect.SetInt("width", originalRectSize);
					rect.SetInt("height", originalRectSize);
					playerIcon.SetFloat("width", playerIconWidth);
					playerIcon.SetFloat("height", playerIconHeight);
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
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint.X *= Map.GetFloat("width");   
				player2DScreenPoint.Y *= Map.GetFloat("height"); 

				transformedX = screenSizeX - Map.GetFloat("width") + player2DScreenPoint.X;
				transformedY = screenSizeY - Map.GetFloat("height") + player2DScreenPoint.Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - 69*scaleFactorX - 35*scaleFactorX + Map.GetFloat("x")) + (69*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - 117*scaleFactorY - 17*scaleFactorY + Map.GetFloat("y")) + (117*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.SetFloat("x", transformedX-(10*scaleFactorX));
				playerIcon.SetFloat("y", transformedY-(10*scaleFactorY));
			}
			else
			{
				//Scales icon to be bigger on first loop minimap is on, once
				if(!scalePlayerIcon)
				{
					self.originalRectSize = self.originalRectSize * 4;
					rect.SetInt("width", originalRectSize);
					rect.SetInt("height", originalRectSize);

					playerIconWidth = playerIcon.GetFloat("width");
					playerIconHeight = playerIcon.GetFloat("height");
					playerIcon.SetFloat("width", playerIconWidth * 4);
					playerIcon.SetFloat("height", playerIconHeight * 4);
					scalePlayerIcon = true;
				}

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
		else if(mapName == "fltemplemaptopplatform")
		{
			if(!miniMap.isOn)
			{
				//Reverts icon scale to be original size on first loop minimap is off, once
				if(scalePlayerIcon)
				{
					self.originalRectSize = self.originalRectSize / 4;
					rect.SetInt("width", originalRectSize);
					rect.SetInt("height", originalRectSize);
					playerIcon.SetFloat("width", playerIconWidth);
					playerIcon.SetFloat("height", playerIconHeight);
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
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint.X *= Map.GetFloat("width");   
				player2DScreenPoint.Y *= Map.GetFloat("height"); 

				transformedX = screenSizeX - Map.GetFloat("width") + player2DScreenPoint.X;
				transformedY = screenSizeY - Map.GetFloat("height") + player2DScreenPoint.Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - 134*scaleFactorX - 8*scaleFactorX + Map.GetFloat("x")) + (134*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - 134*scaleFactorY - 8*scaleFactorY + Map.GetFloat("y")) + (134*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.SetFloat("x", transformedX-(10*scaleFactorX));
				playerIcon.SetFloat("y", transformedY-(10*scaleFactorY));
			}
			else
			{
				//Scales icon to be bigger on first loop minimap is on, once
				if(!scalePlayerIcon)
				{
					self.originalRectSize = self.originalRectSize * 4;
					rect.SetInt("width", originalRectSize);
					rect.SetInt("height", originalRectSize);

					playerIconWidth = playerIcon.GetFloat("width");
					playerIconHeight = playerIcon.GetFloat("height");
					playerIcon.SetFloat("width", playerIconWidth * 4);
					playerIcon.SetFloat("height", playerIconHeight * 4);
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
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				//Scales values to match screen size
				player2DScreenPoint.X *= screenSizeY;   
				player2DScreenPoint.Y *= screenSizeY; 
				transformedX = player2DScreenPoint.X;
				transformedY = player2DScreenPoint.Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetInt("width") - (Map.GetInt("width") * 134/150) - (Map.GetInt("width")*8/150)) + ((Map.GetInt("width")*134/150) * (player2DScreenPoint.X/Map.GetInt("width")));
				transformedY = (Map.GetInt("height") - (Map.GetInt("height") * 134/150) - (Map.GetInt("height")*8/150)) + ((Map.GetInt("height")*134/150) * (player2DScreenPoint.Y/Map.GetInt("height")));

				playerIcon.SetFloat("x", transformedX + Map.GetFloat("x"));
				playerIcon.SetFloat("y", transformedY);
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
					self.originalRectSize = self.originalRectSize / 4;
					rect.SetInt("width", originalRectSize);
					rect.SetInt("height", originalRectSize);
					playerIcon.SetFloat("width", playerIconWidth);
					playerIcon.SetFloat("height", playerIconHeight);
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
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				player2DScreenPoint.X *= Map.GetFloat("width");   
				player2DScreenPoint.Y *= Map.GetFloat("height"); 

				transformedX = screenSizeX - Map.GetFloat("width") + player2DScreenPoint.X;
				transformedY = screenSizeY - Map.GetFloat("height") + player2DScreenPoint.Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetFloat("width") - 120*scaleFactorX - 15*scaleFactorX + Map.GetFloat("x")) + (120*scaleFactorX * ((transformedX - Map.GetFloat("x"))/Map.GetFloat("width")));
				transformedY = (Map.GetFloat("height") - 120*scaleFactorY - 15*scaleFactorY + Map.GetFloat("y")) + (120*scaleFactorY * ((transformedY - Map.GetFloat("y"))/Map.GetFloat("height")));

				playerIcon.SetFloat("x", transformedX-(10*scaleFactorX));
				playerIcon.SetFloat("y", transformedY-(10*scaleFactorY));
			}
			else
			{
				//Scales icon to be bigger on first loop minimap is on, once
				if(!scalePlayerIcon)
				{
					self.originalRectSize = self.originalRectSize * 4;
					rect.SetInt("width", originalRectSize);
					rect.SetInt("height", originalRectSize);

					playerIconWidth = playerIcon.GetFloat("width");
					playerIconHeight = playerIcon.GetFloat("height");
					playerIcon.SetFloat("width", playerIconWidth * 4);
					playerIcon.SetFloat("height", playerIconHeight * 4);
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
				player.trackLocation(player2DScreenPoint.X, player2DScreenPoint.Y, self.mapName);

				//Scales values to match screen size
				player2DScreenPoint.X *= screenSizeY;   
				player2DScreenPoint.Y *= screenSizeY; 
				transformedX = player2DScreenPoint.X;
				transformedY = player2DScreenPoint.Y;

				//Map specify conversion to scale point to ignore image margins
				transformedX = (Map.GetInt("width") - (Map.GetInt("width") * 120/150) - (Map.GetInt("width")*15/150)) + ((Map.GetInt("width")*120/150) * (player2DScreenPoint.X/Map.GetInt("width")));
				transformedY = (Map.GetInt("height") - (Map.GetInt("height") * 120/150) - (Map.GetInt("height")*15/150)) + ((Map.GetInt("height")*120/150) * (player2DScreenPoint.Y/Map.GetInt("height")));

				playerIcon.SetFloat("x", transformedX + Map.GetFloat("x"));
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
	minimaps[1] = Texture2D'sneaktoslimimages.fltemplemaptopplatformTopDownMap'
	minimaps[2] = Texture2D'sneaktoslimimages.flmistTopDownMap'
}
