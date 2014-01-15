class vaseTrigger extends ITrigger;

var vase myVase;        //Place holder for a trigger's associated vase object
var vaseFracturedActor fractureVase;
var SoundCue scVaseBreakSound;
simulated event PostBeginPlay()
{
	//Automatically creates a vase when game loads and sets it in same place as trigger
	myVase = Spawn(class 'vase',,,Location);
    Spawn(class'vase_staticmesh',,,Location);
	fractureVase = Spawn(class'vaseFracturedActor');
	super.PostBeginPlay();
}

//Gets vase's associated location node
function setOriginNode()
{
	local PathNode node;

	ForEach WorldInfo.AllActors(class'PathNode', node) 
	{
		if(Tag == node.Tag)
		{
			myVase.originNode = node;
			break;
		}
	}
	`log(node.Name $ " saved in vase trigger " $ Name $ " at location " $ node.Location);
}

//event Touch (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitLocation, Object.Vector HitNormal)
//{
//	`log("Press 'e' to enter " $ myVase.Name);
//}

//Activates vase and either hides player, make player leave, or destroy vase and stun player
//TODO: Finetune (dis)/enable time code
simulated function bool UsedBy(Pawn User)
{
	local soundSphere sphere;
	local bool used;

    used = super.UsedBy(User);
	//Sets trigger path node once on start
	if(myVase.originNode == NONE)
		setOriginNode();

	fractureVase.Explode();

	//If vase is empty
	if(!myVase.occupied)
	{
		myVase.player = SneaktoSlimPawn(User);      //Cast Pawn to SneaktoSlimPawn and place it in vase's player property
		//myVase.player.hiddenInVase = true;
		//myVase.occupied = true;
		//myVase.player.SetHidden(true);              //Makes player invisible
		//myVase.player.SetCollision(false,false,);   //Makes player's collision set to none 
		//myVase.player.disablePlayerMovement();    //Disable's player movement; Uncommment once collision overlay is checked
		//myVase.playerEntry = User.Location;
		//myVase.player.SetLocation(Location);
		myVase.player.vaseIMayBeUsing = myVase;
		myVase.player = SneaktoSlimPawn(User);
		myVase.occupied = true;
		SneaktoSlimPlayerController(myVase.player.Controller).attemptToChangeState('Hiding');
		SneaktoSlimPlayerController(myVase.player.Controller).GotoState('Hiding');
		return true;
	}
	else
	{
		//myVase.occupied = false;                    //Frees vase 
		//myVase.player.SetHidden(false);             //Makes player visible
		//myVase.player.hiddenInVase = false; 
		//myVase.player.SetCollision(true,true,);     //Resets player's collision
		//myVase.player.enablePlayerMovement();     //Enable's player movement; Uncommment once collision overlay is checked
		//myVase.player.vaseIMayBeUsing = NONE;
		myVase.occupied = false;
		//SneaktoSlimPlayerController(myVase.player.Controller).attemptToChangeState('EndHiding');
		//SneaktoSlimPlayerController(myVase.player.Controller).GotoState('EndHiding');
		SneaktoSlimPlayerController(myVase.player.Controller).attemptToChangeState('PlayerWalking');
		SneaktoSlimPlayerController(myVase.player.Controller).GotoState('PlayerWalking');

		//If player who activates vase is the same person hiding, then he exits vase
		if(myVase.player == SneaktoSlimPawn(User))
		{
			myVase.player.SetLocation(myVase.playerEntry);
			myVase.player = None;                       //NULL vase's player field so others can use
		}
		//If player tries to enter an occupied vase, then vase is destroyed
		else
		{/*
			`log("vaseExplode!");
			PlaySound(scVaseBreakSound);
			myVase.isBroken = true;  
			//myVase.player.stunPlayer(5.0);              //Stuns player for a few seconds
			sneaktoslimplayercontroller(myVase.player.Controller).attemptToChangeState('Stunned');
			sphere = Spawn(class 'soundSphere',,,self.Location);    //Generates sound sphere that guards will detect in soundSphere class
			sphere.setOriginNode(myVase.originNode);                //Passes location node to class for to AI to investigate
			myVase.ShutDown();//Destroys vase and it's trigger
			//fractureVase.Explode();
			fractureVase.ShutDown();
			ShutDown();*/
		}
	}
	return used;
}

DefaultProperties
{
	displayName = "vase";
	PromtText = "Press E to enter vase";
	eqGottenText = ""
	//Create a new mesh object. This object will be the 3D model of the trigger
  //  Begin Object Class=FracturedStaticMeshComponent Name=MyMesh
  //      StaticMesh=StaticMesh'FLInteractiveObject.vase.vase_1_FRACTURED'
		//Scale=1.4
		//Translation=(X=0.000000,Y=0.000000,Z=-32.000000)
		//bUsePrecomputedShadows=True
  //  End Object

    Begin Object Class=CylinderComponent NAME=MyMesh
		CollideActors=true
		CollisionRadius=20
		CollisionHeight=20
		bAlwaysRenderIfSelected=true    
	End Object

    //set collision component
    CollisionComponent=MyMesh 

    //add the new mesh object to trigger’s components
    Components.Add(MyMesh)
    bBlockActors=true //trigger will block players
    bHidden=false //players can see the trigger
	//bNoDelete = true
	bNoEncroachCheck = true     //Enables pawns to move even when overlapping

	scVaseBreakSound = SoundCue'SFX.vaseBreak_test_Cue';
}

