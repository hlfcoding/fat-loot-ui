//In order to use, call Spawn(class 'soundSphere',,,Location);

class soundSphere extends Actor
	placeable;

var DrawSphereComponent body;
var CylinderComponent	CylinderComponent;
var PathNode origin;
var float soundRadius;

event PostBeginPlay()
{ 
}

//Set when vase brakes
function setOriginNode(PathNode node)
{
	local SneakToSlimAIPawn HitActor;
	local SneakToSlimAIController controller;

	origin = node;

	foreach CollidingActors( class'SneakToSlimAIPawn', HitActor, soundRadius, origin.Location)
	{
		//`log("soundsphere found actor " $ HitActor.Name);
		controller = SneakToSlimAIController(HitActor.Controller);
		if(controller.investigateLocation(origin.Location))
		{
			break; //get out of loop if an AI guard went to investigate
		}
	}
}

event Tick (float DeltaTime)
{
	local float scale;

	scale = 10.0;
	body.SphereRadius += scale;
	CylinderComponent.SetCylinderSize(CylinderComponent.CollisionRadius + scale, CylinderComponent.CollisionHeight + scale);
	if(body.SphereRadius > soundRadius)
	{
		ShutDown();
		//`log("Noise is gone");
	}
	body.ForceUpdate(false);
}

DefaultProperties
{
	Begin Object Class=DrawSphereComponent Name=sphere
		SphereRadius = 1
		HiddenGame = false
		CollideActors = true
	End Object
	body = sphere
	//Components.Add(sphere)  
	
	Begin Object Class=CylinderComponent NAME=CollisionCylinder
		CollideActors=true
		CollisionRadius=1
		CollisionHeight=1
		bAlwaysRenderIfSelected=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	bCollideActors=true
	bBlockActors=false
	bHidden=false

	soundRadius = 900
}
