class SneaktoSlimHUD_ResultsScreen extends HUD;

var array<int> scoreBoard;
var array<string> playerTypes;
var SneaktoSlimGFxResults FlashResults;
var bool setTextOnce;

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

	determineRanks();

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

function determineRanks()
{
	local int ranks[4];
	local int highestScore, count, count2, rankValue;

	highestScore = -1;
	//Gets highest score
	for(count = 0; count < scoreBoard.Length; count++)
	{
		if(scoreBoard[count] > highestScore)
		{
			highestScore = scoreBoard[count];
		}
	}

	if(highestScore == 0)
	{
		ranks[0] = 2;
		ranks[1] = 2;
		ranks[2] = 2;
		ranks[3] = 2;
	}
	else
	{
		rankValue = 1;
		for(count2 = highestScore; count2 >= 0; count2--)
		{
			for(count = 0; count < scoreBoard.Length; count++)
			{
				if(scoreBoard[count] == count2)
				{
					ranks[count] = rankValue;
				}
			}
			rankValue++;
		}
	}
	adjustFlashScoreboardSizes(ranks);
	`log("Player 1: " $ ranks[0] $ " | " $ "Player 2: " $ ranks[1] $ " | " $ "Player 3: " $ ranks[2] $ " | " $ "Player 4: " $ ranks[3]);
}

function adjustFlashScoreboardSizes(int ranks[4])
{
	local int sizesWidth[4], sizesHeight[4];
	local int count;
	local GFxObject flashScoreboard;

	sizesWidth[0] = 150;
	sizesHeight[0] = 156;
	sizesWidth[1] = 120;
	sizesHeight[1] = 126;
	sizesWidth[2] = 90;
	sizesHeight[2] = 96;
	sizesWidth[3] = 60;
	sizesHeight[3] = 66;

	for(count = 0; count < 4; count++)
	{
		switch(count+1)
		{
			case 1: flashScoreboard = FlashResults.player1Score;
					break;
			case 2: flashScoreboard = FlashResults.player2Score;
					break;
			case 3: flashScoreboard = FlashResults.player3Score;
					break;
			case 4: flashScoreboard = FlashResults.player4Score;
					break;
		}
		switch(ranks[count])
		{
			case 1: flashScoreboard.SetFloat("width", sizesWidth[0]);
					flashScoreboard.SetFloat("height", sizesHeight[0]);
					break;
			case 2: flashScoreboard.SetFloat("width", sizesWidth[1]);
					flashScoreboard.SetFloat("height", sizesHeight[1]);
					break;
			case 3: flashScoreboard.SetFloat("width", sizesWidth[2]);
					flashScoreboard.SetFloat("height", sizesHeight[2]);
					break;
			case 4: flashScoreboard.SetFloat("width", sizesWidth[3]);
					flashScoreboard.SetFloat("height", sizesHeight[3]);
					break;
		}
	}

	switch(scoreboard.Length)
	{
		case 2: FlashResults.player1Score.SetInt("x", FlashResults.player2Score.GetInt("x"));
				FlashResults.player2Score.SetInt("x", FlashResults.player3Score.GetInt("x"));
				break;
		case 3: FlashResults.player1Score.SetInt("x", (FlashResults.player1Score.GetInt("x") + 115));
				FlashResults.player2Score.SetInt("x", (FlashResults.player2Score.GetInt("x") + 115));
				FlashResults.player3Score.SetInt("x", (FlashResults.player3Score.GetInt("x") + 115));
				break;
	}
}

function showAllScores()
{
	FlashResults.player1Score.SetInt("newScore", scoreBoard[0]);
	FlashResults.player1Score.SetBool("isOn", true);

	if(playerTypes.Length > 1)
	{
		FlashResults.player2Score.SetInt("newScore", scoreBoard[1]);
		FlashResults.player2Score.SetBool("isOn", true);
	}
	else
		FlashResults.player2Score.SetBool("isOn", false);
	if(playerTypes.Length > 2)
	{
		FlashResults.player3Score.SetInt("newScore", scoreBoard[2]);
		FlashResults.player3Score.SetBool("isOn", true);
	}
	else
		FlashResults.player3Score.SetBool("isOn", false);
	if(playerTypes.Length > 3)
	{
		FlashResults.player4Score.SetInt("newScore", scoreBoard[3]);
		FlashResults.player4Score.SetBool("isOn", true);
	}
	else
		FlashResults.player4Score.SetBool("isOn", false);
}

event DrawHUD()
{
	super.DrawHUD();

	if(PlayerOwner != none)
	{
		if(!setTextOnce)
		{
			if(PlayerOwner.PlayerInput.bUsingGamepad)
				FlashResults.continueText.GetObject("continueText").SetText("Press 'A' to continue");
			else
				FlashResults.continueText.GetObject("continueText").SetText("Press 'space' to continue");
			setTextOnce = true;
		}
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
	setTextOnce = false;
}
