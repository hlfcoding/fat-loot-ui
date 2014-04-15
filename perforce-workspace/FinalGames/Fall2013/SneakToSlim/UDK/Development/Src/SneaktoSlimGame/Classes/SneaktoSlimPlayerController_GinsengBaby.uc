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

		if(sneaktoslimpawn(self.Pawn).v_energy <= 20)
			return;
		else
		{
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			resumeSprintTimer();

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
		pauseSprintTimer();

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

		if (sneaktoslimpawn(self.Pawn).bUsingBuffed[0] == 1)
		{
			attemptToChangeState('EndInvisible');
			GoToState('EndInvisible');
			`log("ONRELEASEFROMINVISIBLE");
		}
		else if (sneaktoslimpawn(self.Pawn).bUsingBuffed[1] == 1)
		{
			attemptToChangeState('EndDisguised');
			GoToState('EndDisguised');
		}
		
		energyConsumptionFactor = 1; //this value is not changed on server so energy cost not match. Set to 1 to temporarily fix the bug
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
		SneaktoSlimPawn(self.Pawn).incrementBumpCount();

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
		if (prevState == 'EndInvisible' || prevState == 'EndDisguised')
		{
			OnPressFirstSkill();
		}
		else if (prevState == 'HoldingTreasureWalking')
		{
			if(Role < ROLE_Authority)
				attemptToChangeState('HoldingTreasureBurrow');  //to server
			GoToState('HoldingTreasureBurrow');  //local
		}


		`log("Stopping energy regen", true, 'Ravi');
		ClearTimer('EnergyRegen');
		ClearTimer('StartEnergyRegen');
		SetTimer(ENERGY_UPDATE_FREQUENCY, true, 'UpdateEnergy');
		if (role == role_authority)
		{
			sneaktoslimpawn_ginsengbaby(self.Pawn).CallToggleDustParticle(true, self.GetTeamNum());
		}
	}

	event EndState(Name NextStateName)
	{
		Pawn.bBlockActors = true;
		sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(false, self.GetTeamNum());
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = false;	
		if (role == role_authority)
		{
			sneaktoslimpawn_ginsengbaby(self.Pawn).CallToggleDustParticle(false, self.GetTeamNum());
		}
		`log("Restarting energy regen", true, 'Ravi');
		ClearTimer('UpdateEnergy');
		SetTimer(2, false, 'StartEnergyRegen');
	}

Begin:
	Pawn.bBlockActors = false;
	sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(true, self.GetTeamNum());
	sneaktoslimpawn(self.Pawn).bInvisibletoAI = true;
	if(debugStates) logState();
}

simulated state HoldingTreasureBurrow extends Burrow
{	
	local SneaktoSlimPawn onePawn;

	simulated exec function OnPressFirstSkill()
	{
	}
	simulated exec function OnReleaseFirstSkill()
	{
	}
	simulated exec function OnPressSecondSkill()   //reveal
	{
		pauseSprintTimer();

		//TO-DO		//whether under wall or objects		
		if(Role < ROLE_Authority)
			attemptToChangeState('HoldingTreasureWalking');
		GoToState('HoldingTreasureWalking');
	}

	event EndState(Name NextStateName)
	{
		Pawn.bBlockActors = true;
		sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(false, self.GetTeamNum());
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = false;	
		if (role == role_authority)
		{
			sneaktoslimpawn_ginsengbaby(self.Pawn).CallToggleDustParticle(false, self.GetTeamNum());
		}
		`log("Restarting energy regen", true, 'Ravi');
		ClearTimer('UpdateEnergy');
		SetTimer(2, false, 'StartEnergyRegen');

		if (NextStateName == 'HoldingTreasureWalking')
		{
			SneaktoSlimPawn(self.Pawn).Mesh.SetAnimTreeTemplate(animTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree_treasure');
			if(Role == ROLE_Authority)
			{
				ForEach WorldInfo.AllActors(class'SneaktoSlimPawn', onePawn)
				{
					onePawn.changeAnimTreeOnAllClients(SneaktoSlimPawn(self.Pawn), animTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree_treasure');
				}
			}
		}
		else
		{
			SneaktoSlimPawn(self.Pawn).Mesh.SetAnimTreeTemplate(animTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree');
			if(Role == ROLE_Authority)
			{
				ForEach WorldInfo.AllActors(class'SneaktoSlimPawn', onePawn)
				{
					onePawn.changeAnimTreeOnAllClients(SneaktoSlimPawn(self.Pawn), animTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree');
				}
			}
		}
	}

Begin:
	Pawn.bBlockActors = false;
	sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(true, self.GetTeamNum());
	sneaktoslimpawn(self.Pawn).bInvisibletoAI = true;
	SneaktoSlimPawn(self.Pawn).Mesh.SetAnimTreeTemplate(animTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree_treasure_underground');
	if(Role == ROLE_Authority)
	{
		ForEach WorldInfo.AllActors(class'SneaktoSlimPawn', onePawn)
		{
			onePawn.changeAnimTreeOnAllClients(SneaktoSlimPawn(self.Pawn), animTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree_treasure_underground');
		}
	}
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
					pauseSprintTimer();
					SneaktoSlimPawn(self.Pawn).incrementBumpCount();
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

			if(sneaktoslimpawn(self.Pawn).v_energy <= 20)
				return;
			else
			{		
				SneaktoSlimPawn(self.Pawn).incrementSprintCount();
				resumeSprintTimer();

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
	ENERGY_UPDATE_FREQUENCY = 0.03
	energyConsumptionFactor = 1
}
