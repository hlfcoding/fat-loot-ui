/**
 * Copyright 1998-2013 Epic Games, Inc. All Rights Reserved.
 */
class SneaktoSlimFatLadyController extends SneaktoslimPlayerController
	config(Game);

exec function showFatLootClassName()
{
	`log(self.Pawn.Class);
	`log(self.Class);
}

defaultproperties
{
}
