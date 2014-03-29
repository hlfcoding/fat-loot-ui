class fountainTrigger extends ITrigger;

var fountainDestinationNode destination;

function setDestinationNode()
{
	//Gets fountain's associated destination node
	local fountainDestinationNode node;

	ForEach WorldInfo.AllActors(class'fountainDestinationNode', node) 
	{
		if(Tag == node.Tag)
		{
			destination = node;
			break;
		}
	}
	`log(destination.Name $ " saved in trigger " $ Name);
}

/*event Touch(Actor other, PrimitiveComponent otherComp, vector hitLoc, vector hitNormal)
{
	super.Touch(other, otherComp, hitLoc, hitNormal);
}*/

simulated function bool UsedBy(Pawn User)
{
	//Spawn(class 'soundSphere',,,self.Location);
    super.UsedBy(User);
	if(InRangePawnNumber!=SneaktoSlimPawn(User).GetTeamNum()){
	    return false;
    }
	if(destination == NONE)
		setDestinationNode();   
	if(destination == NONE)
	{
		`log("Trigger " $ Name $ " used by" $ User.Name);
		return super.UsedBy(User);
	}
	if(!destination.checkIfOccupied())
	{
		`log("Trigger " $ Name $ " used by" $ User.Name);
		return super.UsedBy(User);
	}
	else
	{
		`log("Can't use teleporter");
		return false;
	}
}

DefaultProperties
{
	//Create a new mesh object. This object will be the 3D model of the trigger
    /*Begin Object Class=StaticMeshComponent Name=MyMesh
        StaticMesh=StaticMesh'FLInteractiveObject.Portal.PortalBase'
		Translation=(Z=-40.0)
		bUsePrecomputedShadows=True
    End Object*/

    //set collision component
    //CollisionComponent=MyMesh 

    //add the new mesh object to trigger�s components
    //Components.Add(MyMesh)
    bBlockActors=true //trigger will block players
    bHidden=false //players can see the trigger
	bNoEncroachCheck = true     //Enables pawns to move even when overlapping

//	Components.Remove(Sprite)

	// disable futuristic particle
	/*Begin Object Class=ParticleSystemComponent Name=MyParticles
		template=ParticleSystem'flparticlesystem.teleportIn'
		bAutoActivate=true
	End Object
	Components.Add(MyParticles)*/

	Begin Object Class=DrawSphereComponent Name=sphere
		SphereRadius = 20
		HiddenGame = true
	End Object
	Components.Add(sphere)

	PromtText = "Press 'E' to Use the Teleporter";
	PromtTextXbox = "Press 'A' to Use the Teleporter";
}
