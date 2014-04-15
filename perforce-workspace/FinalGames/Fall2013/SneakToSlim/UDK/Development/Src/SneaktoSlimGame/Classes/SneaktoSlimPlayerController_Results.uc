class SneaktoSlimPlayerController_Results extends GamePlayerController
	DLLBind(DllTest);

dllimport final function killTheServer(out string s);

simulated event PostBeginPlay()
{
	//setTimer(1,true,'killZeroPlayerServer');
}

exec function killZeroPlayerServer()
{
	local string i;

	i = ": DemoDay (0 players)";
	killTheServer(i);
}

DefaultProperties
{
}
