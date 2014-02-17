class SneaktoSlimPlayerController_FatLady extends SneaktoslimPlayerController
	config(Game);

exec function showFatLootClassName()
{
	`log(self.Pawn.Class);
	`log(self.Class);
	`log(self.GetTeamNum());
}

simulated state PreBellyBump extends CustomizedPlayerWalking
{
	event BeginState (Name LastStateName)
	{
		if (LastStateName == 'Sprinting')
		{
			OnReleaseSecondSkill();
		}
		else if (LastStateName == 'InvisibleExhausted' || LastStateName == 'InvisibleSprinting' || LastStateName == 'InvisibleWalking')
		{
			attemptToChangeState('EndInvisible');
			GoToState('EndInvisible');
		}
		else if (LastStateName == 'DisguisedExhausted' || LastStateName == 'DisguisedSprinting' || LastStateName == 'DisguisedWalking')
		{
			attemptToChangeState('EndDisguised');
			GoToState('EndDisguised');
		}
	}


Begin:
	if(debugStates) logState();

	ClearTimer('EnergyRegen');

	previousStateName = 'BellyBump';
	//Don't belly bump if map is on
	if(myMap != NONE && !myMap.isOn)
		//!sneaktoslimpawn(self.Pawn).vaseIMayBeUsing.occupied )
	{
		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customBumpReady','preBump', 4.f, true, 0, 0, false);
		FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).mySkelComp.FindAnimNode('customBumpReady')).GetCustomAnimNodeSeq());
		GoToState('InBellyBump');
	}
	GoToState('Playerwalking');
}

simulated state InBellyBump extends CustomizedPlayerWalking
{

	simulated function Timer()
	{    
		GoToState('FinishBellyBump');
	}

	event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime)
	{
		super.OnAnimEnd(SeqNode, PlayedTime, ExcessTime);
		`log("213123123123123");
	}

	simulated function bool letsBellyBump()
	{
		if (sneaktoslimpawn(self.Pawn).v_energy > 10 && sneaktoslimpawn(self.Pawn).GroundSpeed != 0) 
		{
			
			sneaktoslimpawn(self.Pawn).v_energy -= sneaktoslimpawn(self.Pawn).PerDashEnergy;
			sneaktoslimpawn(self.Pawn).TakeDamage(0, none, sneaktoslimpawn(self.Pawn).Location, Vector(sneaktoslimpawn(self.Pawn).Rotation) * 50000, class'DamageType');

			sneaktoslimpawn(self.Pawn).Mesh.MotionBlurInstanceScale = 1;
			return true;
		}
		else
		{
			return false;
		}
	}


Begin:
	if(debugStates) logState();

	letsBellyBump();
	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customBumping','bumping', 1.f, true, 0, 0, false);
	FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).mySkelComp.FindAnimNode('customBumping')).GetCustomAnimNodeSeq());
	
	GoToState('FinishBellyBump');
}


simulated state FinishBellyBump extends CustomizedPlayerWalking
{

	
Begin:
	if(debugStates) logState();
	SetTimer(2, false, 'StartEnergyRegen');

	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customLand','postbump', 0.1f, true, 0, 0.2, false);
	FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).mySkelComp.FindAnimNode('customLand')).GetCustomAnimNodeSeq());

	GoToState('Playerwalking');
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

		if(sneaktoslimpawn(self.Pawn).v_energy <= 20)
			return;
		else
		{
			SneaktoSlimPawn(self.Pawn).incrementBumpCount();

			attemptToChangeState('PreBellyBump');
			GoToState('PreBellyBump');
			//changeEveryoneState('PreBellyBump');
		}
	}

	//Called when sprint-button is clicked down and held. SpeedDown() is called when the button is released.
	simulated exec function OnPressSecondSkill()
	{
		//Player can't sprint if pause menu is on 
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementSprintCount();
		resumeSprintTimer();
		attemptToChangeState('Sprinting');//to server
		GoToState('Sprinting');//local
	}

Begin:
	if(debugStates) logState();
}

//Player goes through this state when he clicks sprint-button.
simulated state Sprinting extends PlayerWalking
{

	event BeginState (Name LastStateName)
	{
		////
		//InvisibleWalking should go into either PlayerWalking or InvisibleSprinting then to Sprinting
		//
		if (LastStateName == 'HoldingTreasureWalking' || LastStateName == 'HoldingTreasureExhausted')
		{
			GoToState('HoldingTreasureSprinting');
		}
		else if (LastStateName == 'InvisibleWalking' || LastStateName == 'InvisibleExhausted')
		{
			GoToState('InvisibleSprinting');
		}
		else if (LastStateName == 'DisguisedWalking' || LastStateName == 'DisguisedExhausted')
		{
			GoToState('DisguisedSprinting');
		}
		else
		{
			`log("state " $ LastStateName $ " trying to go through state Sprinting", true, 'LOG');
		}
	}

	
	//event EndState (name NextStateName)
	//{
	//	if(NextStateName == 'Hiding')
	//		SpeedDown();
	//}

	// when player input 'Left Shift', also overwrite the same func in playerWalking
	simulated exec function FL_useBuff()
	{
		if(sneaktoslimpawn(self.Pawn).mistNum == 0)
		{
			//no "super" because we have to rewtire/ override!
			sneaktoslimpawn(self.Pawn).checkServerFLBuff(sneaktoslimpawn(self.Pawn).enumBuff.bBuffed, true);
		
			if(sneaktoslimpawn(self.Pawn).bBuffed == 1) 
			{
				sneaktoslimpawn(self.Pawn).bBuffed= 0;
				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[0] = 1;//should not be used 

				attemptToChangeState('InvisibleSprinting');
				GoToState('InvisibleSprinting');
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 2) 
			{			
				sneaktoslimpawn(self.Pawn).bBuffed = 0;

				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[1] = 1;//should not be used 

				attemptToChangeState('DisguisedSprinting');
				GoToState('DisguisedSprinting');

			}
		}
	}

	simulated function SpeedUp()
	{
		if(sneaktoslimpawn(self.Pawn).s_energized == 0)
		{
			SetTimer(0.05, true, 'EnergyCheck');
			//SwitchToShoulderCam();        //ANDYCAM
			SwitchToCamera('ShoulderCam');
			sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLSprintingSpeed;
			sneaktoslimpawn(self.Pawn).s_energized = 1;
		}
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();

		ServerSpeedDown();
		//current = sneaktoslimpawn(self.Pawn);
		if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
					SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5);
		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
		{
			ClearTimer('EnergyCheck');
			SetTimer(2, false, 'StartEnergyRegen');
			sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
			sneaktoslimpawn(self.Pawn).s_energized = 0;
		}
		attemptToChangeState('Playerwalking');
		GoToState('Playerwalking');
	}


	simulated function EnergyCheck()
	{
		if (Vsize(sneaktoslimpawn(self.Pawn).Velocity) != 0)
		{
			if(sneaktoslimpawn(self.Pawn).v_energy > sneaktoslimpawn(self.Pawn).PerSpeedEnergy)
			{
				ClearTimer('EnergyRegen');
				ClearTimer('StartEnergyRegen');
				//current.startSpeedUpAnim();
				SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,true,0.5,0.5,true,false);
				sneaktoslimpawn(self.Pawn).v_energy = sneaktoslimpawn(self.Pawn).v_energy - sneaktoslimpawn(self.Pawn).PerSpeedEnergy;
				if (sneaktoslimpawn(self.Pawn).v_energy < 0)
					sneaktoslimpawn(self.Pawn).v_energy = 0;
			}
			else
			{
				//attemptToChangeState('EndSprinting');
				//GoToState('EndSprinting');//local
				OnReleaseSecondSkill();
			}
		}
		else
		{
			SetTimer(2, false, 'StartEnergyRegen');
			SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5f);
		}
	}

Begin:
	if(debugStates) logState();

	//SwitchToShoulderCam();    //ANDYCAM
	Speedup();
}

simulated state InvisibleWalking
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndInvisible');
		GoToState('EndInvisible');
		super.Use();
	}

	exec function OnPressFirstSkill()
	{
		//Player can't belly bump if pause menu is on
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementBumpCount();
		//breaks invisibility
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	//override from playerWalking
	simulated exec function OnPressSecondSkill()
	{
		//Player can't sprint if pause menu is on 
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementSprintCount();
		resumeSprintTimer();
		attemptToChangeState('InvisibleSprinting');//to server
		GoToState('InvisibleSprinting');//local
	}


Begin:
	if(debugStates) logState();

	goInvisible();
}


simulated state InvisibleSprinting extends Sprinting
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndInvisible');
		GoToState('EndInvisible');
	}

	exec function OnPressFirstSkill()
	{
		//Player can't belly bump if pause menu is on
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementBumpCount();
		//breaks invisibility
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();

		ServerSpeedDown();
		if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
					SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5);
		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
		{
			ClearTimer('EnergyCheck');
			SetTimer(2, false, 'StartEnergyRegen');
			sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
			sneaktoslimpawn(self.Pawn).s_energized = 0;
		}
		attemptToChangeState('InvisibleWalking');
		GoToState('InvisibleWalking');
	}

	//event EndState(Name NextStateName)
	//{
	//	ClearTimer('countDownTimer');
	//}

Begin:
	if(debugStates) logState();

	//if(!IsTimerActive('countDownTimer'))
	//	setTimer(1.0f, true, 'countDownTimer');

	Speedup();
	goInvisible();

}

simulated state InvisibleExhausted
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndInvisible');
		GoToState('EndInvisible');
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();
	}

	exec function OnPressFirstSkill()
	{
		//Player can't belly bump if pause menu is on
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementBumpCount();
		//breaks invisibility
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	event EndState(Name NextStateName)
	{
		//current.playerPlayOrStopCustomAnim('customTired','Tired',1.f,false,0,0.5);
		//current.playerPlayOrStopCustomAnimStruct(current.tiredNodeInfo, false);
		//current.toggleTiredAnimation(false);
		sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
	}

Begin:
	if(debugStates) logState();


	goInvisible();
	sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLExhaustedSpeed;
	//current.playerPlayOrStopCustomAnim('customTired','Tired',1.f,true,0,0.5);
}

simulated state DisguisedWalking
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndDisguised');
		GoToState('EndDisguised');
	}

	exec function OnPressFirstSkill()
	{
		//Player can't belly bump if pause menu is on
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementBumpCount();
		//breaks Disguise
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	simulated exec function OnPressSecondSkill()
	{
		//Player can't sprint if pause menu is on 
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementSprintCount();
		resumeSprintTimer();
		attemptToChangeState('DisguisedSprinting');//to server
		GoToState('DisguisedSprinting');//local
	}

Begin:
	if(debugStates) logState();
	goDisguised();
}

simulated state DisguisedSprinting extends Sprinting
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndDisguised');
		GoToState('EndDisguised');
	}

	exec function OnPressFirstSkill()
	{
		//Player can't belly bump if pause menu is on
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementBumpCount();
		//breaks Disguise
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();

		ServerSpeedDown();
		if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
					SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5);
		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
		{
			ClearTimer('EnergyCheck');
			SetTimer(2, false, 'StartEnergyRegen');
			sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
			sneaktoslimpawn(self.Pawn).s_energized = 0;
		}
		attemptToChangeState('DisguisedWalking');
		GoToState('DisguisedWalking');
	}

Begin:
	if(debugStates) logState();
	Speedup();
	goDisguised();
}

//Child of PlayerWalking, entered when player has <20% energy, and exited when >=20%
simulated state DisguisedExhausted
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndDisguised');
		GoToState('EndDisguised');
	}

	exec function OnPressFirstSkill()
	{
		//Player can't belly bump if pause menu is on
		if(pauseMenuOn)
			return;

		SneaktoSlimPawn(self.Pawn).incrementBumpCount();
		//breaks Disguise
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();
	}

	event EndState(Name NextStateName)
	{
		//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTired','Tired',1.f,false,0,0.5);
		//current.toggleTiredAnimation(false);
		sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
	}

Begin:
	if(debugStates) logState();

	goDisguised();
	sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLExhaustedSpeed;
	//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTired','Tired',1.f,true,0,0.5);
	//current.toggleTiredAnimation(true);
}

simulated state HoldingTreasureSprinting extends Sprinting
{
	exec function OnPressFirstSkill()     //Doesn't belly-bump while Holding Treasure
	{
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();

		ServerSpeedDown();
		if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
					SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5);
		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
		{
			ClearTimer('EnergyCheck');
			SetTimer(2, false, 'StartEnergyRegen');
			sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
			sneaktoslimpawn(self.Pawn).s_energized = 0;
		}
		attemptToChangeState('HoldingTreasureWalking');
		GoToState('HoldingTreasureWalking');
	}

	simulated exec function FL_useBuff()
	{

	}

	simulated exec function use()
	{

	}


Begin:
	if(debugStates) logState();
	SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',2.3f,true,0.5,0.5,true,true);
	Speedup();
	HoldTreasure();
}

defaultproperties
{
}