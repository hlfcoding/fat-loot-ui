class SneakToSlimHUD_Spectator extends HUD dependsOn( SneaktoSlimPawn_Spectator );

var array<int> scoreBoard;

var bool colorMarked; // default true

var Color teamColor[4];
var Color defaultTeamColor[4];

var string allPplScore[4];
//var PathNode topDownCam;            
var array<PathNode> corners;        //Placed in map editor beforehand
var array<vector> cornerPoints;
var vector topLeft;
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

var SneaktoSlimHUDGFx_Spectator FlashHUD;
var SneaktoSlimMapGFx_Spectator FlashMap;
var SneaktoSlimPauseGFx_Spectator FlashPause;

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

	if(FlashPause != none)
	{
		FlashPause.Close(true);
		FlashPause = none;
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
	FlashHUD = new class 'SneaktoSlimHUDGFx_Spectator';
	FlashHUD.Init(class 'Engine'.static.GetEngine().GamePlayers[FlashHUD.LocalPlayerOwnerIndex]);
	FlashHUD.SetViewScaleMode(SM_NoScale);
	FlashHUD.SetAlignment(Align_TopLeft);

	//Creates and initializes flash UI
	FlashMap = new class 'SneaktoSlimMapGFx_Spectator';
	FlashMap.Init(class 'Engine'.static.GetEngine().GamePlayers[FlashHUD.LocalPlayerOwnerIndex]);
	FlashMap.SetViewScaleMode(SM_NoScale);
	FlashMap.SetAlignment(Align_TopLeft);

	//Creates and initializes flash UI
	FlashPause = new class 'SneaktoSlimPauseGFx_Spectator';
	FlashPause.Init(class 'Engine'.static.GetEngine().GamePlayers[FlashHUD.LocalPlayerOwnerIndex]);
	FlashPause.SetViewScaleMode(SM_NoScale);
	FlashPause.SetAlignment(Align_TopLeft);

	//Saves map specific info in flash class
	FlashMap.mapName = WorldInfo.GetMapName();
	FlashMap.mapPath = "SneaktoSlimImages." $ FlashMap.mapName $ "TopDownMap";
}

//Called every tick since playerowner isn't set up instantly in postbegin play
//Skips if hud is already set when inner function completes
unreliable server function setCharacterHUD()
{
	//if(!FlashHUD.isHUDSet)
	//	FlashHUD.setHealthBarHead(SneakToSlimPawn(PlayerOwner.Pawn).characterName);
	if(!FlashMap.isHUDSet)
		FlashMap.setMiniMapHead(4);
}

//Calculates current map dimensions based on distance between corner nodes set in editor
//See "Nick P." for more details
function findMapDimensions()
{
	local vector topRight, bottomLeft;
	local vector prime, prime2;
	local int i, k;

	//Same code as if(fltemplemap)
	if(WorldInfo.GetMapName() == "demoday")
	{
		//Breaks if map corners at not placed in editor
		if(corners.Length != 4)
		{
			`log("WARNING: Corners not placed in map");
			return;
		}

		//Gets specify tag corners
		for(i = 0; i < 4; i++)
		{
			//Rotates points in odd, confusing axis to standard xy coordinate system
			//Top down view of corners in editor
			//(Actual) to  (Expected/Pecieved)
			//BR   TR  -->  TL   TR
			//BL   TL  -->  BL   BR
			prime.X = corners[i].Location.Y;    //Rotate point -90 deg (clockwise about origin)
			prime.Y = -corners[i].Location.X;
			prime2.X = prime.X;     //Vertical flip about y axis
			prime2.Y = -prime.Y;
			cornerPoints[i] = prime2;

			if(corners[i].Tag == 'topLeftCorner')
				topLeft = cornerPoints[i];
			if(corners[i].Tag == 'topRightCorner')
				topRight = cornerPoints[i];
			if(corners[i].Tag == 'bottomLeftCorner')
				bottomLeft = cornerPoints[i];
		}

		//translate corner nodes so that topLeft point is at (0,0) and save into mutable array
		for(k = 0; k < 4; k++)
		{
			cornerPoints[k].X += -topLeft.X;
			cornerPoints[k].Y += -topLeft.Y;
		}

		//Distance formula
		mapWidth = sqrt(square(topLeft.X - topRight.X) + square(topLeft.Y - topRight.Y));
		mapHeight = sqrt(square(topLeft.X - bottomLeft.X) + square(topLeft.Y - bottomLeft.Y));
	}
	//Same code as if(demoday)
	else if(WorldInfo.GetMapName() == "fltemplemaptopplatform")
	{
		//Breaks if map corners at not placed in editor
		if(corners.Length != 4)
		{
			`log("WARNING: Corners not placed in map");
			return;
		}

		//Gets specify tag corners
		for(i = 0; i < 4; i++)
		{
			//Rotates points in odd, confusing axis to standard xy coordinate system
			//Top down view of corners in editor
			//(Actual) to  (Expected/Pecieved)
			//BR   TR  -->  TL   TR
			//BL   TL  -->  BL   BR
			prime.X = corners[i].Location.Y;    //Rotate point -90 deg (clockwise about origin)
			prime.Y = -corners[i].Location.X;
			prime2.X = prime.X;     //Vertical flip about y axis
			prime2.Y = -prime.Y;
			cornerPoints[i] = prime2;

			if(corners[i].Tag == 'topLeftCorner')
				topLeft = cornerPoints[i];
			if(corners[i].Tag == 'topRightCorner')
				topRight = cornerPoints[i];
			if(corners[i].Tag == 'bottomLeftCorner')
				bottomLeft = cornerPoints[i];
		}

		//translate corner nodes so that topLeft point is at (0,0) and save into mutable array
		for(k = 0; k < 4; k++)
		{
			cornerPoints[k].X += -topLeft.X;
			cornerPoints[k].Y += -topLeft.Y;
		}

		//Distance formula
		mapWidth = sqrt(square(topLeft.X - topRight.X) + square(topLeft.Y - topRight.Y));
		mapHeight = sqrt(square(topLeft.X - bottomLeft.X) + square(topLeft.Y - bottomLeft.Y));
	}
	//Same code as if(demoday)
	else if(WorldInfo.GetMapName() == "flmist")
	{
		//Breaks if map corners at not placed in editor
		if(corners.Length != 4)
		{
			`log("WARNING: Corners not placed in map");
			return;
		}

		//Gets specify tag corners
		for(i = 0; i < 4; i++)
		{
			//Rotates points in odd, confusing axis to standard xy coordinate system
			//Top down view of corners in editor
			//(Actual) to  (Expected/Pecieved)
			//BR   TR  -->  TL   TR
			//BL   TL  -->  BL   BR
			prime.X = corners[i].Location.Y;    //Rotate point -90 deg (clockwise about origin)
			prime.Y = -corners[i].Location.X;
			prime2.X = prime.X;     //Vertical flip about y axis
			prime2.Y = -prime.Y;
			cornerPoints[i] = prime2;

			if(corners[i].Tag == 'topLeftCorner')
				topLeft = cornerPoints[i];
			if(corners[i].Tag == 'topRightCorner')
				topRight = cornerPoints[i];
			if(corners[i].Tag == 'bottomLeftCorner')
				bottomLeft = cornerPoints[i];
		}

		//translate corner nodes so that topLeft point is at (0,0) and save into mutable array
		for(k = 0; k < 4; k++)
		{
			cornerPoints[k].X += -topLeft.X;
			cornerPoints[k].Y += -topLeft.Y;
		}

		//Distance formula
		mapWidth = sqrt(square(topLeft.X - topRight.X) + square(topLeft.Y - topRight.Y));
		mapHeight = sqrt(square(topLeft.X - bottomLeft.X) + square(topLeft.Y - bottomLeft.Y));
	}
	else
		`log("Add findMapDimensions code for map " $ FlashMap.mapName);
	return;
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
	/*screenPoint.X = (((point3D - topDownCam.Location) dot right) / mapWidth) + 0.5;     //Return value from 0 to 1
	screenPoint.Y = (((point3D - topDownCam.Location) dot up) / mapHeight) + 0.5;
	screenPoint.Z = 0; */ //Unused

	//Since world axis is different from screen axis
	//I translate up 1 to match standard euclid plane,
	//rotate along the x/y axis,
	//then translate back down 1 to match screen axis
	/*prime.X = screenPoint.X;
	prime.Y = 1 - screenPoint.Y;
	prime2.X = prime.Y;
	prime2.Y = prime.X;
	screenPoint.X = prime2.X;
	screenPoint.Y = 1 - prime2.Y;*/
	//canvas.SetPos(Canvas.ClipX*0.2,Canvas.ClipY*0.4);
	//canvas.DrawText("X: " $ screenPoint.X $ " | Y: " $ screenPoint.Y);

	//same
	if(FlashMap.mapName == "demoday")
	{
		prime.X = point3D.Y;    //Rotate point -90 deg (clockwise about origin)
		prime.Y = -point3D.X;
		prime2.X = prime.X;     //Vertical flip about y axis
		prime2.Y = -prime.Y;
		prime2.X += -topLeft.X; //Translate to topLeft origin
		prime2.Y += -topLeft.Y;
		prime2.X = abs(prime2.X)/mapWidth;  //0 to 1 ratio of location point 
		prime2.Y = abs(prime2.Y)/mapHeight; //relative to map dimensions.

		screenPoint.X = prime2.X;
		screenPoint.Y = prime2.Y;
	}
	//same
	else if(FlashMap.mapName == "fltemplemaptopplatform")
	{
		prime.X = point3D.Y;    //Rotate point -90 deg (clockwise about origin)
		prime.Y = -point3D.X;
		prime2.X = prime.X;     //Vertical flip about y axis
		prime2.Y = -prime.Y;
		prime2.X += -topLeft.X; //Translate to topLeft origin
		prime2.Y += -topLeft.Y;
		prime2.X = abs(prime2.X)/mapWidth;  //0 to 1 ratio of location point 
		prime2.Y = abs(prime2.Y)/mapHeight; //relative to map dimensions.

		screenPoint.X = prime2.X;
		screenPoint.Y = prime2.Y;
	}
	//same
	else if(FlashMap.mapName == "flmist")
	{
		prime.X = point3D.Y;    //Rotate point -90 deg (clockwise about origin)
		prime.Y = -point3D.X;
		prime2.X = prime.X;     //Vertical flip about y axis
		prime2.Y = -prime.Y;
		prime2.X += -topLeft.X; //Translate to topLeft origin
		prime2.Y += -topLeft.Y;
		prime2.X = abs(prime2.X)/mapWidth;  //0 to 1 ratio of location point 
		prime2.Y = abs(prime2.Y)/mapHeight; //relative to map dimensions.

		screenPoint.X = prime2.X;
		screenPoint.Y = prime2.Y;
	}
	else
	{
		screenPoint.X = -1;
		screenPoint.Y = -1;
	}

	return screenPoint;
}
                          
simulated event DrawHUD()
{
	local SneaktoSlimPawn localPawn, STSPawn;
	//local int selfScoreMostLeft_i;
	local int j; //, k;
	local byte _tNumber;
	//local byte _selfTNumber;
	//local sneaktoslimpawn current;

	local MiniMap map;
	//local vector tempVector;
	//local String mapName;
	//local vector pawnScreenPoint;
	//local Actor obj;
	//local Texture2D background;
	//local TextureRenderTarget2D material;

	local array<bool> existedTeam;

	super.DrawHUD();

	if(PlayerOwner.Pawn!=none)
	{
		self.setCharacterHUD(); //Tells server HUD to set the player hud once the playerowner pawn is non-null

		map =  SneaktoSlimPlayerController_Spectator(SneaktoSlimPawn_Spectator(PlayerOwner.Pawn).Controller).myMap;
		if(FlashMap != NONE/* && map.isOn*/)
		{
			FlashMap.miniMap = map;
			FlashMap.playerIcon.GetObject("player1").SetBool("visible", true);
			FlashMap.player2DScreenPoint[0] = vect(0.25,0.5,0);
			foreach WorldInfo.AllPawns(class 'SneaktoSlimPawn', STSPawn)
			{
				switch(STSPawn.GetTeamNum())
				{
					case 0: FlashMap.playerIcon.GetObject("player1").SetBool("visible", true);
							break;
					case 1: FlashMap.playerIcon.GetObject("player2").SetBool("visible", true);
							break;
					case 2: FlashMap.playerIcon.GetObject("player3").SetBool("visible", true);
							break;
					case 3: FlashMap.playerIcon.GetObject("player4").SetBool("visible", true);
							break;
				}
				FlashMap.player2DScreenPoint[STSPawn.GetTeamNum()] = WorldPointTo2DScreenPoint(STSPawn.Location);
				//FlashMap.faceRotation[STSPawn.GetTeamNum()] = STSPawn.Rotation.Yaw*UnrRotToDeg;
				FlashMap.mouseRotation[STSPawn.GetTeamNum()] = STSPawn.Rotation.Yaw*UnrRotToDeg;
			}

			/*if(self.trackFountain)
			{
				FlashMap.setFountainPoint(WorldPointTo2DScreenPoint(self.fountainLocation));
				FlashMap.rect.SetBool("visible", true);
			}*/
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

		for(j = 0; j < 4; j++)
			existedTeam[j] = false;

		ForEach WorldInfo.AllPawns(class'SneaktoSlimPawn', localPawn) 
		{
			existedTeam[localPawn.GetTeamNum()] = true;
			switch(localPawn.GetTeamNum())
			{
				case 0: FlashHUD.player1Score.SetInt("newScore", scoreBoard[0]);
						FlashHUD.player1Score.SetBool("isOn", true);
						break;
				case 1: FlashHUD.player2Score.SetInt("newScore", scoreBoard[1]);
						FlashHUD.player2Score.SetBool("isOn", true);
						break;
				case 2: FlashHUD.player3Score.SetInt("newScore", scoreBoard[2]);
						FlashHUD.player3Score.SetBool("isOn", true);
						break;
				case 3: FlashHUD.player4Score.SetInt("newScore", scoreBoard[3]);
						FlashHUD.player4Score.SetBool("isOn", true);
						break;
			}
		}

		//Nick: Activates when player no longer exists/quits
		For(j = 0; j < 4; j++) 
		{
			if(existedTeam[j] == false)
			{
				switch(j)
				{
					case 0: FlashHUD.player1Score.SetBool("isOn", false);
							FlashHUD.player1Score.GetObject("Coin").SetBool("visible", false);
							break;
					case 1: FlashHUD.player2Score.SetBool("isOn", false);
							FlashHUD.player2Score.GetObject("Coin").SetBool("visible", false);
							break;
					case 2: FlashHUD.player3Score.SetBool("isOn", false);
							FlashHUD.player3Score.GetObject("Coin").SetBool("visible", false);
							break;
					case 3: FlashHUD.player4Score.SetBool("isOn", false);
							FlashHUD.player4Score.GetObject("Coin").SetBool("visible", false);
							break;
				}
			}
		}



		//draw score on hud at once
		//For(j = 0; j < sneaktoslimgameinfo(worldinfo.Game).TeamOccupied.Length; j++)
		//{
		//	if(sneaktoslimgameinfo(worldinfo.Game).TeamOccupied[j] == true)
		//	{
		//		switch(j)
		//		{
		//			case 0: FlashHUD.player1Score.SetInt("newScore", scoreBoard[j]);
		//					FlashHUD.player1Score.SetBool("isOn", true);
		//					break;
		//			case 1: FlashHUD.player2Score.SetInt("newScore", scoreBoard[j]);
		//					FlashHUD.player2Score.SetBool("isOn", true);
		//					break;
		//			case 2: FlashHUD.player3Score.SetInt("newScore", scoreBoard[j]);
		//					FlashHUD.player3Score.SetBool("isOn", true);
		//					break;
		//			case 3: FlashHUD.player4Score.SetInt("newScore", scoreBoard[j]);
		//					FlashHUD.player4Score.SetBool("isOn", true);
		//					break;
		//		}
		//	}
		//}
		
		//For(j = 0; j < scoreBoard.Length; j++)
		//{
		//	switch(j)
		//	{
		//		case 0: FlashHUD.player1Score.SetInt("newScore", scoreBoard[j]);
		//				FlashHUD.player1Score.SetBool("isOn", true);
		//				break;
		//		case 1: FlashHUD.player2Score.SetInt("newScore", scoreBoard[j]);
		//				FlashHUD.player2Score.SetBool("isOn", true);
		//				break;
		//		case 2: FlashHUD.player3Score.SetInt("newScore", scoreBoard[j]);
		//				FlashHUD.player3Score.SetBool("isOn", true);
		//				break;
		//		case 3: FlashHUD.player4Score.SetInt("newScore", scoreBoard[j]);
		//				FlashHUD.player4Score.SetBool("isOn", true);
		//				break;
		//	}
		//	/*canvas.SetPos(Canvas.ClipX * (0.1 + j * 0.2), Canvas.ClipY * 0.1);
		//	if(colorMarked) // color ppl
		//	{
		//		canvas.SetDrawColorStruct(teamColor[j]);
		//	}
		//	canvas.DrawText(allPplScore[j]);*/

		//	//clean up
		//	//todo: alpha--
		//	//allPplScore[j] = "";

		//}
	}
}//end DrawHuD

simulated event PostRender()
{
	local MiniMap map;

	super.PostRender();

	map =  SneaktoSlimPlayerController_Spectator(SneaktoSlimPawn_Spectator(PlayerOwner.Pawn).Controller).myMap;

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

	if(FlashPause != none)
	{
		FlashPause.TickMap(0);
		FlashPause.scaleObjects(canvas.SizeX, canvas.SizeY);
	}
}

DefaultProperties
{
	colorMarked = true; // default true
	once = false
	//bEnableActorOverlays=true
}
