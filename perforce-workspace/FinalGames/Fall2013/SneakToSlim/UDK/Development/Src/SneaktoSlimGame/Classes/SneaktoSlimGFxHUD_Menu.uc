class SneaktoSlimGFxHUD_Menu extends GFxMoviePlayer;

var GFxObject Root;
var GFxObject NetworkButton;

function Init(optional LocalPlayer player)
{	
	super.Init(player);
	Start();
	Advance(0.0f);	
}

function setGames(array<clientInfo> clientInfoList)
{
	local GFxObject DataProvider;
	local GFxObject TempObj;
	local int index;

	Root = GetVariableObject("_root");
		
	DataProvider = CreateArray();

	index = 0;

	//`log(clientInfoList.Length);

	while(index < clientInfoList.Length)
	{
		TempObj = CreateObject("Object");

		TempObj.SetInt("id",index);
		tempObj.SetString("level",clientInfoList[index].mapName);
		tempobj.SetInt("_playerCount",0);
		tempObj.SetString("location",clientInfoList[index].IPAddress);
		DataProvider.SetElementObject(index,tempObj);
		index++;
	}

	Root.SetObject("games", DataProvider);
}

DefaultProperties
{ 
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.MainMenu'
	//bGammaCorrection = false
}
