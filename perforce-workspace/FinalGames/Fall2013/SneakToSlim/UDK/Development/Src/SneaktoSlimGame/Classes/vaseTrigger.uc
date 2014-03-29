class vaseTrigger extends ITrigger;

var vaseFracturedActor fractureVase;
var SoundCue scVaseBreakSound;
var bool occupied;              //Nick: Set when player enters/exits vase
var repnotify bool isBroken;              //Nick: set when another player use vase while player is not NULL
var SneaktoSlimPawn Inside_player;     //Nick: Reference to player currently in vase
var Vector playerEntryPosition;

replication {
	if (bNetDirty)
		isBroken;
}

simulated event PostBeginPlay()
{
    //Spawn(class'vase_staticmesh',,,Location);
	fractureVase = Spawn(class'vaseFracturedActor');
	super.PostBeginPlay();
}

simulated event ReplicatedEvent(name VarName){
	if(VarName == 'isBroken'){
		if(isBroken){
			VaseExpoled();
			
		}
	}
}

simulated function VaseExpoled(){
	fractureVase.Explode();
	//fractureVase.bBlocksNavigation= false;
}

function setFree()
{
	occupied = false;                    //Frees vase 
	Inside_player.SetHidden(false);             //Makes player visible
	Inside_player.hiddenInVase = false; 
	Inside_player.SetCollision(true,true,);     //Resets player's collision
	Inside_player.enablePlayerMovement();     //Enable's player movement; Uncommment once collision overlay is checked
	Inside_player.vaseIMayBeUsing = NONE;
	Inside_player.SetLocation(playerEntryPosition);
	Inside_player = None;                       //NULL vase's player field so others can use
}

simulated function bool UsedBy(Pawn User)
{
	local bool used;

    used = super.UsedBy(User);
	
	if(!occupied)
	{
		if(InRangePawnNumber!=SneaktoSlimPawn(User).GetTeamNum()){
	        return used;
        }
		Inside_player = SneaktoSlimPawn(User);      //Cast Pawn to SneaktoSlimPawn and place it in vase's player property
		Inside_player.hiddenInVase = true;
		occupied = true;
		Inside_player.SetHidden(true);              //Makes player invisible
		Inside_player.SetCollision(false,false,);   //Makes player's collision set to none 
		Inside_player.disablePlayerMovement();    //Disable's player movement; Uncommment once collision overlay is checked
		playerEntryPosition = User.Location;
		Inside_player.SetLocation(Location);
		Inside_player.vaseIMayBeUsing = self;
		SneaktoSlimPlayerController(Inside_player.Controller).attemptToChangeState('Hiding');
		SneaktoSlimPlayerController(Inside_player.Controller).GotoState('Hiding');

		Inside_player.totalTimesVasesUsed++;
		SneaktoSlimPlayerController(Inside_player.Controller).resumeVaseTimer();
		return true;
	}
	else
	{
		occupied = false;                    //Frees vase 
		Inside_player.SetHidden(false);             //Makes player visible
		Inside_player.hiddenInVase = false; 
		Inside_player.SetCollision(true,true,);     //Resets player's collision
		Inside_player.enablePlayerMovement();     //Enable's player movement; Uncommment once collision overlay is checked
		Inside_player.vaseIMayBeUsing = NONE;
		SneaktoSlimPlayerController(Inside_player.Controller).attemptToChangeState('EndHiding');
		SneaktoSlimPlayerController(Inside_player.Controller).GotoState('EndHiding');
		SneaktoSlimPlayerController(Inside_player.Controller).attemptToChangeState('PlayerWalking');
		SneaktoSlimPlayerController(Inside_player.Controller).GotoState('PlayerWalking');

		//If player who activates vase is the same person hiding, then he exits vase
		if(Inside_player == SneaktoSlimPawn(User))
		{
			SneaktoSlimPlayerController(Inside_player.Controller).pauseVaseTimer();

			Inside_player.SetLocation(playerEntryPosition);
			Inside_player = None;                       //NULL vase's player field so others can use
		}
		//If player tries to enter an occupied vase, then vase is destroyed
		else
		{
			PlaySound(scVaseBreakSound);
			isBroken = true;  

			SneaktoSlimPlayerController(Inside_player.Controller).pauseVaseTimer();

			sneaktoslimplayercontroller(Inside_player.Controller).attemptToChangeState('Stunned');
			SneaktoSlimPlayerController(Inside_player.Controller).GotoState('Stunned');
			//fractureVase.Explode();
			//fractureVase.ShutDown();
			ShutDown();
		}
	}
	return used;
}



DefaultProperties
{
	displayName = "vase";
	PromtText = "Press E to enter vase";
	PromtTextXbox = "Press 'A' to enter vase";
	eqGottenText = ""
	

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
    bBlockActors=false //trigger will block players
    bHidden=false //players can see the trigger
	//bNoDelete = true
	bNoEncroachCheck = true     //Enables pawns to move even when overlapping

	scVaseBreakSound = SoundCue'SFX.vaseBreak_test_Cue';
    occupied = false;
	isBroken = false;
}

