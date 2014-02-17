class SneaktoSlimPlayerController_Rabbit extends SneaktoslimPlayerController
	config(Game);

var int perRoarEnergy;
var float roarTime;
var int perDiveEnergy;
var float distanceDive;
var vector myOffset;

exec function showFatLootClassName()
{
	`log(self.Pawn.Class);
	`log(self.Class);
}

simulated state PlayerWalking
{
	ignores SeePlayer, HearNoise, Bump;

	exec function testForEnergy()
	{
		`log(sneaktoslimpawn(self.Pawn).v_energy);
	}

	exec function OnPressFirstSkill()
	{
		//Player can't belly bump if pause menu is on
		if(pauseMenuOn)
			return;

		if(sneaktoslimpawn(self.Pawn).v_energy <= perRoarEnergy)
			return;
		else
		{
			attemptToChangeState('Roaring');
			GoToState('Roaring');
		}
	}

	exec function OnPressSecondSkill()
	{
		if(pauseMenuOn)
			return;

		if(sneaktoslimpawn(self.Pawn).v_energy <= perDiveEnergy)
			return;
		else
		{
			attemptToChangeState('Diving');
			GoToState('Diving');
		}
	}


Begin:
	if(debugStates) logState();
}

simulated state Diving// extends CustomizedPlayerWalking
{
	local vector endDive;
	local vector startDive;
	local vector hitLocation;
	local vector hitNormal;
	local TraceHitInfo hitDiveInfo;
	local float distRabbittoTracehit;
	//local vector jumpHeight;
	simulated function Rabbit_Dive()
	{
		sneaktoslimpawn(self.Pawn).v_energy -= perDiveEnergy;
		startDive = self.Pawn.Location;
		endDive = Normal(vector(self.Pawn.Rotation)) * distanceDive + startDive;
		Trace(hitLocation, hitNormal, endDive, startDive, false, , hitDiveInfo, );
		distRabbittoTracehit = VSize(hitLocation - startDive);
		if(distRabbittoTracehit > distanceDive)
		{
			//self.Pawn.Mesh.SetTranslation(myOffset);
			//self.Pawn.Mesh.SetTranslation(endDive);
		`log(vector(self.Pawn.Rotation));
		`log(Normal(vector(self.Pawn.Rotation)));
		`log(distanceDive);
		`log(startDive);
			`log(endDive);
			//self.Pawn.SetLocation(endDive);
			Blink(endDive);
			//myOffset.Z = -48;
			//self.Pawn.Mesh.SetTranslation(myOffset);
			//myOffset.Z = -80;
		}
		else
		{
		//	self.Pawn.Mesh.SetTranslation(myOffset);
		//	self.Pawn.SetLocation(hitLocation + myOffset);
		//	myOffset.Z = -48;
		//	self.Pawn.Mesh.SetTranslation(myOffset);
		//	myOffset.Z = -80;
			Blink(hitLocation);
		}
	}
Begin:
	if(debugStates) logState();

	sneaktoslimpawn(self.Pawn).stopAllTheLoopAnimation();
	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customVanish', 'Vanish', 1.f, true, 0.1f, 0.1f, false, true);
	sleep(0.8);

	Rabbit_Dive();
	//jumpHeight.X = 0;
	//jumpHeight.Y = 0;
	//jumpHeight.Z = 1;
	//sneaktoslimpawn(self.Pawn).TakeDamage(0, none, self.Pawn.Location, jumpHeight * 1500, class 'DamageType');
	attemptToChangeState('PlayerWalking');
	GoToState('PlayerWalking');
}

unreliable server function Blink(vector endLocation)
{
	self.Pawn.SetLocation(endLocation);
}

simulated state Roaring extends CustomizedPlayerWalking
{
	simulated function Rabbit_Roar()
	{
		local SneaktoSlimPawn victim;
		`log("Rabbit_Roar!!");

		SneaktoSlimPawn(self.Pawn).v_energy -= perRoarEnergy;

		foreach self.Pawn.VisibleCollidingActors(class'SneaktoSlimPawn', victim, 300)
		{
			if (ActorLookingAt(SneaktoSlimPawn(self.Pawn), victim, 15))
			{
				SneaktoSlimPlayerController(victim.Controller).attemptToChangeState('Stunned');
				SneaktoSlimPlayerController(victim.Controller).GoToState('Stunned');
			}
		}
	}

	
	simulated function StopRoaring()
	{
		GoToState('PlayerWalking');
		attemptToChangeState('PlayerWalking');
	}



Begin:
	Rabbit_Roar();
	SetTimer(roarTime, false, 'StopRoaring');	
}





defaultproperties
{
	perRoarEnergy = 50;
	roarTime = 1.0f;
	perDiveEnergy = 10;
	distanceDive = 150.0;
	myOffset = (X=0, Y=0, Z=-90)
}
