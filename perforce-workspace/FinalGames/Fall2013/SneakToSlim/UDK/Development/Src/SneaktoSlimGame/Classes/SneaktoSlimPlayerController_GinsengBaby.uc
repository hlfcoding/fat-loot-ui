class SneaktoSlimPlayerController_GinsengBaby extends SneaktoslimPlayerController
	config(Game);

var vector myOffset;
var float ENERGY_UPDATE_FREQUENCY;
var float burstChargeTime;

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
			//myOffset.X = 0;//sneaktoslimpawn(self.Pawn).Location.X;
			//myOffset.Y = 0;//sneaktoslimpawn(self.Pawn).Location.Y;
			//myOffset.Z = -80;//sneaktoslimpawn(self.Pawn).Location.Z - 15;
			////sneaktoslimpawn(self.Pawn).SetPhysics(PHYS_FLYING);
			//sneaktoslimpawn(self.Pawn).Mesh.SetTranslation(myOffset);
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

exec function changeMeshTranslation(int zValue)
{
	myOffset.X = 0;//sneaktoslimpawn(self.Pawn).Location.X;
	myOffset.Y = 0;//sneaktoslimpawn(self.Pawn).Location.Y;
	myOffset.Z = zValue;//sneaktoslimpawn(self.Pawn).Location.Z - 15;
	//sneaktoslimpawn(self.Pawn).SetPhysics(PHYS_FLYING);
	sneaktoslimpawn(self.Pawn).Mesh.SetTranslation(myOffset);
	serverChangeMeshTranslation(zValue);
}

reliable server function serverChangeMeshTranslation(int zValue)
{
	myOffset.X = 0;//sneaktoslimpawn(self.Pawn).Location.X;
	myOffset.Y = 0;//sneaktoslimpawn(self.Pawn).Location.Y;
	myOffset.Z = zValue;//sneaktoslimpawn(self.Pawn).Location.Z - 15;
	//sneaktoslimpawn(self.Pawn).SetPhysics(PHYS_FLYING);
	sneaktoslimpawn(self.Pawn).Mesh.SetTranslation(myOffset);
}

simulated state Burrow extends PlayerWalking
{
	simulated exec function OnPressSecondSkill()   //reveal
	{
		//TO-DO
		//whether under wall or objects
		myOffset.Z = -48;//sneaktoslimpawn(self.Pawn).Location.Z - 15;
		//sneaktoslimpawn(self.Pawn).SetPhysics(PHYS_Walking);
		sneaktoslimpawn(self.Pawn).Mesh.SetTranslation(myOffset);
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
		burstChargeTime = WorldInfo.TimeSeconds;		
	}

	simulated exec function OnReleaseFirstSkill()
	{
		burstChargeTime = WorldInfo.TimeSeconds - burstChargeTime;
		if(Role < ROLE_Authority)
			attemptToChangeState('Burst');  //to server
		GoToState('Burst');  //local
	}

	simulated function UpdateEnergy()
	{
		SneaktoSlimPawn(Pawn).v_energy -= ENERGY_UPDATE_FREQUENCY * SneaktoSlimPawn(Pawn).PerDashEnergy;
		if(SneaktoSlimPawn(Pawn).v_energy < 30)
		{			
			//SneaktoSlimPawn(Pawn).v_energy = 0;
			OnPressFirstSkill(); //forcibly stop the charge			
		}
	}

	simulated event BeginState(name prevState)
	{   	
		`log("Stopping energy regen", true, 'Ravi');
		ClearTimer('EnergyRegen');
		SetTimer(ENERGY_UPDATE_FREQUENCY, true, 'UpdateEnergy');		
	}

	event EndState(Name NextStateName)
	{
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = false;		
		`log("Restarting energy regen", true, 'Ravi');
		ClearTimer('UpdateEnergy');
		SetTimer(2, false, 'StartEnergyRegen');
	}

	simulated function meshTranslation(int zValue)
	{
		myOffset.X = 0;//sneaktoslimpawn(self.Pawn).Location.X;
		myOffset.Y = 0;//sneaktoslimpawn(self.Pawn).Location.Y;
		myOffset.Z = zValue;
		sneaktoslimpawn(self.Pawn).Mesh.SetTranslation(myOffset);
	}

Begin:
	sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(-80, self.GetTeamNum());
	sneaktoslimpawn(self.Pawn).bInvisibletoAI = true;
	if(debugStates) logState();
}

simulated state Burst
{
	local bool burstComplete;

	simulated event BeginState(name prevState)
	{
		`log("burst charge time: " $ burstChargeTime, true, 'Ravi');
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

Begin:	
	if(debugStates) logState();	
	myOffset.Z = -48;
	sneaktoslimpawn(self.Pawn).Mesh.SetTranslation(myOffset);
	ClearTimer('EnergyRegen');
	SneaktoSlimPawn_GinsengBaby(self.Pawn).BabyBurst();
	SetTimer(2, false, 'StartEnergyRegen');
	burstComplete = true;
}

defaultproperties
{	
	ENERGY_UPDATE_FREQUENCY = 0.2
	myOffset = (X=0, Y=0, Z=-80)
}
