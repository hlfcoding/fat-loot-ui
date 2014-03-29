/**
 * Copyright 1998-2013 Epic Games, Inc. All Rights Reserved.
 */
class SneaktoSlimGameInfo extends GameInfo;

var byte newPlayerNumber;

var array <PlayerStart> PlayerStartPointsUsed;

var array<SneaktoSlimTreasure> myTreasureBox;

var array<bool> TeamOccupied;


var array<SneakToSlimTreasureSpawnPoint> TreasureSpawnList;
var array<SneakToSlimClothSpawner> ClothSpawnList;

var sneaktoslimplayercontroller sneaktoslimplayercontroller;
var sneaktoslimPawn sneaktoslimPawnArchetype;

var int timePerMatch;
var string uniqueMatchDate;     //Randomly generated number to associate files with a certain game

/**
 * Called when the game info is first initialized
 *
 * @network		Server
 */
event PreBeginPlay()
{
	timePerMatch = 300;
	uniqueMatchDate = TimeStamp();
	uniqueMatchDate = Repl(uniqueMatchDate, ":", ";");    //.txt format doesn't allow colons in filenames
	uniqueMatchDate = Repl(uniqueMatchDate, "/", ",");    //.txt format doesn't allow slashs in filenames

	Super.PreBeginPlay();

	// Initialze the teams
	InitTeamInfos();
	
	InitTeamOccupied();
}

function GameOver()
{
	local SneaktoSlimPawn pawn;

	`log("Time up.");
	foreach WorldInfo.AllPawns(class'SneaktoSlimPawn', pawn)
	{
		//TODO: send each pawn to "level select room"
		//pawn.ConsoleCommand("open SneaktoSlimMenu_LandingPage");
		pawn.showDemoTime("Up!");
	}
}

function updateStatsFile()
{
	local FileWriter f;
	local int count;
	local SneakToSlimAINavMeshController AIController;
	local SneaktoSlimPawn pawn;

	//Opens file
	f = Spawn(class'FileWriter');
	if(f != NONE)
	{
		f.OpenFile(uniqueMatchDate $ " ~ Global - " $ WorldInfo.GetMapName(), FWFT_Stats);
	}

	//Writes to file
	f.Logf("Total AI Guard Catches: ");
	count = 1;

	foreach self.WorldInfo.AllControllers(class 'SneakToSlimAINavMeshController', AIController)
	{
		f.Logf("   Guard " $ count $ " = " $ AIController.totalCatches);
		count++;
	}

	f.Logf("");
	f.Logf("Final Scores: ");
	count = 1;

	foreach self.WorldInfo.AllPawns(class 'SneaktoSlimPawn', pawn)
	{
		f.Logf("   Player " $ count $ " = " $ pawn.playerScore);
		count++;
	}

	//Closes file
	if(f != NONE)
	{
		f.Destroy();
	}
}

event Tick(float deltaTime)
{
	local int currentTime, count;
	local SneaktoSlimPawn pawn;
	local string time;
	local SneakToSlimAINavMeshController AIController;
	local string AICatchText;

	super.Tick(deltaTime);

	AICatchText = "";
	count = 1;
	currentTime = int(GetTimerCount('GameOver',));

	if(currentTime != -1)
	{
		if((timePerMatch - currentTime) % 60 < 10)
		{
			time = (timePerMatch - currentTime) / 60 $ ":0" $ (timePerMatch - currentTime) % 60;
		}
		else
		{
			time = (timePerMatch - currentTime) / 60 $ ":" $ (timePerMatch - currentTime) % 60;
		}
		foreach WorldInfo.AllPawns(class'SneaktoSlimPawn', pawn)
		{
			pawn.showDemoTime(time);
		}
	}
	else
	{
		PauseTimer(true, 'GameOver');
	}
}

// Called after a successful login. This is the first place
// it is safe to call replicated functions on the PlayerController.
//
event PostLogin( PlayerController NewPlayer )
{
	local string Address, StatGuid;
	local int pos, i;
	local Sequence GameSeq;
	local array<SequenceObject> AllInterpActions;

	local int HidePlayer, HideHud, DisableMovement, DisableTurning, DisableInput;

	// update player count
	if (NewPlayer.PlayerReplicationInfo.bOnlySpectator)
	{
		NumSpectators++;
	}
	else if (WorldInfo.IsInSeamlessTravel() || NewPlayer.HasClientLoadedCurrentWorld())
	{
		if(NumPlayers == 0)
			SetTimer(timePerMatch, false, 'GameOver',);
		NumPlayers++;
	}
	else
	{
		NumTravellingPlayers++;
	}

	// Tell the online subsystem the number of players in the game
	UpdateGameSettingsCounts();

	// save network address for re-associating with reconnecting player, after stripping out port number
	Address = NewPlayer.GetPlayerNetworkAddress();
	pos = InStr(Address,":");
	NewPlayer.PlayerReplicationInfo.SavedNetworkAddress = (pos > 0) ? left(Address,pos) : Address;

	// check if this player is reconnecting and already has PRI
	FindInactivePRI(NewPlayer);

	if ( !bDelayedStart )
	{
		// start match, or let player enter, immediately
		bRestartLevel = false;	// let player spawn once in levels that must be restarted after every death
		if ( 	bWaitingToStartMatch )
			StartMatch();
		else
		{
			`log("I am 1"@NewPlayer.pawn.GetTeamNum());
			
			RestartPlayer(newPlayer);
			sneaktoslimpawn(NewPlayer.Pawn).changePlayerColorIndex(sneaktoslimPawn(NewPlayer.Pawn).GetTeamNum());
			`log("I am 3"@sneaktoslimPawn(NewPlayer.Pawn).GetTeamNum());
			`log("I am 5"@self.GetTeamNum());
			//sneaktoslimpawn(NewPlayer.Pawn).drawPlayerColor();
			
		}
		bRestartLevel = Default.bRestartLevel;
	}

	if (NewPlayer.Pawn != None)
	{
		NewPlayer.Pawn.ClientSetRotation(NewPlayer.Pawn.Rotation);
	}

	NewPlayer.ClientCapBandwidth(NewPlayer.Player.CurrentNetSpeed);
	UpdateNetSpeeds();

	GenericPlayerInitialization(NewPlayer);

	// Tell the new player the stat guid
	if (GameReplicationInfo.bMatchHasBegun && OnlineSub != None && OnlineSub.StatsInterface != None)
	{
		// Get the stat guid for the server
		StatGuid = OnlineSub.StatsInterface.GetHostStatGuid();
		if (StatGuid != "")
		{
			NewPlayer.ClientRegisterHostStatGuid(StatGuid);
		}
	}

	// Tell the player to disable voice by default and use the push to talk method
	if (bRequiresPushToTalk)
	{
		NewPlayer.ClientStopNetworkedVoice();
	}
	else
	{
		NewPlayer.ClientStartNetworkedVoice();
	}

	if (NewPlayer.PlayerReplicationInfo.bOnlySpectator)
	{
		NewPlayer.ClientGotoState('Spectating');
	}

	// add the player to any matinees running so that it gets in on any cinematics already running, etc
	GameSeq = WorldInfo.GetGameSequence();
	if (GameSeq != None)
	{
		// find any matinee actions that exist
		GameSeq.FindSeqObjectsByClass(class'SeqAct_Interp', true, AllInterpActions);

		// tell them all to add this PC to any running Director tracks
		for (i = 0; i < AllInterpActions.Length; i++)
		{
			SeqAct_Interp(AllInterpActions[i]).AddPlayerToDirectorTracks(NewPlayer);
		}
	}

	//Check to see if we should start in cinematic mode (matinee movie capture)
	if(ShouldStartInCinematicMode(HidePlayer, HideHud, DisableMovement, DisableTurning, DisableInput))
	{
		NewPlayer.SetCinematicMode(true, HidePlayer == 1, HideHud == 1, DisableMovement == 1, DisableTurning == 1, DisableInput == 1);
	}
	
	//set the players color
	if(NewPlayer.Pawn.Class == class 'sneaktoslimPawn')
	{
		`log("I am 2"@NewPlayer.pawn.GetTeamNum());
		`log("I am 4"@sneaktoslimpawn(NewPlayer.pawn).GetTeamNum());
		
		//sneaktoslimpawn(NewPlayer.Pawn).drawPlayerColor();
		//sneaktoslimPawn(NewPlayer.Pawn).colorIndex = NewPlayer.GetTeamNum();
	}
		
	// Pass on to access control
	if (AccessControl != none)
	{
		AccessControl.PostLogin(NewPlayer);
	}
}

function InitTeamOccupied()
{
	local int i;
	for(i=0;i<=3;i++)
	{
		TeamOccupied[i]=false;
	}
}

function int FindTheFirstEmptyTeam()
{
	local int i;
	for(i=0;i<=3;i++)
	{
		if(TeamOccupied[i]==false)
			return i;
	}
	return 4;
}

function int FindTeamTotalNumber()
{
	local int total_number;
	local int i;

	for(i=0;i<=3;i++)
	{
		if(TeamOccupied[i]==true)
			total_number++;
	}

	return total_number;
}

/**
 * Handles the creation of teams
 *
 * @network		Server
 */
function InitTeamInfos()
{
	local GameReplicationInfo SneaktoSlimGameReplicationInfo;
	local int i;

	// Grab the MOBA game replication info, abort if it does not exist
	SneaktoSlimGameReplicationInfo = GameReplicationInfo;
	`log("SneaktoSlimGameReplicationInfo:"@SneaktoSlimGameReplicationInfo,true,'Lu');
	if (SneaktoSlimGameReplicationInfo == None)
	{
		return;
	}

	// Create the teams
	for (i = 0; i < 5; ++i)
	{
		SneaktoSlimGameReplicationInfo.SetTeam(i, Spawn(class'SneaktoSlimTeamInfo'));
		if (SneaktoSlimGameReplicationInfo.Teams[i] != None)
		{
			SneaktoSlimGameReplicationInfo.Teams[i].TeamIndex = i;
		}
	}
}


auto State PendingMatch
{
Begin:
	StartMatch();
}

/** FindPlayerStart()
* Return the 'best' player start for this player to start from.  PlayerStarts are rated by RatePlayerStart().
* @param Player is the controller for whom we are choosing a playerstart
* @param InTeam specifies the Player's team (if the player hasn't joined a team yet)
* @param IncomingName specifies the tag of a teleporter to use as the Playerstart
* @returns NavigationPoint chosen as player start (usually a PlayerStart)
 */
function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string IncomingName )
{
	local NavigationPoint N, BestStart;
	local Teleporter Tel;

	// allow GameRulesModifiers to override playerstart selection
	if (BaseMutator != None)
	{
		N = BaseMutator.FindPlayerStart(Player, InTeam, IncomingName);
		if (N != None)
		{
			return N;
		}
	}

	// if incoming start is specified, then just use it
	if( incomingName!="" )
	{
		ForEach WorldInfo.AllNavigationPoints( class 'Teleporter', Tel )
			if( string(Tel.Tag)~=incomingName )
				return Tel;
	}

	// always pick StartSpot at start of match
	if ( ShouldSpawnAtStartSpot(Player) &&
		(PlayerStart(Player.StartSpot) == None || RatePlayerStart(PlayerStart(Player.StartSpot), InTeam, Player) >= 0.0) )
	{
		return Player.StartSpot;
	}

	BestStart = ChoosePlayerStart(Player, InTeam);

	if ( (BestStart == None) && (Player == None) )
	{
		// no playerstart found, so pick any NavigationPoint to keep player from failing to enter game
		`log("Warning - PATHS NOT DEFINED or NO PLAYERSTART with positive rating");
		ForEach AllActors( class 'NavigationPoint', N )
		{
			if(N.GetTeamNum() == InTeam)
			{
				BestStart = N;
				break;
			}
		}
	}
	return BestStart;
}

function PrintPri()
{
	local int i;
	for(i=0;i<self.GameReplicationInfo.PRIArray.Length;i++)
	{
		`Log(i@" team "@GameReplicationInfo.PRIArray[i].Team.TeamIndex);
	}
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local NavigationPoint StartSpot;
	local PlayerController NewPlayer;
	local string InName, InCharacter/*, InAdminName*/, InPassword;
	local byte InTeam;
	local bool bSpectator, bAdmin, bPerfTesting;
	local rotator SpawnRotation;
	local UniqueNetId ZeroId;
	local int SupposeTeam;
	local bool IsSpectator;


	// Get URL options.
	InName     = Left(ParseOption ( Options, "Name"), 20);

	InCharacter = ParseOption(Options, "Character");
	NewPlayer.SetCharacter(InCharacter);

	//get suppose team
	SupposeTeam=FindTheFirstEmptyTeam();
	if(InCharacter == "Spectator")
	{
		`log("enter spectator mode");
		//IsSpectator=true;
		SupposeTeam = 4;
		//return None;
	}

	bAdmin = false;

	// Kick the player if they joined during the handshake process
	if (bUsingArbitration && bHasArbitratedHandshakeBegun)
	{
		ErrorMessage = PathName(WorldInfo.Game.GameMessageClass) $ ".ArbitrationMessage";
		return None;
	}

	if ( BaseMutator != None )
		BaseMutator.ModifyLogin(Portal, Options);

	bPerfTesting = ( ParseOption( Options, "AutomatedPerfTesting" ) ~= "1" );
	bSpectator = bPerfTesting || ( ParseOption( Options, "SpectatorOnly" ) ~= "1" );

	

	//InTeam     = GetIntOption( Options, "Team", 255 ); // default to "no team"
	//if(IsSpectator==true)
	//	InTeam= 255;
	//else
		InTeam = SupposeTeam;
	
	//InAdminName= ParseOption ( Options, "AdminName");
	InPassword = ParseOption ( Options, "Password" );
	//InChecksum = ParseOption ( Options, "Checksum" );

	if ( AccessControl != None )
	{
		bAdmin = AccessControl.ParseAdminOptions(Options);
	}

	// Make sure there is capacity except for admins. (This might have changed since the PreLogin call).
	if ( !bAdmin && AtCapacity(bSpectator) )
	{
		ErrorMessage = PathName(WorldInfo.Game.GameMessageClass) $ ".MaxedOutMessage";
		return None;
	}

	// if this player is banned, kick him
	if( ( WorldInfo.Game.AccessControl != none ) && (WorldInfo.Game.AccessControl.IsIDBanned(UniqueId)) )
	{
		`Log(InName @ "is banned, rejecting...");
		ErrorMessage = "Engine.AccessControl.SessionBanned";
		return None;
	}

	// If admin, force spectate mode if the server already full of reg. players
	if ( bAdmin && AtCapacity(false) )
	{
		bSpectator = true;
	}

	// Pick a team (if need teams)
	InTeam = PickTeam(InTeam,None);

	// Find a start spot.
	StartSpot = FindPlayerStart( None, InTeam, Portal );

	if( StartSpot == None )
	{
		ErrorMessage = PathName(WorldInfo.Game.GameMessageClass) $ ".FailedPlaceMessage";
		return None;
	}

	SpawnRotation.Yaw = StartSpot.Rotation.Yaw;
	//NewPlayer = SpawnPlayerController(StartSpot.Location, SpawnRotation);

	//choose different character by character's name
	if (InCharacter == "FatLady")
	{
		NewPlayer = Spawn(class 'SneaktoSlimPlayerController_FatLady',,, StartSpot.Location, SpawnRotation);
		NewPlayer.Pawn = Spawn(class 'SneaktoSlimPawn_FatLady',,,StartSpot.Location,SpawnRotation);
	}
	else if (InCharacter == "Rabbit")
	{
		NewPlayer = Spawn(class 'SneaktoSlimPlayerController_Rabbit',,, StartSpot.Location, SpawnRotation);
		NewPlayer.Pawn = Spawn(class 'SneaktoSlimPawn_Rabbit',,,StartSpot.Location,SpawnRotation);
	}
	else if (InCharacter == "GinsengBaby")
	{
		NewPlayer = Spawn(class 'SneaktoSlimPlayerController_GinsengBaby',,, StartSpot.Location, SpawnRotation);
		NewPlayer.Pawn = Spawn(class 'SneaktoSlimPawn_GinsengBaby',,,StartSpot.Location,SpawnRotation);
	}
	else if (InCharacter == "Shorty")
	{
		NewPlayer = Spawn(class 'SneaktoSlimPlayerController_Shorty',,, StartSpot.Location, SpawnRotation);
		NewPlayer.Pawn = Spawn(class 'SneaktoSlimPawn_Shorty',,,StartSpot.Location,SpawnRotation);
	}
	else if (InCharacter == "Spectator")
	{
		NewPlayer = Spawn(class 'SneaktoSlimPlayerController_Spectator',,, StartSpot.Location, SpawnRotation);
		NewPlayer.Pawn = Spawn(class 'SneaktoSlimPawn_Spectator',,,StartSpot.Location,SpawnRotation);
	}
	else if (InCharacter == "Menu")
	{
		NewPlayer = Spawn(class 'SneaktoSlimGame.SneaktoSlimPlayerController_Menu',,, StartSpot.Location, SpawnRotation);
		NewPlayer.Pawn = Spawn(class 'SneaktoSlimGame.SneaktoSlimPawn_Menu',,,StartSpot.Location,SpawnRotation);
		HUDType=class'Engine.HUD'; //disable in-game HUD
	}
	else
	{
		NewPlayer = Spawn(class 'SneaktoSlimPlayerController',,, StartSpot.Location, SpawnRotation);
		NewPlayer.Pawn = Spawn(class 'SneaktoSlimPawn',,,StartSpot.Location,SpawnRotation);
	}

	//attach PlayerReplicationInfo
	if(!IsSpectator && InTeam < 4)
	{
		NewPlayer.PlayerReplicationInfo = GameReplicationInfo.PRIArray[GameReplicationInfo.PRIArray.Length-1];
		NewPlayer.PlayerReplicationInfo.SetPlayerTeam(GameReplicationInfo.Teams[SupposeTeam]);
		NewPlayer.PlayerReplicationInfo.Team.TeamIndex=SupposeTeam;
		TeamOccupied[SupposeTeam]=true;
		newPlayerNumber=FindTeamTotalNumber();
	}
	else
	{
		NewPlayer.PlayerReplicationInfo = GameReplicationInfo.PRIArray[GameReplicationInfo.PRIArray.Length-1];
		NewPlayer.PlayerReplicationInfo.SetPlayerTeam(GameReplicationInfo.Teams[SupposeTeam]);
		NewPlayer.PlayerReplicationInfo.Team.TeamIndex=SupposeTeam;
	}
	
	//`Log("team "@NewPlayer.PlayerReplicationInfo.Team.TeamIndex@" in, total number "@newPlayerNumber@" supposed to be"@SupposeTeam);
	//`Log(TeamOccupied[0]@" "@TeamOccupied[1]@" "@TeamOccupied[2]@" "@TeamOccupied[3]);

	//PrintPri();

	// Handle spawn failure.
	if( NewPlayer == None )
	{
		`log("Couldn't spawn player controller of class "$PlayerControllerClass);
		ErrorMessage = PathName(WorldInfo.Game.GameMessageClass) $ ".FailedSpawnMessage";
		return None;
	}

	NewPlayer.StartSpot = StartSpot;

	// Set the player's ID.
	NewPlayer.PlayerReplicationInfo.PlayerID = GetNextPlayerID();

	// If the access control is currently authenticating the players UID, don't store the UID until it is authenticated
	if (AccessControl == none || !AccessControl.IsPendingAuth(UniqueId))
	{
		NewPlayer.PlayerReplicationInfo.SetUniqueId(UniqueId);
	}

	if (OnlineSub != None && 
		OnlineSub.GameInterface != None &&
		UniqueId != ZeroId)
	{
		// Go ahead and register the player as part of the session
		WorldInfo.Game.OnlineSub.GameInterface.RegisterPlayer(PlayerReplicationInfoClass.default.SessionName, UniqueId, HasOption(Options, "bIsFromInvite"));
	}
	// Now that the unique id is replicated, this player can contribute to skill
	RecalculateSkillRating();

	// Init player's name
	if( InName=="" )
	{
		InName=DefaultPlayerName$NewPlayer.PlayerReplicationInfo.PlayerID;
	}

	ChangeName( NewPlayer, InName, false );

	

	if ( bSpectator || NewPlayer.PlayerReplicationInfo.bOnlySpectator || !ChangeTeam(newPlayer, InTeam, false) )
	{
		NewPlayer.GotoState('Spectating');
		NewPlayer.PlayerReplicationInfo.bOnlySpectator = true;
		NewPlayer.PlayerReplicationInfo.bIsSpectator = true;
		NewPlayer.PlayerReplicationInfo.bOutOfLives = true;
		return NewPlayer;
	}

	// perform auto-login if admin password/name was passed on the url
	if ( AccessControl != None && AccessControl.AdminLogin(NewPlayer, InPassword) )
	{
		AccessControl.AdminEntered(NewPlayer);
	}


	// if delayed start, don't give a pawn to the player yet
	// Normal for multiplayer games
	if ( bDelayedStart )
	{
		// @todo ib2merge: Chair had this commented out
		NewPlayer.GotoState('PlayerWaiting');
		return NewPlayer;
	}

	return newPlayer;
}

event PostBeginPlay()
{
	local SneaktoSlimTreasure tmpTreasureBox;
	if(Role == Role_Authority){
	    TreasureInit();
	}
	ClothInit();
	foreach AllActors(class 'SneaktoSlimTreasure',tmpTreasureBox)
	{
		myTreasureBox.AddItem(tmpTreasureBox);
	}
	
}

simulated function TreasureInit()
{
	local SneakToSlimTreasureSpawnPoint TSP;
	local SneaktoSlimTreasure myTreasure;
	local int TSPnum ,index;
    
	TSPnum = 0;
	foreach AllActors(class'SneakToSlimTreasureSpawnPoint',TSP)
	{
		TSPnum++;
		TSP.LightBeamEffectRef.SetHidden(true);
	}
	index = Rand(TSPnum);
	foreach AllActors(class'SneakToSlimTreasureSpawnPoint',TSP)
	{
		if(TSP.BoxIndex == index){
            myTreasure=TSP.SpawnTreasure();
			myTreasure.CurrentSpawnPointIndex = index;
		}
	}
    
	
	`Log("complete searching all the TSP" @myTreasure.Location,true,'alex');
}



function ClothInit()
{
	local SneakToSlimClothSpawner CSP;
	local SneaktoSlimCloth myCloth;
	local int i;

	foreach AllActors(class'SneakToSlimClothSpawner',CSP)
	{
		//ClothSpawnList[ClothSpawnList.Length] = CSP;
		ClothSpawnList.AddItem(CSP);
	}

	for(i=0; i<ClothSpawnList.Length; i++)
	{
		myCloth = ClothSpawnList[i].SpawnCloth();
		//myTreasure.SpawnPoints[i]=TreasureSpawnList[i].Location;
		myCloth.SpawnPoints[i] = CSP.Location;
	}

		`Log("complete searching all the CSP" @myCloth.Location,true,'alex');
}

/** spawns a PlayerController at the specified location; split out from Login()/HandleSeamlessTravelPlayer() for easier overriding */
function PlayerController SpawnPlayerController(vector SpawnLocation, rotator SpawnRotation)
{
	return Spawn(PlayerControllerClass,,, SpawnLocation, SpawnRotation);
}

function Pawn SpawnDefaultPawnFor(Controller NewPlayer, NavigationPoint StartSpot)
{
	local class<Pawn> DefaultPlayerClass;
	local Rotator StartRotation;
	local Pawn ResultPawn;

	DefaultPlayerClass = GetDefaultPlayerClass(NewPlayer);

	// don't allow pawn to be spawned with any pitch or roll
	StartRotation.Yaw = StartSpot.Rotation.Yaw;


	//modified
	if(DefaultPlayerClass == class 'SneaktoSlimPawn')
	{
		ResultPawn = Spawn(DefaultPlayerClass,,,StartSpot.Location,StartRotation,sneaktoslimPawnArchetype);
	}
	else
	{
		ResultPawn = Spawn(DefaultPlayerClass,,,StartSpot.Location,StartRotation);
	}

	
	if ( ResultPawn == None )
	{
		`log("Couldn't spawn player of type "$DefaultPlayerClass$" at "$StartSpot);
	}

	return ResultPawn;
}

exec function findTreasureBox()
{
	local int i;
	local SneaktoSlimPawn tmpPawn;
	for(i=0;i<myTreasureBox.Length;++i)
	{
		myTreasureBox[i].setBeingTracked();
	}
	foreach worldinfo.AllPawns(class 'SneaktoSlimPawn', tmpPawn){
		if(tmpPawn.isGotTreasure)
			tmpPawn.setBeingTracked();
	}
}

exec function stopFindingTreasureBox()
{
	local int i;
	local SneaktoSlimPawn tmpPawn;
	for(i=0;i<myTreasureBox.Length;++i)
	{
		myTreasureBox[i].releaseBeingTracked();
	}
	foreach worldinfo.AllPawns(class 'SneaktoSlimPawn', tmpPawn){
		if(tmpPawn.isGotTreasure)
			tmpPawn.releaseBeingTracked();
	}
}

function Logout( Controller Exiting )
{
	SearchDestroyPlayer(Exiting);
	super.Logout(Exiting);
	if(Exiting.PlayerReplicationInfo.Team!=none)
		TeamOccupied[SneaktoSlimPlayerController(Exiting).PlayerReplicationInfo.Team.TeamIndex]=false;	
	ServerPrintOccupied();
}

Server Reliable function ServerPrintOccupied()
{
	`Log(SELF.TeamOccupied[0]@SELF.TeamOccupied[1]@SELF.TeamOccupied[2]@SELF.TeamOccupied[3],true,'alex');
}

function SearchDestroyPlayer(Controller Exiting)
{
	Local SneaktoSlimPawn Current;
	foreach AllActors(class'SneaktoSlimPawn',Current)
	{
		if(SneaktoSlimPlayerController(Current.Controller)==none)
		{
			if(Current.isGotTreasure == true){
				Current.LostTreasure();
			}
			Current.Destroy();
			`Log("find one");
		}
	}
	`Log("destroy has been called");
}


defaultproperties
{
	HUDType=class'SneaktoSlimGame.SneaktoSlimHUD'
	PlayerControllerClass=class'SneaktoSlimGame.SneaktoSlimPlayerController'
	DefaultPawnClass=class'SneaktoSlimGame.SneaktoSlimPawn'
	bDelayedStart=false
	newPlayerNumber=0
	sneaktoslimPawnArchetype = SneaktoSlimPawn'FLCharacter.FLPawnArchetype'
	GameReplicationInfoClass=class'SneaktoSlimGameReplicationInfo'
}


