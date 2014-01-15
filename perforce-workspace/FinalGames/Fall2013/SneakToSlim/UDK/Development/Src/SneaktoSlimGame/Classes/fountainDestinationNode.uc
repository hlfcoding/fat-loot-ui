class fountainDestinationNode extends PathNode;

function bool checkIfOccupied()
{
	//local SneaktoSlimPawn pawn;

	/*foreach CollidingActors(class 'SneaktoSlimPawn', pawn, 20) {
		`Log(pawn.Name $ " near pathnode");
		return true;
	}*/
	return false;
}

DefaultProperties
{
	Begin Object Class=DrawSphereComponent Name=sphere
		SphereRadius = 20
		HiddenGame = true
	End Object
	Components.Add(sphere)
}
