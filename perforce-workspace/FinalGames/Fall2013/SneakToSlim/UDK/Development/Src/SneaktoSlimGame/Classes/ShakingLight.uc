class ShakingLight extends Actor placeable;

var Rotator TargetRotation1;
var Rotator TargetRotation2;
var Rotator TargetRotation;
var int RotationDifference;
var SpotLightComponent Flashlight;
var StaticMeshComponent lantern;
var DynamicLightEnvironmentComponent LightEnvironment;
var float speed;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	TargetRotation1 = self.Rotation;
	TargetRotation1.Pitch = TargetRotation1.Pitch+16384;
	TargetRotation2 = self.Rotation;
	TargetRotation2.Pitch = TargetRotation2.Pitch-16384;
	TargetRotation = TargetRotation1;
}

simulated event Tick(float DeltaTime){
	local Quat currentQuat;
	local rotator currentRotation;
	currentQuat = QuatSlerp(QuatFromRotator(self.Rotation),QuatFromRotator(TargetRotation),DeltaTime*speed,  false);
    currentRotation = QuatToRotator(currentQuat);
	if(Abs(currentRotation.Pitch - TargetRotation1.Pitch)<= 16384 - RotationDifference){
		TargetRotation = TargetRotation2;
	}
	if(Abs(currentRotation.Pitch - TargetRotation2.Pitch)<= 16384 - RotationDifference){
		TargetRotation = TargetRotation1;
	}
	self.SetRotation(currentRotation);
	`log("hah"@currentRotation);
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
	  LightShadowMode = LightShadow_Normal ;
	  Radius=250.000000
	  Brightness=30.0
	  LightColor=(R=235,G=235,B=110)
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

	speed = 0.2;
    RotationDifference = 3000; // 16384 means 90 degree. Dont set the difference bigger than that. 
}
