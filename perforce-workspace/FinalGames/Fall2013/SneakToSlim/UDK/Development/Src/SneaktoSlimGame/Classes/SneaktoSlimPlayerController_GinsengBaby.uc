class SneaktoSlimPlayerController_GinsengBaby extends SneaktoslimPlayerController
	config(Game);

var float ENERGY_UPDATE_FREQUENCY;
var float burstChargeTime;
var float energyConsumptionFactor; //To know if player is Bursting while Burrowed
var bool burstComplete;

exec function showFatLootClassName()
{
	`log(self.Pawn.Class);
	`log(self.Class);
	`log(self.GetTeamNum());
}

simulated state PlayerWalking
{
	ignores SeePlayer, HearNoise, Bump;

	exec function testForEnergy()
	{
		`log(sneaktoslimpawn(self.Pawn).v_energy);
	}

	simulated exec function OnPressSecondSkill()   //burrow
	{
		//Player can't sprint if pause menu is on 
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementSprintCount();
		resumeSprintTimer();

		if(sneaktoslimpawn(self.Pawn).v_energy <= 20)
			return;
		else
		{
			if(Role < ROLE_Authority)
				attemptToChangeState('Burrow');
			GoToState('Burrow');
			//TO-DO: 
			//change the model
			//particle system: dust
			//ignore wall and objects
		}
	}

	simulated exec function OnPressFirstSkill()
	{	
		//cant use Burst while walking
	}

Begin:
	if(debugStates) logState();
}


/************************ BURROW STATE **********************************/
simulated state Burrow extends PlayerWalking
{
	simulated exec function OnPressSecondSkill()   //reveal
	{
		//TO-DO		//whether under wall or objects		
		if(Role < ROLE_Authority)
			attemptToChangeState('PlayerWalking');
		GoToState('PlayerWalking');
	}

	simulated exec function OnPressFirstSkill()
	{
		//Player can't Burst if pause menu is on 
		if(pauseMenuOn)
			return;
		
		SneaktoSlimPawn(self.Pawn).incrementBumpCount();
		energyConsumptionFactor = 1.5;
		burstChargeTime = WorldInfo.TimeSeconds;
		SetTimer(0.01, true, 'drawBurstAOE');		
	}

	simulated function drawBurstAOE()
	{
		local float burstRadius;
		local vector cylinderStartPoint;
		cylinderStartPoint = Pawn.Location + vect(0,0,-35);

		burstRadius = SneaktoSlimPawn_GinsengBaby(Pawn).calculateBurstRadius(WorldInfo.TimeSeconds - burstChargeTime);
		if(burstRadius > 0)
			DrawDebugCylinder(cylinderStartPoint, cylinderStartPoint + vect(0,0,2), burstRadius-10, 25, 255, 255, 255, false);
	}

	simulated exec function OnReleaseFirstSkill()
	{
		burstChargeTime = WorldInfo.TimeSeconds - burstChargeTime;
		energyConsumptionFactor = 1;
		ClearTimer('drawBurstAOE');
		if(Role < ROLE_Authority)
			attemptToChangeState('Burst');  //to server
		GoToState('Burst');  //local
	}

	simulated function UpdateEnergy()
	{
		SneaktoSlimPawn(Pawn).v_energy -= ENERGY_UPDATE_FREQUENCY * SneaktoSlimPawn(Pawn).PerDashEnergy * energyConsumptionFactor;
		if(SneaktoSlimPawn(Pawn).v_energy < SneaktoSlimPawn(Pawn).PerDashEnergy)
		{
			//SneaktoSlimPawn(Pawn).v_energy = 0;
			OnPressSecondSkill(); //forcibly stop the charge			
		}
	}

	simulated event BeginState(name prevState)
	{   	
		`log("Stopping energy regen", true, 'Ravi');
		ClearTimer('EnergyRegen');
		ClearTimer('StartEnergyRegen');
		SetTimer(ENERGY_UPDATE_FREQUENCY, true, 'UpdateEnergy');
		sneaktoslimpawn_ginsengbaby(self.Pawn).toggleDustParticle(true);
	}

	event EndState(Name NextStateName)
	{
		sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(false, self.GetTeamNum());
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = false;	
		sneaktoslimpawn_ginsengbaby(self.Pawn).toggleDustParticle(false);
		`log("Restarting energy regen", true, 'Ravi');
		ClearTimer('UpdateEnergy');
		SetTimer(2, false, 'StartEnergyRegen');
	}

Begin:
	sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(true, self.GetTeamNum());
	sneaktoslimpawn(self.Pawn).bInvisibletoAI = true;
	if(debugStates) logState();
}


/************************ BURST STATE **********************************/
simulated state Burst
{
	simulated event BeginState(name prevState)
	{
		burstComplete = false;
	}

	simulated function PlayerMove( float DeltaTime )
	{		
		if( Pawn == None )
		{
			GoToState('Dead');
		}
		else
		{			
			UpdateRotation( DeltaTime ); //move camera
			if(Role < ROLE_Authority) //check for player input on client only
			{
				//if we receive player input after finishing burst, only then move to walking state
				if( burstComplete && (PlayerInput.aStrafe != 0 || PlayerInput.aForward != 0) )
				{					
					if(Role < ROLE_Authority)
						attemptToChangeState('PlayerWalking');
					GoToState('PlayerWalking');
				}
			}
		}
	}

	simulated exec function OnPressSecondSkill()
	{
		if(burstComplete)
		{					
			//Player can't sprint if pause menu is on 
			if(pauseMenuOn)
				return;

			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			resumeSprintTimer();

			if(sneaktoslimpawn(self.Pawn).v_energy <= 20)
				return;
			else
			{				
				if(Role < ROLE_Authority)
					attemptToChangeState('Burrow');
				GoToState('Burrow');				
			}
		}
	}

Begin:	
	if(debugStates) logState();	
	sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(false, self.GetTeamNum());
	ClearTimer('EnergyRegen');
	ClearTimer('StartEnergyRegen');

	if( Role < Role_Authority )
	{
		ServerStartBurst(burstChargeTime);		
		BurstTheBaby(burstChargeTime);
	}

	SetTimer(2, false, 'StartEnergyRegen');	
}

reliable server function ServerStartBurst(float chargeTime)
{
	BurstTheBaby(chargeTime);
}

simulated function BurstTheBaby(float chargeTime)
{
	if(!burstComplete)
	{
		SneaktoSlimPawn_GinsengBaby(Pawn).BabyBurst(chargeTime);
		burstComplete = true;
	}
}

defaultproperties
{	
	ENERGY_UPDATE_FREQUENCY = 0.2
	energyConsumptionFactor = 1
}
