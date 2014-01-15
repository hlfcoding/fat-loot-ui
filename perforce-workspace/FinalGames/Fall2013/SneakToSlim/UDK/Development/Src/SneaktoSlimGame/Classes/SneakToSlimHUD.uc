class SneakToSlimHUD extends HUD dependsOn( SneaktoSlimPawn );

var array<int> scoreBoard;

var bool colorMarked; // default true

var Color teamColor[4];
var Color defaultTeamColor[4];

var string allPplScore[4];
var PathNode topDownCam;  
var array<PathNode> corners;        //Placed in map editor beforehand
var bool once;
       
var vector right, up, dir;
var float mapWidth, mapHeight;      //Determined at postBeginPlay()

var int screenXResolution;
var int screenYResolution;
//struct HUDMessage
//{
//	var string sMeg;
//	var float MsgTimer;
//};

var SneaktoSlimGFxHUD FlashHUD;
var SneaktoSlimGFxMap FlashMap;

replication 
{   //ARRANGE THESE ALPHABETICALLY
//	if (bNetDirty)
//		arrMsg;
}


enum orderByEnum {
  selfScoreMostLeft,
  orderByTeam
};
var orderByEnum scoreOrderType;

singular event Destroyed()
{
	if(FlashHUD != none)
	{
		FlashHUD.Close(true);
		FlashHUD = none;
	}

	if(FlashMap != none)
	{
		FlashMap.Close(true);
		FlashMap = none;
	}

	super.Destroyed();
}

simulated function PostBeginPlay()
{
	//local CameraActor cam;
	local PathNode node;

	defaultTeamColor[0] = MakeColor( 255, 0, 0, 255 );// cannot in DefaultProperties
	defaultTeamColor[1] = MakeColor( 0, 255, 0, 255 );// cannot in DefaultProperties
	defaultTeamColor[2] = MakeColor( 0, 0, 255, 255 );// cannot in DefaultProperties
	defaultTeamColor[3] = MakeColor( 255, 0, 255, 255 );// cannot in DefaultProperties

	teamColor[0] = defaultTeamColor[0];
	teamColor[1] = defaultTeamColor[1];
	teamColor[2] = defaultTeamColor[2];
	teamColor[3] = defaultTeamColor[3];

	scoreOrderType = orderByEnum.orderByTeam; // cannot in DefaultProperties

	super.PostBeginPlay();        

	//Grabs all four corner nodes
	foreach WorldInfo.AllActors(class'PathNode', node)
	{
		if(InStr(node.Tag, 'Corner') != -1)
			corners[corners.Length] = node;
		if(node.Tag == 'topDownCamera')
			topDownCam = node;
	}
	findMapDimensions();
	//Presets simple vectors for 3D to 2D calculation
	right.X = 1;
	dir.Z = -1;
	up = dir cross right;
	up = Normal(up);
	right = up cross dir;
	right = Normal(right);

	screenXResolution = Canvas.ClipX;
	screenYResolution = Canvas.ClipY;

	//Creates and initializes flash UI
	FlashHUD = new class 'SneaktoSlimGFxHUD';
	FlashHUD.Init(class 'Engine'.static.GetEngine().GamePlayers[FlashHUD.LocalPlayerOwnerIndex]);
	FlashHUD.SetViewScaleMode(SM_NoScale);
	FlashHUD.SetAlignment(Align_TopLeft);

	FlashMap = new class 'SneaktoSlimGFxMap';
	FlashMap.Init(class 'Engine'.static.GetEngine().GamePlayers[FlashMap.LocalPlayerOwnerIndex]);
	FlashMap.SetViewScaleMode(SM_NoScale);
	FlashMap.SetAlignment(Align_TopLeft);

	//Saves map specific info in flash class
	FlashMap.mapName = WorldInfo.GetMapName();
	FlashMap.mapPath = "SneaktoSlimImages." $ FlashMap.mapName $ "TopDownMap";
}

//Calculates current map dimensions based on distance between corner nodes set in editor
//See "Nick P." for more details
function findMapDimensions()
{
	local PathNode topLeft, topRight, bottomLeft;
	local int i;

	//Breaks if map corners at not placed in editor
	if(corners.Length == 0)
	{
		`log("WARNING: Corners not placed in map");
		return;
	}

	//Gets specify tag corners
	for(i = 0; i < 4; i++)
	{
		if(corners[i].Tag == 'topLeftCorner')
			topLeft = corners[i];
		if(corners[i].Tag == 'topRightCorner')
			topRight = corners[i];
		if(corners[i].Tag == 'bottomLeftCorner')
			bottomLeft = corners[i];
	}

	//Distance formula
	mapWidth = sqrt(square(topLeft.Location.X - topRight.Location.X) + square(topLeft.Location.Y - topRight.Location.Y));
	mapHeight = sqrt(square(topLeft.Location.X - bottomLeft.Location.X) + square(topLeft.Location.Y - bottomLeft.Location.Y));
}


//Converts 3D world space point to 2D screen point
function Vector WorldPointTo2DScreenPoint(Vector point3D)
{
	//local TPOV camProperties;
	local vector screenPoint, prime, prime2;

	//topDownCam.GetCameraView(1, camProperties);
	
	//Runned once to display camera and corner info
	/*if(!once)
	{
		`log(topDownCam.Name);
		`log("Top down cam location: " $ camProperties.Location);
		`log("Cam Rotation: " $ camProperties.Rotation);
		`log(corners[0].Name $ "(" $ corners[0].Tag $ ") at " $ corners[0].Location);
		`log(corners[1].Name $ "(" $ corners[1].Tag $ ") at " $ corners[1].Location);
		`log(corners[2].Name $ "(" $ corners[2].Tag $ ") at " $ corners[2].Location);
		`log(corners[3].Name $ "(" $ corners[3].Tag $ ") at " $ corners[3].Location);
		once = true;
	}*/
	screenPoint.X = (((point3D - topDownCam.Location) dot right) / mapWidth) + 0.5;     //Return value from 0 to 1
	screenPoint.Y = (((point3D - topDownCam.Location) dot up) / mapHeight) + 0.5;
	screenPoint.Z = 0;  //Unused

	//Since world axis is different from screen axis
	//I translate up 1 to match standard euclid plane,
	//rotate along the x/y axis,
	//then translate back down 1 to match screen axis
	prime.X = screenPoint.X;
	prime.Y = 1 - screenPoint.Y;
	prime2.X = prime.Y;
	prime2.Y = prime.X;
	screenPoint.X = prime2.X;
	screenPoint.Y = 1 - prime2.Y;
	//canvas.SetPos(Canvas.ClipX*0.2,Canvas.ClipY*0.4);
	//canvas.DrawText("X: " $ screenPoint.X $ " | Y: " $ screenPoint.Y);

	//Scales values to match screen size
	screenPoint.X *= canvas.SizeX;   
	screenPoint.Y *= canvas.SizeY;

	return screenPoint;
}
                          
simulated event DrawHUD()
{
	local SneaktoSlimPawn localPawn;
	//local int selfScoreMostLeft_i;
	local int j, k;
	local byte _tNumber;
	//local byte _selfTNumber;

	local MiniMap map;
	//local String mapName;
	//local vector pawnScreenPoint;
	//local Actor obj;
	//local Texture2D background;
	//local TextureRenderTarget2D material;

	super.DrawHUD();

	if(PlayerOwner.Pawn!=none)
	{
		map =  SneaktoSlimPlayerController(SneaktoSlimPawn(PlayerOwner.Pawn).Controller).myMap;
		if(FlashMap != NONE/* && map.isOn*/)
		{
			FlashMap.miniMap = map;
			FlashMap.player2DScreenPoint = WorldPointTo2DScreenPoint(map.playerLocation);
		}
		//map = SneaktoSlimPlayerController(SneaktoSlimPawn(PlayerOwner.Pawn).Controller).myMap;
		/*if(map != NONE && map.isOn)
		{
			//sets font and color
			Canvas.DrawColor=WhiteColor;
			Canvas.Font=class'Engine'.static.GetLargeFont();

			//Gets texture of minimap dynamically
			mapName = "SneaktoSlimImages." $ WorldInfo.GetMapName() $ "TopDownMap";
			background = Texture2D(DynamicLoadObject(mapName,class'Texture2D'));
			//Testing purposes only
			switch (WorldInfo.GetMapName())
			{
				case "mansiontest":     //Must be lowercase
					background = Texture2D 'SneaktoSlimImages.MansionTestTopDownMap';   //Must match texture name but is formatted like this.
					break;
				case "minimapbasic":
					background = Texture2D 'SneaktoSlimImages.minimapbasicTopDownMap';
					break;
				case "midterm2":
					//material = TextureRenderTarget2D 'Test.HealthBarRender';
					break;
			}
			canvas.SetPos(0, 0);
			if(background != NONE)
			{
				/*if(material != NONE)
				{
					canvas.SetPos(50, canvas.SizeY - material.SizeY + 50);
					canvas.DrawTile(material, material.SizeX, material.SizeY, 0, 0, material.SizeX, material.SizeY, , , EBlendMode(BLEND_Translucent));
				}
				else*/
					canvas.DrawTile(background, canvas.SizeX, canvas.SizeY, 0, 0, background.SizeX, background.SizeY, , , EBlendMode(BLEND_Translucent));
				
			}
			else
				`log("Failed to load " $ background.Name);

			//Draws player's location
			canvas.SetDrawColorStruct(teamColor[SneaktoSlimPawn(PlayerOwner.Pawn).GetTeamNum()]);
			pawnScreenPoint = WorldPointTo2DScreenPoint(map.Location);
			canvas.SetPos(pawnScreenPoint.X, pawnScreenPoint.Y);
			canvas.DrawRect(10, 10);
			canvas.SetPos(pawnScreenPoint.X + Cos(PlayerOwner.Pawn.Rotation.Yaw*UnrRotToRad - (Pi*0.5)) * 15, pawnScreenPoint.Y + Sin(PlayerOwner.Pawn.Rotation.Yaw*UnrRotToRad - (Pi*0.5)) * 15);
			canvas.DrawRect(5, 5);
			canvas.SetPos(pawnScreenPoint.X + Cos(PlayerOwner.Rotation.Yaw*UnrRotToRad - (Pi*0.5)) * 11, pawnScreenPoint.Y + Sin(PlayerOwner.Rotation.Yaw*UnrRotToRad - (Pi*0.5)) * 11);
			canvas.DrawRect(2, 2);
			//canvas.DrawText(PlayerOwner.Rotation.Yaw*UnrRotToRad - (Pi*0.5));    //Can use PlayerOwner.Rotation.Pitch to track mouse rotation
			/*foreach map.objects(obj)
			{
				pawnScreenPoint = WorldPointTo2DScreenPoint(obj.Location);
				canvas.SetPos(pawnScreenPoint.X, pawnScreenPoint.Y);
				//canvas.SetDrawColor(255,255,255,);    //Not working?
				canvas.DrawBox(10, 10);
			}*/
			//canvas.SetPos(Canvas.ClipX*0.2,Canvas.ClipY*0.2);
			//canvas.DrawText("MiniMap Project: " $ pawnScreenPoint $ " | World Location: " $ map.Location);
		}*/

		//sets font and color
		Canvas.DrawColor=WhiteColor;
		Canvas.Font=class'Engine'.static.GetLargeFont();

		//Draws player's energy
		//canvas.SetPos(Canvas.ClipX*0.1,Canvas.ClipY*0.9);
		//canvas.DrawText("Current Energy: " @ int(SneaktoSlimPawn(PlayerOwner.Pawn).v_energy));

		//selfScoreMostLeft_i = 1;

		//_selfTNumber = SneaktoSlimPawn(PlayerOwner.Pawn).GetTeamNum();
		//Gets score info of all pawns
		ForEach WorldInfo.AllPawns(class'SneaktoSlimPawn', localPawn) 
		{
			_tNumber = localPawn.GetTeamNum();
			//`log(_tNumber);

			if( _tNumber >= 0 && _tNumber <= 4)	//__tNumber = 255 is dropout ppl
			{
				//Updates pawn score in local var
				scoreBoard[_tNumber] = localPawn.playerScore;

				/*switch(scoreOrderType)
				{
					case orderByEnum.selfScoreMostLeft:
						if( _tNumber == _selfTNumber)
						{
							allPplScore[0] = "Score: " $  scoreBoard[_tNumber];
							teamColor[0] = defaultTeamColor[_tNumber];
						}
						else
						{
							allPplScore[selfScoreMostLeft_i] = "Score: " $ scoreBoard[_tNumber];
							teamColor[selfScoreMostLeft_i] = defaultTeamColor[_tNumber];
							selfScoreMostLeft_i++;
						}
						break;

					case orderByEnum.orderByTeam:

					default:
						allPplScore[_tNumber] ="Score: " $ scoreBoard[_tNumber];
						break;
				}*/
			}
		}//end foreach

		//draw score on hud at once
		For(j = 0; j < scoreBoard.Length; j++)
		{
			switch(j)
			{
				case 0: FlashHUD.player1Score.SetInt("newScore", scoreBoard[j]);
						FlashHUD.player1Score.SetBool("isOn", true);
						break;
				case 1: FlashHUD.player2Score.SetInt("newScore", scoreBoard[j]);
						FlashHUD.player2Score.SetBool("isOn", true);
						break;
				case 2: FlashHUD.player3Score.SetInt("newScore", scoreBoard[j]);
						FlashHUD.player3Score.SetBool("isOn", true);
						break;
				case 3: FlashHUD.player4Score.SetInt("newScore", scoreBoard[j]);
						FlashHUD.player4Score.SetBool("isOn", true);
						break;
			}
			/*canvas.SetPos(Canvas.ClipX * (0.1 + j * 0.2), Canvas.ClipY * 0.1);
			if(colorMarked) // color ppl
			{
				canvas.SetDrawColorStruct(teamColor[j]);
			}
			canvas.DrawText(allPplScore[j]);*/

			//clean up
			//todo: alpha--
			//allPplScore[j] = "";

		}
		for(k = scoreBoard.Length; k < 4; k++)
		{
			switch(k)
			{
				case 0: FlashHUD.player1Score.SetBool("isOn", false);
						break;
				case 1: FlashHUD.player2Score.SetBool("isOn", false);
						break;
				case 2: FlashHUD.player3Score.SetBool("isOn", false);
						break;
				case 3: FlashHUD.player4Score.SetBool("isOn", false);
						break;
			}
		}

//draw MSG
		DrawCascadeMsg();
		if(SneaktoSlimPawn(PlayerOwner.Pawn).staticHUDmsg.stringCountDown != "")
			DrawStringEX(SneaktoSlimPawn(PlayerOwner.Pawn).staticHUDmsg.stringCountDown, 600, 200, 255, 255, 255, 255);
		if(SneaktoSlimPawn(PlayerOwner.Pawn).staticHUDmsg.triggerPromtText != "")
			DrawStringEX(SneaktoSlimPawn(PlayerOwner.Pawn).staticHUDmsg.triggerPromtText, 500, 300, 255, 255, 255, 255);
		if(SneaktoSlimPawn(PlayerOwner.Pawn).staticHUDmsg.eqGotten != "")
			DrawStringEX(SneaktoSlimPawn(PlayerOwner.Pawn).staticHUDmsg.eqGotten, 900, 600, 255, 255, 255, 255);
	}
}//end DrawHuD

simulated event PostRender()
{
	local MiniMap map;

	super.PostRender();

	map =  SneaktoSlimPlayerController(SneaktoSlimPawn(PlayerOwner.Pawn).Controller).myMap;

	if(FlashHUD != none)
	{
		if(!map.isOn)
		{
			FlashHUD.TickHud(0);
			FlashHUD.scaleObjects(canvas.SizeX, canvas.SizeY);
		}
	}

	if(FlashMap != none)
	{
		FlashMap.TickMap(0);
		FlashMap.scaleObjects(canvas.SizeX, canvas.SizeY);
	}
}

simulated event Tick(float DeltaTime)
{
	local int i;

	if(PlayerOwner.Pawn!=none)
		for(i = 0; i < SneaktoSlimPawn(PlayerOwner.Pawn).arrMsg.Length; ++i)
		{
			SneaktoSlimPawn(PlayerOwner.Pawn).arrMsg[i].MsgTimer += DeltaTime;
		}
}

function DrawStringEX(string _text, int _x, int _y, int _r, int _g, int _b, int _a)
{
	Canvas.SetPos(_x, _y);
	Canvas.SetDrawColor(_r, _g, _b, _a);
	//Canvas.Font = class
	Canvas.DrawText(_text);
}

function DrawCascadeMsg()
{
	local HUDMessage mmsg;
	local float offsetY;

	offsetY = 0;

	foreach SneaktoSlimPawn(PlayerOwner.Pawn).arrMsg(mmsg)
	{
		if(mmsg.MsgTimer < 3.0f)
		{
			DrawStringEX(mmsg.sMeg, 950, 150 + offsetY, 255, 255, 255, 255);
			offsetY += 20;
		}
		else
		{
			SneaktoSlimPawn(PlayerOwner.Pawn).arrMsg.RemoveItem(mmsg);
		}
	}
}


DefaultProperties
{
	colorMarked = true; // default true
	once = false
	//bEnableActorOverlays=true
}
