class SneakToSlimFireCracker extends Projectile;

var float MAX_CHARGE_TIME; //max time (in seconds) firecracker throw can be charged
var int EXPLOSION_EFFECT_RADIUS;

simulated event HitWall( vector HitNormal, actor Wall, PrimitiveComponent WallComp )
{
	//`log("hit wall");
	NotifyGuards(self.Location);
}

simulated event Landed( vector HitNormal, actor FloorActor )
{
	//`log("landed");
	NotifyGuards(self.Location);
}

//function createExplosion(vector loc)
//{
//	WorldInfo.MyEmitterPool.SpawnEmitter(
//		ParticleSystem'flparticlesystem.fireCracker', 
//		loc, 
//		rot(0,0,0), 
//		None);

//}

unreliable server function ServerCreateExplosion(vector loc)
{
	local SneakToSlimPawn current;
	foreach worldinfo.allactors(class 'SneakToSlimPawn', current)
	{
		current.ClientCreateExplosion(loc);
	}
}



reliable server function NotifyGuards(vector loc)
{
	local SneakToSlimAIPawn aiPawn;
	local SneakToSlimAINavMeshController con;

	//DrawDebugSphere(loc,10,20,255,255,255,true);
	//`log("notify guards");

	ServerCreateExplosion(loc);
	//ServerCreateExplosion(loc);

	//local SneakToSlimpawn current;

	//foreach worldinfo.allactors(class 'SneakToSlimpawn', current)
	//{
	//	current.ClientCreateExplosion(loc);
	//}

	foreach OverlappingActors(class'SneakToSlimAIPawn', aiPawn, EXPLOSION_EFFECT_RADIUS, loc)
	{
		con = SneakToSlimAINavMeshController(aiPawn.Controller);
		if(con != None && con.investigateLocation(loc))
		{
			`log(self.Name $ " called " $ aiPawn.Name $ " to investigate " $ loc, true, 'Ravi');
			//break; //get out of loop if an AI guard went to investigate
		}
	}

	self.Destroy();
}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent   Name=FireCrackerMesh
		StaticMesh=StaticMesh'FLInteractiveObject.treasure.Tresure'		
		CastShadow=true
		Scale=0.3
	End Object	

	Components.Add(FireCrackerMesh)

	Begin Object Class=ParticleSystemComponent Name=fireCrackerSmoke
        Template=ParticleSystem'flparticlesystem.fireCrackerSmoke'
        bAutoActivate=true
		//Translation=(Z=80.0)
	End Object
	Components.Add(fireCrackerSmoke)


	bCollideActors=false
	MaxSpeed=+0300.000000
	Speed=+0300.000000
	LifeSpan=+001.000000
	bCanBeDamaged=false
	Physics=PHYS_Falling	
	bRotationFollowsVelocity=true

	MAX_CHARGE_TIME = 2.6
	EXPLOSION_EFFECT_RADIUS = 1000
}
