class SneakToSlimTreasureSpawnPoint extends ITrigger;

var SneaktoSlimPawn tempUser;
var SneaktoSlimTreasure MyTreasure;
var repnotify bool isHaveTreasure;
var ParticleSystemComponent ParticalEffect;
var ParticleSystemComponent LightBeamEffectRef;
var () int BoxIndex;
var PointLightComponent ChestLight;
var StaticMeshComponent myEmissiveLightCube;
var MaterialInstanceConstant EmissiveMaterialOn;
var MaterialInstanceConstant EmissiveMaterialOff;
var SpotLightComponent Flashlight;

replication {
	if (bNetDirty)
		BoxIndex,isHaveTreasure;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	LightBeamEffectRef.SetHidden(true);
	ChestLight.SetLightProperties(0.f);
	ChestLight.SetEnabled(false);
	//EmissiveMaterialOn = MaterialInstanceConstant(DynamicLoadObject("flvfx.EmissiveLighting.EmissiveLight_base_treasure", class'MaterialInstanceConstant'));
	//EmissiveMaterialoff = MaterialInstanceConstant(DynamicLoadObject("flvfx.EmissiveLighting.Invisible", class'MaterialInstanceConstant'));

}

simulated function SneaktoSlimTreasure SpawnTreasure()
{
	//`log("Spawn Index~~~~~~~~~~~~~~~~~~~~~~~~~~"@BoxIndex);
	MyTreasure = spawn(class'SneaktoSlimTreasure',,,self.Location);
	MyTreasure.ShutDown();
	MyTreasure.SetHidden(true);
	isHaveTreasure = true;
    ParticalEffect.SetActive(true);
	LightBeamEffectRef.SetHidden(false);
	ChestLight.SetLightProperties(5.f);
	ChestLight.SetEnabled(true);
	PromtText = "Press 'E' to Get the treasure";
	PromtTextXbox = "Press 'A' to Get the treasure";
	return MyTreasure;
}



reliable server function SetTreasureFlag(bool flag){
	isHaveTreasure = flag;
}

simulated event ReplicatedEvent(name VarName){
	if(VarName == 'isHaveTreasure'){
        //`log("Change Flag in replicated ~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"@isHaveTreasure);
		if(isHaveTreasure){
			SetParticalEffectActive(true);
		}
		else{
			SetParticalEffectActive(false);
		}
	}

}


simulated function SetParticalEffectActive(bool flag){
     ParticalEffect.SetActive(flag);
	 LightBeamEffectRef.SetHidden(!flag);
	 Flashlight.SetEnabled(flag);
	 if (flag)
	 {
		ChestLight.SetLightProperties(5.f);
		ChestLight.SetEnabled(true);
		myEmissiveLightCube.SetMaterial(0,EmissiveMaterialOn);
		PromtText = "Press 'E' to Get the treasure";
		PromtTextXbox = "Press 'A' to Get the treasure";
	 } else
	 {
		ChestLight.SetLightProperties(0.f);
		ChestLight.SetEnabled(false);
		myEmissiveLightCube.SetMaterial(0,EmissiveMaterialOff);
		PromtText = "";
		PromtTextXbox = "";
	 }
}


simulated function bool UsedBy(Pawn User)
{
	local bool used;
	local SneakToSlimPawn current;
	used = super.UsedBy(User);
	if(InRangePawnNumber!=SneaktoSlimPawn(User).GetTeamNum()){
	    return used;
    }
    if(isHaveTreasure == true)
    {
		//`log("GetTreasure!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
		MyTreasure.giveTreasure(SneaktoSlimPawn(User),self);

		foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
		{
			//`log("clientRoarParticle" $ current.GetTeamNum());
			current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Treasure_Stolen_Cue');
			
		}

		if(role == role_authority){
		    isHaveTreasure=false;
		}
	}
	else
	{
		PlaySound(SoundCue'flsfx.Buzz_fx_Cue');
	}
	return used;
}

DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object
	Components.Add(MyLightEnvironment)
	
	Begin Object Class=StaticMeshComponent Name=EmissiveLightCube
		bUsePrecomputedShadows=true
        StaticMesh=StaticMesh'flvfx.EmissiveLighting.TexPropCube'
		LightEnvironment=MyLightEnvironment
		CastShadow= false
		Scale=1.5
		Translation=(X=-1.0,Y=-1.0,Z=-20.0)
    End Object
    Components.Add(EmissiveLightCube)
	myEmissiveLightCube = EmissiveLightCube;

    Begin Object Class=ParticleSystemComponent Name=LightBeamEffect
        Template=ParticleSystem'flvfx.Dust.Light_beam'
        bAutoActivate=true
		Translation=(Z=1000.0)
    End Object

    Components.Add(LightBeamEffect)
    LightBeamEffectRef = LightBeamEffect;

	Begin Object Class=ParticleSystemComponent Name=TreasureEffectComponent
        Template=ParticleSystem'flparticlesystem.DragontreasureChestEffect'
        bAutoActivate=false
		//Translation=(Z=80.0)
	End Object
    ParticalEffect = TreasureEffectComponent;
	Components.Add(TreasureEffectComponent)

	Begin Object Class=SpotLightComponent Name=MyFlashlight
	  bEnabled=true
	  bCastCompositeShadow = true;
	  bAffectCompositeShadowDirection =true;
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Modulate;
	  Radius=300.000000
	  Brightness=4.0
	  LightColor=(R=255,G=241,B=134)
	  Rotation=(Pitch=-16384, Yaw=0, Roll=0)
	  Translation=(Z=200.0)
	End Object
	Components.Add(MyFlashlight)
	Flashlight=MyFlashlight

	Begin Object Class=pointlightcomponent Name=TreasurePointLight
      Translation = (Z = -22.0)
	  bEnabled = true
	  bCastCompositeShadow = true
	  bAffectCompositeShadowDirection = true
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Normal
	  Radius=128.000000
	  Brightness=1.0000	 
	  LightColor=(R=255,G=255,B=0)
      bRenderLightShafts = true
	  LightmassSettings = (LightSourceRadius = 32.0)
	End Object
	Components.Add(TreasurePointLight)
	ChestLight=TreasurePointLight

	EmissiveMaterialOn = MaterialInstanceConstant'flvfx.EmissiveLighting.EmissiveLight_base_treasure'
	EmissiveMaterialoff = MaterialInstanceConstant'flvfx.EmissiveLighting.Invisible'

    bBlockActors=true
    bHidden=false

    isHaveTreasure = false;
	PromtText = "";
	PromtTextXbox = ""
 
	bNoDelete=false// if this is set to true we can never spawn it using spawn point
	RemoteRole=ROLE_AutonomousProxy
	bAlwaysRelevant=true
	
}
