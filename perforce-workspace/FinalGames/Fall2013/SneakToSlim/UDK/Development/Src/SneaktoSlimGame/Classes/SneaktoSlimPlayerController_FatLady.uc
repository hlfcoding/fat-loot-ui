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
			SpeedDown();
		}
		else if (LastStateName == 'InvisibleExhausted' || LastStateName == 'InvisibleSprinting' || LastStateName == 'InvisibleWalking')
		{
			attemptToChangeState('EndInvisible');
			GoToState('EndInvisible');
		}
		else if (LastStateName == 'DisguisedExhausted' || /*LastStateName == 'DisguisedSprinting' || */LastStateName == 'DisguisedWalking')
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
		FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).Mesh.FindAnimNode('customBumpReady')).GetCustomAnimNodeSeq());
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
	FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).Mesh.FindAnimNode('customBumping')).GetCustomAnimNodeSeq());
	
	GoToState('FinishBellyBump');
}


simulated state FinishBellyBump extends CustomizedPlayerWalking
{

	
Begin:
	if(debugStates) logState();
	SetTimer(2, false, 'StartEnergyRegen');

	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customLand','postbump', 0.1f, true, 0, 0.2, false);
	FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).Mesh.FindAnimNode('customLand')).GetCustomAnimNodeSeq());

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

		if (LastStateName == 'HoldingTreasureWalking' || LastStateName == 'HoldingTreasureExhausted')
		{
			GoToState('HoldingTreasureSprinting');
		}
		else if (LastStateName == 'InvisibleWalking' || LastStateName == 'InvisibleExhausted')
		{
			GoToState('InvisibleSprinting');
		}
		else
		{
			`log("state " $ LastStateName $ " trying to go through state Sprinting", true, 'LOG');
		}
	}

	event EndState (Name NextStateName)
	{
		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
		{
			ServerSpeedDown();
			if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
						SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
			sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5);
			if(sneaktoslimpawn(self.Pawn).s_energized == 1)
			{
				ClearTimer('removeEnergyWithTime');
				SetTimer(2, false, 'StartEnergyRegen');
				sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
				sneaktoslimpawn(self.Pawn).s_energized = 0;
			}
		}
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();

		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
		{
			ServerSpeedDown();
			if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
						SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
			sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5);
			if(sneaktoslimpawn(self.Pawn).s_energized == 1)
			{
				ClearTimer('removeEnergyWithTime');
				SetTimer(2, false, 'StartEnergyRegen');
				sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
				sneaktoslimpawn(self.Pawn).s_energized = 0;
			}
			attemptToChangeState('Playerwalking');
			GoToState('Playerwalking');
		}
	}


	// when player input 'Left Shift', also overwrite the same func in playerWalking
	simulated exec function FL_useBuff()
	{
		if(sneaktoslimpawn(self.Pawn).mistNum == 0)
		{
			//no "super" because we have to rewtire/ override!
			sneaktoslimpawn(self.Pawn).checkServerFLBuff(sneaktoslimpawn(self.Pawn).enumBuff.bBuffed, true);
		
			if(sneaktoslimpawn(self.Pawn).bBuffed == 1) 
			{
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();
				sneaktoslimpawn(self.Pawn).bBuffed= 0;
				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[0] = 1;//should not be used 

				attemptToChangeState('InvisibleSprinting');
				GoToState('InvisibleSprinting');
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 2) 
			{			
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();
				sneaktoslimpawn(self.Pawn).bBuffed = 0;

				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[1] = 1;//should not be used 
				OnReleaseSecondSkill();
				ApplySprintingSpeed();
				SetTimer(0.05, true, 'removeEnergyWithTime');
				attemptToChangeState('DisguisedWalking');
				GoToState('DisguisedWalking');

			}
		}
	}

	simulated function SpeedUp()
	{
		if(sneaktoslimpawn(self.Pawn).s_energized == 0)
		{
			SetTimer(0.05, true, 'removeEnergyWithTime');
			
			sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLSprintingSpeed;
			sneaktoslimpawn(self.Pawn).s_energized = 1;
		}
	}




	//simulated function EnergyCheck()
	//{
	//	if (Vsize(sneaktoslimpawn(self.Pawn).Velocity) != 0)
	//	{
	//		if(sneaktoslimpawn(self.Pawn).v_energy > sneaktoslimpawn(self.Pawn).PerSpeedEnergy)
	//		{
	//			ClearTimer('EnergyRegen');
	//			ClearTimer('StartEnergyRegen');
	//			//current.startSpeedUpAnim();
	//			SwitchToCamera('ShoulderCam');
	//			SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,true,0.5,0.5,true,false);
	//			sneaktoslimpawn(self.Pawn).v_energy = sneaktoslimpawn(self.Pawn).v_energy - sneaktoslimpawn(self.Pawn).PerSpeedEnergy;
	//			if (sneaktoslimpawn(self.Pawn).v_energy < 0)
	//				sneaktoslimpawn(self.Pawn).v_energy = 0;
	//		}
	//		else
	//		{
	//			//attemptToChangeState('EndSprinting');
	//			//GoToState('EndSprinting');//local
	//			OnReleaseSecondSkill();
	//		}
	//	}
	//	else
	//	{
	//		SetTimer(2, false, 'StartEnergyRegen');
	//		if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
	//				SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
	//		SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5f);
	//	}
	//}

	simulated function removeEnergyWithTime()
	{
		if (Vsize(sneaktoslimpawn(self.Pawn).Velocity) != 0)
		{
			if(sneaktoslimpawn(self.Pawn).v_energy > sneaktoslimpawn(self.Pawn).PerSpeedEnergy)
			{
				ClearTimer('EnergyRegen');
				ClearTimer('StartEnergyRegen');
				SwitchToCamera('ShoulderCam');                                                                                  //change camera
				SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,true,0.5,0.5,true,false);     //play animation
				SneaktoSlimPawn(self.Pawn).v_energy = SneaktoSlimPawn(self.Pawn).v_energy - SneaktoSlimPawn(self.Pawn).PerSpeedEnergy;
				if (sneaktoslimpawn(self.Pawn).v_energy < 0)
						sneaktoslimpawn(self.Pawn).v_energy = 0;
			}
			else
			{
				OnReleaseSecondSkill();
			}
		}
		else
		{
			SetTimer(2, false, 'StartEnergyRegen');
			if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
					SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);                          //change camera
			SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5f);        //stop animation
		}
	}

Begin:
	if(debugStates) logState();
	Speedup();
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

		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
		{
			ServerSpeedDown();
			if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
						SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
			sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5);
			if(sneaktoslimpawn(self.Pawn).s_energized == 1)
			{
				ClearTimer('removeEnergyWithTime');
				SetTimer(2, false, 'StartEnergyRegen');
				sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
				sneaktoslimpawn(self.Pawn).s_energized = 0;
			}
			attemptToChangeState('InvisibleWalking');
			GoToState('InvisibleWalking');
		}
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

//simulated state DisguisedSprinting extends Sprinting
//{
//	simulated exec function use()           //E-button
//	{
//		attemptToChangeState('EndDisguised');
//		GoToState('EndDisguised');
//	}

//	exec function OnPressFirstSkill()
//	{
//		//Player can't belly bump if pause menu is on
//		if(pauseMenuOn)
//			return;

//		SneaktoSlimPawn(self.Pawn).incrementBumpCount();
//		//breaks Disguise
//		attemptToChangeState('PreBellyBump');
//		GoToState('PreBellyBump');
//	}

//	simulated exec function OnReleaseSecondSkill()
//	{
//		pauseSprintTimer();

//		ServerSpeedDown();
//		if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
//					SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
//		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Sprint',1.f,false,0,0.5);
//		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
//		{
//			ClearTimer('EnergyCheck');
//			SetTimer(2, false, 'StartEnergyRegen');
//			sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
//			sneaktoslimpawn(self.Pawn).s_energized = 0;
//		}
//		attemptToChangeState('DisguisedWalking');
//		GoToState('DisguisedWalking');
//	}

//Begin:
//	if(debugStates) logState();
//	Speedup();
//	goDisguised();
//}

simulated state HoldingTreasureSprinting extends Sprinting
{
	exec function OnPressFirstSkill()     //Doesn't belly-bump while Holding Treasure
	{
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();

		if(sneaktoslimpawn(self.Pawn).s_energized == 1)
		{
			ServerSpeedDown();
			if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
						SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
			sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Treasure_Walk',1.f,true,0,0.5);
			if(sneaktoslimpawn(self.Pawn).s_energized == 1)
			{
				ClearTimer('removeEnergyWithTime');
				SetTimer(2, false, 'StartEnergyRegen');
				sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
				sneaktoslimpawn(self.Pawn).s_energized = 0;
			}
			attemptToChangeState('HoldingTreasureWalking');
			GoToState('HoldingTreasureWalking');
		}
	}

	simulated exec function FL_useBuff()
	{

	}

	simulated exec function use()
	{

	}

	//simulated function EnergyCheck()
	//{
	//	if (Vsize(sneaktoslimpawn(self.Pawn).Velocity) != 0)
	//	{
	//		if(sneaktoslimpawn(self.Pawn).v_energy > sneaktoslimpawn(self.Pawn).PerSpeedEnergy)
	//		{
	//			ClearTimer('EnergyRegen');
	//			ClearTimer('StartEnergyRegen');
	//			//current.startSpeedUpAnim();
	//			SwitchToCamera('ShoulderCam');
	//			SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Treasure_Walk',2.0f,true,0.5,0.5,true,false);
	//			sneaktoslimpawn(self.Pawn).v_energy = sneaktoslimpawn(self.Pawn).v_energy - sneaktoslimpawn(self.Pawn).PerSpeedEnergy;
	//			if (sneaktoslimpawn(self.Pawn).v_energy < 0)
	//				sneaktoslimpawn(self.Pawn).v_energy = 0;
	//		}
	//		else
	//		{
	//			//attemptToChangeState('EndSprinting');
	//			//GoToState('EndSprinting');//local
	//			OnReleaseSecondSkill();
	//		}
	//	}
	//	else
	//	{
	//		SetTimer(2, false, 'StartEnergyRegen');
	//		if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
	//				SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
	//		SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Treasure_Walk',2.0f,false,0,0.5f);
	//	}
	//}

	simulated function removeEnergyWithTime()
	{
		if (Vsize(sneaktoslimpawn(self.Pawn).Velocity) != 0)
		{
			if(sneaktoslimpawn(self.Pawn).v_energy > sneaktoslimpawn(self.Pawn).PerSpeedEnergy)
			{
				ClearTimer('EnergyRegen');
				ClearTimer('StartEnergyRegen');
				SwitchToCamera('ShoulderCam');                                                                                  //change camera
				SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Treasure_Walk',1.f,true,0.5,0.5,true,false);     //play animation
				SneaktoSlimPawn(self.Pawn).v_energy = SneaktoSlimPawn(self.Pawn).v_energy - SneaktoSlimPawn(self.Pawn).PerSpeedEnergy;
				if (sneaktoslimpawn(self.Pawn).v_energy < 0)
						sneaktoslimpawn(self.Pawn).v_energy = 0;
			}
			else
			{
				OnReleaseSecondSkill();
			}
		}
		else
		{
			SetTimer(2, false, 'StartEnergyRegen');
			if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
					SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);                          //change camera
			SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Treasure_Walk',1.f,false,0,0.5f);        //stop animation
		}
	}


Begin:
	if(debugStates) logState();
	SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint','Treasure_Walk',2.0f,true,0.5,0.5,true,true);
	Speedup();
	HoldTreasure();
}

defaultproperties
{
}