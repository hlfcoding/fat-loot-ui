class SneaktoSlimPlayerController_Menu extends GamePlayerController
	DLLBind(DllTest);


var string characterName;
var string mapName;
var string gameMode;

var string targetIPAddress;
var string selfIPAddress;
var array<string> IPAddressList;

var int timeLimit;
var int scoreLimit;
var int playerNumLimit;

dllimport final function runWindowsCommand(out string s);

//exec function selectMapInUdk(string inputString)
//{
//	if(inputString != "Null")
//		mapName = inputString;
//}
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

//Menu Two
//get room's IP. This function can be used for refresh
exec function getIPList()
{
	`log("getIPList");
	//need to get IP address from others

}

//join a room
exec function joinRoom()
{
	`log("joinRoom");
	//ConsoleCommand("open "$targetIPAddress$"?"$"Character="$characterName);
}

//Menu Three
exec function selectGameMapInUDK(string inMapName)
{
	`log("selectMap");

	gameMode = "Server";

	if(inMapName == "Mansion")
		mapName = "DemoDay";
	else if(inMapName == "Mist")
		mapName = "FLMist";
	else if(inMapName == "Temple")
		mapName = "FLTempleMap";
	else if(inMapName == "Pit")
		mapName = "DemoDay";
	else
		mapName = inMapName;

}

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
}

//menu 4
exec function selectCharacterInUdk(string inCharacterName)
{
	`log("selectCharacterInUdk "$inCharacterName);
	characterName = inCharacterName;
	//change character's model
}

exec function playTutorialInUdk()
{
	ConsoleCommand("open TutorialSmall?Character=FatLady");
}


exec function joinGameInUdk(string inIpAddress)
{

	local string urlAddress;
	local string windowsCmd;

	//public self ip address, player number, map
	//ConsoleCommand("open "$"map"$"?"$"Character="$characterName);

	`log("open 127.0.0.1"$"?Character="$characterName$" -log");

	if(gameMode == "Client")
	{
		`log("wyliya");
		ConsoleCommand("open 127.0.0.1"$"?Character="$characterName);
	}
	else if(gameMode == "Server")
	{
		createRoom();
		ConsoleCommand("open 127.0.0.1"$"?Character="$characterName);
	}

}

exec function readyButton()
{
	`log("readyButton");
	//boardcast ready status
}

DefaultProperties
{
	characterName = "FatLady"
	mapName = "Null"
	gameMode = "Client"


	targetIPAddress = "127.0.0.1";
	selfIPAddress = "127.0.0.1";
	IPAddressList[0] = "127.0.0.1";

	timeLimit = 300;
	scoreLimit = 5;
	playerNumLimit = 4;
}