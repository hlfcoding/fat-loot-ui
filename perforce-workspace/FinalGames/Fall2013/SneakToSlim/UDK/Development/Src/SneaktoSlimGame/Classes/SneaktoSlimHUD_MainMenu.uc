class SneaktoSlimHUD_MainMenu extends HUD;

var SneaktoSlimGFxHUD_Menu FlashMenu;

singular event Destroyed()
{
	super.Destroyed();
}

event PostBeginPlay()
{
	super.PostBeginPlay();

	//Creates and initializes flash UI
	FlashMenu = new class 'SneaktoSlimGFxHUD_Menu';
	FlashMenu.Init();
	`log("mainMenu................................................................");
	//FlashResults.SetViewScaleMode(SM_NoScale);
	//FlashResults.SetAlignment(Align_TopLeft);
}

event DrawHUD()
{
	super.DrawHUD();
}

simulated event PostRender()
{
	super.PostRender();
}

function refreshGameList(array<clientInfo> clientInfoList)
{
	FlashMenu.setGames(clientInfoList);
}

//function saySomething()
//{
//	FlashMenu.saySomething();
//}

//function outputArray()
//{
//	FlashMenu.outputArray();
//}

DefaultProperties
{
	setTextOnce = false;
}
