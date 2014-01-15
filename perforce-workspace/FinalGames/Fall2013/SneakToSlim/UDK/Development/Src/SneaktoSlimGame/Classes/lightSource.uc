class lightSource extends Actor
	placeable;

var SneaktoSlimPawn players[4];     // Reference to players currently under light
var PathNode originNode;
var () float distance;
var () float angle;
var () Vector lightLookDirection;
var DrawSphereComponent rangeIndicator;
var CylinderComponent collider;
var bool bturn_on;

function Toggle()
{
	if(bturn_on)
		bturn_on=false;
	else
		bturn_on=true;
}

function setRadius (float radius)
{
	distance = radius;
	collider.SetCylinderSize(radius, 200);
	rangeIndicator.SphereRadius = radius;
	rangeIndicator.ForceUpdate(false);
	rangeIndicator.SetHidden(true);
}

DefaultProperties
{
	distance = 75
	angle = 360

	Begin Object Class=DrawSphereComponent Name=sphere
		SphereRadius = 75
		HiddenGame = true
		CollideActors = true
	End Object
	rangeIndicator=sphere
	Components.Add(sphere)

	Begin Object Class=CylinderComponent NAME=CollisionCylinder
		CollideActors=true
		CollisionRadius= 75
		CollisionHeight = 100
		bAlwaysRenderIfSelected=true    
	End Object
	CollisionComponent=CollisionCylinder
	collider=CollisionCylinder
	Components.Add(CollisionCylinder)

	bCollideActors=true
	bBlockActors=true
	bNoEncroachCheck = true     //Enables pawns to move even when overlapping

	bturn_on = true //control the signal light
}
