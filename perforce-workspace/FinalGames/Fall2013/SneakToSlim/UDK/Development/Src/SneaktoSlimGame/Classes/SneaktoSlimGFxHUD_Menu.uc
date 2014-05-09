class SneaktoSlimGFxHUD_Menu extends GFxMoviePlayer;

var GFxObject Root;
var GFxObject NetworkButton;

function Init(optional LocalPlayer player)
{

	local GFxObject DataProvider;
	local GFxObject TempObj;

	//local GFxObject HudMovieSize;
	super.Init(player);

	Start();
	Advance(0.0f);

	//Root = GetVariableObject("_root");
	
	//`log(root.GetObject("games").GetElementObject(0).GetString("level"));


	//DataProvider = CreateArray();

	//TempObj = CreateObject("Object");

	//TempObj.SetInt("id",0);
	//tempObj.SetString("level","Mist");
	//tempobj.SetInt("playerCount",4);
	//tempObj.SetString("location","127.0.0.1");
 //   DataProvider.SetElementObject(0,tempObj);

	//Root.SetObject("games", DataProvider);

	//`log(root.GetObject("games").GetElementObject(0).GetString("level"));

	//`log("data added");

	`log("init @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
}

function setGames(array<clientInfo> clientInfoList)
{
	local GFxObject DataProvider;
	local GFxObject TempObj;
	local int index;

	Root = GetVariableObject("_root");
		
	DataProvider = CreateArray();

	index = 0;

	`log(clientInfoList.Length);

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

//function saySomething()
//{
//	local GFxObject DataProvider;
//	local GFxObject TempObj;

//	Root = GetVariableObject("_root");
	
//	`log(root.GetObject("games").GetElementObject(0).GetString("level"));


//	DataProvider = CreateArray();

//	TempObj = CreateObject("Object");

//	TempObj.SetInt("id",0);
//	tempObj.SetString("level","Mist");
//	tempobj.SetInt("_playerCount",4);
//	tempObj.SetString("location","127.0.0.1");
//    DataProvider.SetElementObject(0,tempObj);

//	TempObj = CreateObject("Object");

//	TempObj.SetInt("id",1);
//	tempObj.SetString("level","temple");
//	tempobj.SetInt("_playerCount",3);
//	tempObj.SetString("location","128.125.121.141");
//    DataProvider.SetElementObject(1,tempObj);

//	Root.SetObject("games", DataProvider);

//	`log(root.GetObject("games").GetElementObject(0).GetString("level"));

//	`log("data added");
	
//}

//function outputArray()
//{
//	local GFxObject gameArray;
//	local int i;

//	i = 0;
//	Root = GetVariableObject("_root");

//	gameArray = root.GetObject("games");
	
//	while(gameArray.GetElementObject(i) != none)
//	{
//		`log("id:" $ gameArray.GetElementObject(i).GetInt("id"));
//		`log("location:" $ gameArray.GetElementObject(i).GetString("location"));
//		`log("playerCount:" $ gameArray.GetElementObject(i).GetInt("_playerCount"));
//		`log("level:" $ gameArray.GetElementObject(i).GetString("level"));


//		`log("index:" $ i);

//		`log("-------------------------------------------------");
//		i++;
//	}
	
//}

DefaultProperties
{ 
	bDisplayWithHudOff = false
	MovieInfo = SwfMovie'Test.MainMenu'
	//bGammaCorrection = false
}
