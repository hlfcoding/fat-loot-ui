/**
 * Copyright 1998-2013 Epic Games, Inc. All Rights Reserved.
 */
class SneaktoSlimPlayerController extends GamePlayerController
	config(Game);
var bool bPlayerCanZoom;
var name previousStateName;
//var bool bIsSprinting;
var bool debugStates;
var bool debugAnimes;
var MiniMap myMap;
//var bool bCaughtByAI;
var float HoldTime;
var int RESPAWN_TIME;
var PlayerStart playerBase;
var bool uiOn;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	SetTimer(2, false, 'StartEnergyRegen');
	
	SetTimer(0.05, true, 'ExhaustedCheck');

	SetTimer(0.05, false, 'addOutLine');

	myMap = Spawn(class'SneaktoSlimGame.MiniMap',,,self.Location,,,);
	uiOn = true;
	
	SetTimer(0.05, false, 'getBase');
	

}

simulated function getBase()
{
	foreach WorldInfo.AllNavigationPoints (class'PlayerStart', playerBase)
	{					
		if (playerBase.TeamIndex == SneaktoSlimPawn(self.Pawn).GetTeamNum())
		{
			break;
		}
	}
}

//Currently makes player input zero, while still accepting player inputs.
simulated state CustomizedPlayerWalking
{
	//Update player rotation when walking
	simulated function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local Rotator CameraRotationYawOnly;
		//local Vector ZeroVector;
		//ZeroVector = vect(0.0, 0.0, 0.0);

		//previousStateName = 'Walking';

		if( Pawn == None )
		{
			return;
		}

		if (Role == ROLE_Authority)
		{
			// Update ViewPitch for remote clients
			Pawn.SetRemoteViewPitch( Rotation.Pitch );
		}

		//get the controller yaw to transform our movement-accelerations by
		CameraRotationYawOnly.Yaw = Rotation.Yaw; 
		NewAccel = NewAccel>>CameraRotationYawOnly; //transform the input by the camera World orientation so that it's in World frame

		Pawn.Acceleration = vect(0.0, 0.0, 0.0);
   
		Pawn.FaceRotation(Rotation,DeltaTime); //notify pawn of rotation

		CheckJumpOrDuck();
	}

	simulated function PlayerMove( float DeltaTime )
	{
		local vector		NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator		OldRotation;

		if( Pawn == None )
		{
			GoToState('Dead');
		}
		else
		{
			NewAccel.Y =  0;
			NewAccel.X = 0;
			NewAccel.Z = 0; //no vertical movement for now, may be needed by ladders later

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );

			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
		}
	}

	simulated exec function SpeedDown()
	{
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
	}

Begin:
	if(debugStates) logState();
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
	if(myMap != NONE && !myMap.isOn) //&& 
	//if(//////////////////////////////////////////////////////////////////////////!myMap.isOn && 
		//!sneaktoslimpawn(self.Pawn).vaseIMayBeUsing.occupied )
	{
		//sneaktoslimpawn(self.Pawn).bumpReadyNode.PlayCustomAnim('preBump', 4.0f, 0.1f, 0, false, true);
		//FinishAnim(sneaktoslimpawn(self.Pawn).bumpReadyNode.GetCustomAnimNodeSeq() );

		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customBumpReady','preBump', 4.f, true, 0, 0, false);
		//WaitForLanding();

		FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).mySkelComp.FindAnimNode('customBumpReady')).GetCustomAnimNodeSeq());

		GoToState('InBellyBump');
	}
	GoToState('Playerwalking');
}

function addOutLine()
{
	// To fix custom post processing chain when not running in editor or PIE.
	local localPlayer LP;

	//`log("controller process chain called");
	LP = LocalPlayer(self.Player); 
	if(LP != None) 
	{ 
		`log("sneak to lim chain processing");
		LP.RemoveAllPostProcessingChains(); 
		LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
		if(self.myHUD != None)
		{
			self.myHUD.NotifyBindPostProcessEffects();
		}
	} 
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
			//current.SetPhysics(PHYS_FALLING);

			//current.Velocity = Vector(current.Rotation) * current.GroundSpeed * 5;
			//current.Velocity.Z = 100;
			//`log("current.Location " $ current.Location $ " current.Velocity " $ current.Velocity);
			sneaktoslimpawn(self.Pawn).TakeDamage(0, none, sneaktoslimpawn(self.Pawn).Location, Vector(sneaktoslimpawn(self.Pawn).Rotation) * 50000, class'DamageType');

			//sneaktoslimpawn(self.Pawn).bIsDashing = true;
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

	//current_2.bIsDashing = true;
	letsBellyBump();
	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customBumping','bumping', 1.f, true, 0, 0, false);
	//WaitForLanding();

	FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).mySkelComp.FindAnimNode('customBumping')).GetCustomAnimNodeSeq());
	//settimer(2);
	//
	GoToState('FinishBellyBump');
}


simulated state FinishBellyBump extends CustomizedPlayerWalking
{

	
Begin:
	if(debugStates) logState();
	SetTimer(2, false, 'StartEnergyRegen');

	//sneaktoslimpawn(self.Pawn).bIsDashing = false;
	//sneaktoslimpawn(self.Pawn).bumpLandNode.PlayCustomAnim('Postbump', 0.5f, 0, 0.1f, false, true);
	//FinishAnim(sneaktoslimpawn(self.Pawn).bumpLandNode.GetCustomAnimNodeSeq() );


	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customLand','postbump', 0.1f, true, 0, 0.2, false);
	FinishAnim(AnimNodePlayCustomAnim(sneaktoslimpawn(self.pawn).mySkelComp.FindAnimNode('customLand')).GetCustomAnimNodeSeq());

	GoToState('Playerwalking');
}



exec simulated function clientChangeState(name stateName)
{
	attemptToChangeState(stateName);
	//simulatedChangeState(stateName);
}

simulated reliable server function attemptToChangeState(name stateName)
{
		if (stateName == 'PreBellyBump')
		{
			//sneaktoslimpawn(self.Pawn).bIsDashing = true;
			GoToState(stateName);
		}
		else if (stateName == 'PlayerWalking')
		{
			GoToState(stateName);
		}
		else if (stateName == 'Sprinting')
		{
			GoToState(stateName);
		}
		else if (stateName == 'EndSprinting')
		{
			GoToState(stateName);
		}
		else if (stateName == 'Stunned')
		{
			//sneaktoslimpawn(self.Pawn).isStunned = true;
			GoToState(stateName);
		}
		else if (stateName == 'Hiding')
		{
			GoToState(stateName);
		}
		else if (stateName == 'EndHiding')
		{
			GoToState(stateName);
		}
		else if (stateName == 'Exhausted')
		{
			GoToState(stateName);
		}
		else if (stateName == 'InvisibleWalking')
		{
			GoToState(stateName);
		}
		else if (stateName == 'InvisibleSprinting')
		{
			GoToState(stateName);
		}
		else if (stateName == 'InvisibleExhausted')
		{
			GoToState(stateName);
		}
		else if (stateName == 'EndInvisible')
		{
			GoToState(stateName);
		}
		else if (stateName == 'DisguisedWalking')
		{
			GoToState(stateName);
		}
		else if (stateName == 'DisguisedSprinting')
		{
			GoToState(stateName);
		}
		else if (stateName == 'DisguisedExhausted')
		{
			GoToState(stateName);
		}
		else if (stateName == 'EndDisguised')
		{
			`log("server EndDisguised");
			GoToState(stateName);
		}
		else if (stateName == 'HoldingTreasureWalking')
		{
			GoToState(stateName);
		}
		else if (stateName == 'HoldingTreasureSprinting')
		{
			GoToState(stateName);
		}
		else if (stateName == 'HoldingTreasureExhausted')
		{
			GoToState(stateName);
		}
	//simulatedChangeState(stateName);
}

/*event PlayerTick( float DeltaTime )
{
	super.PlayerTick(DeltaTime);

	//Nick: updates map's location to match player's location (if on)
	if(myMap != NONE)
	{
		if(myMap.isOn)
			myMap.playerLocation = Location;
	}
}*/

//When player clicks 'M' their minimap is turned on/off
exec function toggleMap()
{
	//local CameraActor topDownCamera, cam;
	/*if(ROLE == ROLE_Authority)
		toggleServerUI();
	else
		toggleClientUI();*/
		
	if(myMap != NONE)
	{
		myMap.toggleMap();
		if(myMap.isOn)
			SneaktoSlimPawn(self.Pawn).disablePlayerMovement();
		else
			SneaktoSlimPawn(self.Pawn).enablePlayerMovement();
	}
	
	//Grabs camera that is set above map in editor
	/*foreach WorldInfo.AllActors(class'CameraActor', cam)
	{
		if(cam.Tag == 'topDownCamera')
			topDownCamera = cam;
	}
	SneaktoSlimPlayerController(Controller).setCameraActor(topDownCamera);*/
}

unreliable client function toggleClientUI()
{
	uiOn = !uiOn;
}

unreliable server function toggleServerUI()
{
	uiOn = !uiOn;
}

simulated function changeEveryoneState(name stateName)
{
	local SneaktoSlimPlayerController onePawnC;

	if(debugStates)
					`log(self.Name  $ "@" $ self.GetStateName(), false, 'StateChecking');

	if( ROLE == ROLE_Authority )//server only
	{		
		ForEach class'WorldInfo'.static.GetWorldInfo().AllActors(class 'SneaktoSlimPlayerController', onePawnC)
		{
			//`log(onePawnC.Name  $ "@" $ onePawnC.GetStateName(), false, 'StateChecking');

			if(onePawnC == self)// server only modify specific PlayerController
			{
				if(debugStates)
					`log(onePawnC.Name  $ "@" $ onePawnC.GetStateName(), false, 'StateChecking');

				onePawnC.GoToState(stateName);
				//changeThisOneState(self, stateName);// tell self that target has state change
			}
		}
	}
	else// ROLE < ROLE_Authority 
		self.GoToState(stateName);// local simulation

	if(debugStates)
				`log(self.Name  $ "@" $ self.GetStateName(), false, 'StateChecking');
}

reliable client function clientAttemptToState(name stateName)
{
	gotostate(stateName);
}

//Update player rotation when walking
simulated state PlayerWalking
{
	ignores SeePlayer, HearNoise, Bump;

	exec function testForEnergy()
	{
		`log(sneaktoslimpawn(self.Pawn).v_energy);
	}

	exec function BellyBump()
	{
		if(sneaktoslimpawn(self.Pawn).v_energy <= 20)
			return;
		else
		{
			attemptToChangeState('PreBellyBump');
			GoToState('PreBellyBump');
			//changeEveryoneState('PreBellyBump');
		}
	}

	// when player input 'Left Shift'
	simulated exec function FL_useBuff()
	{
		sneaktoslimpawn(self.Pawn).checkServerFLBuff(sneaktoslimpawn(self.Pawn).enumBuff.bBuffed, true);
		
		if(sneaktoslimpawn(self.Pawn).bBuffed == 1) 
		{
			sneaktoslimpawn(self.Pawn).serverResetBBuffed();

			//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
			sneaktoslimpawn(self.Pawn).bUsingBuffed[0] = 1;//should not be used , kept for "countdown"  at this moment

			attemptToChangeState('InvisibleWalking');
			GoToState('InvisibleWalking');
		}
		if(sneaktoslimpawn(self.Pawn).bBuffed == 2) 
		{			
			sneaktoslimpawn(self.Pawn).serverResetBBuffed();
			//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
			sneaktoslimpawn(self.Pawn).bUsingBuffed[1] = 1;//should not be used 

			attemptToChangeState('DisguisedWalking');
			GoToState('DisguisedWalking');

		}
	}

	

	//Called when sprint-button is clicked down and held. SpeedDown() is called when the button is released.
	simulated exec function SneakySpeed()
	{
		attemptToChangeState('Sprinting');//to server
		GoToState('Sprinting');//local
	}

	//Called when sprint-button is released.
	//simulated exec function NoMoreSpeed()
	//{
	//	//attemptToChangeState('EndSprinting');//to server
	//	//GoToState('EndSprinting');//local
	//	SpeedDown();
	//}
	
	//function applyInvis()
	//{
	//	//Passes current countdown time to itself as client
	//	current.showCountdownTimer(int(current.BuffedTimerDefault[0]-current.BuffedTimer));

	//	if(current.BuffedTimer >= current.BuffedTimerDefault[0])
	//	{
	//		current.hideCountdownTimer();
	//		current.BuffedTimer = 0;
	//		current.inputStringToCenterHUD(0);
	//		`log("buff end ");
	//		GoToState('EndInvisible');
	//		attemptToChangeState('EndInvisible');
	//	}
	//}

	//Update player rotation when walking
	simulated function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local Rotator CameraRotationYawOnly;
		local Vector ZeroVector;
		ZeroVector = vect(0.0, 0.0, 0.0);

		previousStateName = 'Walking';

		if( Pawn == None )
		{
			return;
		}

		if (Role == ROLE_Authority)
		{
			// Update ViewPitch for remote clients
			Pawn.SetRemoteViewPitch( Rotation.Pitch );
		}

		//get the controller yaw to transform our movement-accelerations by
		CameraRotationYawOnly.Yaw = Rotation.Yaw; 
		NewAccel = NewAccel>>CameraRotationYawOnly; //transform the input by the camera World orientation so that it's in World frame

		if (NewAccel != ZeroVector)
			Pawn.Acceleration = NewAccel;
		else
			Pawn.Acceleration = vlerp(Pawn.Acceleration, ZeroVector, 0.8);
   
		Pawn.FaceRotation(Rotation,DeltaTime); //notify pawn of rotation

		CheckJumpOrDuck();
	}

	simulated function PlayerMove( float DeltaTime )
	{
		local vector		NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator		OldRotation;

		if( Pawn == None )
		{
			GoToState('Dead');
		}
		else
		{
			NewAccel.Y =  PlayerInput.aStrafe * DeltaTime * 100 * PlayerInput.MoveForwardSpeed;
			NewAccel.X = PlayerInput.aForward * DeltaTime * 100 * PlayerInput.MoveForwardSpeed;
			NewAccel.Z = 0; //no vertical movement for now, may be needed by ladders later

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );

			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
		}
	}

	simulated function goInvisible()
	{
		sneaktoslimpawn(self.Pawn).invisibleNum = self.GetTeamNum();
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = true;
	}

	simulated function goDisguised()
	{
		sneaktoslimpawn(self.Pawn).disguiseNum = self.GetTeamNum();
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = true;
	}

	simulated function HoldTreasure()
	{
		//
		//
	}



	//exec function forceStun (int number)
	//{
	//	PushState ('Stunned');
	//}



Begin:
	if(debugStates) logState();
}

simulated function DropTreasure()
{
	ServerDropTreasure();
	`log("Function dropping treasure");
	SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',1.f,false,0.5,0.5,true,false);
}

reliable server function ServerDropTreasure()
{
	SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',1.f,false,0.5,0.5,true,false);
}


simulated function StartEnergyRegen()
{
	SetTimer(0.05, true, 'EnergyRegen');
}

simulated function EnergyRegen()
{
	if (sneaktoslimpawn(self.Pawn).v_energy + sneaktoslimpawn(self.Pawn).energyRegenerateRate <= 100)
	{
		sneaktoslimpawn(self.Pawn).v_energy = sneaktoslimpawn(self.Pawn).v_energy + sneaktoslimpawn(self.Pawn).energyRegenerateRate;
		if (sneaktoslimpawn(self.Pawn).v_energy > 99.95)
			sneaktoslimpawn(self.Pawn).v_energy = 100;
	}
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

	simulated exec function SpeedDown()
	{
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
				SpeedDown();
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

reliable server function ServerSpeedDown()
{
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
}

simulated state InvisibleWalking extends PlayerWalking
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndInvisible');
		GoToState('EndInvisible');
		super.Use();
	}

	exec function BellyBump()
	{
		//breaks invisibility
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	//override from playerWalking
	simulated exec function SneakySpeed()
	{
		attemptToChangeState('InvisibleSprinting');//to server
		GoToState('InvisibleSprinting');//local
	}

	//event PlayerTick( float DeltaTime ) 
	//{
	//	`log(current.BuffedTimer $ " InvisibleWalking PlayerTick " $ DeltaTime);
	//	current.BuffedTimer += DeltaTime;
	//}	

	//event EndState(Name NextStateName)
	//{
	//	ClearTimer('countDownTimer');
	//}

Begin:
	if(debugStates) logState();

	//if(!IsTimerActive('countDownTimer'))
	//	setTimer(1.0f, true, 'countDownTimer');

	goInvisible();
}


//function countDownTimer()
//{
//	sneaktoslimpawn(self.Pawn).BuffedTimer += 1.f;
//	`log(sneaktoslimpawn(self.Pawn).BuffedTimer);
//}

simulated state InvisibleSprinting extends Sprinting
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndInvisible');
		GoToState('EndInvisible');
	}

	exec function BellyBump()
	{
		//breaks invisibility
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	simulated exec function SpeedDown()
	{
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

//Will end Invisible from any Invisible state
simulated state EndInvisible
{

	simulated function removeInvisible()
	{
		//if(!sneaktoslimpawn(self.Pawn).hiddenInVase)
		//	sneaktoslimpawn(self.Pawn).SetHidden(false);
		sneaktoslimpawn(self.Pawn).Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
		sneaktoslimpawn(self.Pawn).simulatedDrawPlayerColor();
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = false;
	}

	event BeginState (Name LastStateName)
	{

		`log("!@#!@EASDFASDF BEGIN STATE" $ self.GetTeamNum());
		
		sneaktoslimpawn(self.Pawn).endinvisibleNum = self.GetTeamNum();
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = false;
		sneaktoslimpawn(self.Pawn).bUsingBuffed[0] = 0;

		if (LastStateName == 'InvisibleSprinting')
		{
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeInvisible();
			attemptToChangeState('Sprinting');
			GoToState('Sprinting');
		}
		else if (LastStateName == 'InvisibleExhausted')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeInvisible();
			attemptToChangeState('Exhausted');
			GoToState('Exhausted');
		}
		else if (LastStateName == 'PreBellyBump')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeInvisible();
			attemptToChangeState('PreBellyBump');
			GoToState('PreBellyBump');
		}
	}

Begin:
	if(debugStates) logState();

	`log("!@#!@EASDFASDF");
	//removeInvisible();
	sneaktoslimpawn(self.Pawn).BuffedTimer = 0;
	attemptToChangeState('Playerwalking');
	GoToState('Playerwalking');
}

//Child of PlayerWalking, entered when player has <20% energy, and exited when >=20%
simulated state Exhausted extends PlayerWalking
{

	simulated exec function FL_useBuff()
	{
		//no "super" because we have to rewtire/ override!
		sneaktoslimpawn(self.Pawn).checkServerFLBuff(sneaktoslimpawn(self.Pawn).enumBuff.bBuffed, true);
		
		if(sneaktoslimpawn(self.Pawn).bBuffed == 1) 
		{
			sneaktoslimpawn(self.Pawn).bBuffed= 0;
			//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
			sneaktoslimpawn(self.Pawn).bUsingBuffed[0] = 1;//should not be used 

			attemptToChangeState('InvisibleExhausted');
			GoToState('InvisibleExhausted');
		}
		if(sneaktoslimpawn(self.Pawn).bBuffed == 2) 
		{			
			sneaktoslimpawn(self.Pawn).bBuffed = 0;

			//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
			sneaktoslimpawn(self.Pawn).bUsingBuffed[1] = 1;//should not be used 

			attemptToChangeState('DisguisedExhausted');
			GoToState('DisguisedExhausted');

		}
	}


	event EndState(Name NextStateName)
	{
		
		//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTired','Tired',1.f,false,0,0.5);
		//current.toggleTiredAnimation(false);
		sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
	}

Begin:
	if(debugStates) logState();
	sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLExhaustedSpeed;
	//current.playerPlayOrStopCustomAnim('customTired','Tired',1.f,true,0,0.5,true);
}

//Child of PlayerWalking, entered when player has <20% energy, and exited when >=20%
simulated state InvisibleExhausted extends InvisibleWalking
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndInvisible');
		GoToState('EndInvisible');
	}

	simulated exec function SpeedDown()
	{
	}

	exec function BellyBump()
	{
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

simulated state caughtByAI extends CustomizedPlayerWalking
{

	event EndState (Name NextStateName)
	{
		sneaktoslimpawn(self.Pawn).v_energy = 100;
		//Removed animation statement from here because Vanish animation is already played once.
	}

	event BeginState (Name LastStateName)
	{

		//stopAllTheLoopAnimation();

		if(LastStateName == 'Sprinting' || LastStateName == 'HoldingTreasureSprinting')
		{
			sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customSprint', 'Sprint', 1.f, false);
			SpeedDown();
		}
		else if(LastStateName == 'Stun')
			sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customStun', 'Stun', 1.f, false);
	}

	simulated function hideStateSpottedIcon()
	{
		sneaktoslimpawn(self.Pawn).hideSpottedIcon();
	}

	simulated function movehar()
	{
		`log(sneaktoslimpawn(self.Pawn).Name $ ": Moving " $ sneaktoslimpawn(self.Pawn).name $ " to location " $ playerBase.Name , true, 'Ravi');
		sneaktoslimpawn(self.Pawn).SetLocation(playerBase.Location);

		//guard can catch u when u r in vase ?
		//freeVaseFromPawn() has bug, anyway
		if (sneaktoslimpawn(self.Pawn).vaseIMayBeUsing != none)
		{
			sneaktoslimpawn(self.Pawn).freeVaseFromPawn();
		}
	}

	simulated function endCatchByAI()
	{
		if(Role == Role_Authority)//only server command this
			gotoState('PlayerWalking');
	}

Begin:
	if(debugStates) logState();	

	sneaktoslimpawn(self.Pawn).stopAllTheLoopAnimation();
	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customVanish', 'Vanish', 1.f, true, 0.1f, 0.1f, false, true);
	
	foreach WorldInfo.AllNavigationPoints (class'PlayerStart', playerBase)
	{					
		if (playerBase.TeamIndex == SneaktoSlimPawn(self.Pawn).GetTeamNum())
		{
			break;
		}
	}

	sleep(HoldTime);
	hideStateSpottedIcon();	
	movehar();	
	endCatchByAI();
	//setTimer(HoldTime/2, false, 'hideStateSpottedIcon');
	//setTimer((HoldTime+RESPAWN_TIME)/2, false, 'movehar');
	//setTimer((HoldTime+RESPAWN_TIME), false, 'endCatchByAI');
}

simulated state DisguisedWalking extends PlayerWalking
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndDisguised');
		GoToState('EndDisguised');
	}

	exec function BellyBump()
	{
		//breaks Disguise
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	simulated exec function SneakySpeed()
	{
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

	exec function BellyBump()
	{
		//breaks Disguise
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	simulated exec function SpeedDown()
	{
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
simulated state DisguisedExhausted extends DisguisedWalking
{
	simulated exec function use()           //E-button
	{
		attemptToChangeState('EndDisguised');
		GoToState('EndDisguised');
	}

	exec function BellyBump()
	{
		//breaks Disguise
		attemptToChangeState('PreBellyBump');
		GoToState('PreBellyBump');
	}

	simulated exec function SpeedDown()
	{
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

//Will end Disguised from any Disguised state
simulated state EndDisguised
{
	simulated function removeDisguised()
	{
		sneaktoslimpawn(self.Pawn).endDisguiseNum = self.GetTeamNum();
		//sneaktoslimpawn(self.Pawn).DetachComponent(sneaktoslimpawn(self.Pawn).AISkelComp);
		//sneaktoslimpawn(self.Pawn).ReattachComponent(sneaktoslimpawn(self.Pawn).mySkelComp);
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = false;
	}

	event BeginState (Name LastStateName)
	{
		sneaktoslimpawn(self.Pawn).endDisguiseNum = self.GetTeamNum();
		sneaktoslimpawn(self.Pawn).bInvisibletoAI = false;
		sneaktoslimpawn(self.Pawn).bUsingBuffed[1] = 0;

		if (LastStateName == 'DisguisedSprinting')
		{
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeDisguised();
			attemptToChangeState('Sprinting');
			GoToState('Sprinting');
		}
		else if (LastStateName == 'DisguisedExhausted')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeDisguised();
			attemptToChangeState('Exhausted');
			GoToState('Exhausted');
		}
		else if (LastStateName == 'PreBellyBump')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeDisguised();
			attemptToChangeState('PreBellyBump');
			GoToState('PreBellyBump');
		}
	}

Begin:
	if(debugStates) logState();
	//removeDisguised();
	//sneaktoslimpawn(self.Pawn).endDisguiseNum = self.GetTeamNum();
	attemptToChangeState('Playerwalking');
	GoToState('Playerwalking');
}

///////////////////////////////////////////////

simulated function logState()
{
	if(Role == Role_Authority)
		`log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
	else
		`log( self.GetStateName(), false, 'state');
}



///////////////////////////////////////////////
//////////////////TREASURE CODE

simulated state HoldingTreasureWalking extends PlayerWalking
{

	exec function BellyBump()   //Can't Belly-bump while holding treasure
	{
	}

	simulated exec function SneakySpeed()
	{
		attemptToChangeState('HoldingTreasureSprinting');//to server
		GoToState('HoldingTreasureSprinting');//local
	}

	simulated exec function FL_useBuff()    //Left shift
	{

	}

	simulated exec function use()           //E-button
	{

	}

Begin:
	if(debugStates)
	{
		if(Role == Role_Authority)
			`log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
		else
			`log( self.GetStateName(), false, 'state');
	}
	SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',1.f,true,0.5,0.5,true,true);
	HoldTreasure();
}

simulated state HoldingTreasureSprinting extends Sprinting
{
	exec function BellyBump()     //Doesn't belly-bump while Holding Treasure
	{
	}

	simulated exec function SpeedDown()
	{
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

//Child of PlayerWalking, entered when player has <20% energy, and exited when >=20%
simulated state HoldingTreasureExhausted extends HoldingTreasureWalking
{

	simulated exec function SpeedDown()
	{
	}

	event EndState(Name NextStateName)
	{
		//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTired','Tired',1.f,false,0,0.5);
		//current.toggleTiredAnimation(false);
		sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLWalkingSpeed;
	}

	simulated exec function FL_useBuff()
	{

	}

	simulated exec function use()
	{

	}


Begin:
	if(debugStates) logState();
	SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',0.5f,true,0.5,0.5,true,true);
	HoldTreasure();
	sneaktoslimpawn(self.Pawn).GroundSpeed = sneaktoslimpawn(self.Pawn).FLExhaustedSpeed;
	//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTired','Tired',1.f,true,0,0.5);
	//current.toggleTiredAnimation(true);
}

///

unreliable server function passPlayerCountToPawn()
{
	SneaktoSlimPawn(self.Pawn).setPlayerCount(WorldInfo.Game.NumPlayers);
}



simulated function ExhaustedCheck()
{
	//Handles switching of state between PlayerWalking (normal) and Exhausted
	//Add more conditions for new states
	if (self.IsInState('HoldingTreasureExhausted') == true)
	{
		if (sneaktoslimpawn(self.Pawn).v_energy >= 20.0)
			GoToState('HoldingTreasureWalking');
	}
	else if (self.IsInState('HoldingTreasureWalking') == true && !self.IsInState('HoldingTreasureSprinting'))
	{
		if (sneaktoslimpawn(self.Pawn).v_energy < 20.0)
			GoToState('HoldingTreasureExhausted');
	}
	else if (self.IsInState('DisguisedExhausted') == true)
	{
		if (sneaktoslimpawn(self.Pawn).v_energy >= 20.0)
			GoToState('DisguisedWalking');
	}
	else if (self.IsInState('DisguisedWalking') == true && !self.IsInState('DisguisedSprinting'))
	{
		if (sneaktoslimpawn(self.Pawn).v_energy < 20.0)
			GoToState('DisguisedExhausted');
	}
	else if (self.IsInState('InvisibleExhausted') == true)
	{
		if (sneaktoslimpawn(self.Pawn).v_energy >= 20.0)
			GoToState('InvisibleWalking');
	}
	else if (self.IsInState('InvisibleWalking') == true && !self.IsInState('InvisibleSprinting'))
	{
		if (sneaktoslimpawn(self.Pawn).v_energy < 20.0)
			GoToState('InvisibleExhausted');
	}
	else if (self.IsInState('Exhausted') == true)
	{
		if(sneaktoslimpawn(self.Pawn).v_energy >= 20.0)
			GoToState('PlayerWalking');
	}
	else if (self.IsInState('PlayerWalking') && !self.IsInState('Sprinting'))
	{
		if(sneaktoslimpawn(self.Pawn).v_energy < 20.0)
			GoToState('Exhausted');
	}
	
}

simulated state BeingBellyBumped extends CustomizedPlayerWalking
{
	//local Vector knockBackVector;
	//local SneaktoSlimAIPawn HitActor;
	//local SneaktoSlimAINavMeshController HitController;
	//local SneaktoSlimPawn victim;
	//local vector dropLocation;

	simulated function BeingBellyBumped()
	{
		`log("Player is now in mid-air!", true, 'ANDY');
	}

	simulated function StateBump()
	{
		//knockBackVector = Other.Location - self.Location;
		//knockBackVector.Z = 0; //attempting to keep the hit player grounded.
		//current.startHitAnim();
		`log("server being bumped");
		sneaktoslimpawn(self.Pawn).callClientBumpParticle(sneaktoslimpawn(self.Pawn).GetTeamNum());
		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customHit', 'Hit', 1.f, true, 0, 0, true, true);
		sneaktoslimpawn(self.Pawn).TakeDamage(0, none, sneaktoslimpawn(self.Pawn).Location, sneaktoslimpawn(self.Pawn).knockBackVector * 1500, class'DamageType');
		PlayCameraBumpShake();
		//current.bOOM = true;
		//current.FaceRotation(RInterpTo(current.Rotation, Rotator(current.knockBackVector), DeltaTime, 60000, true), DeltaTime);
		//Rotation.Yaw = current.knockBackVector;
		//UpdateRotation(Rotation, DeltaTime);
		//`log(victim.Name $ " " $ victim.bOOM);
		//current.setTimer(1,false,'FOOM');
		//current.SetRotation(RInterpTo(current.Rotation, Rotator(current.knockBackVector), 0.1, 20000, true));
		//current.SetDesiredRotation(Rotator(current.knockBackVector));
		//current.FaceRotation(RInterpTo(current.Rotation, Rotator(current.knockBackVector), 0.1, 20000, true), 0.1);
	}

	simulated function rotateTimer()
	{    
		//current.bOOM = false;
		//`log(current.Name $ " " $ current.bOOM);
		sneaktoslimpawn(self.Pawn).SetRotation(RInterpTo(sneaktoslimpawn(self.Pawn).Rotation, Rotator(sneaktoslimpawn(self.Pawn).knockBackVector), 0.01, 80000, true));
	}

	event EndState(Name NextStateName)
	{
		//current.stopHitAnim();
		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customHit', 'Hit', 1.f, false);

		ClearTimer('rotateTimer');
		//changeEveryoneState('Stunned');
		attemptToChangeState('Stunned');
		GoToState('Stunned');
	}

Begin:
	if(debugStates) logState();

	`log("Player is now in mid-air! Inline", true, 'ANDY');
	StateBump();
	SetTimer(0.01f, true, 'rotateTimer');
	//BeingBellyBumped();
	//GoToState('PlayerWalking');
	//shouldn't go immediately, give a timer or use event --ANDY
	//GoToState('PlayerWalking');
}


simulated state Stunned extends CustomizedPlayerWalking
{
	//simulated event PushedState()
	//{
	//	SetTimer(1.0f);
	//}

	simulated function StunnedPeriod()
	{    
		//PopState();
		//sneaktoslimpawn(self.Pawn).stopStunnedAnim();		
		sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customStun', 'Stun', 1.f, false);
		//sneaktoslimpawn(self.Pawn).startStopStunnedAnim(false);
		//sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnimStruct(sneaktoslimpawn(self.Pawn).stunnedNodeInfo, false);
		//`log(sneaktoslimpawn(self.Pawn).stunnedNodeInfo.AnimName $ sneaktoslimpawn(self.Pawn).stunnedNodeInfo.AnimNode);
		//sneaktoslimpawn(self.Pawn).isStunned = false;// should not use this  anymore 
		GoToState('PlayerWalking');
		//PopState();
	}

Begin:
	if(debugStates) logState();

	//sneaktoslimpawn(self.Pawn).startStunnedAnim();
	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customStun', 'Stun', 1.f, true, 0, 0, true, true);
	//sneaktoslimpawn(self.Pawn).startStopStunnedAnim(true);
	//sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnimStruct(sneaktoslimpawn(self.Pawn).stunnedNodeInfo, true);
	SetTimer(2.0f, false, 'StunnedPeriod');
}


//state InvisibleToAI
//{
//	//event PushedState()
//	//{
//	//	SetTimer(1.0f);
//	//}

//	//function Timer()
//	//{    
//	//	PopState();
//	//}
//}

simulated state Hiding extends CustomizedPlayerWalking
{

	event BeginState (Name LastStateName)
	{
		if (LastStateName == 'HoldingTreasureSprinting' || LastStateName == 'DisguisedSprinting' || LastStateName == 'InvisibleSprinting' || LastStateName == 'Sprinting')
		{
			if(debugStates) `log(self.GetStateName());
			SpeedDown();
		}
	}


	event EndState (name NextStateName)
	{
		if (NextStateName != 'PlayerWalking')       //Why is 'PreviousStateName' used when it's 'event EndState (name NextStateName)'??
			`log("not goto PlayerWalking but " $ NextStateName);
		SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreVaseCamera);     //ANDYCAM
		if (SneakToSlimPlayerCamera(PlayerCamera).PreVaseCamera != 'FirstPerson')
			sneaktoslimpawn(self.Pawn).SetHidden(false);
		sneaktoslimpawn(self.Pawn).SetCollision(true, true);
		//SwitchToThirdPersonCam();
		attemptToChangeState('PlayerWalking');
		gotostate('PlayerWalking');
		//changeEveryoneState('PlayerWalking');
	}

Begin:
	if(debugStates) logState();

	SwitchToCamera('VaseCam');
	//`log("server ?");
	if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'FirstPerson')
		sneaktoslimpawn(self.Pawn).SetHidden(true);
	sneaktoslimpawn(self.Pawn).SetCollision(false, false);
	//SwitchToVaseCam();
}

//simulated state EndHiding extends CustomizedPlayerWalking
//{
//	local sneaktoslimpawn current;
//Begin:
//	if(debugStates) logState();

//	current = sneaktoslimpawn(self.Pawn);
//	current.SetHidden(false);
//	current.SetCollision(true, true);
//	SwitchToThirdPersonCam();
//	gotostate('PlayerWalking');
//	attemptToChangeState('PlayerWalking');
//	//changeEveryoneState('PlayerWalking');
//}
	

simulated function simulatedAttemptToChangeState(name stateName)
{
	GoToState(stateName);
}

//////////////////////////////////////////////////////////////////
//
//  Camera and Control
//
//////////////////////////////////////////////////////////////////

//Controller rotates with turning input
function UpdateRotation( float DeltaTime )
{
	local Rotator   DeltaRot, newRotation, ViewRotation;
	local Vector    CamLoc, PlayerLoc;

	if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'IsometricCam')
	{
		ViewRotation = Rotation;
		if (Pawn!=none)
		{
			Pawn.SetDesiredRotation(ViewRotation);
		}

		// Calculate Delta to be applied on ViewRotation
		DeltaRot.Yaw   = PlayerInput.aTurn;
		//DeltaRot.Pitch   = PlayerInput.aLookUp;

		ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
		SetRotation(ViewRotation);

		NewRotation = ViewRotation;
		NewRotation.Roll = Rotation.Roll;

		if ( Pawn != None )
			Pawn.FaceRotation(NewRotation, deltatime); //notify pawn of rotation

		////////
		//The following code hides the Pawn's Mesh when the CameraPOV comes very close to the Mesh.
		CamLoc = SneakToSlimPlayerCamera(PlayerCamera).ViewTarget.POV.Location;
		PlayerLoc = SneaktoSlimPawn(self.Pawn).Location;
		CamLoc.Z = 0;
		PlayerLoc.Z = 0;

		if (VSize(CamLoc - PlayerLoc) < 30.f)
			SneaktoSlimPawn(self.Pawn).Mesh.SetHidden(true);
		else
			SneaktoSlimPawn(self.Pawn).Mesh.SetHidden(false);

	}
} 

simulated function PlayCameraBumpShake()
{
	local CameraShake bumpShake;
	bumpShake = new class'CameraShake';

	bumpShake.OscillationDuration=0.5;

	bumpShake.RotOscillation.Pitch.Amplitude=100;
	bumpShake.RotOscillation.Pitch.Frequency=30;

	SneakToSlimPlayerCamera(PlayerCamera).PlayCameraShake(bumpShake,1);
}

exec function SwitchToCamera(name CameraMode)
{
	if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != CameraMode)
	{
		//SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = CameraMode;  //needs type-casting, far as I understand -- ANDY

		if (CameraMode == 'ShoulderCam')
		{
			if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'IsometricCam' && SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'FirstPerson')
			{
				SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera = SneakToSlimPlayerCamera(PlayerCamera).CameraStyle;
				SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = CameraMode;
			}
		}
		else if (CameraMode == 'ThirdPerson')
		{
			if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'IsometricCam')
			{
				SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = CameraMode;
			}
		}
		else if (CameraMode == 'VaseCam')
		{
			if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'IsometricCam')
			{
				SneakToSlimPlayerCamera(PlayerCamera).PreVaseCamera = SneakToSlimPlayerCamera(PlayerCamera).CameraStyle;
				SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = CameraMode;
			}
		}
		else if (CameraMode == 'IsometricCam')
		{
			SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = CameraMode;
		}
		else if (CameraMode == 'FirstPerson')
		{
			SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = CameraMode;
		}
		else if (CameraMode == 'FreeCam')
		{
			SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = CameraMode;
		}
		else
		{
			`log("NO SUCH CAMERA FOUND!");
		}

	}
}

//exec function SwitchToAlertCam()
//{
//	if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'AlertCam')
//	{
//		SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = 'AlertCam';  //needs type-casting, far as I understand -- ANDY
//	}
//}

//exec function SwitchToVaseCam()
//{
//	if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'VaseCam' && SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'IsometricCam')
//	{
//		SneakToSlimPlayerCamera(PlayerCamera).PreVaseCamera = SneakToSlimPlayerCamera(PlayerCamera).CameraStyle;
//		SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = 'VaseCam';  //needs type-casting, far as I understand -- ANDY
//	}
//}

//Switching to ThirdPersonCam
//exec function SwitchToThirdPersonCam()
//{
//	if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'ThirdPerson' && SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'IsometricCam')
//	{
//		SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = 'ThirdPerson';  // Restoring the previous camera style
//	}
//}

function setCameraActor(CameraActor cam)
{
	SetViewTarget(cam,);
}


//Functions for zooming in and out
exec function NextWeapon() 
{
	if (bPlayerCanZoom && PlayerCamera.FreeCamDistance < 512)
    {
        PlayerCamera.FreeCamDistance += 64*(PlayerCamera.FreeCamDistance/256);
		//SneaktoSlimPawn(Pawn).CamZoomOut();
    }  
}

exec function PrevWeapon()
{
	if (bPlayerCanZoom && PlayerCamera.FreeCamDistance > 64) //Checking if the distance is at our minimum distance
    {
        PlayerCamera.FreeCamDistance -= 64*(PlayerCamera.FreeCamDistance/256); //Once again scaling the zoom for distance
		//SneaktoSlimPawn(Pawn).CamZoomIn();
	}
}

exec function callRestartGame()
{
	newServerPlayerRestart();
}

server reliable function newServerPlayerRestart()
{
	local sneaktoslimplayercontroller current;
	local SneaktoSlimSpawnPoint currentSpawnPoint;
	local SneaktoSlimPawn currentPawn;

	//reset character
	foreach allactors(class 'sneaktoslimplayercontroller', current)
	{
		currentPawn = sneaktoslimpawn(current.Pawn);
		
		//reset score
		currentpawn.playerScore = 0;
		
		//reset buff
		if(currentPawn.bBuffed != 0)
		{
			currentPawn.hidePowerupUI(currentPawn.bBuffed);
			currentPawn.bBuffed = 0;
		}

		//reset mesh
		if(current.GetStateName() == 'DisguisedWalking')
		{
			currentPawn.DetachComponent(currentPawn.AISkelComp);
			currentPawn.AttachComponent(currentPawn.mySkelComp);

			clientResetDisguiseModel();
		}

		//sent all players back
		if(currentpawn.isGotTreasure == true)
			currentpawn.LostTreasure();
		current.GotoState('caughtByAI');
		//current.clientResetState();

		//reset all the variable
		
		currentPawn.bBuffed = 0;
		currentPawn.bUsingBuffed[0] = 0;
		currentPawn.bUsingBuffed[1] = 0;

		currentPawn.BuffedTimerDefault[0] = 10.0; // buff invis period
		currentPawn.BuffedTimerDefault[1] = 20.0; // buff disguise period
		currentPawn.BuffedTimer = 0.0;
		currentPawn.bInvisibletoAI = false;

		//bIsDashing = false;
		currentPawn.DashDuration = 0.1f;
		currentPawn.bIsHitWall = false;
		currentPawn.disguiseNum = -1;
		currentPawn.endDisguiseNum = -1;

		currentPawn.bOOM = false;

		currentPawn.bPreDash = false;
		currentPawn.underLight = false;

		
	}
}

reliable client function clientResetDisguiseModel()
{
	sneaktoslimpawn(self.Pawn).DetachComponent(sneaktoslimpawn(self.Pawn).AISkelComp);
	sneaktoslimpawn(self.Pawn).AttachComponent(sneaktoslimpawn(self.Pawn).mySkelComp);
}

reliable client function clientResetState()
{
	self.GotoState('caughtByAI');
}

///////////////////////////////////////////////////////////
//
//END-CAMERA CODE
//
///////////////////////////////////////////////////////////

defaultproperties
{
	CameraClass=class'SneaktoSlimGame.SneaktoSlimPlayerCamera'
	DefaultFOV=90.f
	bPlayerCanZoom = false;
	//bCaughtByAI = true;//for use by AiNavMeshController
	//bIsSprinting = false;
	RESPAWN_TIME = 2
	HoldTime =0;

	debugStates = true;
	debugAnimes = true;
}
