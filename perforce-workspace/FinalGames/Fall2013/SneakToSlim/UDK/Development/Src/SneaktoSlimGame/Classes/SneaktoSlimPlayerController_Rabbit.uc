class SneaktoSlimPlayerController_Rabbit extends SneaktoslimPlayerController
	config(Game);

exec function showFatLootClassName()
{
	`log(self.Pawn.Class);
	`log(self.Class);
}

defaultproperties
{
}
