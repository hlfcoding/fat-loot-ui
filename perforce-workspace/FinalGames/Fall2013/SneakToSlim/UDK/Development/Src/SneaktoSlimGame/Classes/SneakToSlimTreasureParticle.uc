class SneakToSlimTreasureParticle extends Actor;

var float treasureVelocity;
var bool bTreasureParticleIsMoving;
var Vector targetLocation;

simulated function particleStartMoving(Vector inTargetLocation)
{
	targetLocation = inTargetLocation;
	bTreasureParticleIsMoving = true;
}

simulated event Tick(float DeltaTime)
{
	local Vector vdirection;

	if (bTreasureParticleIsMoving)
	{
		vdirection = targetLocation - self.Location;
	
		if (VSize(vdirection)>treasureVelocity * DeltaTime)
		{
			//`log("treasure is moving!" @ self.Location);
			vDirection = Normal(vDirection);

			self.SetLocation(self.Location + vdirection * treasureVelocity*DeltaTime);
			vdirection = targetLocation - self.Location;
		}
		else
		{
			self.SetLocation(targetLocation);
			bTreasureParticleIsMoving = false;
			self.ShutDown();
		}
	}
}

DefaultProperties
{
	Begin Object Class=ParticleSystemComponent Name=particle_1
        Template=ParticleSystem'flparticlesystem.treasureMovingEffect'
        bAutoActivate=true
		//Translation=(Z=80.0)
	End Object
	Components.Add(particle_1)
	treasureVelocity = 200.0
	bTreasureParticleIsMoving = false
}
