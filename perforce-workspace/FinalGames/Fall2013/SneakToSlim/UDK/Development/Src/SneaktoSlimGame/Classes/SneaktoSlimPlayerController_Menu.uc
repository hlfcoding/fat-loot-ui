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

var string IPAddress;

var array<clientInfo> clientInfoList;

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

	setTimer(1,true,'killZeroPlayerServer');
	setTimer(1,true,'updateClientArray');

	IgnoreLookInput(true);
	IgnoreMoveInput(true);

	disableLoopCalling = false;
}

exec function joinGameScreen(int index)
{
	//`log("join fucking game");
	//sendMyMessage("query","null");
	//getClientInfo();

	//if(clientInfoList.Length == 0 || index >=  clientInfoList.Length)
	//{
	//	`log("No client info");
	//}
	//else
	//{
	//	ConsoleCommand("open "$clientInfoList[index].IPAddress$"?Character="$characterName$"?Time="$timeLimit);
	//}
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

		if(newClientInfo.IPAddress == "")
		{
			//`log("quit reading ClientInfo Loop");
			break;
		}

		//`log(newClientInfo.IPAddress);
		//`log(newClientInfo.mapName);
		clientInfoList.AddItem(newClientInfo);
	}
	
	closeClientInfoFile();
}

exec function sendMyMessage(string inputCommand, string inputMapName)
{
	sendClientMessage(inputCommand,inputMapName);
}

function updateClientArray()
{
	sendMyMessage("query","null");
	getClientInfo();
}

function resetDisable()
{
	disableLoopCalling = false;
}

exec function requestGamesInUdk()
{
	if(disableLoopCalling == false)
	{
		sneaktoslimHUD_MainMenu(self.myHUD).refreshGameList(clientInfoList);
		disableLoopCalling = true;
		settimer(1,false,'resetDisable');
	}
	//getClientInfo();
	//sneaktoslimHUD_MainMenu(self.myHUD).refreshGameList(clientInfoList);
}

exec function selectGameInUDK(string inIPAddress)
{
	IPAddress = inIPAddress;
}

exec function selectGameMapInUDK(string inMapName)
{
	`log(inMapName);

	if(inMapName == "Vault")
		mapName = "FLMist";
	else if(inMapName == "Temple")
		mapName = "FLTempleMapTopPlatform";
	else
		mapName = "FLMist";

}

exec function selectCharacterInUdk(string inCharacterName)
{
	`log("selectCharacterInUdk "$inCharacterName);
	characterName = inCharacterName;
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
	
	//public self ip address, player number, map
	//ConsoleCommand("open "$"map"$"?"$"Character="$characterName);

	urlAddress = "start ..\\udk.exe server "$mapName$" -log";

	`log(urlAddress);

	runWindowsCommand(urlAddress);
	sendMyMessage("add",mapName);
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
	ConsoleCommand("open TutorialSmall?Character=Tutor");
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


}