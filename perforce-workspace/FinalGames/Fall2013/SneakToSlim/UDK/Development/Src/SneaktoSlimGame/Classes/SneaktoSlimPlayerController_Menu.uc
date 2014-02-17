class SneaktoSlimPlayerController_Menu extends GamePlayerController;

var string characterName;
var string mapName;
var string gameMode;

var string targetIPAddress;
var string selfIPAddress;
var array<string> IPAddressList;

var int timeLimit;
var int scoreLimit;
var int playerNumLimit;

exec function selectMapInUdk(string inputString)
{
	if(inputString != "Null")
		mapName = inputString;
}

exec function selectClientorServerInUdk(string inputString)
{
	if(inputString != "Null")
		gameMode = inputString;

	//`log("open " $mapName$"?"$"Character="$characterName);
	
	if(gameMode == "Server")
		ConsoleCommand("open server " $mapName$" -log");
	else if(gameMode == "Client")
		ConsoleCommand("open 127.0.0.1"$"?"$"Character="$characterName);
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
exec function selectMap(string inMapName)
{
	`log("selectMap");
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
	`log("createRoom");
	//public self ip address, player number, map
	//ConsoleCommand("open "$"map"$"?"$"Character="$characterName);
}

//menu 4
exec function selectCharacterInUdk(string inCharacterName)
{
	`log("selectCharacterInUdk ");
	characterName = inCharacterName;
	//change character's model
}

exec function readyButton()
{
	`log("readyButton");
	//boardcast ready status
}




DefaultProperties
{
	characterName = "FatLady"
	mapName = "DemoDay"
	gameMode = "Server"


	targetIPAddress = "127.0.0.1";
	selfIPAddress = "127.0.0.1";
	IPAddressList[0] = "127.0.0.1";

	timeLimit = 300;
	scoreLimit = 5;
	playerNumLimit = 4;
}