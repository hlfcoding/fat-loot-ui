class drumTrigger extends Trigger;

var const float effectRadius;
var PathNode originNode;

var SoundCue scDrumSound;

//Gets drum's associated location node
function setOriginNode()
{
	local PathNode node;

	ForEach WorldInfo.AllActors(class'PathNode', node) 
	{
		if(Tag == node.Tag)
		{
			originNode = node;
			break;
		}
	}
	`log(node.Name $ " saved in drum trigger " $ Name $ " at location " $ node.Location);
}

function bool UsedBy(Pawn User)
{
	//local SneakToSlimAIPawn A;
	//local vector loc;
	//local SneakToSlimAIController contr;
	local soundSphere sphere;

	//Sets trigger path node once on start
	if(originNode == NONE)
		setOriginNode();

	PlaySound(scDrumSound);
	/*
	 * done in sound sphere, check vase trigger tutorial about adding path node in editor to ai's path.
	loc = self.Location;
	foreach OverlappingActors(class 'SneakToSlimAIPawn',A,effectRadius)
	{
		contr=SneakToSlimAIController(A.Controller);
		contr.investigateLocation(loc);
		`log("drum location: " $ self.Location,true,'Qing');
	}*/
	sphere = Spawn(class 'soundSphere',,,self.Location);
	sphere.setOriginNode(originNode);
	return super.UsedBy(User);
}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent Name=MyMesh
		StaticMesh=StaticMesh'enginevolumetrics.FogEnvironment.Mesh.S_EV_FogVolume_Cylinder_01'
		Scale=0.2
		bUsePrecomputedShadows=True
	End Object

	Components.Remove(Sprite)

	CollisionComponent=MyMesh
	Components.Add(MyMesh)

	bBlockActors=true
	bHidden=false
	effectRadius=1000

	scDrumSound = SoundCue'SFX.drum_test_Cue'
}
