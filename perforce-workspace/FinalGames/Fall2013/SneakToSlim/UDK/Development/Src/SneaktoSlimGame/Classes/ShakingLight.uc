class ShakingLight extends Actor placeable;

var Rotator TargetRotation1;
var Rotator TargetRotation2;
var Rotator TargetRotation;
var int RotationDifference;
var SpotLightComponent Flashlight;
var StaticMeshComponent lantern;
var DynamicLightEnvironmentComponent LightEnvironment;
var float Rotatingspeed;
var float Flashingspeed;
var float MaxBrightness;
var float MinBrightness;
var bool tend;
simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	Flashlight.SetLightProperties(Rand(MaxBrightness)+1);
	TargetRotation1 = self.Rotation;
	TargetRotation1.Pitch = TargetRotation1.Pitch+16384;
	TargetRotation2 = self.Rotation;
	TargetRotation2.Pitch = TargetRotation2.Pitch-16384;
	TargetRotation = TargetRotation1;
	tend = bool(Rand(2));
	
}

simulated event Tick(float DeltaTime){
	local Quat currentQuat;
	local rotator currentRotation;
	local float currentBrightness;
	currentQuat = QuatSlerp(QuatFromRotator(self.Rotation),QuatFromRotator(TargetRotation),DeltaTime*Rotatingspeed,  false);
    currentRotation = QuatToRotator(currentQuat);
	if(tend){
	    currentBrightness =  Flashlight.Brightness+DeltaTime*Flashingspeed;
	}
	else{
		currentBrightness = Flashlight.Brightness-DeltaTime*Flashingspeed;
	}
	if(currentBrightness>=MaxBrightness){
		Tend = false;
	}
	if(currentBrightness<=MinBrightness){
		Tend = true;
	}
	Flashlight.SetLightProperties(currentBrightness);
	if(Abs(currentRotation.Pitch - TargetRotation1.Pitch)<= 16384 - RotationDifference){
		TargetRotation = TargetRotation2;
	}
	if(Abs(currentRotation.Pitch - TargetRotation2.Pitch)<= 16384 - RotationDifference){
		TargetRotation = TargetRotation1;
	}
	self.SetRotation(currentRotation);
}

DefaultProperties
{
	Begin Object Class=ParticleSystemComponent Name=LightEffectCompoent
        Template=ParticleSystem'flvfx.Dust.Dust_falling_particles'
        bAutoActivate=true
	End Object
    //Rotation=(Pitch=-16384, Yaw=0, Roll=0)
	Components.Add(LightEffectCompoent)

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
	End Object
	Components.Add(MyFlashlight)
	Flashlight=MyFlashlight


	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment	

	Rotatingspeed = 0.05;
	Flashingspeed = 3.0;
    RotationDifference = 500; // 16384 means 90 degree. Dont set the difference bigger than that. 
	MaxBrightness = 10.0;
	MinBrightness = 3.0;
	bHidden=false;
	RemoteRole=ROLE_AutonomousProxy;
}
