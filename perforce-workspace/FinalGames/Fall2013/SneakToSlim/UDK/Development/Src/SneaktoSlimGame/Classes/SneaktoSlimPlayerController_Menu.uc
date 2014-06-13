class SneaktoSlimPlayerController_Menu extends GamePlayerController
	DLLBind(FatLootDllBinding);


var string characterName;
var string mapName;
var string gameMode;

var string targetIPAddress;
var string selfIPAddress;
var array<string> IPAddressList;

var int timeLimit;
var int scoreLimit;
var int playerNumLimit;

var bool disableLoopCalling;
var bool disableLoopCalling_Character;
var bool disableLoopCalling_Map;

var string IPAddress;

var array<clientInfo> clientInfoList;

var bool bGameCreateCoolDown;

dllimport final function runWindowsCommand(out string s);
dllimport final function killTheServer(out string s);
dllimport final function string sendClientMessage(out string inputCommand, out string inputMapName);
dllimport final function openClientInfoFile();
dllimport final function closeClientInfoFile();
dllimport final function string readline();

//exec function selectMapInUdk(string inputString)
//{
//	if(inputString != "Null")
//		mapName = inputString;
//}

simulated event PostBeginPlay()
{
	`log("Menu_controller");

	//setTimer(1,true,'killZeroPlayerServer');
	setTimer(1,true,'updateClientArray');

	IgnoreLookInput(true);
	IgnoreMoveInput(true);

	disableLoopCalling = false;

	//fixing text create problem
	//disable for demoday
	sendMyMessage("query","null");

	bGameCreateCoolDown = false;
}

exec function joinGameScreen(int index)
{
	
}

exec function showCreditInUdk()
{
	ConsoleCommand("open Credit?Character=FatLady");
}

exec function getClientInfo()
{
	local ClientInfo newClientInfo;

	//clean the client info list
	clientInfoList.Remove(0,clientInfoList.Length);

	//read client info list
	openClientInfoFile();

	while(true)
	{
		newClientInfo = new class 'ClientInfo';
		newClientInfo.IPAddress = readline();
		newClientInfo.mapName = readline();

		//`log("IPaddress: "$newClientInfo.IPAddress);
		//`log("Map:" $ newClientInfo.mapName);

		if(newClientInfo.IPAddress == "end" || newClientInfo.mapName == "end"
			||newClientInfo.IPAddress == "" || newClientInfo.mapName == "")
		{
			//`log("quit reading ClientInfo Loop");
			break;
		}

		//`log(newClientInfo.IPAddress);
		//`log(newClientInfo.mapName);
		clientInfoList.AddItem(newClientInfo);
	}
	
	closeClientInfoFile();

	//fix can't get first option problem.
	//if(clientInfoList.Length == 1)
	//	IPAddress = clientInfoList[1].IPAddress;
}

exec function sendMyMessage(string inputCommand, string inputMapName)
{
	sendClientMessage(inputCommand,inputMapName);
}

function updateClientArray()
{
	//disable for demoday
	sendMyMessage("query","null");
	getClientInfo();
}

function resetDisable()
{
	disableLoopCalling = false;
}

function resetDisable_Character()
{
	disableLoopCalling_Character = false;
}

function resetDisable_Map()
{
	disableLoopCalling_Map = false;
}

exec function lobbyScreen()
{
	requestGamesInUdk();
}

exec function requestGamesInUdk()
{

	`log("called" $ disableLoopCalling);

	if(disableLoopCalling == false)
	{	
		disableLoopCalling = true;
		settimer(0.5,false,'resetDisable');
	}
	else
		return;
	//getClientInfo();
	//sneaktoslimHUD_MainMenu(self.myHUD).refreshGameList(clientInfoList);

	sneaktoslimHUD_MainMenu(self.myHUD).refreshGameList(clientInfoList);
	//fix can't get first option problem.
	if(clientInfoList.Length > 0)
		IPAddress = clientInfoList[0].IPAddress;
}

exec function selectGameInUDK(string inIPAddress)
{
	IPAddress = inIPAddress;
}

exec function selectGameMapInUDK(string inMapName)
{
	`log(inMapName);


	if(disableLoopCalling_Map == false)
	{
		disableLoopCalling_Map = true;
		settimer(0.5,false,'resetDisable_Map');
	}
	else 
		return;

	if(inMapName == "Vault")
	{
		mapName = "flmist";
		PlaySound(SoundCue'flsfx.globalAnnouncement.Empress_Basement_Cue');
	}
	else if(inMapName == "Temple")
	{
		mapName = "fltemplemaptopplatform";
		PlaySound(SoundCue'flsfx.globalAnnouncement.Duchess_Arboretum_Cue');
	}
	else
		mapName = "FLMist";
}

exec function selectCharacterInUdk(string inCharacterName)
{
	`log("selectCharacterInUdk "$inCharacterName);

	if(disableLoopCalling_Character == false)
	{
		disableLoopCalling_Character = true;
		settimer(0.5,false,'resetDisable_Character');
	}
	else 
		return;

	characterName = inCharacterName;
	if (characterName == "FatLady")
	{
		PlaySound(SoundCue'flsfx.globalAnnouncement.Lady_Qian_Cue');
	}
	else if (characterName == "GinsengBaby")
	{
		PlaySound(SoundCue'flsfx.globalAnnouncement.GinsengBaby_Cue');
	}
	else if (characterName == "Rabbit")
	{
		PlaySound(SoundCue'flsfx.globalAnnouncement.Tiger_Cue');
	}
	else if (characterName == "Shorty")
	{
		PlaySound(SoundCue'flsfx.globalAnnouncement.Shorty_Cue');
	}
	//change character's model
}


//kill 0 player server
exec function killZeroPlayerServer()
{
	local string outputString;

	//find and kill
	outputString = ": FLMist (0 players)";
	killTheServer(outputString);

	outputString = ": DemoDay (0 players)";
	killTheServer(outputString);

	outputString = ": FLTempleMapTopPlatform (0 players)";
	killTheServer(outputString);
}

//Menu One//
//start tutorial
exec function startTutorialLevel()
{
	`log("open tutorial level");
	//ConsoleCommand("open 127.0.0.1"$"?"$"Character="$characterName);
}

exec function startCreditLevel()
{
	`log("open credit level");
	//ConsoleCommand("open 127.0.0.1"$"?"$"Character="$characterName);
}

exec function quitGameInUdk()
{
	ConsoleCommand("quit");
}

//join a room
exec function joinRoom()
{
	`log("joinRoom");
	//ConsoleCommand("open "$targetIPAddress$"?"$"Character="$characterName);
}

//exec function printFlash()
//{
//	foreach WorldInfo.AllNavigationPoints (class'PlayerStart', playerBase)
//	{					
//		if (playerBase.TeamIndex == SneaktoSlimPawn(self.Pawn).GetTeamNum())
//		{
//			break;
//		}
//	}
//}

//Menu Three


exec function selectTimeLimit(int inTimeLimit)
{
	`log("selectTimeLimit");
	timeLimit = inTimeLimit;
}

exec function selectPlayerNumLimit(int inPlayerNumLimit)
{
	`log("selectPlayerNumLimit");
	PlayerNumLimit = inPlayerNumLimit;
}

exec function selectScoremLimit(int inScoreLimit)
{
	`log("selectScoremLimit");
	ScoreLimit = inScoreLimit;
}

exec function createRoom()
{
	local string urlAddress;

	//check mutiple click
	if(bGameCreateCoolDown == true)
		return;

	bGameCreateCoolDown = true;
	settimer(3, false, 'clearGameCreateCoolDown');
	
	//public self ip address, player number, map
	//ConsoleCommand("open "$"map"$"?"$"Character="$characterName);

	urlAddress = "start ..\\udk.exe server "$mapName$" -silent";

	`log(urlAddress);

	runWindowsCommand(urlAddress);

	//disable for demoday
	sendMyMessage("add",mapName);

	
	
}

function clearGameCreateCoolDown()
{
	bGameCreateCoolDown = false;
}

exec function joinGameInUdk_Host()
{
	createRoom();
	ConsoleCommand("open 127.0.0.1"$"?Character="$characterName);
}

exec function joinGameInUdk_NonHost()
{
	`log("open "$IPAddress$"?Character="$characterName);

	ConsoleCommand("open "$IPAddress$"?Character="$characterName);

}

//menu 4

exec function playTutorialInUdk()
{
	//ConsoleCommand("open TutorialSmall?Character=Tutor");

	local string urlAddress;

	//check mutiple click
	if(bGameCreateCoolDown == true)
		return;

	bGameCreateCoolDown = true;
	settimer(3, false, 'clearGameCreateCoolDown');

	urlAddress = "start ..\\udk.exe server TutorialSmall -silent";

	`log(urlAddress);

	runWindowsCommand(urlAddress);

	ConsoleCommand("open 127.0.0.1?Character=FatLady");
}

exec function setIPAddress(string inIpAddress)
{
	targetIPAddress = inIpAddress;
}

exec function joinGameInUdk(string inIpAddress)
{

	//local string urlAddress;
	//local string windowsCmd;

	//public self ip address, player number, map
	//ConsoleCommand("open "$"map"$"?"$"Character="$characterName);

	//`log("open 127.0.0.1"$"?Character="$characterName$" -log");

	//ConsoleCommand("open 127.0.0.1"$"?Character="$characterName$"?Time="$timeLimit);
	
}


//exec function saySometing()
//{
//	sneaktoslimHUD_MainMenu(self.myHUD).saySomething();
//}

//exec function outputArray()
//{
//	sneaktoslimHUD_MainMenu(self.myHUD).outputArray();
//}

DefaultProperties
{
	characterName = "FatLady"
	mapName = "FLMist"
	gameMode = "Client"


	targetIPAddress = "127.0.0.1";
	selfIPAddress = "127.0.0.1";
	IPAddressList[0] = "127.0.0.1";

	timeLimit = 567;
	scoreLimit = 5;
	playerNumLimit = 4;

	disableLoopCalling = false
	disableLoopCalling_Menu = false
	disableLoopCalling_Map = false

	bGameCreateCoolDown = false
}