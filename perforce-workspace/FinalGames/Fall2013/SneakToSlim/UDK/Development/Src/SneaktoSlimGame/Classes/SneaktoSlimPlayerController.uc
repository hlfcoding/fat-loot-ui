/**
 * Copyright 1998-2013 Epic Games, Inc. All Rights Reserved.
 */
class SneaktoSlimPlayerController extends GamePlayerController
	config(Game);

Const DegreeToRadian = 0.01745329252;

var bool bPlayerCanZoom;
//var bool bIsSprinting;
var bool debugStates;
var bool debugAnimes;
var MiniMap myMap;
//var bool bCaughtByAI;
var float HoldTime;
var int RESPAWN_TIME;
var PlayerStart playerBase;
var bool uiOn, pauseMenuOn;
var int exhaustedThreshold;

var int totalParticipateTime, totalSprintTime, locationTime, locationTime2, totalVaseTime;       //Timer variables
var float totalLocationTime[20];                                                                 //Array which contains times players spend in an area. 
																								 //Index is hardcode to a particular section. See "trackLocation()"

//Additions stats associated with guard catches
var float averageTimeBetweenCatch, longestTimeBetweenCatch, shortTimeBetweenCatch, averageDifferenceInCatchTime, firstTimeCaught;
var int timeBetweenGuardCatches, timesCaughtAboveAverage, timesCaughtBelowAverage;

//Additional stats associated with treasure
var float averageTimeBetweenTreasureHolds, longestTimeBetweenTreasureHold, shortestTimeBetweenTreasureHold, averageDifferenceInBetweenHoldTime, firstTimeBetweenHold;
var int timeBetweenGettingTreasure, timesBetweenHoldsAboveAverage, timesBetweenHoldsBelowAverage;
var float averageTimeHoldingTreasure, longestTimeHoldingTreasure, shortestTimeHoldingTreasure, averageDifferenceInTreasureHoldTime, firstTimeTreasureHold;
var int timeHoldingTreasure, timesHoldingTreasureAboveAverage, timesHoldingTreasureBelowAverage;

var int totalLocationIndex, totalLocationIndex2;
var int numberOfTimesHitWithBellyBump;
var string tempString;
var float playerInputATurn; //used in spectator mode, to sent player input to spectator controller

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
	SetTimer(2, false, 'StartEnergyRegen');
	
	SetTimer(0.05, true, 'ExhaustedCheck');

	SetTimer(0.05, false, 'addOutLine');

	myMap = Spawn(class'SneaktoSlimGame.MiniMap',,,self.Location,,,);
	uiOn = true;
	pauseMenuOn = false;
	
	SetTimer(0.05, false, 'getBase');

	totalParticipateTime = 0;
	SetTimer(1, true, 'addToParticipateTime');

	totalSprintTime = 0;
	SetTimer(1, true, 'addToSprintTime');
	pauseSprintTimer();

	totalVaseTime = 0;
	SetTimer(1, true, 'addToVaseTime');
	pauseVaseTimer();

	totalLocationIndex = -1;
	totalLocationIndex2 = -1;
	locationTime = 0;
	locationTime2 = 0;
	SetTimer(1, true, 'addToLocationTime');
	SetTimer(1, true, 'addToLocationTime2');

	timeBetweenGuardCatches = 0;
	SetTimer(1, true, 'addToCatchTime');
	longestTimeBetweenCatch = -1;
	shortTimeBetweenCatch = 99999;

	self.timeHoldingTreasure = 0;
	self.timeBetweenGettingTreasure = 0;
	SetTimer(1, true, 'addToTreasureHoldTime');
	self.pauseTreasureHoldTimer();
	self.longestTimeBetweenTreasureHold = -1;
	self.longestTimeHoldingTreasure = -1;
	self.shortestTimeHoldingTreasure = 99999;
	self.shortestTimeBetweenTreasureHold = 99999;
	totalParticipateTime = 0;
	SetTimer(1, true, 'addToBetweenTreasureTime');

	tempString = "";
}

exec function ForceGameOver()
{
	forceGameOverQuit();
}

reliable server function forceGameOverQuit()
{
	SneaktoslimGameInfo(WorldInfo.Game).GameOver();
}

simulated function addToParticipateTime()
{
	totalParticipateTime++;
}

simulated function addToSprintTime()
{
	totalSprintTime++;
}

simulated function addToVaseTime()
{
	totalVaseTime++;
}

simulated function addToLocationTime()
{
	if(totalLocationIndex == -1)
		return;

	locationTime++;
}

simulated function addToLocationTime2()
{
	if(totalLocationIndex2 == -1)
		return;

	locationTime2++;
}

simulated function addToTreasureHoldTime()
{
	self.timeHoldingTreasure++;
}

simulated function addToBetweenTreasureTime()
{
	self.timeBetweenGettingTreasure++;
}

simulated function addToCatchTime()
{
	timeBetweenGuardCatches++;
}

unreliable server function pauseParticipateTimer()
{
	PauseTimer(true, 'addToParticipateTime');
}

unreliable server function resumeParticipateTimer()
{
	PauseTimer(false, 'addToParticipateTime');
}

unreliable server function pauseSprintTimer()
{
	PauseTimer(true, 'addToSprintTime');
}

unreliable server function resumeSprintTimer()
{
	PauseTimer(false, 'addToSprintTime');
}

unreliable server function pauseVaseTimer()
{
	PauseTimer(true, 'addToVaseTime');
}

unreliable server function resumeVaseTimer()
{
	PauseTimer(false, 'addToVaseTime');
}

unreliable server function pauseLocationTimer()
{
	PauseTimer(true, 'addToLocationTime');
}

unreliable server function resumeLocationTimer()
{
	PauseTimer(false, 'addToLocationTime');
}

unreliable server function pauseLocationTimer2()
{
	PauseTimer(true, 'addToLocationTime2');
}

unreliable server function resumeLocationTimer2()
{
	PauseTimer(false, 'addToLocationTime2');
}

unreliable server function pauseCatchTimer()
{
	PauseTimer(true, 'addToCatchTime');
}

unreliable server function resumeCatchTimer()
{
	PauseTimer(false, 'addToCatchTime');
}

unreliable server function pauseTreasureHoldTimer()
{
	PauseTimer(true, 'addToTreasureHoldTime');
}

unreliable server function resumeTreasureHoldTimer()
{
	PauseTimer(false, 'addToTreasureHoldTime');
}

unreliable server function pauseBetweenTreasureTimer()
{
	PauseTimer(true, 'addToBetweenTreasureTime');
}

unreliable server function resumeBetweenTreasureTimer()
{
	PauseTimer(false, 'addToBetweenTreasureTime');
}

unreliable server function recordHoldTreasureTime()
{
	local float time;

	self.pauseTreasureHoldTimer();

	time = self.timeHoldingTreasure + GetTimerCount('addToTreasureHoldTime');

	if(!(self.averageTimeHoldingTreasure != 0))
		self.firstTimeTreasureHold = time;

	//Records shortest time
	if(time < self.shortestTimeHoldingTreasure)
		self.shortestTimeHoldingTreasure = time;
	//Records largest time
	if(time > self.longestTimeHoldingTreasure)
		self.longestTimeHoldingTreasure = time;
	//Calculates average time
	self.averageTimeHoldingTreasure = (self.averageTimeHoldingTreasure*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1) + time) / SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot;
	
	//Calculates "average deviation"
	//For example, a small deviation means that a majority of times were close to the average time 
	//where as a large deviation means the difference in times between various catches were large
	if(self.averageTimeHoldingTreasure < time)
	{
		self.timesHoldingTreasureAboveAverage++;
		self.averageDifferenceInTreasureHoldTime = (self.averageDifferenceInTreasureHoldTime*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 2) + abs(time - self.averageTimeHoldingTreasure)) / (SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1);
	}
	if(self.averageTimeHoldingTreasure > time)
	{
		self.timesHoldingTreasureBelowAverage++;
		self.averageDifferenceInTreasureHoldTime = (self.averageDifferenceInTreasureHoldTime*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 2) + abs(time - self.averageTimeHoldingTreasure)) / (SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1);
	}

	//Resets Timer
	SetTimer(1, true, 'addToTreasureHoldTime');
	self.timeHoldingTreasure = 0;
	self.pauseTreasureHoldTimer();

	self.resumeBetweenTreasureTimer();
}

unreliable server function recordBetweenTreasureTime()
{
	local float time;

	pauseBetweenTreasureTimer();

	time = self.timeBetweenGettingTreasure + GetTimerCount('addToBetweenTreasureTime');

	if(!(self.averageTimeBetweenTreasureHolds != 0))
		self.firstTimeBetweenHold = time;

	//Records shortest time
	if(time < self.shortestTimeBetweenTreasureHold)
		self.shortestTimeBetweenTreasureHold = time;
	//Records largest time
	if(time > self.longestTimeBetweenTreasureHold)
		self.longestTimeBetweenTreasureHold = time;
	//Calculates average time
	self.averageTimeBetweenTreasureHolds = (self.averageTimeBetweenTreasureHolds*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1) + time) / SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot;
	
	//Calculates "average deviation"
	//For example, a small deviation means that a majority of times were close to the average time 
	//where as a large deviation means the difference in times between various catches were large
	if(self.averageTimeBetweenTreasureHolds < time)
	{
		self.timesBetweenHoldsAboveAverage++;
		self.averageDifferenceInBetweenHoldTime = (self.averageDifferenceInBetweenHoldTime*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 2) + abs(time - self.averageTimeBetweenTreasureHolds)) / (SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1);
	}
	if(self.averageTimeBetweenCatch > time)
	{
		self.timesBetweenHoldsBelowAverage++;
		self.averageDifferenceInBetweenHoldTime = (self.averageDifferenceInBetweenHoldTime*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 2) + abs(time - self.averageTimeBetweenTreasureHolds)) / (SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1);
	}

	//Resets Timer
	SetTimer(1, true, 'addToBetweenTreasureTime');
	self.timeBetweenGettingTreasure = 0;
	self.pauseBetweenTreasureTimer();

	resumeTreasureHoldTimer();
}

unreliable server function recordCatchStats()
{
	local float time;

	pauseCatchTimer();

	SneaktoSlimPawn(self.Pawn).totalTimesCaught++;
	time = timeBetweenGuardCatches + GetTimerCount('addToCatchTime');

	if(!(self.averageTimeBetweenCatch != 0))
		self.firstTimeCaught = time;

	//Records shortest catch time
	if(time < self.shortTimeBetweenCatch)
		self.shortTimeBetweenCatch = time;
	//Records largest catch time
	if(time > self.longestTimeBetweenCatch)
		self.longestTimeBetweenCatch = time;
	//Calculates average catch time
	self.averageTimeBetweenCatch = (self.averageTimeBetweenCatch*(SneaktoSlimPawn(self.Pawn).totalTimesCaught - 1) + time) / SneaktoSlimPawn(self.Pawn).totalTimesCaught;
	
	//Calculates "average deviation"
	//For example, a small deviation means that a majority of catches were close to the average time 
	//where as a large deviation means the difference in times between various catches were large
	if(self.averageTimeBetweenCatch < time)
	{
		self.timesCaughtAboveAverage++;
		self.averageDifferenceInCatchTime = (self.averageDifferenceInCatchTime*(SneaktoSlimPawn(self.Pawn).totalTimesCaught - 2) + abs(time - self.averageTimeBetweenCatch)) / (SneaktoSlimPawn(self.Pawn).totalTimesCaught - 1);
	}
	if(self.averageTimeBetweenCatch > time)
	{
		self.timesCaughtBelowAverage++;
		self.averageDifferenceInCatchTime = (self.averageDifferenceInCatchTime*(SneaktoSlimPawn(self.Pawn).totalTimesCaught - 2) + abs(time - self.averageTimeBetweenCatch)) / (SneaktoSlimPawn(self.Pawn).totalTimesCaught - 1);
	}

	//Resets Timer
	SetTimer(1, true, 'addToCatchTime');
	timeBetweenGuardCatches = 0;
	resumeCatchTimer();

	//self.totalParticipateTime + GetTimerCount('addToParticipateTime')
	//averageTimeBetweenCatch, longestTimeBetweenCatch, shortTimeBetweenCatch;
}

function recordFirstAverageTime()
{
	//Checks first record of time caught by guard and averages it into the deviation stats
	if(self.averageTimeBetweenCatch < self.firstTimeCaught)
	{
		self.timesCaughtAboveAverage++;
		self.averageDifferenceInCatchTime = (self.averageDifferenceInCatchTime*(SneaktoSlimPawn(self.Pawn).totalTimesCaught - 2) + abs(self.firstTimeCaught - self.averageTimeBetweenCatch)) / (SneaktoSlimPawn(self.Pawn).totalTimesCaught - 1);
	}
	if(self.averageTimeBetweenCatch > self.firstTimeCaught)
	{
		self.timesCaughtBelowAverage++;
		self.averageDifferenceInCatchTime = (self.averageDifferenceInCatchTime*(SneaktoSlimPawn(self.Pawn).totalTimesCaught - 2) + abs(self.firstTimeCaught - self.averageTimeBetweenCatch)) / (SneaktoSlimPawn(self.Pawn).totalTimesCaught - 1);
	}
}

function recordFirstBetweenHoldTime()
{
	if(self.averageTimeBetweenTreasureHolds < self.firstTimeBetweenHold)
	{
		self.timesBetweenHoldsAboveAverage++;
		self.averageDifferenceInBetweenHoldTime = (self.averageDifferenceInBetweenHoldTime*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 2) + abs(self.firstTimeBetweenHold - self.averageTimeBetweenTreasureHolds)) / (SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1);
	}
	if(self.averageTimeBetweenCatch > self.firstTimeBetweenHold)
	{
		self.timesBetweenHoldsBelowAverage++;
		self.averageDifferenceInBetweenHoldTime = (self.averageDifferenceInBetweenHoldTime*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 2) + abs(self.firstTimeBetweenHold - self.averageTimeBetweenTreasureHolds)) / (SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1);
	}
}

function recordFirstTreasureHoldTime()
{
	if(self.averageTimeHoldingTreasure < self.firstTimeTreasureHold)
	{
		self.timesHoldingTreasureAboveAverage++;
		self.averageDifferenceInTreasureHoldTime = (self.averageDifferenceInTreasureHoldTime*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 2) + abs(self.firstTimeTreasureHold - self.averageTimeHoldingTreasure)) / (SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1);
	}
	if(self.averageTimeHoldingTreasure > self.firstTimeTreasureHold)
	{
		self.timesHoldingTreasureBelowAverage++;
		self.averageDifferenceInTreasureHoldTime = (self.averageDifferenceInTreasureHoldTime*(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 2) + abs(self.firstTimeTreasureHold - self.averageTimeHoldingTreasure)) / (SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot - 1);
	}
}

unreliable server function trackLocation(float X, float Y, string mapName)
{
	local Vector point, radiusVector;
	local float radius;

	tempString = mapName;
	//Done this instead of just passing vector as parameter because for 
	//some reason the values were being read as ints instead of floats
	point.X = X;
	point.Y = Y;

	if(mapName == "demoday")
	{
		//Upper left quad
		if((point.X >= 0 && point.X < 0.5) && (point.Y >= 0 && point.Y < 0.5))
		{
			if(totalLocationIndex != 0)
			{
				recordRemainingLocationTime();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime');
				totalLocationIndex = 0;
			}
		}
		//Upper right quad
		if((point.X >= 0.5 && point.X < 1.0) && (point.Y >= 0 && point.Y < 0.5))
		{
			if(totalLocationIndex != 1)
			{
				recordRemainingLocationTime();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime');
				totalLocationIndex = 1;
			}
		}
		//Lower left quad
		if((point.X >= 0 && point.X < 0.5) && (point.Y >= 0.5 && point.Y < 1.0))
		{
			if(totalLocationIndex != 2)
			{
				recordRemainingLocationTime();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime');
				totalLocationIndex = 2;
			}
		}
		//Lower right quad
		if((point.X >= 0.5 && point.X < 1.0) && (point.Y >= 0.5 && point.Y < 1.0))
		{
			if(totalLocationIndex != 3)
			{
				recordRemainingLocationTime();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime');
				totalLocationIndex = 3;
			}
		}
		//Center
		if((point.X >= 0.3 && point.X < 0.7) && (point.Y >= 0.3 && point.Y < 0.7))
		{
			if(totalLocationIndex2 != 4)
			{
				recordRemainingLocationTime2();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime2');
				totalLocationIndex2 = 4;
			}
		}
	}
	if(mapName == "flmist")
	{
		radiusVector = point;
		radiusVector.X -= 0.5;
		radiusVector.Y -= 0.5;
		radius = sqrt(radiusVector.X*radiusVector.X + radiusVector.Y*radiusVector.Y);

		//Upper left quad
		if((point.X >= 0 && point.X < 0.5) && (point.Y >= 0 && point.Y < 0.5))
		{
			if(totalLocationIndex != 0)
			{
				recordRemainingLocationTime();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime');
				totalLocationIndex = 0;
			}
		}
		//Upper right quad
		if((point.X >= 0.5 && point.X < 1.0) && (point.Y >= 0 && point.Y < 0.5))
		{
			if(totalLocationIndex != 1)
			{
				recordRemainingLocationTime();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime');
				totalLocationIndex = 1;
			}
		}
		//Lower left quad
		if((point.X >= 0 && point.X < 0.5) && (point.Y >= 0.5 && point.Y < 1.0))
		{
			if(totalLocationIndex != 2)
			{
				recordRemainingLocationTime();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime');
				totalLocationIndex = 2;
			}
		}
		//Lower right quad
		if((point.X >= 0.5 && point.X < 1.0) && (point.Y >= 0.5 && point.Y < 1.0))
		{
			if(totalLocationIndex != 3)
			{
				recordRemainingLocationTime();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime');
				totalLocationIndex = 3;
			}
		}
		//Center Ring
		if(radius <= 0.22)
		{
			if(totalLocationIndex2 != 4)
			{
				recordRemainingLocationTime2();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime2');
				totalLocationIndex2 = 4;
			}
		}
		//Middle Ring
		if(radius > 0.22 && radius <= 0.425)
		{
			if(totalLocationIndex2 != 5)
			{
				recordRemainingLocationTime2();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime2');
				totalLocationIndex2 = 5;
			}
		}
		//Outer Ring
		if(radius > 0.425)
		{
			if(totalLocationIndex2 != 6)
			{
				recordRemainingLocationTime2();
				//Resets timer
				SetTimer(1, true, 'addToLocationTime2');
				totalLocationIndex2 = 6;
			}
		}
	}
}

//Saved current location time to total time array
//Called in track location method if player moves to a different area and once during prepForQuit
unreliable server function recordRemainingLocationTime()
{
	//Doesn't add time for out of bounds
	if(totalLocationIndex != -1)
	{
		totalLocationTime[totalLocationIndex] += self.locationTime + GetTimerCount('addToLocationTime');
		locationTime = 0;
		ClearTimer('addToLocationTime');
	}
}

//Saved current location time to total time array
//Called in track location method if player moves to a different area and once during prepForQuit
unreliable server function recordRemainingLocationTime2()
{
	//Doesn't add time for out of bounds
	if(totalLocationIndex2 != -1)
	{
		totalLocationTime[totalLocationIndex2] += self.locationTime2 + GetTimerCount('addToLocationTime2');
		locationTime2 = 0;
		ClearTimer('addToLocationTime2');
	}
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

final function bool IsInViewCos( vector ViewVec, vector DirVec, float FOVCos )
{
	local float CosAngle;		//cosine of angle from object's LOS to WP
	CosAngle = Normal( ViewVec ) dot  Normal( DirVec );
	return (0 <= CosAngle && FOVCos < CosAngle);
}

final function bool ActorLookingAt(Actor SeeingActor, Vector SeeingLocation, Actor Target, float AngleInDegreeFromLOS )
{
	if( Target == None || SeeingActor == None )
		return false;

	return IsInViewCos( vector(SeeingActor.Rotation), Target.Location - SeeingLocation, Cos(AngleInDegreeFromLOS * DegreeToRadian) );
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
		pauseSprintTimer();
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

Begin:
	if(debugStates) logState();
}

reliable server function ServerSpeedDown()
{
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

unreliable server function recordRemainingStats()
{
	recordFirstAverageTime();
	recordFirstBetweenHoldTime();
	recordFirstTreasureHoldTime();
	recordRemainingLocationTime();
	recordRemainingLocationTime2();
}

//Writes stats to "../UDKGame/Stats"
unreliable server function prepForQuit()
{
	local FileWriter f;
	local float totalPlayTime;
	local string characterType;

	characterType = SneaktoSlimPawn(self.Pawn).characterName;

	totalPlayTime = self.totalParticipateTime + GetTimerCount('addToParticipateTime');
	recordRemainingStats();

	f = Spawn(class'FileWriter');
	if(f != NONE)
	{
		f.OpenFile(SneaktoSlimGameInfo(WorldInfo.Game).uniqueMatchDate $ " ~ STS Player " $ SneaktoSlimPawn(self.Pawn).GetTeamNum()+1 $ " (" $ characterType $ ")", FWFT_Stats);
	}

	SneaktoSlimGameInfo(WorldInfo.Game).updateStatsFile();

	//Player unique stats
	f.Logf("Total Time(s):");
	f.Logf("    In play session: " $ totalPlayTime);
	f.Logf("             *Pause Time is ignored");
	f.Logf("");
	if(tempString == "demoday")
	{
		f.Logf("    DemoDay      *See .png image for more accurate region representation");
		f.Logf("    ---------------------------");
		f.Logf("    |            |            |");
		f.Logf("    |   Quad 1   |   Quad 2   |");
		f.Logf("    |         ---|----        |");
		f.Logf("    |--------|-Center-|-------|");
		f.Logf("    |         ---|----        |");
		f.Logf("    |   Quad 3   |   Quad 4   |");
		f.Logf("    |            |            |");
		f.Logf("    ---------------------------");
		f.Logf("    In quad 1: " $ totalLocationTime[0]);
		f.Logf("    In quad 2: " $ totalLocationTime[1]);
		f.Logf("    In quad 3: " $ totalLocationTime[2]);
		f.Logf("    In quad 4: " $ totalLocationTime[3]);
		f.Logf("    In center: " $ totalLocationTime[4]);
	}
	if(tempString == "flmist")
	{
		f.Logf("    FLMist      *See .png image for more accurate region representation");
		f.Logf("    ---------------------------");
		f.Logf("    |       Outer|            |");
		f.Logf("    |   Quad 1/-----\\ Quad 2   |");
		f.Logf("    |        /Mid-   \\        |");
		f.Logf("    |-------(--(In.)--)-------|");
		f.Logf("    |        \\   -   /        |");
		f.Logf("    |   Quad 3\\-----/Quad 4   |");
		f.Logf("    |            |            |");
		f.Logf("    ---------------------------");
		f.Logf("    In quad 1: " $ totalLocationTime[0]);
		f.Logf("    In quad 2: " $ totalLocationTime[1]);
		f.Logf("    In quad 3: " $ totalLocationTime[2]);
		f.Logf("    In quad 4: " $ totalLocationTime[3]);
		f.Logf("    In inner ring: " $ totalLocationTime[4]);
		f.Logf("    In middle ring: " $ totalLocationTime[5]);
		f.Logf("    In outer ring: " $ totalLocationTime[6]);
	}
	f.Logf("");
	f.Logf("");
	f.Logf("Total # of Times:");
	f.Logf("----------------------------------------------------------------------------------");
	f.Logf("    Caught by Guards = " $ SneaktoSlimPawn(self.Pawn).totalTimesCaught);
	if(SneaktoSlimPawn(self.Pawn).totalTimesCaught > 0)
	{
		f.Logf("");
		f.Logf("         *Related Stats:");
		f.Logf("               Average Time Between Catches: " $ self.averageTimeBetweenCatch);
		f.Logf("                    *Deviation: " $ self.averageDifferenceInCatchTime);
		f.Logf("                    *Times caught above average: " $ self.timesCaughtAboveAverage);
		f.Logf("                    *Times caught below average: " $ self.timesCaughtBelowAverage);
		f.Logf("                Longest Time Caught: " $ self.longestTimeBetweenCatch);
		f.Logf("               Shortest Time Caught: " $ self.shortTimeBetweenCatch);
	}
	f.Logf("-----------------------------------------------------------------------------------");
	f.Logf("          Final Score = " $ SneaktoSlimPawn(self.pawn).playerScore);
	f.Logf("                       ---");
	f.Logf("    Treasure Obtained = " $ SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot $ " times");
	if(SneaktoSlimPawn(self.Pawn).totalTimesTreasureGot > 0)
	{
		f.Logf("");
		f.Logf("         *Related Stats:");
		f.Logf("               Average Time Between Acquisitions: " $ self.averageTimeBetweenTreasureHolds);
		f.Logf("                    *Deviation: " $ self.averageDifferenceInBetweenHoldTime);
		f.Logf("                    *Times above average: " $ self.timesBetweenHoldsAboveAverage);
		f.Logf("                    *Times below average: " $ self.timesBetweenHoldsBelowAverage);
		f.Logf("                Longest Time: " $ self.longestTimeBetweenTreasureHold);
		f.Logf("               Shortest Time: " $ self.shortestTimeBetweenTreasureHold);
		f.Logf("");
		f.Logf("               Average Time Holding Treasure: " $ self.averageTimeHoldingTreasure);
		f.Logf("                    *Deviation: " $ self.averageDifferenceInTreasureHoldTime);
		f.Logf("                    *Times above average: " $ self.timesHoldingTreasureAboveAverage);
		f.Logf("                    *Times below average: " $ self.timesHoldingTreasureBelowAverage);
		f.Logf("                Longest Time: " $ self.longestTimeHoldingTreasure);
		f.Logf("               Shortest Time: " $ self.shortestTimeHoldingTreasure);
	}
	f.Logf("-----------------------------------------------------------------------------------");
	f.Logf("           Vase Used = " $ SneaktoSlimPawn(self.Pawn).totalTimesVasesUsed);
	if(SneaktoSlimPawn(self.Pawn).totalTimesVasesUsed != 0)
	{
		f.Logf("                      *Total Time: " $ self.totalVaseTime + GetTimerCount('addToVaseTime'));
	}
	f.Logf("-----------------------------------------------------------------------------------");
	f.Logf("       Powerups Used = " $ SneaktoSlimPawn(self.Pawn).totalTimesPowerupsUsed);
	f.Logf("-----------------------------------------------------------------------------------");
	f.Logf("");
	f.Logf("");
	f.Logf("Character Specific Stats:");
	if(characterType == "FatLady")
	{
		f.Logf("-----------------------------------------------------------------------------------");
		f.Logf("    Belly Bumps Used = " $ SneaktoSlimPawn(self.Pawn).totalTimesBellyBumpUsed);
		//Unreliable stats
		/*f.Logf("                           *Misses = " $ SneaktoSlimPawn(self.Pawn).getBBMissCount());
		f.Logf("                             *Hits = " $ SneaktoSlimPawn(self.Pawn).getBBHitCount());
		f.Logf("  Hit by Belly Bumps = " $ self.getBBHitByCount());*/
		f.Logf("-----------------------------------------------------------------------------------");
		f.Logf("   Sprints Activated = " $ SneaktoSlimPawn(self.Pawn).totalTimesSprintActivate);
		f.Logf("                      *Total Time: " $ (self.totalSprintTime + GetTimerCount('addToSprintTime')) $ " secs.   (" $ ((self.totalSprintTime + GetTimerCount('addToSprintTime'))/totalPlayTime * 100) $ "% of play time)");
		f.Logf("-----------------------------------------------------------------------------------");
	}
	if(characterType == "GinsengBaby")
	{
		f.Logf("-----------------------------------------------------------------------------------");
		f.Logf("       Bursts Used = " $ SneaktoSlimPawn(self.Pawn).totalTimesBellyBumpUsed);
		f.Logf("-----------------------------------------------------------------------------------");
		f.Logf(" Burrows Activated = " $ SneaktoSlimPawn(self.Pawn).totalTimesSprintActivate);
		f.Logf("                      *Total Time: " $ (self.totalSprintTime + GetTimerCount('addToSprintTime')) $ " secs.   (" $ ((self.totalSprintTime + GetTimerCount('addToSprintTime'))/totalPlayTime * 100) $ "% of play time)");
		f.Logf("-----------------------------------------------------------------------------------");
	}
	if(characterType == "Rabbit")
	{
		f.Logf("-----------------------------------------------------------------------------------");
		f.Logf("          Roars Used = " $ SneaktoSlimPawn(self.Pawn).totalTimesBellyBumpUsed);
		f.Logf("-----------------------------------------------------------------------------------");
		f.Logf(" Teleports Activated = " $ SneaktoSlimPawn(self.Pawn).totalTimesSprintActivate);
		f.Logf("-----------------------------------------------------------------------------------");
	}
	if(characterType == "Shorty")
	{
		f.Logf("-----------------------------------------------------------------------------------");
		f.Logf(" FireCrackers Used = " $ SneaktoSlimPawn(self.Pawn).totalTimesBellyBumpUsed);
		f.Logf("-----------------------------------------------------------------------------------");
		f.Logf("   Dashs Activated = " $ SneaktoSlimPawn(self.Pawn).totalTimesSprintActivate);
		f.Logf("-----------------------------------------------------------------------------------");
	}
	if(f != NONE)
	{
		f.Destroy();
	}
}
 
function GetTriggerUseList(float interactDistanceToCheck, float crosshairDist, float minDot, bool bUsuableOnly, out array<Trigger> out_useList)
{
    local int Idx;
    local vector cameraLoc;
    local rotator cameraRot;
    local Trigger checkTrigger;
    local SeqEvent_Used UseSeq;
 
    if (Pawn != None)
    {
        // grab camera location/rotation for checking crosshairDist
        GetPlayerViewPoint(cameraLoc, cameraRot); 
        // search of nearby actors that have use events 
        foreach Pawn.CollidingActors(class'Trigger',checkTrigger,interactDistanceToCheck) 
        { 
            for (Idx = 0; Idx < checkTrigger.GeneratedEvents.Length; Idx++)
			{
				UseSeq = SeqEvent_Used(checkTrigger.GeneratedEvents[Idx]);

				if( ( UseSeq != None )
					// if bUsuableOnly is true then we must get true back from CheckActivate (which tests various validity checks on the player and on the trigger's trigger count and retrigger conditions etc)
					&& ( !bUsuableOnly || ( checkTrigger.GeneratedEvents[Idx].CheckActivate(checkTrigger,Pawn,true)) )
					// check to see if we are looking at the object
					&& ( Normal(checkTrigger.Location-cameraLoc) dot vector(cameraRot) >= minDot )

					// if this is an aimToInteract then check to see if we are aiming at the object and we are inside the InteractDistance (NOTE: we need to do use a number close to 1.0 as the dot will give a number that is very close to 1.0 for aiming at the target)
					&& ( ( ( UseSeq.bAimToInteract && IsAimingAt( checkTrigger, 0.98f ) && ( VSize(Pawn.Location - checkTrigger.Location) <= UseSeq.InteractDistance ) ) )
					      // if we should NOT aim to interact then we need to be close to the trigger
			  || ( !UseSeq.bAimToInteract && ( VSize(Pawn.Location - checkTrigger.Location) <= UseSeq.InteractDistance ) )  // this should be UseSeq.InteractDistance
						  )
				   )
				{
					out_useList[out_useList.Length] = checkTrigger;

					// don't bother searching for more events
					Idx = checkTrigger.GeneratedEvents.Length;
				}
			}

			//If it's a usable actor and it hasn't already been added to the list, let's add it. 
			if ((out_useList.Length == 0 || out_useList[out_useList.Length-1] != checkTrigger))
			{
				out_useList[out_useList.Length] = checkTrigger;
			}
        }
    }
}
 
exec simulated function clientChangeState(name stateName)
{
	attemptToChangeState(stateName);
}

simulated reliable server function attemptToChangeState(name stateName)
{
	GoToState(stateName);		
}

//When player clicks 'M' their minimap is turned on/off
exec function toggleMap()
{
	//local CameraActor topDownCamera, cam;
	/*if(ROLE == ROLE_Authority)
		toggleServerUI();
	else
		toggleClientUI();*/
		
	//Checks if map exists and pause menu isn't on
	if(myMap != NONE && !pauseMenuOn)
	{
		myMap.toggleMap();
		if(myMap.isOn)
		{
			SneaktoSlimPawn(self.Pawn).disablePlayerMovement();
			self.IgnoreLookInput(true);
		}
		else
		{
			SneaktoSlimPawn(self.Pawn).enablePlayerMovement();
			self.IgnoreLookInput(false);
		}
	}
	
	//Grabs camera that is set above map in editor
	/*foreach WorldInfo.AllActors(class'CameraActor', cam)
	{
		if(cam.Tag == 'topDownCamera')
			topDownCamera = cam;
	}
	SneaktoSlimPlayerController(Controller).setCameraActor(topDownCamera);*/
}

exec function ToggleUIHUD()
{
	uiOn = !uiOn;
}

//When press 'ESC' key the pause menu field is active and disables/enables player movement
//Other classes like STSHUD and STSGFxPauseMenu check this field during their ticks
exec function togglePauseMenu()
{
	//Checks if map is not used
	if(myMap != NONE)
	{
		if(!myMap.isOn)
		{
			//`log("Pause Menu activated");
			pauseMenuOn = !pauseMenuOn;

			if(pauseMenuOn)
			{
				pauseParticipateTimer();
				SneaktoSlimPawn(self.Pawn).disablePlayerMovement();
				IgnoreLookInput(true);
			}
			else
			{
				resumeParticipateTimer();
				SneaktoSlimPawn(self.Pawn).enablePlayerMovement();
				IgnoreLookInput(false);
			}
		}
	}
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

	// when player input 'Left Shift'
	simulated exec function FL_useBuff()
	{
		Local SneaktoSlimpawn current;

		if(sneaktoslimpawn(self.Pawn).mistNum == 0)
		{
			sneaktoslimpawn(self.Pawn).checkServerFLBuff(sneaktoslimpawn(self.Pawn).enumBuff.bBuffed, true);

			if(sneaktoslimpawn(self.Pawn).bBuffed == 1) 
			{
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();

				sneaktoslimpawn(self.Pawn).serverResetBBuffed();

				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[0] = 1;//should not be used , kept for "countdown"  at this moment
				
				attemptToChangeState('InvisibleWalking');
				GoToState('InvisibleWalking');
				WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'flparticlesystem.stateChange',SneaktoSlimPawn(self.Pawn).Location - vect(0.f,0.f,40.0f));
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Invisibility');
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 2) 
			{			
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();

				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[1] = 1;//should not be used 

				attemptToChangeState('DisguisedWalking');
				GoToState('DisguisedWalking');
				WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'flparticlesystem.stateChange',SneaktoSlimPawn(self.Pawn).Location - vect(0.f,0.f,40.0f));
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Guard_Like_Cue');
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 3) 
			{			
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();

				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[2] = 1;//should not be used 

				attemptToChangeState('UsingThunderFan');
				GoToState('UsingThunderFan');
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Thunder_Fan');
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 4) 
			{			
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();

				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				//sneaktoslimpawn(self.Pawn).bUsingBuffed[2] = 1;//should not be used 

				//attemptToChangeState('UsingThunderFan');
				//GoToState('UsingThunderFan');
				sneaktoslimpawn(self.Pawn).v_energy = 100;
				ServerResetEnergy();
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Gives_Wings_Cue');
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 5)
			{
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();
				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				attemptToChangeState('UsingSuperSprint');
				GoToState('UsingSuperSprint');
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					//current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Get_out_of_the_way_Cue');
					current.clientAnnounceBasedOnTeam(SneaktoSlimPawn(self.Pawn).GetTeamNum());
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 6)
			{
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();
				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				SneaktoSlimPawn(self.Pawn).SetUsingBeer(true);
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Cursed_Blood_Cue');
				}
			}
		}
	}
	
	//function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	//{
	//	if( Pawn == None )
	//	{
	//		return;
	//	}

	//	if (Role == ROLE_Authority)
	//	{
	//		// Update ViewPitch for remote clients
	//		Pawn.SetRemoteViewPitch( Rotation.Pitch );
	//	}

	//	Pawn.Acceleration = NewAccel;

	//	CheckJumpOrDuck();
	//}

	//function PlayerMove( float DeltaTime )
	//{
	//	local vector			X,Y,Z, NewAccel;
	//	local eDoubleClickDir	DoubleClickMove;
	//	local rotator			OldRotation;
	//	local bool				bSaveJump;

	//	if( Pawn == None )
	//	{
	//		GotoState('Dead');
	//	}
	//	else
	//	{
	//		GetAxes(Pawn.Rotation,X,Y,Z);

	//		// Update acceleration.
	//		NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y;
	//		NewAccel.Z	= 0;
	//		NewAccel = Pawn.AccelRate * Normal(NewAccel);

	//		if (IsLocalPlayerController())
	//		{
	//			AdjustPlayerWalkingMoveAccel(NewAccel);
	//		}

	//		DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

	//		// Update rotation.
	//		OldRotation = Rotation;
	//		UpdateRotation( DeltaTime );
	//		bDoubleJump = false;

	//		if( bPressedJump && Pawn.CannotJumpNow() )
	//		{
	//			bSaveJump = true;
	//			bPressedJump = false;
	//		}
	//		else
	//		{
	//			bSaveJump = false;
	//		}

	//		if( Role < ROLE_Authority ) // then save this move and replicate it
	//		{
	//			ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
	//		}
	//		else
	//		{
	//			ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
	//		}
	//		bPressedJump = bSaveJump;
	//	}
	//}
	
	
	//Update player rotation when walking
	simulated function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local Rotator CameraRotationYawOnly;
		local Vector ZeroVector;
		ZeroVector = vect(0.0, 0.0, 0.0);


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
			NewAccel.Y = sneaktoslimpawn(self.Pawn).beerNum * PlayerInput.aStrafe * DeltaTime * 100 * PlayerInput.MoveForwardSpeed;
			NewAccel.X = sneaktoslimpawn(self.Pawn).beerNum * PlayerInput.aForward * DeltaTime * 100 * PlayerInput.MoveForwardSpeed; 
			NewAccel.Z = 0; //no vertical movement for now, may be needed by ladders later

			//`log("Camera rotation" $ SneaktoslimPlayerCamera(PlayerCamera).Rotation);
			//`log("Pawn rotation" $ Pawn.Rotation);
			//`log("NewAccel" $ NewAccel);
			//`log("aForward" $ PlayerInput.aForward);
			//`log("aStrafe" $ PlayerInput.aStrafe);

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );			
			playerInputATurn = PlayerInput.aTurn;
			sendInputToServer(playerInputATurn);

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

Begin:
	if(debugStates) logState();
}

//used to send player turn input to spectator
server reliable function sendInputToServer(float inputPlayerInputATurn)
{
	self.playerInputATurn = inputPlayerInputATurn;	
}

simulated function changeAnimTreeToTreasure()
{
	local AnimTree animTreeToChangeTo;
	local SneaktoSlimPawn onePawn;

	if(self.Class == class 'SneaktoSlimPlayerController_FatLady')
		animTreeToChangeTo = animTree'FLCharacter.lady.lady_AnimTree_treasure';
	else if(self.Class == class 'SneaktoSlimPlayerController_Rabbit')
		animTreeToChangeTo = animTree'FLCharacter.Rabbit.rabbit_AnimTree_treasure';
	else if(self.Class == class 'SneaktoSlimPlayerController_GinsengBaby')
		animTreeToChangeTo = animTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree_treasure';
	else if(self.Class == class 'SneaktoSlimPlayerController_Shorty')
		animTreeToChangeTo = animTree'FLCharacter.Shorty.Shorty_Treasure_AnimTree';

	SneaktoSlimPawn(self.Pawn).Mesh.SetAnimTreeTemplate(animTreeToChangeTo);

	if(Role == ROLE_Authority)
	{
		ForEach WorldInfo.AllActors(class'SneaktoSlimPawn', onePawn)
		{
			onePawn.changeAnimTreeOnAllClients(SneaktoSlimPawn(self.Pawn), animTreeToChangeTo);
		}
	}
}



simulated function changeAnimTreeToNormal()
{
	local AnimTree animTreeToChangeTo;
	local SneaktoSlimPawn onePawn;

	if(self.Class == class 'SneaktoSlimPlayerController_FatLady')
		animTreeToChangeTo = animTree'FLCharacter.lady.lady_AnimTree_copy';
	else if(self.Class == class 'SneaktoSlimPlayerController_Rabbit')
		animTreeToChangeTo = animTree'FLCharacter.Rabbit.rabbit_AnimTree';
	else if(self.Class == class 'SneaktoSlimPlayerController_GinsengBaby')
		animTreeToChangeTo = animTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree';
	else if(self.Class == class 'SneaktoSlimPlayerController_Shorty')
		animTreeToChangeTo = animTree'FLCharacter.Shorty.Shorty_AnimTree';

	SneaktoSlimPawn(self.Pawn).Mesh.SetAnimTreeTemplate(animTreeToChangeTo);

	if(Role == ROLE_Authority)
	{
		ForEach WorldInfo.AllActors(class'SneaktoSlimPawn', onePawn)
		{
			onePawn.changeAnimTreeOnAllClients(SneaktoSlimPawn(self.Pawn), animTreeToChangeTo);
		}
	}
}

simulated function DropTreasure()
{
	self.recordHoldTreasureTime();

	ServerDropTreasure();
	`log("Function dropping treasure");
	changeAnimTreeToNormal();
	//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',1.f,false,0.5,0.5,true,false);
}

reliable server function ServerDropTreasure()
{
	changeAnimTreeToNormal();
	//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',1.f,false,0.5,0.5,true,false);
}


simulated function StartEnergyRegen()
{
	SetTimer(0.05, true, 'EnergyRegen');
}

//Nick: Fixed minor bug where energy would stop regen at 99
simulated function EnergyRegen()
{
	if (sneaktoslimpawn(self.Pawn).v_energy/* + sneaktoslimpawn(self.Pawn).energyRegenerateRate*/ < 100)
	{
		sneaktoslimpawn(self.Pawn).v_energy = sneaktoslimpawn(self.Pawn).v_energy + sneaktoslimpawn(self.Pawn).energyRegenerateRate;
		/*if (sneaktoslimpawn(self.Pawn).v_energy > 99.95)
			sneaktoslimpawn(self.Pawn).v_energy = 100;*/
	}
	else
		sneaktoslimpawn(self.Pawn).v_energy = 100;
}

reliable server function ServerResetEnergy()
{  
	sneaktoslimpawn(self.Pawn).v_energy = 100;
}



simulated state UsingThunderFan extends CustomizedPlayerWalking
{
	simulated function UseThunderFan()
	{
		//local SneaktoSlimPawn victim;
		////local SneaktoSlimBuddhaPalm slapHand;
		//`log("UsingThunderFan!!");
		
		////slapHand = Spawn(class'SneaktoSlimBuddhaPalm', , , SneaktoSlimPawn(Self.Pawn).Location);
		//foreach self.Pawn.VisibleCollidingActors(class'SneaktoSlimPawn', victim, 300)
		//{
		//	if (ActorLookingAt(SneaktoSlimPawn(self.Pawn), SneaktoSlimPawn(self.Pawn).Location, victim, 45))
		//	{				
		//		victim.knockBackVector = (victim.Location - self.Location);
		//		victim.knockBackVector = 25 * Normal(victim.knockBackVector);
			
		//		victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.					
		//		SneaktoSlimPlayerController(victim.Controller).attemptToChangeState('BeingBellyBumped');//already done by server, no need to call server again
		//		SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//already done by server, no need to call server again
		//	}
		//}
		
		if( Role < Role_Authority )
			ServerSpawnThunderFan();
		else
			SpawnThunderFan();
	}

	simulated function StopThunderFan()
	{
		GoToState('PlayerWalking');
		attemptToChangeState('PlayerWalking');
	}

Begin:
	UseThunderFan();
	SetTimer(0.5f, false, 'StopThunderFan');	
}

simulated exec function TTF()
{
		if( Role < Role_Authority )
			ServerSpawnThunderFan();
		else
			SpawnThunderFan();
}

simulated function SpawnThunderFan()
{
	local SneaktoSlimBuddhaPalm slapHand;
	`log("UsingTempThunderFan!!");
	slapHand = Spawn(class'SneaktoSlimBuddhaPalm', , , SneaktoSlimPawn(Self.Pawn).Location + vect(0,0,-50) + (40*Vector(SneaktoSlimPawn(Self.Pawn).Rotation)));
	slapHand.Init(Vector(SneaktoSlimPawn(Self.Pawn).Rotation));
}

reliable server function ServerSpawnThunderFan()
{
	SpawnThunderFan();
}

simulated state UsingSuperSprint
{
	simulated event BeginState(Name LastStateName)
	{
		Pawn.AccelRate = 4000;
		SwitchToCamera('ShoulderCam');
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
			NewAccel.Y = sneaktoslimpawn(self.Pawn).beerNum * 0 * DeltaTime * 100 * PlayerInput.MoveForwardSpeed;
			NewAccel.X = sneaktoslimpawn(self.Pawn).beerNum * 1935.5007 * DeltaTime * 100 * PlayerInput.MoveForwardSpeed; 
			NewAccel.Z = 0;

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

	//Update player rotation when walking
	simulated function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local Rotator CameraRotationYawOnly;
		local Vector ZeroVector;
		ZeroVector = vect(0.0, 0.0, 0.0);


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

	simulated event EndState(name nextState)
	{
		if(SneakToSlimPlayerCamera(PlayerCamera).CameraStyle == 'ShoulderCam')
			SwitchToCamera(SneakToSlimPlayerCamera(PlayerCamera).PreSprintCamera);     //ANDYCAM
		Pawn.AccelRate = 500;
		Pawn.GroundSpeed = Sneaktoslimpawn(Pawn).FLWalkingSpeed;
		Pawn.bForceMaxAccel = false;
	}

Begin:
	if(debugStates) logState();
	Pawn.GroundSpeed = Sneaktoslimpawn(Pawn).SuperSprintSpeed;
	Pawn.bForceMaxAccel = true;
}


simulated state InvisibleWalking extends PlayerWalking
{
	local name previousStateName;

	simulated event BeginState(Name LastStateName)
	{
		previousStateName = LastStateName;
	}

	simulated exec function use()           //E-button
	{
		sneaktoslimpawn(self.Pawn).removePowerUp();
		attemptToChangeState('EndInvisible');
		GoToState('EndInvisible');
		super.Use();
	}

	//override from playerWalking
	//simulated exec function OnPressSecondSkill()
	//{

	//}

	exec function OnPressFirstSkill()
	{
		if (self.Class == class'SneaktoSlimPlayerController_FatLady')
		{
		}
		if (self.Class == class'SneaktoSlimPlayerController_Rabbit')
		{
			//Player can't belly bump if pause menu is on
			if(pauseMenuOn)
				return;

			if(sneaktoslimpawn(self.Pawn).v_energy <= SneaktoSlimPlayerController_Rabbit(self).perRoarEnergy)
				return;
			else
			{
				SneaktoSlimPawn(self.Pawn).incrementBumpCount();
				sneaktoslimpawn(self.Pawn).removePowerUp();
				attemptToChangeState('Roaring');
				GoToState('Roaring');
			}
		}
		else if (self.Class == class'SneaktoSlimPlayerController_Shorty')
		{
			if( SneaktoSlimPawn(Pawn).isGotTreasure) // don't throw fire cracker if player has treasure
				return;

			if(Role < ROLE_Authority)
				attemptToChangeState('ChargingFireCracker');

			GotoState('ChargingFireCracker');
		}
	}

	exec function OnReleaseFirstSkill()
	{
	}

	exec function OnPressSecondSkill()
	{
		if (self.Class == class'SneaktoSlimPlayerController_Rabbit')
		{
			if(pauseMenuOn)
				return;

			if(sneaktoslimpawn(self.Pawn).v_energy <= SneaktoSlimPlayerController_Rabbit(self).perDiveEnergy)
				return;
			else
			{
				SneaktoSlimPawn(self.Pawn).incrementSprintCount();
				attemptToChangeState('Teleport');
				GoToState('Teleport');
			}
		}
		else if (self.Class == class'SneaktoSlimPlayerController_FatLady')
		{
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			resumeSprintTimer();
			attemptToChangeState('InvisibleSprinting');//to server
			GoToState('InvisibleSprinting');//local
		}
		else if (self.Class == class'SneaktoSlimPlayerController_GinsengBaby')
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
				if(previousStateName == 'PlayerWalking')
				{
					if(Role < ROLE_Authority)
						attemptToChangeState('Burrow');
					GoToState('Burrow');
				}
				else if(previousStateName == 'Burrow')
				{
					sneaktoslimpawn_ginsengbaby(self.Pawn).meshTranslation(false, self.GetTeamNum());
					if(Role < ROLE_Authority)
						attemptToChangeState('PlayerWalking');
					GoToState('PlayerWalking');
				}
				//TO-DO: 
				//change the model
				//particle system: dust
				//ignore wall and objects
			}
		}
		else if (self.Class == class'SneaktoSlimPlayerController_Shorty')
		{
			if(Role < ROLE_Authority)
				attemptToChangeState('ChargingDash');

			GotoState('ChargingDash');
		}
	}

	exec function OnReleaseSecondSkill()
	{			
	}


Begin:
	if(debugStates) logState();

	goInvisible();
	sleep(1.0);
	if(previousStateName == 'Burrow')
	{
		if(Role < ROLE_Authority)
			attemptToChangeState('Burrow');
		GoToState('Burrow');
	}	
}


//Will end Invisible from any Invisible state
simulated state EndInvisible
{

	simulated function removeInvisible()
	{
		//if(!sneaktoslimpawn(self.Pawn).hiddenInVase)
		//	sneaktoslimpawn(self.Pawn).SetHidden(false);
		sneaktoslimpawn(self.Pawn).changeCharacterMaterial(sneaktoslimpawn(self.Pawn),self.GetTeamNum(),"Character");
		//sneaktoslimpawn(self.Pawn).Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
		//sneaktoslimpawn(self.Pawn).simulatedDrawPlayerColor();
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
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
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
		else if (LastStateName == 'Roaring')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeInvisible();
			SneaktoSlimPawn(self.Pawn).incrementBumpCount();
			attemptToChangeState('Roaring');
			GoToState('Roaring');
		}
		else if (LastStateName == 'ThrowingFireCracker')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeInvisible();
			SneaktoSlimPawn(self.Pawn).incrementBumpCount();
			attemptToChangeState('ThrowingFireCracker');
			GoToState('ThrowingFireCracker');
		}
		else if (LastStateName == 'Dashing')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeInvisible();
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			attemptToChangeState('Dashing');
			GoToState('Dashing');
		}
		else if (LastStateName == 'Burrow')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeInvisible();
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			resumeSprintTimer();
			attemptToChangeState('Burrow');
			GoToState('Burrow');
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
		Local SneaktoSlimpawn current;

		if(sneaktoslimpawn(self.Pawn).mistNum == 0)
		{
			sneaktoslimpawn(self.Pawn).checkServerFLBuff(sneaktoslimpawn(self.Pawn).enumBuff.bBuffed, true);

			if(sneaktoslimpawn(self.Pawn).bBuffed == 1) 
			{
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();

				sneaktoslimpawn(self.Pawn).serverResetBBuffed();

				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[0] = 1;//should not be used , kept for "countdown"  at this moment
				
				attemptToChangeState('InvisibleWalking');
				GoToState('InvisibleWalking');
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Invisibility');
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 2) 
			{			
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();

				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[1] = 1;//should not be used 

				attemptToChangeState('DisguisedWalking');
				GoToState('DisguisedWalking');
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Guard_Like_Cue');
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 3) 
			{			
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();

				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				sneaktoslimpawn(self.Pawn).bUsingBuffed[2] = 1;//should not be used 

				attemptToChangeState('UsingThunderFan');
				GoToState('UsingThunderFan');
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Thunder_Fan');
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 4) 
			{			
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();

				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				//TODO: remove the use of bUsingBuffed[], this info is kept by state mechanism already
				//sneaktoslimpawn(self.Pawn).bUsingBuffed[2] = 1;//should not be used 

				//attemptToChangeState('UsingThunderFan');
				//GoToState('UsingThunderFan');
				sneaktoslimpawn(self.Pawn).v_energy = 100;
				ServerResetEnergy();
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Gives_Wings_Cue');
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 5)
			{
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();
				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				attemptToChangeState('UsingSuperSprint');
				GoToState('UsingSuperSprint');
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					//current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Get_out_of_the_way_Cue');
					current.clientAnnounceBasedOnTeam(SneaktoSlimPawn(self.Pawn).GetTeamNum());
				}
			}
			if(sneaktoslimpawn(self.Pawn).bBuffed == 6)
			{
				SneaktoSlimPawn(self.Pawn).incrementPowerupCount();
				sneaktoslimpawn(self.Pawn).serverResetBBuffed();
				SneaktoSlimPawn(self.Pawn).SetUsingBeer(true);
				foreach worldinfo.allactors(class 'sneakToSlimPawn', current)
				{
					current.clientGlobalAnnouncement(SoundCue'flsfx.globalAnnouncement.Cursed_Blood_Cue');
				}
			}
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
		sneaktoslimpawn(self.Pawn).removePowerUp();
		attemptToChangeState('EndInvisible');
		GoToState('EndInvisible');
	}

	simulated exec function OnReleaseSecondSkill()
	{
		pauseSprintTimer();
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
		sneaktoslimpawn(self.Pawn).beerNum = 1;
		sneaktoslimpawn(self.Pawn).BuffedTimer = 20;  //to clear the countdown
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
		local SneaktoSlimTreasureSpawnPoint treasureChest;  

		`log(sneaktoslimpawn(self.Pawn).Name $ ": Moving " $ sneaktoslimpawn(self.Pawn).name $ " to location " $ playerBase.Name , true, 'Ravi');
		sneaktoslimpawn(self.Pawn).flashCurtain(false);
		sneaktoslimpawn(self.Pawn).SetLocation(playerBase.Location);

		foreach allactors(class 'SneaktoSlimTreasureSpawnPoint', treasureChest)
		{
			SneaktoSlimPawn(self.Pawn).SetRotation(rotator(treasureChest.Location - playerBase.Location));
			self.SetRotation(rotator(treasureChest.Location - playerBase.Location)); //Camera's orientation
		}

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

	simulated exec function OnPressSecondSkill()
	{
	}

	simulated exec function OnReleaseSecondSkill()
	{
	}

	simulated exec function OnPressFirstSkill()
	{	
	}

	simulated exec function OnReleaseFirstSkill()
	{
	}

Begin:
	if(debugStates) logState();	

	sneaktoslimpawn(self.Pawn).stopAllTheLoopAnimation();
	sneaktoslimpawn(self.Pawn).playerPlayOrStopCustomAnim('customVanish', 'Vanish', 1.f, true, 0.1f, 0.1f, false, true);
	sneaktoslimpawn(self.Pawn).SetTimer(0.5, false, 'fadeOutCurtain');
	
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
	//setTimer(HoldTime, false, 'hideStateSpottedIcon');
	//setTimer(HoldTime, false, 'movehar');
	//setTimer(HoldTime, false, 'endCatchByAI');
}

simulated state DisguisedWalking extends PlayerWalking
{
	simulated exec function use()           //E-button
	{
		sneaktoslimpawn(self.Pawn).removePowerUp();
		attemptToChangeState('EndDisguised');
		GoToState('EndDisguised');
		super.Use();
	}

	exec function OnPressFirstSkill()
	{
		if (self.Class == class'SneaktoSlimPlayerController_Rabbit')
		{
			//Player can't belly bump if pause menu is on
			if(pauseMenuOn)
				return;

			if(sneaktoslimpawn(self.Pawn).v_energy <= SneaktoSlimPlayerController_Rabbit(self).perRoarEnergy)
				return;
			else
			{
				SneaktoSlimPawn(self.Pawn).incrementBumpCount();
				attemptToChangeState('Roaring');
				GoToState('Roaring');
			}
		}
		else if(self.Class == class'SneaktoSlimPlayerController_Shorty')
		{
			if(Role < ROLE_Authority)
				attemptToChangeState('ChargingFireCracker');

			GotoState('ChargingFireCracker');
		}
		else if(self.Class == class'SneaktoSlimPlayerController_FatLady')
		{
			 if(pauseMenuOn)
				return;
			 if(sneaktoslimpawn(self.Pawn).v_energy <= Sneaktoslimpawn_fatlady(self.Pawn).PerDashEnergy)
				return;
			 else 
			 {
				attemptToChangeState('PreBellyBump');
				GoToState('PreBellyBump');
			 }
		}
	}

	simulated exec function OnPressSecondSkill()
	{
		ApplySprintingSpeed();
		SetTimer(0.05, true, 'removeEnergyWithTime');
	}

	simulated exec function OnReleaseSecondSkill()
	{
		ApplyWalkingSpeed();
		ClearTimer('removeEnergyWithTime');
		SetTimer(2, false, 'StartEnergyRegen');
	}

	//simulated exec function OnPressSecondSkill()
	//{
	//	SneaktoSlimPawn(self.Pawn).incrementSprintCount();
	//	resumeSprintTimer();
	//	attemptToChangeState('DisguisedSprinting');//to server
	//	GoToState('DisguisedSprinting');//local
	//}

	event EndState(Name NextStateName)
	{
		ApplyWalkingSpeed();
	}

Begin:
	if(debugStates) logState();
	goDisguised();
}

simulated function ApplySprintingSpeed()
{
	SneaktoSlimPawn(self.Pawn).GroundSpeed = SneaktoSlimPawn(self.Pawn).FLSprintingSpeed;
	`log("ApplySprintingSpeed");
	serverApplySprintingSpeed();
}

reliable server function serverApplySprintingSpeed()
{
	SneaktoSlimPawn(self.Pawn).GroundSpeed = SneaktoSlimPawn(self.Pawn).FLSprintingSpeed;
	`log("serverApplySprintingSpeed");
}

simulated function ApplyWalkingSpeed()
{
	SneaktoSlimPawn(self.Pawn).GroundSpeed = SneaktoSlimPawn(self.Pawn).FLWalkingSpeed;
	`log("ApplyWalkingSpeed");
	serverApplyWalkingSpeed();
}

reliable server function serverApplyWalkingSpeed()
{
	SneaktoSlimPawn(self.Pawn).GroundSpeed = SneaktoSlimPawn(self.Pawn).FLWalkingSpeed;
	`log("serverApplyWalkingSpeed");
}

simulated function removeEnergyWithTime()
{
	if (Vsize(sneaktoslimpawn(self.Pawn).Velocity) != 0)
	{
		if(sneaktoslimpawn(self.Pawn).v_energy > sneaktoslimpawn(self.Pawn).PerSpeedEnergy)
		{
			ClearTimer('EnergyRegen');
			ClearTimer('StartEnergyRegen');
			SneaktoSlimPawn(self.Pawn).v_energy = SneaktoSlimPawn(self.Pawn).v_energy - SneaktoSlimPawn(self.Pawn).PerSpeedEnergy;
			if (sneaktoslimpawn(self.Pawn).v_energy < 0)
					sneaktoslimpawn(self.Pawn).v_energy = 0;
		}
		else
		{
			ApplyWalkingSpeed();
			SetTimer(2, false, 'StartEnergyRegen');
		}
	}
	else
	{
		SetTimer(2, false, 'StartEnergyRegen');
	}
}


//Child of PlayerWalking, entered when player has <20% energy, and exited when >=20%
simulated state DisguisedExhausted extends DisguisedWalking
{
	simulated exec function use()           //E-button
	{
		sneaktoslimpawn(self.Pawn).removePowerUp();
		attemptToChangeState('EndDisguised');
		GoToState('EndDisguised');
	}

	//simulated exec function OnReleaseSecondSkill()
	//{
	//	pauseSprintTimer();
	//}

	event EndState(Name NextStateName)
	{
		//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTired','Tired',1.f,false,0,0.5);
		//current.toggleTiredAnimation(false);
		ApplyWalkingSpeed();
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

		//if (LastStateName == 'DisguisedSprinting')
		//{
		//	if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
		//	removeDisguised();
		//	attemptToChangeState('Sprinting');
		//	GoToState('Sprinting');
		//}
		if (LastStateName == 'DisguisedExhausted')
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
		else if (LastStateName == 'Roaring')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeDisguised();
			SneaktoSlimPawn(self.Pawn).incrementBumpCount();
			attemptToChangeState('Roaring');
			GoToState('Roaring');
		}
		else if (LastStateName == 'ThrowingFireCracker')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeDisguised();
			SneaktoSlimPawn(self.Pawn).incrementBumpCount();
			attemptToChangeState('ThrowingFireCracker');
			GoToState('ThrowingFireCracker');
		}
		else if (LastStateName == 'Dashing')
		{			
			if(debugStates) `log(SneaktoSlimPawn(self.Pawn).name $ " " $ self.GetStateName(), false, 'state');
			removeDisguised();
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			attemptToChangeState('Dashing');
			GoToState('Dashing');
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

	exec function OnPressFirstSkill()   //Can't Belly-bump while holding treasure
	{
	}

	simulated exec function OnPressSecondSkill()
	{
		if(self.Class == class 'SneaktoSlimPlayerController_FatLady')
		{
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			resumeSprintTimer();
			attemptToChangeState('HoldingTreasureSprinting');//to server
			GoToState('HoldingTreasureSprinting');//local
		}
		else if(self.Class == class 'SneaktoSlimPlayerController_Rabbit')
		{
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			attemptToChangeState('Teleport');
			GoToState('Teleport');
		}
		else if(self.Class == class 'SneaktoSlimPlayerController_GinsengBaby')
		{
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			resumeSprintTimer();
			attemptToChangeState('HoldingTreasureBurrow');
			GoToState('HoldingTreasureBurrow');
		}
		else if(self.Class == class 'SneaktoSlimPlayerController_Shorty')
		{
			SneaktoSlimPawn(self.Pawn).incrementSprintCount();
			attemptToChangeState('ChargingDash');
			GoToState('ChargingDash');
		}
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
	changeAnimTreeToTreasure();
	//SneaktoSlimPawn(self.Pawn).playerPlayOrStopCustomAnim('customTreasureWalk','Treasure_Walk',1.f,true,0.5,0.5,true,true);
	HoldTreasure();
}

//Child of PlayerWalking, entered when player has <20% energy, and exited when >=20%
simulated state HoldingTreasureExhausted extends HoldingTreasureWalking
{

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

	simulated exec function FL_useBuff()
	{

	}

	simulated exec function use()
	{

	}


Begin:
	if(debugStates) logState();
	changeAnimTreeToTreasure();
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
		if (sneaktoslimpawn(self.Pawn).v_energy >= exhaustedThreshold)
		{
			attemptToChangeState('HoldingTreasureWalking');
			GoToState('HoldingTreasureWalking');
		}
	}
	else if (self.IsInState('HoldingTreasureWalking') == true && !self.IsInState('HoldingTreasureSprinting') && !self.IsInState('HoldingTreasureBurrow'))
	{
		if (sneaktoslimpawn(self.Pawn).v_energy < exhaustedThreshold)
		{
			attemptToChangeState('HoldingTreasureExhausted');
			GoToState('HoldingTreasureExhausted');
		}
	}
	else if (self.IsInState('DisguisedExhausted') == true)
	{
		if (sneaktoslimpawn(self.Pawn).v_energy >= exhaustedThreshold)
		{
			attemptToChangeState('DisguisedWalking');
			GoToState('DisguisedWalking');
		}
	}
	else if (self.IsInState('DisguisedWalking') == true && sneaktoslimpawn(self.Pawn).GroundSpeed < sneaktoslimpawn(self.Pawn).FLSprintingSpeed/* && !self.IsInState('DisguisedSprinting')*/)
	{
		if (sneaktoslimpawn(self.Pawn).v_energy < exhaustedThreshold)
		{
			attemptToChangeState('DisguisedExhausted');
			GoToState('DisguisedExhausted');
		}
	}
	else if (self.IsInState('InvisibleExhausted') == true)
	{
		if (sneaktoslimpawn(self.Pawn).v_energy >= exhaustedThreshold)
		{
			attemptToChangeState('InvisibleWalking');
			GoToState('InvisibleWalking');
		}
	}
	else if (self.IsInState('InvisibleWalking') == true && !self.IsInState('InvisibleSprinting'))
	{
		if (sneaktoslimpawn(self.Pawn).v_energy < exhaustedThreshold)
		{
			attemptToChangeState('InvisibleExhausted');
			GoToState('InvisibleExhausted');
		}
	}
	else if (self.IsInState('Exhausted') == true)
	{
		if(sneaktoslimpawn(self.Pawn).v_energy >= exhaustedThreshold)
		{
			attemptToChangeState('PlayerWalking');
			GoToState('PlayerWalking');
		}
	}
	else if (self.IsInState('PlayerWalking') && !self.IsInState('Sprinting') && !self.IsInState('Burrow') && !self.IsInState('DisguisedWalking') && !self.IsInState('InvisibleWalking') && !self.IsInState('HoldingTreasureWalking'))
	{
		if(sneaktoslimpawn(self.Pawn).v_energy < exhaustedThreshold)
		{
			attemptToChangeState('Exhausted');
			GoToState('Exhausted');
		}
	}
	
}

unreliable server function incrementBellyBumpHitBys()
{
	numberOfTimesHitWithBellyBump++;;
}

unreliable server function int getBBHitByCount()
{
	//`log("Client Hit By count: " $ numberOfTimesHitWithBellyBump);
	return self.numberOfTimesHitWithBellyBump;
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
	event BeginState (Name LastStateName)
	{
		sneaktoslimpawn(self.Pawn).countGlobalAnnounHit[self.GetTeamNum()]++;
		if(sneaktoslimpawn(self.Pawn).countGlobalAnnounHit[self.GetTeamNum()] == 1) //First time got hit
		{
			sneaktoslimpawn(self.Pawn).timePlayerHit[self.GetTeamNum()] = WorldInfo.TimeSeconds; //record the hitting time
		}
		else
		{
			if(WorldInfo.TimeSeconds - sneaktoslimpawn(self.Pawn).timePlayerHit[self.GetTeamNum()] <= 5)
			{
				//playsound
				`log("Player XX is getting hit twice!!!!!!!");
			}
			sneaktoslimpawn(self.Pawn).timePlayerHit[self.GetTeamNum()] = WorldInfo.TimeSeconds;
			sneaktoslimpawn(self.Pawn).countGlobalAnnounHit[self.GetTeamNum()] == 1;
		}
			
		SetTimer(2.0f, false, 'StunnedPeriod');
		if(SneaktoSlimPawn(self.Pawn).isGotTreasure)    //if self is holding treasure...
		{            
			SneaktoSlimPawn(self.Pawn).dropTreasure(Normal(vector(self.rotation)));         //...drops it.
		}
	}

	event EndState (name NextStateName)
	{
		StunnedPeriod();
	}

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
	//SetTimer(2.0f, false, 'StunnedPeriod');
}


simulated state Hiding extends CustomizedPlayerWalking
{

	event BeginState (Name LastStateName)
	{
		if (LastStateName == 'HoldingTreasureSprinting' || /*LastStateName == 'DisguisedSprinting' ||*/ LastStateName == 'InvisibleSprinting' || LastStateName == 'Sprinting')
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
		else if(CameraMode == 'Fixed')
		{
			SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = CameraMode;
		}
		else
		{
			`log("NO SUCH CAMERA FOUND!");
		}

	}
}

simulated exec function ToggleFirstThirdCamera()
{
	if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'ThirdPerson')
		SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = 'ThirdPerson';
	else if (SneakToSlimPlayerCamera(PlayerCamera).CameraStyle != 'FirstPerson')
		SneakToSlimPlayerCamera(PlayerCamera).CameraStyle = 'FirstPerson';
}

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

///////////////////////////////////////////////////////////
//
//END-CAMERA CODE
//
///////////////////////////////////////////////////////////

exec function callRestartGame()
{
	newServerPlayerRestart();
}

server reliable function newServerPlayerRestart()
{
	local sneaktoslimplayercontroller current;
	//local SneaktoSlimSpawnPoint currentSpawnPoint;
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
		currentPawn.bUsingBuffed[2] = 0;
		currentPawn.bUsingBuffed[6] = 0;

		currentPawn.BuffedTimerDefault[0] = 10.0; // buff invis period
		currentPawn.BuffedTimerDefault[1] = 20.0; // buff disguise period
		currentPawn.BuffedTimerDefault[2] = 0.0;
		currentPawn.BuffedTimer = 0.0;
		currentPawn.bInvisibletoAI = false;

		//bIsDashing = false;
		currentPawn.disguiseNum = -1;
		currentPawn.endDisguiseNum = -1;

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



defaultproperties
{
	CameraClass=class'SneaktoSlimGame.SneaktoSlimPlayerCamera'
	DefaultFOV=90.f
	bPlayerCanZoom = false;
	//bCaughtByAI = true;//for use by AiNavMeshController
	//bIsSprinting = false;
	RESPAWN_TIME = 2
	HoldTime = 1.0;

	debugStates = true;
	debugAnimes = true;
	exhaustedThreshold = 10;
}
