class SneakToSlimTeleportTrigger extends Trigger placeable;

var SneaktoSlimPawn tempUser;
var SneakToSlimTeleportDestinationNode Destination;

simulated event PostBeginPlay()
{
	Local SneakToSlimTeleportDestinationNode node;
    foreach allactors(class 'SneakToSlimTeleportDestinationNode', node) 
	{
		if(Tag == node.Tag)
		{
			Destination = node;
			break;
		}
	}
}

event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
    
	//`log("treasure touch anyway");
	if(string(Other.Class) == "SneaktoSlimPawn")
	{
		//SetHidden(true);
		tempUser = SneaktoSlimPawn(Other);
		
		//tempUser.ChangeMesh(true);
        tempUser.SetLocation(Destination.Location);
		tempUser.SetRotation(Destination.Rotation);
		

	}
}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
        StaticMesh= StaticMesh'FLInteractiveObject.Portal.PortalBase'
		Scale=1.0
		Translation=(Z=-200.0)
		bUsePrecomputedShadows=True
		//LightEnvironment=MyLightEnvironment
    End Object
    Components.Remove(Sprite)
	Components.Add(MyStaticMeshComponent)

	CollisionComponent=MyStaticMeshComponent 
    bHidden=false
}
