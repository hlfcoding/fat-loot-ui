class vase extends Actor
	placeable;

var bool occupied;              //Nick: Set when player enters/exits vase
var bool isBroken;              //Nick: set when another player use vase while player is not NULL
var SneaktoSlimPawn player;     //Nick: Reference to player currently in vase
var Vector playerEntry;
var PathNode originNode;

//Frees vase without it being broken, called in pawn class when AI chases player
function setFree()
{
	occupied = false;                    //Frees vase 
	player.SetHidden(false);             //Makes player visible
	player.hiddenInVase = false; 
	player.SetCollision(true,true,);     //Resets player's collision
	player.enablePlayerMovement();     //Enable's player movement; Uncommment once collision overlay is checked
	player.vaseIMayBeUsing = NONE;
	player.SetLocation(playerEntry);
	player = None;                       //NULL vase's player field so others can use
}

DefaultProperties
{
	//Nick: May not be needed
	Begin Object Class=DrawSphereComponent Name=sphere
		SphereRadius = 20
		HiddenGame = true
		CollideActors = true
	End Object
	//Components.Add(sphere)

	Begin Object Class=CylinderComponent NAME=CollisionCylinder
		CollideActors=true
		CollisionRadius=20
		CollisionHeight=20
		bAlwaysRenderIfSelected=true    
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	//Begin Object Class=FracturedStaticMeshComponent Name=MyMesh
 //       StaticMesh=FracturedStaticMesh'FLInteractiveObject.vase.vase_1_FRACTURED'
	//	Scale=1.0
	//	Translation=(X=0.000000,Y=0.000000,Z=-32.000000)
	//	bUsePrecomputedShadows=True
 //   End Object

	//Components.Add(MyMesh);

	bCollideActors=true
	bBlockActors=true
	bNoEncroachCheck = true     //Enables pawns to move even when overlapping
}
