class nearbyTrigger extends ITrigger;


var () int NoBuffProbility;
var () int InvisibleProbility;
var int BuffType;
var repnotify bool isHaveBuff;
var ParticleSystemComponent ParticalEffect;

replication {
	if (bNetDirty)
		isHaveBuff;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	//if(Role == ROLE_Authority){
		//isHaveBuff = true;
	//}

}

simulated function StartSpawnBuffItem(){
	
	Local int randNum;
	isHaveBuff = true;
	//if(Role == ROLE_Authority){
        randNum = Rand(100);
		if(randNum < 30){
            BuffType = 1;
		}
		else if(randNum<60){
			BuffType = 2;
		}
		else{
			BuffType = 3;
		}


    //}
}


simulated event ReplicatedEvent(name VarName){
	if(VarName == 'isHaveBuff'){
        `log("1111111111122222222222222isHaveBuff~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"@isHaveBuff);
		
		SetParticalEffectActive(isHaveBuff);
	}

}

simulated function SetParticalEffectActive(bool flag){
     ParticalEffect.SetActive(flag);
	 if (flag)
	 {
		PromtText = "Press E to Get the treasure";
	 } else
	 {
		PromtText = "";
	 }
}


simulated function ChangeBuff(int type){
	BuffType = type;
}
//function bool UsedBy(Pawn User)
simulated function bool UsedBy(Pawn User)
{
	//local bool used;
	//used = super.UsedBy(User);

		//Only use power if user is currently not using a power
	     if(BuffType !=0){
	         SneaktoSlimPawn(User).bBuffed = BuffType;
			//SneaktoSlimPawn(User).inputStringToHUD("get invis powerup, press Shift to use");
			
			//Tells the user as a client to update its UI
			 SneaktoSlimPawn(User).showPowerupUI(BuffType);
			 ChangeBuff(0);
			 isHaveBuff = false;
			 `log("33333333333333333333333333333isHaveBuff~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"@isHaveBuff);
			 //if(Role == ROLE_Authority){
		     setTimer(10.0,false,'StartSpawnBuffItem');
	         //}
		}
        

		Sneaktoslimpawn(User).playerPlayOrStopCustomAnim('customSearch', 'Search', 1.f, true, 0, 0, false, true);

		return true;
}


DefaultProperties
{
	displayName = "BookShelf"
	PromtText = "Press 'E' to Check the shelf"
	eqGottenText = ""

	Begin Object Class=ParticleSystemComponent Name=TeapotEffectComponent
        Template=ParticleSystem'flparticlesystem.Steam'
        bAutoActivate = true
		//Translation=(Z=80.0)
	End Object
    ParticalEffect = TeapotEffectComponent
	Components.Add(TeapotEffectComponent)

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object
	Components.Add(MyLightEnvironment)
	MyLight = MyLightEnvironment

	//Create a new mesh object. This object will be the 3D model of the trigger
	Begin Object Class=StaticMeshComponent Name=MyMesh
        StaticMesh=StaticMesh'FLInteractiveObject.teapot.teapot'
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
	 BuffType = 1
	 isHaveBuff = true
	 NoBuffProbility = 50
	 InvisibleProbility = 50
}
