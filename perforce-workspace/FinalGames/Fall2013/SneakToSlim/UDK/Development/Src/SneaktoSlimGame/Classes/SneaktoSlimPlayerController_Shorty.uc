class SneaktoSlimPlayerController_Shorty extends SneaktoslimPlayerController
	config(Game);

var float dashChargeTime;
var float fireCrackerChargeTime;
var float ENERGY_UPDATE_FREQUENCY;
var bool firstSkillUsed;
var bool secondSkillUsed;
var float FIRECRACKER_INDICATOR_SPEED;
var bool fireCrackerCheatModeOn;


simulated event PostBeginPlay()
{
	ServerStopEnergyRegen();
	Super.PostBeginPlay();	
}

simulated event Possess(Pawn inPawn, bool bVehicleTransition)
{	
	super.Possess(inPawn, bVehicleTransition);	
	`log("Pawn " $ Pawn.Name $ " is attached to controller " $ self.Name, true, 'Ravi');
    Pawn.SetMovementPhysics();

    FIRECRACKER_INDICATOR_SPEED = 13.5 / 250 * SneaktoSlimPawn_Shorty(inPawn).FIRECRACKER_SPEED_MULTIPLIER;
	clientSetFirecrackerIndicatorSpeed(FIRECRACKER_INDICATOR_SPEED);
	`log("Indicator speed is " $ FIRECRACKER_INDICATOR_SPEED, true,'Ravi');
}

reliable client function clientSetFirecrackerIndicatorSpeed(float speed)
{
	FIRECRACKER_INDICATOR_SPEED = speed;
	`log("Indicator speed is " $ FIRECRACKER_INDICATOR_SPEED, true,'Ravi');
}

exec function showFatLootClassName()
{
	`log(self.Pawn.Class);
	`log(self.Class);
}

exec function OnPressFirstSkill() 
{	
	if(Role < ROLE_Authority)
		ServerGotoState('ChargingFireCracker');

	GotoState('ChargingFireCracker');	
}

exec function OnReleaseFirstSkill()
{
	if( !firstSkillUsed )
	{
		if(Role < ROLE_Authority)
			ServerGotoState('ThrowingFireCracker');

		GotoState('ThrowingFireCracker');
	}
}

//exec function ChargeShortyDash() 
exec function OnPressSecondSkill()
{		
	if(Role < ROLE_Authority)
		ServerGotoState('ChargingDash');

	GotoState('ChargingDash');
}

//exec function ActivateShortyDash()
exec function OnReleaseSecondSkill()
{	
	if( !secondSkillUsed )
	{
		if(Role < ROLE_Authority)
			ServerGotoState('Dashing');

		GotoState('Dashing');
	}
}

/******************************* FIRECRACKER STATES START *****************************/
simulated state ChargingFireCracker
{
	local SneakToSlimSpotLight splight;
	local float timeSpentInState;

	simulated function UpdateEnergy()
	{
		SneaktoSlimPawn(Pawn).v_energy -= ENERGY_UPDATE_FREQUENCY * SneaktoSlimPawn(Pawn).PerDashEnergy * 2;
		if(SneaktoSlimPawn(Pawn).v_energy < 0)
		{			
			SneaktoSlimPawn(Pawn).v_energy = 0;
			OnReleaseFirstSkill(); //forcibly stop the charge			
		}
	}

	simulated event BeginState(Name LastStateName)
	{	
		firstSkillUsed = false;
		fireCrackerChargeTime = WorldInfo.TimeSeconds; //time when charging started		
		Pawn.GroundSpeed = 0;
		if(Role < ROLE_Authority)
		{
			ClearTimer('EnergyRegen');
			ClearTimer('StartEnergyRegen');
			SetTimer(ENERGY_UPDATE_FREQUENCY, true, 'UpdateEnergy');
		}
	}

	simulated event EndState(Name NextStateName)
	{
		ClearTimer('MoveLight');
		if(splight != none)
			splight.Destroy();

		if(Role < ROLE_Authority)
		{
			ClearTimer('UpdateEnergy');
			SetTimer(2, false, 'StartEnergyRegen');
		}
	}

	simulated event MoveLight()
	{			
		timeSpentInState = WorldInfo.TimeSeconds - fireCrackerChargeTime;
		if(timeSpentInState < SneaktoSlimPawn_Shorty(Pawn).MAX_FIRECRACKER_CHARGE_TIME * 1.2)
		{			
			splight.Move(splight.Velocity * FIRECRACKER_INDICATOR_SPEED);
		}
	}

Begin:
	splight = Spawn(class'SneakToSlimSpotLight', Self,,Pawn.Location);
	//`log("Spawned light " $ splight.Name $ " at loc " $ splight.Location, true, 'Ravi');
	splight.Velocity = vector(Pawn.Rotation);
	SetTimer(0.1, true, 'MoveLight');	
}

simulated state ThrowingFireCracker
{
	local vector fireCrackerLoc;
	local vector fireCrackerdir;

	simulated event BeginState(Name LastStateName)
	{			
		fireCrackerChargeTime = WorldInfo.TimeSeconds - fireCrackerChargeTime;		
	}

Begin:
	
	fireCrackerLoc = Pawn.Location + vect(0,0,10);
	fireCrackerdir = Normal(vector(Pawn.Rotation) + SneaktoSlimPawn_Shorty(Pawn).FIRECRACKER_THROW_DIRECTION);
	if( Role < Role_Authority )
	{
		ServerStartThrow(fireCrackerChargeTime, fireCrackerLoc.X, fireCrackerLoc.Y, fireCrackerLoc.Z, fireCrackerdir.X, fireCrackerdir.Y, fireCrackerdir.Z);		
	}
	ThrowFireCracker(fireCrackerChargeTime, fireCrackerLoc.X, fireCrackerLoc.Y, fireCrackerLoc.Z, fireCrackerdir.X, fireCrackerdir.Y, fireCrackerdir.Z);
		
	Pawn.GroundSpeed = SneaktoSlimPawn_Shorty(Pawn).FLWalkingSpeed;
	GotoState('PlayerWalking');	
}
/******************************* FIRECRACKER STATES END *****************************/


/******************************* DASH STATES START *****************************/
simulated state ChargingDash
{
	simulated function UpdateEnergy()
	{
		SneaktoSlimPawn(Pawn).v_energy -= ENERGY_UPDATE_FREQUENCY * SneaktoSlimPawn_Shorty(Pawn).DASH_ENERGY_CONSUMPTION_RATE;
		if(SneaktoSlimPawn(Pawn).v_energy < 0)
		{
			SneaktoSlimPawn(Pawn).v_energy = 0;
			OnReleaseSecondSkill();
		}
	}

	simulated event BeginState(Name LastStateName)
	{		
		secondSkillUsed = false;
		dashChargeTime = WorldInfo.TimeSeconds; //time when charging started		
		Pawn.GroundSpeed = 0;
		if(Role < ROLE_Authority)
		{
			ClearTimer('EnergyRegen');
			ClearTimer('StartEnergyRegen');
			SetTimer(ENERGY_UPDATE_FREQUENCY, true, 'UpdateEnergy');
		}
	}

	simulated event EndState(Name NextStateName)
	{
		if(Role < ROLE_Authority)
		{
			ClearTimer('UpdateEnergy');
			SetTimer(2, false, 'StartEnergyRegen');
		}
	}
}

simulated state Dashing
{
	local float dashStartTime;
	local float cappedChargeTime;

	simulated event BeginState(Name LastStateName)
	{		
		secondSkillUsed = true;
		dashChargeTime = WorldInfo.TimeSeconds - dashChargeTime;
		dashStartTime = WorldInfo.TimeSeconds;
		cappedChargeTime = FMin(dashChargeTime * SneaktoSlimPawn_Shorty(Pawn).DASH_CHARGE_VS_MOVE_DURATION_FACTOR, SneaktoSlimPawn_Shorty(Pawn).MAX_DASH_TIME);
	}

	simulated function PlayerMove( float DeltaTime )
	{
		local vector		NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator		OldRotation;
		local vector        viewDirection;
		local float        lerpedSpeed;

		viewDirection = vector(Pawn.Rotation);

		if( Pawn == None )
		{
			GoToState('Dead');
		}
		else
		{
			lerpedSpeed =  FMax(0.0 , (1 - Square((WorldInfo.TimeSeconds - dashStartTime)/cappedChargeTime)) * SneaktoSlimPawn_Shorty(Pawn).SHORTY_DASH_SPEED); //shouldn't go less than 0			
			NewAccel = 10 * viewDirection * DeltaTime * lerpedSpeed;
			NewAccel.Z = 0; //no vertical movement				

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}
			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );

			if( Role < ROLE_Authority ) // save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
		}
	}

	simulated event EndState(name nextState)
	{
		Pawn.GroundSpeed = SneaktoSlimPawn_Shorty(Pawn).FLWalkingSpeed;	
		Pawn.bForceMaxAccel = false;
		dashChargeTime = 0;
	}

Begin:
	
	Pawn.GroundSpeed = SneaktoSlimPawn_Shorty(Pawn).SHORTY_DASH_SPEED;
	Pawn.bForceMaxAccel = true;	
	sleep(cappedChargeTime);	
	GotoState('PlayerWalking');
}
/******************************* DASH STATES END *****************************/

simulated function StopDashing()
{
	Pawn.GroundSpeed = SneaktoSlimPawn_Shorty(Pawn).FLWalkingSpeed;	
	Pawn.bForceMaxAccel = false;
	dashChargeTime = 0;	
	GotoState('PlayerWalking');
}

reliable server function ServerGotoState(name state)
{
	GotoState(state);
}

reliable server function ServerStopEnergyRegen()
{
	ClearTimer('EnergyRegen');
	ClearTimer('StartEnergyRegen');
}

reliable server function ServerStartThrow(float chargeTime, int locX, int locY, int locZ, float dirX, float dirY, float dirZ)
{
	ThrowFireCracker(chargeTime, locX, locY, locZ, dirX, dirY, dirZ);
}

simulated function ThrowFireCracker(float chargeTime, int locX, int locY, int locZ, float dirX, float dirY, float dirZ)
{
	local SneakToSlimFireCracker SpawnedProjectile;
	local vector loc, dir;
	loc.X = locX; loc.Y = locY; loc.Z = locZ;
	dir.X = dirX; dir.Y = dirY; dir.Z = dirZ;
	
	if( !firstSkillUsed && (chargeTime >= SneaktoSlimPawn_Shorty(Pawn).MIN_FIRECRACKER_CHARGE_TIME || fireCrackerCheatModeOn) )
	{
		SpawnedProjectile = Spawn(class'SneakToSlimFireCracker', Self,,loc );
		if(fireCrackerCheatModeOn)
		{
			chargeTime = 3;			
		}		
		SpawnedProjectile.Speed = FMin(chargeTime, SneaktoSlimPawn_Shorty(Pawn).MAX_FIRECRACKER_CHARGE_TIME) * SneaktoSlimPawn_Shorty(Pawn).FIRECRACKER_SPEED_MULTIPLIER;
		//`log("Throwing from " $ loc $ " dir " $ dir $ " speed " $ SpawnedProjectile.Speed, true, 'Ravi');
		SpawnedProjectile.Init(dir);
		firstSkillUsed = true;
	}
}

exec function SpamFireCrackers()
{
	fireCrackerCheatModeOn = true;
}

defaultproperties
{	
	ENERGY_UPDATE_FREQUENCY = 0.2	
	fireCrackerCheatModeOn = false
}