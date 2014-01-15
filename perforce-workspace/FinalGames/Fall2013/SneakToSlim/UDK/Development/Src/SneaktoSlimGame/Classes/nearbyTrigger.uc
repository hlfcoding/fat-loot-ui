class nearbyTrigger extends ITrigger;

var repnotify int BuffType;
var () int NoBuffProbility;
var () int InvisibleProbility;
var BuffBottle PotionBottle;
replication {   //ARRANGE THESE ALPHABETICALLY
	if (bNetDirty)
		BuffType;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	if(Role == ROLE_Authority){
		StartSpawnBuffItem();
	}

}

simulated function StartSpawnBuffItem(){
	
	Local int randNum;
	`log("Spawn the Item!!!!!!!!!FGSDDGAGG!1111111111111111111111111");
	if(Role == ROLE_Authority){
        randNum = Rand(100);
		if(randNum < InvisibleProbility){
            BuffType = 1;
		}
		else{
			BuffType = 2;
		}
    }
}



simulated function CreatePotionMesh(){
	Local vector NewLocation;
	PotionBottle = spawn(class'BuffBottle',,,self.Location);
	if(PotionBottle!=none){
		`log("Spawn bottle!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	}
	else{
		`log("Cant Spawn bottle!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	}
    NewLocation.X = PotionBottle.Location.X+30;
	NewLocation.Y = PotionBottle.Location.Y+30;
	NewLocation.Z = PotionBottle.Location.Z+30;
	PotionBottle.SetLocation(NewLocation);
	PotionBottle.SetHidden(false);
}

//function bool UsedBy(Pawn User)
simulated function bool UsedBy(Pawn User)
{
	local bool used;
	used = super.UsedBy(User);
	if(string(User.Class) == "SneaktoSlimPawn")
	{
		`log( Name $ " Touched by " $ User.Name $ " name is " $ displayName);

		//Only use power if user is currently not using a power
	     if(BuffType == 1){
	         SneaktoSlimPawn(User).bBuffed = 1;
			//SneaktoSlimPawn(User).inputStringToHUD("get invis powerup, press Shift to use");
			
			//Tells the user as a client to update its UI
			 SneaktoSlimPawn(User).showPowerupUI(BuffType);

			 `log( User.Name $ ".bBuffed " $ " is " $ SneaktoSlimPawn(User).bBuffed );
			 BuffType=0;
			 if(Role == ROLE_Authority){
		        setTimer(10.0,false,'StartSpawnBuffItem');
	         }
		}
		if(BuffType == 2){
			SneaktoSlimPawn(User).bBuffed = 2;
			//SneaktoSlimPawn(User).inputStringToHUD("get invis powerup, press Shift to use");
			
			//Tells the user as a client to update its UI
			SneaktoSlimPawn(User).showPowerupUI(BuffType);

			`log( User.Name $ ".bBuffed " $ " is " $ SneaktoSlimPawn(User).bBuffed );
			BuffType=0;
			if(Role == ROLE_Authority){
		        setTimer(10.0,false,'StartSpawnBuffItem');
	        }
		}
        

		Sneaktoslimpawn(User).playerPlayOrStopCustomAnim('customSearch', 'Search', 1.f, true, 0, 0, false, true);

		return true;
	}
	return used;
}


DefaultProperties
{
	displayName = "BookShelf";
	PromtText = "Press 'E' to Check the shelf";
	eqGottenText = "";

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object
	Components.Add(MyLightEnvironment)
	MyLight = MyLightEnvironment;

	//Create a new mesh object. This object will be the 3D model of the trigger
	Begin Object Class=StaticMeshComponent Name=MyMesh
        StaticMesh=StaticMesh'FLInteractiveObject.Shelf.large_shelf'
		bUsePrecomputedShadows=True
		LightEnvironment=MyLightEnvironment
		CastShadow=true
    End Object

	//set collision component
    CollisionComponent=MyMesh 
 
	//add the new mesh object to trigger¡¦s components
    Components.Add(MyMesh)

  	 bBlockActors=true //trigger will block players
  	 bHidden=false //players can see the trigger
	 BuffType = 0;
	 NoBuffProbility = 50;
	 InvisibleProbility = 50;
}
