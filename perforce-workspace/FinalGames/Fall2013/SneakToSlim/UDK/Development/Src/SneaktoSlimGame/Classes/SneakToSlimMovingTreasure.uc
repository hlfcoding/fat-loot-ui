class SneakToSlimMovingTreasure extends Projectile;

var float MAX_CHARGE_TIME; //max time (in seconds) firecracker throw can be charged
var int EXPLOSION_EFFECT_RADIUS;
var SneakToSlimPawn MyPawn;
simulated event HitWall( vector HitNormal, actor Wall, PrimitiveComponent WallComp )
{
}

simulated event Landed( vector HitNormal, actor FloorActor )
{
	local sneaktoslimpawn current;
	local vector newlocation;
	if(MyPawn == None){
		`log("I dont have pawn!!!!!!!!!!!!!!!!!!!!!!!");
	}
	else{
	newlocation = self.Location;
	newlocation.Z = newlocation.Z-16;
	MyPawn.myTreasure.SetLocation(newlocation);
	MyPawn.myTreasure.turnOn();
	if(Role == Role_Authority){
		MyPawn.myTreasure.StartResetTreasure();
	}
	MyPawn.myTreasure = none;
	if(Role == Role_Authority){
		foreach allActors(class 'sneaktoslimpawn', current)
			{
	   		   current.ClientMovingTreasure(newlocation);
			}
	}
	}
	self.Destroy();
}




DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object
	Components.Add(MyLightEnvironment)
	//LightEnvironment=MyLightEnvironment

	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
        StaticMesh= StaticMesh'FLInteractiveObject.treasure.Tresure'
		Scale=1.0
		//Translation=(Z=-48.0)
		bUsePrecomputedShadows=True
		LightEnvironment=MyLightEnvironment
    End Object
 
    CollisionComponent=MyStaticMeshComponent 
	//myMesh = MyStaticMeshComponent;

    Components.Add(MyStaticMeshComponent)

	Begin Object Class=ParticleSystemComponent Name=TreasureEffectCompoent
        Template=ParticleSystem'flparticlesystem.treasureMovingEffect'
        bAutoActivate=true
	End Object

	Components.Add(TreasureEffectCompoent)


	bCollideActors=false
	MaxSpeed=+0300.000000
	Speed=+0300.000000
	LifeSpan=0
	bCanBeDamaged=false
	Physics=PHYS_Falling	
	bRotationFollowsVelocity=true

	MAX_CHARGE_TIME = 2.6
	EXPLOSION_EFFECT_RADIUS = 1000
}
