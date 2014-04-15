class SneaktoSlimHUD_ResultsScreen extends HUD;

var array<int> scoreBoard;
var array<string> playerTypes;
var SneaktoSlimGFxResults FlashResults;

singular event Destroyed()
{
	if(FlashResults != none)
	{
		FlashResults.Close(true);
		FlashResults = none;
	}

	super.Destroyed();
}

event PostBeginPlay()
{
	local SaveGameState sgs;
	local int count;

	super.PostBeginPlay();

	//Creates and initializes flash UI
	FlashResults = new class 'SneaktoSlimGFxResults';
	FlashResults.Init(class 'Engine'.static.GetEngine().GamePlayers[FlashResults.LocalPlayerOwnerIndex]);
	FlashResults.SetViewScaleMode(SM_NoScale);
	FlashResults.SetAlignment(Align_TopLeft);

	count = 0;
	sgs = new class 'SaveGameState';

	class'Engine'.static.BasicLoadObject(sgs, "GameResults.bin", true, 1);

	for(count = 0; count < sgs.characterType.Length; count++)
	{
		scoreBoard.AddItem(sgs.scoreBoard[count]);
		playerTypes.AddItem(sgs.characterType[count]);
	}

	for(count = 1; count <= scoreBoard.Length; count++)
	{
		class'Engine'.static.BasicLoadObject(sgs, "GameResultsPlayer" $ count $ ".bin", true, 1);
		`log("HUD Player " $ count $ " Stats");
		`log("  Character: " $ sgs.character);
		`log("  Caught #: " $ sgs.timesCaughtByGuards);
		`log("  First Skill #: " $ sgs.timesFirstSkillUsed);
		`log("  Second Skill #: " $ sgs.timesSecondSkillUsed);
		`log("  Treasure #: " $ sgs.timesTreasureLost);
	}
}

event DrawHUD()
{
	super.DrawHUD();

	Canvas.DrawColor=WhiteColor;
	Canvas.Font=class'Engine'.static.GetLargeFont();

	if(playerTypes.Length >= 0)
	{
		canvas.SetPos(Canvas.ClipX*0.1,Canvas.ClipY*0.2);
		canvas.DrawText("Player 1 - Score = " $ scoreboard[0]);
	}
	if(playerTypes.Length > 1)
	{
		canvas.SetPos(Canvas.ClipX*0.3,Canvas.ClipY*0.2);
		canvas.DrawText("Player 2 - Score = " $ scoreboard[1]);
	}
	if(playerTypes.Length > 2)
	{
		canvas.SetPos(Canvas.ClipX*0.5,Canvas.ClipY*0.2);
		canvas.DrawText("Player 3 - Score = " $ scoreboard[2]);
	}
	if(playerTypes.Length > 3)
	{
		canvas.SetPos(Canvas.ClipX*0.7,Canvas.ClipY*0.2);
		canvas.DrawText("Player 4 - Score = " $ scoreboard[3]);
	}

	if(PlayerOwner.PlayerInput.bUsingGamepad)
	{
		canvas.SetPos(Canvas.ClipX*0.5,Canvas.ClipY*0.1);
		canvas.DrawText("Press 'A' to continue");
	}
	else
	{
		canvas.SetPos(Canvas.ClipX*0.5,Canvas.ClipY*0.1);
		canvas.DrawText("Press 'space' to continue");
	}
}

simulated event PostRender()
{
	super.PostRender();

	if(FlashResults != none)
	{
		FlashResults.TickHud(0);
		FlashResults.scaleObjects(canvas.SizeX, canvas.SizeY);
	}
}

DefaultProperties
{
}
