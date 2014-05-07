class SneaktoSlimPlayerController_Rabbit extends SneaktoslimPlayerController
	config(Game);

var int perRoarEnergy;
var float roarTime;
var int perDiveEnergy;
var float distanceDive;
var vector myOffset;
var float TELEPORT_DURATION;
var bool RoarLinesIsOn;

exec function toggleRoarLines()
{
	if (RoarLinesIsOn == false)
	{
		SetTimer(0.01, true, 'showRoarLines');
		RoarLinesIsOn = true;
	}
	else
	{
		clearTimer('showRoarLines');
		RoarLinesIsOn = false;
	}
}

simulated function showRoarLines()
{
	local Vector selfLocation;
	local Rotator selfRotation, selfRotationL, selfRotationR;

	selfLocation = SneaktoSlimPawn(self.Pawn).Location - (100* Vector(SneaktoSlimPawn(self.Pawn).Rotation));
	selfRotation = SneaktoSlimPawn(self.Pawn).Rotation;
	selfRotationL = selfRotation;
	selfRotationL.Yaw -= DegToUnrRot*15;
	
	selfRotationR = selfRotation;
	selfRotationR.Yaw += DegToUnrRot*15;


	DrawDebugLine(selfLocation, selfLocation + (300 * Vector(selfRotationL)), 0, 80, 200, false);
	DrawDebugLine(selfLocation, selfLocation + (300 * Vector(selfRotationR)), 0, 80, 200, false);
}

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
			SneaktoSlimPawn(self.Pawn).incrementBumpCount();
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
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			attemptToChangeState('Teleport');
			GoToState('Teleport');
		}
	}


Begin:
	if(debugStates) logState();
}

simulated state Teleport
{
	simulated exec function use()
	{
		if(SneaktoSlimPawn(self.Pawn).isGotTreasure == true)
			return;
		else
			super.Use();
	}
	
	event BeginState (Name LastStateName)
	{
		if(sneaktoslimpawn(self.Pawn).v_energy <= perDiveEnergy)
			return;

		SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customBlink', 'Blink', 1.f, true, 0.1f, 0.2f, false, true);
		sneaktoslimpawn(self.Pawn).v_energy -= perDiveEnergy;
		//SwitchToCamera('Fixed');
		Pawn.GroundSpeed = SneaktoSlimPawn_Rabbit(Pawn).TELEPORT_SPEED;
		Pawn.bForceMaxAccel = true;	
		SneaktoSlimPawn_Rabbit(Pawn).AccelRate = SneaktoSlimPawn_Rabbit(Pawn).TELEPORT_ACCELERATION;
		SneaktoSlimPawn_Rabbit(Pawn).SetCollisionType(COLLIDE_NoCollision);
		//if(Role < ROLE_Authority)
		//{
			ClearTimer('EnergyRegen');
			ClearTimer('StartEnergyRegen');			
		//}
	}
	
	simulated function PlayerMove( float DeltaTime )
	{
		local vector		NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator		OldRotation;
		local vector        viewDirection;

		viewDirection = vector(Pawn.Rotation);
		if( Pawn == None )
		{
			GoToState('Dead');
		}
		else
		{
			NewAccel = 10 * viewDirection * DeltaTime * SneaktoSlimPawn_Rabbit(Pawn).TELEPORT_SPEED;
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

	simulated function ResetValues()
	{
		SneaktoSlimPawn_Rabbit(Pawn).SetCollisionType(COLLIDE_BlockAll);
		SneaktoSlimPawn_Rabbit(Pawn).AccelRate = SneaktoSlimPawn_Rabbit(Pawn).NORMAL_ACCELERATION;
		Pawn.GroundSpeed = SneaktoSlimPawn_Rabbit(Pawn).FLWalkingSpeed;
		Pawn.bForceMaxAccel = false;
	}

	simulated event EndState(name nextState)
	{
		ResetValues();
		//SwitchToCamera('ThirdPerson');
		//if(Role < ROLE_Authority)
		//{			
			SetTimer(2, false, 'StartEnergyRegen');
		//}
	}

Begin:
	if(debugStates) logState();	
	sleep(TELEPORT_DURATION);	
	ResetValues();
	sleep(0.15); //wait for camera to catch up
	if(SneaktoSlimPawn(self.Pawn).isGotTreasure == true)
	{
		attemptToChangeState('HoldingTreasureWalking');
		GoToState('HoldingTreasureWalking');
	}
	else
	{
		attemptToChangeState('PlayerWalking');
		GoToState('PlayerWalking');
	}
}

simulated state Roaring extends CustomizedPlayerWalking
{

	event BeginState (Name LastStateName)
	{
		if (LastStateName == 'InvisibleExhausted' || LastStateName == 'InvisibleWalking')
		{
			attemptToChangeState('EndInvisible');
			GoToState('EndInvisible');
		}
		else if (LastStateName == 'DisguisedExhausted' || LastStateName == 'DisguisedWalking')
		{
			attemptToChangeState('EndDisguised');
			GoToState('EndDisguised');
		}
		ClearTimer('EnergyRegen');
		ClearTimer('StartEnergyRegen');	
	}

	simulated function Rabbit_Roar()
	{
		local SneaktoSlimPawn victim;
		`log("Rabbit_Roar!!");

		
		SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customRoar', 'roar', 1.f, true, 0.1f, 0.1f, false, true);

		if(sneaktoslimpawn(self.Pawn).v_energy <= perRoarEnergy)
			return;

		SneaktoSlimPawn(self.Pawn).v_energy -= perRoarEnergy;
		
		if(Role == Role_Authority)
			SneaktoSlimPawn(self.Pawn).callClientRoarParticle(SneaktoSlimPawn_Rabbit(self.Pawn).GetTeamNum());

		foreach self.Pawn.VisibleCollidingActors(class'SneaktoSlimPawn', victim, 300)
		{
			if (ActorLookingAt(SneaktoSlimPawn(self.Pawn),SneaktoSlimPawn(self.Pawn).Location, victim, 90) && ActorLookingAt(SneaktoSlimPawn(self.Pawn),SneaktoSlimPawn(self.Pawn).Location - (100 * vector(SneaktoSlimPawn(self.Pawn).Rotation)), victim, 15))
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

	simulated event EndState(name nextState)
	{
		SetTimer(2, false, 'StartEnergyRegen');
	}

Begin:
	Rabbit_Roar();
	SetTimer(roarTime, false, 'StopRoaring');
}





defaultproperties
{
	perRoarEnergy = 30;
	roarTime = 0.2f;
	perDiveEnergy = 35;
	distanceDive = 225.0;
	myOffset = (X=0, Y=0, Z=-90)
	TELEPORT_DURATION = 0.2f
	RoarLinesIsOn = false
}
