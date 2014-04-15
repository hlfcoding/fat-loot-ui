class SneakToSlimFireCracker extends Projectile;

var int EXPLOSION_DETECT_RADIUS;
var int EXPLOSION_AFFECT_RADIUS;
var name fireCrackerOwner; //which player threw this firecracker
var StaticMeshComponent fireCrackerMesh;

simulated event HitWall( vector HitNormal, actor Wall, PrimitiveComponent WallComp )
{
	//`log("hit wall");
	NotifyGuards(self.Location);
	StunPlayers(self.Location);
}

simulated event Landed( vector HitNormal, actor FloorActor )
{
	//`log("landed");
	NotifyGuards(self.Location);
	StunPlayers(self.Location);	
}

//simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
//{
//	`log("Touched an actor " $ Other.Name, true, 'Ravi');	
//}

unreliable server function ServerCreateExplosion(vector loc)
{
	local SneakToSlimPawn current;
	foreach worldinfo.allactors(class 'SneakToSlimPawn', current)
	{
		current.ClientCreateExplosion(loc);
	}
}

reliable server function StunPlayers(vector loc)
{
	local SneaktoSlimPawn playerPawn;
	
	foreach OverlappingActors(class'SneaktoSlimPawn', playerPawn, EXPLOSION_AFFECT_RADIUS, loc)
	{		
		if( playerPawn.Name != fireCrackerOwner) //don't stun the player who threw the firecracker!
		{
			`log("Firecraker is stunning player: " $ playerPawn.Name, true, 'Ravi');
			if(playerPawn.Controller != None)
			{
				playerPawn.Controller.GoToState('Stunned');
			}
		}
	}
}

reliable server function NotifyGuards(vector loc)
{
	local SneakToSlimAIPawn aiPawn;
	local SneakToSlimAINavMeshController con;

	//DrawDebugSphere(loc,10,20,255,255,255,true);
	ServerCreateExplosion(loc);

	foreach OverlappingActors(class'SneakToSlimAIPawn', aiPawn, EXPLOSION_DETECT_RADIUS, loc)
	{
		con = SneakToSlimAINavMeshController(aiPawn.Controller);
		if(con != None && con.investigateLocation(loc))
		{
			`log(self.Name $ " called " $ aiPawn.Name $ " to investigate " $ loc, true, 'Ravi');			
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
	fireCrackerMesh = FireCrackerMesh

	Begin Object Class=ParticleSystemComponent Name=fireCrackerSmoke
        Template=ParticleSystem'flparticlesystem.fireCrackerSmoke'
        bAutoActivate=true		
	End Object
	Components.Add(fireCrackerSmoke)

	bCollideActors=false
	MaxSpeed=+0300.000000
	Speed=+0300.000000
	LifeSpan=+001.000000
	bCanBeDamaged=false
	Physics=PHYS_Falling	
	bRotationFollowsVelocity=true
}
