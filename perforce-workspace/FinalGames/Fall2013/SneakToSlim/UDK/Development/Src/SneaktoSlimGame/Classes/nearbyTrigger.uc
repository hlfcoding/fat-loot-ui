class nearbyTrigger extends ITrigger;


var () int NoBuffProbility;
var () int InvisibleProbility;
var repnotify int BuffType;
var ParticleSystemComponent ParticalEffect;
var array<color> steamParticleColor;
var int powerupNum;
replication {
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
	//if(Role == ROLE_Authority){
        randNum = Rand(100);
		if(randNum < (1*100/powerupNum)){
            BuffType = 1;
		}
		else if(randNum < (2*100/powerupNum)){
			BuffType = 2;
		}
		else if(randNum < (3*100/powerupNum)){
			BuffType = 3;
		}
		else if(randNum < (4*100/powerupNum)){
			BuffType = 4;
		}
		else if(randNum < (5*100/powerupNum)){
			BuffType = 5;
		}
		else{
			BuffType = 6;
		}
    //}
}


simulated event ReplicatedEvent(name VarName){
	if(VarName == 'BuffType'){
        `log("1111111111122222222222222isHaveBuff~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"@BuffType);
		ParticalEffect.SetColorParameter('steamColor', steamParticleColor[BuffType]);
		`log("steamColor is"@steamParticleColor[BuffType].R);
		switch (BuffType){
		case 0:
			ParticalEffect.SetActive(false);
			break;
		case 1:
			ParticalEffect.SetActive(true);
			break;
		case 2:
			ParticalEffect.SetActive(true);
			break;
		case 3:
			ParticalEffect.SetActive(true);
			break;
		case 4:
			ParticalEffect.SetActive(true);
			break;
		case 5:
			ParticalEffect.SetActive(true);
			break;
		case 6:
			ParticalEffect.SetActive(true);
			break;
		}
		//SetParticalEffectActive();
	}

}

simulated function SetParticalEffectActive(bool flag){
     ParticalEffect.SetActive(flag);
	 if (flag)
	 {
		PromtText = "Press E to Get the treasure";
		PromtTextXbox = "Press 'A' to Get the treasure";
	 } else
	 {
		PromtText = "";
		PromtTextXbox = "";
	 }
}


simulated function ChangeBuff(int type){
	BuffType = type;
}
//function bool UsedBy(Pawn User)
simulated function bool UsedBy(Pawn User)
{
	local bool used;
	used = super.UsedBy(User);
        if(InRangePawnNumber!=SneaktoSlimPawn(User).GetTeamNum()){
			return used;
        }
		//Only use power if user is currently not using a power
	     if(BuffType !=0){
	         SneaktoSlimPawn(User).bBuffed = BuffType;
			//SneaktoSlimPawn(User).inputStringToHUD("get invis powerup, press Shift to use");
			
			//Tells the user as a client to update its UI
			 SneaktoSlimPawn(User).showPowerupUI(BuffType);
			 ChangeBuff(0);
			 //if(Role == ROLE_Authority){
		     setTimer(10.0,false,'StartSpawnBuffItem');
	         //}
		}
        

		Sneaktoslimpawn(User).playerPlayOrStopCustomAnim('customSearch', 'Search', 1.f, true, 0, 0, false, true);

		return used;
}


DefaultProperties
{
	displayName = "BookShelf"
	PromtText = "Press 'E' to Check the shelf"
	PromtTextXbox = "Press 'A' to Check the shelf"
	eqGottenText = ""
	powerupNum = 6

	Begin Object Class=ParticleSystemComponent Name=TeapotEffectComponent
        Template=ParticleSystem'flparticlesystem.Steam'
        bAutoActivate = true
		//Translation=(X=-50, Y= 0, Z=30.0)
		Scale = 0.5
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
		Translation = (X=35, Y= 5, Z=50)
		Scale = 5
    End Object
    steamParticleColor[0]=(R=0,G=0,B=0,A=255)
	steamParticleColor[1]=(R=255,G=255,B=180,A=26) //invisible
	steamParticleColor[2]=(R=26,G=80,B=255,A=26) //disquise
	steamParticleColor[3]=(R=120,G=255,B=26,A=26) //burp


	//set collision component
    CollisionComponent=MyMesh 
 
	//add the new mesh object to trigger¡¦s components
    Components.Add(MyMesh)

  	 bBlockActors=true //trigger will block players
  	 bHidden=false //players can see the trigger
	 BuffType = 0
	 NoBuffProbility = 50
	 InvisibleProbility = 50
	 RemoteRole=ROLE_AutonomousProxy
	 bAlwaysRelevant=true
}
