class SneaktoSlimGameReplicationInfo extends GameReplicationInfo
	DLLBind(FatLootDllBinding);

dllimport final function runWindowsCommand(out string s);
dllimport final function killTheServer(out string s);
dllimport final function string sendClientMessage(out string inputCommand, out string inputMapName);
dllimport final function openClientInfoFile();
dllimport final function closeClientInfoFile();
dllimport final function string readline();

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	if(worldInfo.NetMode == NM_DedicatedServer)
	{
		settimer(2.0,true,'sendGameInfo');
	}

	worldInfo.GetMapName();
	//setTimer(2.0,true,'killZeroPlayerServer');
}

function sendMyMessage(string inputCommand, string inputMapName)
{
	sendClientMessage(inputCommand,inputMapName);
}

function sendGameInfo(name VarName)
{
	//`log("increaseServerGameTime");
	//`log(worldInfo.NetMode);


	//disable for demoday
	//sendMyMessage("add",worldInfo.GetMapName());


	//`log(worldInfo.GetMapName());
}


function killZeroPlayerServer()
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




DefaultProperties
{

}
