class MistTrigger extends Trigger;

var repnotify bool isTurnedOn;
var ParticleSystemComponent ParticalEffect;
var () int Mistnum;

replication {
	if (bNetDirty)
		isTurnedOn;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	if(role == role_authority){
		setTimer(30.0,false,'ChangeisTurnedOn');
	}

}

simulated function ChangeisTurnedOn(){
	local SneaktoSlimPawn currentPawn;
	local bool overlapping;
	isTurnedOn = !isTurnedOn;
	if(!isTurnedOn){
		foreach worldinfo.AllActors(class 'SneaktoSlimPawn', currentPawn){
			if(currentPawn.mistNum == Mistnum){
				`log("Reset Invisible");
				currentPawn.mistNum = 0;
				currentpawn.bInvisibletoAI=false;
		    }
		}
	}
	else{
		foreach worldinfo.AllActors(class 'SneaktoSlimPawn', currentPawn){
			overlapping=IsOverlapping(currentPawn);
			if(overlapping){
				`log("Start Invisible");
				currentPawn.mistNum = Mistnum;
				currentpawn.bInvisibletoAI=true;
		    }
		}
	}
	setTimer(10.0,false,'ChangeisTurnedOn');
}

simulated event ReplicatedEvent(name VarName){
	
	if(VarName == 'isTurnedOn'){
        `log("Change isTurnedOn in replicated ~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"@isTurnedOn);
		ParticalEffect.SetActive(isTurnedOn);
		
	}

}

event Touch(Actor other, PrimitiveComponent otherComp, vector hitLoc, vector hitNormal)
{
	
	super.Touch(other, otherComp, hitLoc, hitNormal);
	if(isTurnedOn){
		`log("Step In Mist");
	    sneaktoslimpawn(other).bInvisibletoAI = true;
	    sneaktoslimpawn(other).mistNum = Mistnum;//need to be set to mistTrigger num
	}
}

event UnTouch(Actor other)
{
	
	//sneaktoslimpawn(other).endinvisibleNum = other.GetTeamNum();
	if(isTurnedOn){
		`log("Step Out Of Mist");
	    sneaktoslimpawn(other).bInvisibletoAI = false;
	    sneaktoslimpawn(other).mistNum = 0;
	}
}

DefaultProperties
{
	displayName = "Mist";
	PromtText = "";//"You are in the Mist!"
	PromtTextXbox = ""
	

    Begin Object Class=CylinderComponent NAME=MyMesh
		CollideActors=true
		CollisionRadius=100
		CollisionHeight=100
		bAlwaysRenderIfSelected=true    
	End Object
    
	Begin Object Class=ParticleSystemComponent Name=FogParticalComponent
        Template=ParticleSystem'flvfx.Fog.Mist_particle'
        bAutoActivate=true
		//Translation=(Z=80.0)
	End Object
    ParticalEffect = FogParticalComponent;
	Components.Add(FogParticalComponent)
    //set collision component
    CollisionComponent=MyMesh 

    //add the new mesh object to trigger’s components
    Components.Add(MyMesh)
    bBlockActors=false //trigger will block players
    bHidden=false //players can see the trigger
	//bNoDelete = true
	bNoEncroachCheck = true     //Enables pawns to move even when overlapping

	scVaseBreakSound = SoundCue'SFX.vaseBreak_test_Cue';
	RemoteRole=ROLE_AutonomousProxy
	bAlwaysRelevant=true
	isTurnedOn = true
	Components.Remove(Sprite)
}

