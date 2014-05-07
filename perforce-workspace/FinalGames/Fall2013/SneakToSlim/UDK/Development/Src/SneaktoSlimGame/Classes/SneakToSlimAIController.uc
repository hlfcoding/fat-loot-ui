class SneakToSlimAIController extends AIController;

var int nextPatrolPointIndex;
var SneakToSlimPawn chaseTarget;                //player the AI is trying to follow
var int alreadyStartled;
var Vector investigationLocation;               //location AI has to currently investigate
var array<SneaktoSlimPawn> visiblePlayers;      //stores currently visible SneakToSlimPawns
var float currentChaseStamina;
var bool rotateTowardsMoveDirection;	
var Vector lastSeenPlayerLocation;              //when AI is following player, he stores the last seen location.
var SneakToSlimDestination currentDestinationActor;	
var vector currentDestinationLocation;
var bool canReachCurrentDestination;
var Name currentPathNodeDestinationName;
var bool isOnPatrolRoute;
var bool AIWantsToTurn;
var vector lastPawnLocation;                    //to keep track of guard getting stuck
var float pawnStuckDuration;                    //how long in seconds is guard stuck
var int jumpCount;                              //number of times pawn tried to jump from one stuck location
var bool pawnWantsToMove;
var bool isCatching;
var array<PathNode> reachablePathnodes;         //nodes directly reachable from current location. choose a random node from here when pawn is lost.
var PlayerStart playerBases[4];                 //store reference to all 4 player bases in the level
var array<ShakingLight> shakingLightsInLevel;
var array<SpotLight> spotLightsInLevel;
var vector LightLookDirection;
var int timeSinceDestinationChanged;

var float MIN_ROTATION_TIME;                        //time taken to rotate when guard has to face new direction
var float MAX_ROTATION_TIME;
var float STAMINA_CHECK_FREQUENCY;              //how often to update stamina
var float VISION_CHECK_FREQUENCY;               //how often guard "sees" things in the environment
var float STUCK_CHECK_FREQUENCY;                //how often to check if guard is stuck
var int NAVMESH_MAX_ITERATIONS;                 //we don't want navigation loops to run infinitely in case the destination cannot be reached
var int MAX_DISTANCE;                           //used in setting initial value of distance between AI and any player
var int RESPAWN_TIME;
var float UNCHANGED_DESTINATION_TIMEOUT;
var float PAWN_STUCK_TIMEOUT;                   //duration in seconds that guard has not moved to be considered stuck
var float DISTANCE_EPSILON;                     //non-zero distance
var float JUMP_FORCE;                           //pawn's jumping strength
var float REACHED_DESTINATION_EPSILON;          //if pawn is this distance away from destination, it is approximated to have reached the destination
var int totalCatches;
var int MAX_PUSH_TO_MOVE_STATE_ITERATIONS;      //how many times to retry movement to a given location
var int PATHNODE_HEIGHT_DIFFERENCE_FROM_PAWN;   //when finding pathnodes to go to, choose one that is not more than this much higher than current pawn height.

event PostBeginPlay()
{
	local PlayerStart playerBase;
	local ShakingLight tempShakingLight;
	local SpotLight tempSpotLight;
	nextPatrolPointIndex = 0;
	chaseTarget = none;
	
	//Find all player bases and store references
	foreach WorldInfo.AllNavigationPoints (class'PlayerStart', playerBase)
	{					
		if(playerBase.TeamIndex > 3)
		{
			`log("ERROR: Can't have > 4 player bases in the level. Unexpected value " $ playerBase.TeamIndex $ ", base: " $ playerBase.Name, true, 'Ravi');
			continue; 
		}
		playerBases[playerBase.TeamIndex] = playerBase;
	}

	//Find all shaking lights in the level and store references
	foreach WorldInfo.AllActors(class'ShakingLight', tempShakingLight)
	{				
		shakingLightsInLevel.AddItem(tempShakingLight);
	}

	//Find all spot lights in the level and store references
	foreach WorldInfo.AllActors(class'SpotLight', tempSpotLight)
	{				
		spotLightsInLevel.AddItem(tempSpotLight);
	}
	
	`log(self.name $ ": Number of shaking lights found in level: " $ shakingLightsInLevel.Length, true, 'Ravi');
	`log(self.name $ ": Number of spot lights found in level: " $ spotLightsInLevel.Length, true, 'Ravi');
	super.PostBeginPlay();
}





public event Possess(Pawn inPawn, bool bVehicleTransition)
{	
	super.Possess(inPawn, bVehicleTransition);	
	`log("Pawn " $ Pawn.Name $ " is attached to controller " $ self.Name, true, 'Ravi');
    Pawn.SetMovementPhysics();

	//initialize variables and functions
    isOnPatrolRoute = true;                                                 //Initially Guard is on Patrol (can find next destination)	
	jumpCount = 0;
	canReachCurrentDestination = true;
	isCatching = false;
	currentPathNodeDestinationName = Name("");
	//alreadyStartled = 0;
	pawnWantsToMove = true;
	timeSinceDestinationChanged = 0;
	currentChaseStamina = SneakToSlimAIPawn(Pawn).MaxChaseStamina;          //Initially stamina is full (max possible)
	SetTimer(VISION_CHECK_FREQUENCY, true, 'setVisibleSneaktoSlimPawns');   //AI is always watching for players	
	SetTimer(STAMINA_CHECK_FREQUENCY, true, 'manageStaminaAndSpeed');       //periodically update stamina		
	SetTimer(STUCK_CHECK_FREQUENCY, true, 'checkPawnStuck');                //periodically check if guard is stuck/ unable to move
	GotoState('Patrol');
}






state Idle
{
Begin:
	pawnWantsToMove = false;
	Pawn.GroundSpeed = 0;
	AIWantsToTurn = true;
	SneakToSlimAIPawn(Pawn).controlAIAnimation('CustomLantern', 'Idle_Lantern', 0.66f, true, 0.1f, 0.1f, false, true);
	turnYaw(SneakToSlimAIPawn(Pawn).rotationAngle/2, SneakToSlimAIPawn(Pawn).rotationDuration/2);
	sleep(SneakToSlimAIPawn(Pawn).rotationDuration/2);
	turnYaw(-(SneakToSlimAIPawn(Pawn).rotationAngle), SneakToSlimAIPawn(Pawn).rotationDuration);
	sleep(SneakToSlimAIPawn(Pawn).rotationDuration);
	//SneakToSlimAIPawn(pawn).Flashlight.SetRotation(SneakToSlimAIPawn(Pawn).Rotation);
	AIWantsToTurn = false;
	Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;

	goto 'Begin';
}

state Patrol
{
	local string patrolPointTag;
	local int waitTimeIndex;
	local int waitTime;
	local vector moveDestination;
	local SneaktoSlimPawn playerWithinVisibleRange;
	local int pushToMoveStateIteration;
	
	event BeginState(name prevState)
	{
		`log(Pawn.Name $ ": entered state " $ self.GetStateName(), true, 'Ravi');
	}

 Begin:		
	if (chaseTarget!=none || visiblePlayers.Length>0)
	{
		chaseTarget.hideSpottedIcon();
		chaseTarget = none;
		visiblePlayers.Length = 0;
	}

	alreadyStartled = 0;
	pushToMoveStateIteration = 0;
	pawnWantsToMove = true;
	SneakToSlimAIPawn(Pawn).aiState = "Patrol";	
	performPatrolChecks();	
	setMoveTarget();
	canReachCurrentDestination = true;
	if(MoveTarget == none)
	{
		`log(Pawn.Name $ ": Cannot find any pathnode that is reachable!", true, 'Ravi');
		GotoState('Idle');
	}
	moveDestination = MoveTarget.Location;
	currentDestinationLocation = MoveTarget.Location;	
	Sleep(RotateTowardsLocation(moveDestination));

	while(canReachCurrentDestination && VSize(moveDestination - Pawn.Location) > REACHED_DESTINATION_EPSILON)
	{
		PushState('MoveToLocation');	
		pushToMoveStateIteration++;
		if(pushToMoveStateIteration > MAX_PUSH_TO_MOVE_STATE_ITERATIONS)
			break;
	}

	//After reaching destination
	if(VSize(moveDestination - Pawn.Location) < REACHED_DESTINATION_EPSILON)
	{		
		patrolPointTag = Caps( SneakToSlimAIPawn(Pawn).MyNavigationPoints[nextPatrolPointIndex].Tag );
		waitTimeIndex = InStr( patrolPointTag, "WAIT-" );
		
		//Stop and look around
		if(patrolPointTag == "LOOK")
		{
			pawnWantsToMove = false;
			Pawn.GroundSpeed = 0;
			AIWantsToTurn = true;
			SneakToSlimAIPawn(Pawn).controlAIAnimation('CustomLantern', 'Idle_Lantern', 0.66f, true, 0.1f, 0.1f, false, true);
			turnYaw(SneakToSlimAIPawn(Pawn).rotationAngle/2, SneakToSlimAIPawn(Pawn).rotationDuration/2);
			sleep(SneakToSlimAIPawn(Pawn).rotationDuration/2);
			turnYaw(-(SneakToSlimAIPawn(Pawn).rotationAngle), SneakToSlimAIPawn(Pawn).rotationDuration);
			sleep(SneakToSlimAIPawn(Pawn).rotationDuration);
			//SneakToSlimAIPawn(pawn).Flashlight.SetRotation(SneakToSlimAIPawn(Pawn).Rotation);
			AIWantsToTurn = false;
			Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;	
		}
		else if(waitTimeIndex >= 0) //Need to wait at this patrol point
		{
			waitTime = int(Mid(patrolPointTag, waitTimeIndex + 5));
			`log(Pawn.Name $ ": Waiting for " $ waitTime $ " seconds");
			pawnWantsToMove = false;
			sleep(waitTime);			
		}
		nextPatrolPointIndex++;		
		rotateTowardsMoveDirection = true;
	}
	goto 'Begin';
}





state Follow
{
	local PlayerStart playerBase;  //base that the player will be sent to when caught	

	event EndState(Name nextState)
	{
		if(chaseTarget != none)
			chaseTarget.hideSpottedIcon();

		//alreadyStartled = 0;		
		chaseTarget = none;
		isCatching = false;
		visiblePlayers.Length = 0;
	}

Begin:		
	pawnWantsToMove = true;
	
	if(visiblePlayers.Length > 0 && chaseTarget!=none)
	{		
		if(chaseTarget.bInvisibletoAI)
		{
			if(chaseTarget.GetTeamNum() > 3)
			{
				`log("ERROR: Cannot have player team number greater than 3. Unexpected value", true, 'Ravi');
				goto 'End';
			}			
			playerBase = playerBases[chaseTarget.GetTeamNum()];
			
			if(VSize(chaseTarget.Location - playerBase.Location) > chaseTarget.PlayerBaseRadius)
			{
				chaseTarget.hideSpottedIcon();
				chaseTarget = none;
				visiblePlayers.Length = 0;

				investigationLocation = lastSeenPlayerLocation;
				`log(Pawn.Name $ ": Cannot see player anymore! Investigating last seen location: " $ lastSeenPlayerLocation, true, 'Ravi');
				GoToState('Investigate');
			}
			else
			{
				goto 'End';
			}
		}

		currentDestinationLocation = chaseTarget.Location;
		
		//if AI is close enough to player, player is caught
		if( !chaseTarget.bInvisibletoAI && (VSize(chaseTarget.Location - Pawn.Location) < SneakToSlimAIPawn(Pawn).CatchDistance))
		{
			totalCatches++;
			chaseTarget.recordCatchStats();

			isCatching = true;

			`log(Pawn.Name $ ": has caught player " $ chaseTarget.name, true, 'Ravi');			 

			if( chaseTarget.isGotTreasure == true )
			{
				`log(Pawn.Name $ ": Dropping treasure from " $ chaseTarget.name, true, 'Ravi');				
				chaseTarget.LostTreasure();
			}
			//send player to base							
			if(!SneaktoslimPlayerController(chaseTarget.Controller).isInState('caughtByAI') && Role == Role_Authority)
			{
				SneaktoslimPlayerController(chaseTarget.Controller).GotoState('caughtByAI');
				SneaktoslimPlayerController(chaseTarget.Controller).clientAttemptToState('caughtByAI');
			}

			pawnWantsToMove = false;
			SneakToSlimAIPawn(Pawn).GroundSpeed = 0;
			sleep(SneakToSlimAIPawn(Pawn).HoldTime);
			pawnWantsToMove = true;
			SneakToSlimAIPawn(Pawn).GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;
			goto 'End';
		}
		else
		{			
			PushState('MoveToLocation');			
		}
	}
	goto 'Begin';

End:
	setStateVariables("Patrol");
	GoToState('Patrol');

Startled:	
	SneakToSlimAIPawn(Pawn).aiState = "Follow";
	if (alreadyStartled == 0)
	{
		alreadyStartled = 1;
		isOnPatrolRoute = false;
		`log(Pawn.Name $ " has spotted player! Startled for " $ SneakToSlimAIPawn(Pawn).DetectReactionTime $ " seconds", true, 'Ravi');	
		pawnWantsToMove = false;
		Pawn.GroundSpeed = 0; //AI should not move when it is startled
		MoveToward(chaseTarget, chaseTarget); //Rotate toward player
		Sleep(SneakToSlimAIPawn(Pawn).DetectReactionTime);	
	}
	setStateVariables("Follow");
	goto 'Begin';
}








state Investigate
{
	local bool reachedDestination;
	local int pushToMoveStateIteration;

	event BeginState(name prevState)
	{
		`log(Pawn.Name $ ": entered state " $ self.GetStateName(), true, 'Ravi');
		currentDestinationLocation = investigationLocation;		
	}

	event EndState(name nextState)
	{		
		setStateVariables("Patrol");
	}

Begin:	
	isOnPatrolRoute = false;
	SneakToSlimAIPawn(Pawn).aiState = "Investigate";
	pawnWantsToMove = false;
	Pawn.GroundSpeed = 0;
	pushToMoveStateIteration = 0;
	canReachCurrentDestination = true;
	rotateTowardsMoveDirection = true;	
	Sleep(RotateTowardsLocation(currentDestinationLocation));	
	pawnWantsToMove = true;
	setStateVariables("Investigate");
	
	if(VSize(Pawn.Location - currentDestinationLocation) < SneakToSlimAIPawn(Pawn).MaxInvestigationDistance)
	{
		`log(Pawn.Name $ ": Investigating location: " $ currentDestinationLocation, true, 'Ravi');
		while(canReachCurrentDestination && VSize(currentDestinationLocation - Pawn.Location) > REACHED_DESTINATION_EPSILON)
		{
			PushState('MoveToLocation');	
			pushToMoveStateIteration++;
			if(pushToMoveStateIteration > MAX_PUSH_TO_MOVE_STATE_ITERATIONS)
				break;
		}		
	}
	else //too far away. 
	{
		`log(Pawn.Name $ ": Distance to event exceeds MaxInvestigationDistance (" $ SneakToSlimAIPawn(Pawn).MaxInvestigationDistance $ ").", true, 'Ravi');
	}

	pawnWantsToMove = false;
	Pawn.GroundSpeed = 0;
	AIWantsToTurn = true;
	SneakToSlimAIPawn(Pawn).controlAIAnimation('CustomLantern', 'Idle_Lantern', 0.66f, true, 0.1f, 0.1f, false, true);
	turnYaw(SneakToSlimAIPawn(Pawn).rotationAngle/2, SneakToSlimAIPawn(Pawn).rotationDuration/2);
	sleep(SneakToSlimAIPawn(Pawn).rotationDuration/2);
	turnYaw(-(SneakToSlimAIPawn(Pawn).rotationAngle), SneakToSlimAIPawn(Pawn).rotationDuration);
	sleep(SneakToSlimAIPawn(Pawn).rotationDuration);	
	//SneakToSlimAIPawn(pawn).Flashlight.SetRotation(SneakToSlimAIPawn(Pawn).Rotation);
	AIWantsToTurn = false;	
	rotateTowardsMoveDirection = true;
	Sleep (RotateTowardsLocation(currentDestinationLocation) );
	pawnWantsToMove = true;	
	//alreadyStartled = 0;
	setStateVariables("Patrol");
	pawnWantsToMove = true;
	GotoState('Patrol');
}








state MoveToLocation
{
	local vector aiNextMoveLocation;
	local int navmeshIteration;		
	local bool reachedDestination;
	local SneakToSlimDestination aiNextLocationActor;

Begin:
	
	//`log(Pawn.Name $ ": entered state " $ self.GetStateName(), true, 'Ravi');
	currentDestinationActor = Spawn(class'SneakToSlimDestination',,,currentDestinationLocation,,,);		
	reachedDestination = false;	
	canReachCurrentDestination = true;
	navmeshIteration = 0;

	while( !reachedDestination && currentDestinationActor != None)
	{
		if( isWithinLineOfSight(currentDestinationActor) )
		{
			//`log(Pawn.Name $ " destination within line of sight", true, 'Ravi');
			MoveTo(currentDestinationActor.Location, currentDestinationActor, Pawn.GetCollisionRadius());			
		}
		else if( FindNavMeshPath(currentDestinationActor.Location) ) //found a path
		{		
			//`log(Pawn.Name $ " navmesh path found to destination", true, 'Ravi');
			NavigationHandle.SetFinalDestination(currentDestinationActor.Location);
			//FlushPersistentDebugLines();
			//NavigationHandle.DrawPathCache(,true,);	
			if( NavigationHandle.GetNextMoveLocation( aiNextMoveLocation, Pawn.GetCollisionRadius()) )
			{
				aiNextLocationActor = Spawn(class'SneakToSlimDestination',,,aiNextMoveLocation,,,); //spawm actor so pawn faces that direction when moving
				MoveTo( aiNextMoveLocation, aiNextLocationActor, Pawn.GetCollisionRadius() );
				aiNextLocationActor.Destroy();
			}
		}
		else
		{
			`log(Pawn.Name $ " Cannot find path to destination", true, 'Ravi');		
			canReachCurrentDestination = false;
			isOnPatrolRoute = false;
			break;
		}
		if(VSize(Pawn.Location - currentDestinationActor.Location) < REACHED_DESTINATION_EPSILON)
		{
			reachedDestination = true;			
			//`log(Pawn.Name $ ": reached destination!", true, 'Ravi');
			break;
		}
		navmeshIteration++;
		if(navmeshIteration > NAVMESH_MAX_ITERATIONS)
		{
			`log(Pawn.Name $ ": Hit NAVMESH_MAX_ITERATIONS trying to reach " $ currentDestinationActor.Name, true, 'Ravi');			
			break;
		}
	}
	destroyCurrentDestinationActor();
	PopState();
}




function destroyCurrentDestinationActor()
{
	if(currentDestinationActor != None)
	{
		currentDestinationActor.Destroy();
		currentDestinationActor = None;
	}
}


function checkPawnStuck()
{
	if(SneakToSlimAIPawn(Pawn).aiState == "Patrol")
		timeSinceDestinationChanged += STUCK_CHECK_FREQUENCY; //advance time

	//`log(Pawn.Name $ " timeSinceDestinationChanged = " $ timeSinceDestinationChanged, true, 'Ravi');
	if( timeSinceDestinationChanged > UNCHANGED_DESTINATION_TIMEOUT )
	{		
		isOnPatrolRoute = false;
		if(IsInState('MoveToLocation'))
		{
			destroyCurrentDestinationActor();
			PopState(); //stop trying to move. get another destination
		}
	}

	if( VSIZE(Pawn.Location - lastPawnLocation) > DISTANCE_EPSILON )
	{
		//pawn has moved
		pawnStuckDuration = 0;
		jumpCount = 0;
	}
	else if(pawnWantsToMove) //check for being stuck only if Pawn is trying to move
	{
		pawnStuckDuration += STUCK_CHECK_FREQUENCY;
		if(pawnStuckDuration > PAWN_STUCK_TIMEOUT) //pawn is stuck
		{			
			isOnPatrolRoute = false;
			if(jumpCount == 0 && SneakToSlimAIPawn(Pawn).aiState!="Investigate" && chaseTarget == none)
			{
				jump();
				jumpCount = 1;
			}
			else if (SneakToSlimAIPawn(Pawn).aiState=="Investigate" || chaseTarget != none)
			{
				chaseTarget = none;
				setStateVariables("Patrol");
				GotoState('Patrol');
			}
		}
	}
	lastPawnLocation = Pawn.Location;
}






function setStateVariables(string state)
{
	SneakToSlimAIPawn(Pawn).aiState = state;
	if(state == "Patrol")
	{		
		SneakToSlimAIPawn(Pawn).GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;
	}
	else if(state == "Follow")
	{		
		SneakToSlimAIPawn(Pawn).GroundSpeed = SneakToSlimAIPawn(Pawn).ChaseSpeed;
	}
	else if(state == "Investigate")
	{		
		SneakToSlimAIPawn(Pawn).GroundSpeed = SneakToSlimAIPawn(Pawn).ChaseSpeed;
	}
}






function performPatrolChecks()
{
	if(SneakToSlimAIPawn(Pawn).MyNavigationPoints.Length == 0)
	{
		`log(Pawn.Name $  ": No waypoints found. Cannot patrol", true, 'Ravi');
		GotoState('Idle');
	}
	if (nextPatrolPointIndex >= SneakToSlimAIPawn(Pawn).MyNavigationPoints.Length)
	{
		nextPatrolPointIndex = 0;
	}
}






function bool FindNavMeshPath(Vector destination)
{
	// Clear cache and constraints
	NavigationHandle.PathConstraintList = none;
	NavigationHandle.PathGoalList = none;

	// Create constraints
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle, destination);
	class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, destination, REACHED_DESTINATION_EPSILON, true);
	
	return NavigationHandle.FindPath();
}





public function bool investigateLocation(vector iLocation)
{		
	local PlayerStart playerBase;
	local SneaktoSlimPawn playerWithinVisibleRange;

	investigationLocation = iLocation;

	foreach WorldInfo.AllPawns(class'SneaktoSlimPawn', playerWithinVisibleRange)
	{
		if(playerWithinVisibleRange.GetTeamNum() > 3)
		{
			`log("ERROR: Cannot have player team number greater than 3. Unexpected value", true, 'Ravi');
			return false;
		}			
		playerBase = playerBases[playerWithinVisibleRange.GetTeamNum()];

		if(VSize(investigationLocation - playerBase.Location) < playerWithinVisibleRange.PlayerBaseRadius)
		{
			return false;
		}
	}		
	
	if( SneakToSlimAIPawn(Pawn).aiState == "Follow")
	{
		`log(Pawn.Name $ " is following a player. Cannot investigate location: " $ location, true, 'Ravi');
		return false;
	}
	else
	{
		GotoState('Investigate');
		return true;
	}
}





function jump()
{
	Pawn.TakeDamage(0, none, Pawn.Location, Vector(Pawn.Rotation) * JUMP_FORCE, class'DamageType');
}






function setVisibleSneaktoSlimPawns()
{
	local SneaktoSlimPawn playerWithinVisibleRange;	
	local ShakingLight tempShakingLight;	
	local SpotLight tempSpotLight;	
	local Vector aiLocation;	
	local float angleBetweenPlayerAndAI;
	local float angleBetweenPlayerAndLight;
	local float DetectAngle;
	local vector aiLookDirection;
	local vector aiToPlayerDirection;
	local vector lightToPlayerDirection;
	local vector hitLocation;
	local vector hitNormal;
	local int numberOfVisiblePlayers;
	local float distAItoTracehit;
	local float distAItoPlayer;	
	local float distLightToPlayer;
	local float minimumAi2playerDistance; //among all players detected by AI, what is the distance of closest player
	local PlayerStart playerBase;
	local int chaseTargetIndex;          //index into the visiblePlayers list that identifies chaseTarget. Is set based on priority. Player with treasure > Player closest to Guard > Any other player	
	local int lightIndex;

	numberOfVisiblePlayers = 0;	
	aiLocation = Pawn.Location;
	if (AIWantsToTurn == false)
	{
		LightLookDirection = vector( Pawn.Rotation );
	}
	aiLookDirection = LightLookDirection;

	//if (AIWantsToTurn == false)
	//{
		DetectAngle = SneakToSlimAIPawn(Pawn).DetectAngle;
	//}
	//else
	//{
	//	DetectAngle = SneakToSlimAIPawn(Pawn).DetectAngle * 3;
	//}

	chaseTargetIndex = -1;
	minimumAi2playerDistance = MAX_DISTANCE;

	if(chaseTarget != none)
	{
		lastSeenPlayerLocation = chaseTarget.Location;
	}

	//DrawDebugLine(aiLocation, aiLocation + SneakToSlimAIPawn(Pawn).DetectDistance*aiLookDirection, 255, 0, 0, false);
	//if(MoveTarget != none)
	//	DrawDebugLine(aiLocation, MoveTarget.Location, 200, 200, 200, false);	

	//main vision logic
	foreach OverlappingActors( class'SneaktoSlimPawn', playerWithinVisibleRange, SneakToSlimAIPawn(Pawn).DetectDistance, aiLocation,)
	{
		if(playerWithinVisibleRange.GetTeamNum() > 3)
		{
			`log("ERROR: Cannot have player team number greater than 3. Unexpected value", true, 'Ravi');
			return;
		}			
		playerBase = playerBases[playerWithinVisibleRange.GetTeamNum()];		

		if( playerBase != none && VSize(playerWithinVisibleRange.Location - playerBase.Location) < playerWithinVisibleRange.PlayerBaseRadius )
		{
			continue; //don't "see" this player since she is in her base area
		}
				
		aiToPlayerDirection = Normal(playerWithinVisibleRange.Location - aiLocation);
		angleBetweenPlayerAndAI = Acos( aiLookDirection dot aiToPlayerDirection ) * 180/pi;

		if(angleBetweenPlayerAndAI > DetectAngle)
		{
			continue; //player is outside the FOV of Pawn's sight
		}

		//player is potentially visible, but now we need to check there are no objects between player and AI
		Trace(hitLocation, hitNormal, playerWithinVisibleRange.Location, aiLocation, true,,);
		distAItoTracehit = VSize(hitLocation - aiLocation); 
		distAItoPlayer = VSize(playerWithinVisibleRange.Location - aiLocation);
		// if ray hits the player, hitLocation is where the ray touches the player collider. since collider sphere is around the player, hitLocation will not equal the playerLocation		

		if( (distAItoTracehit + playerWithinVisibleRange.CollisionComponent.Bounds.SphereRadius/2) <= distAItoPlayer )
		{
			continue; //AI does not have direct line of sight to player
		}

		//check if player is in light or in darkness
		if( distAItoPlayer < SneakToSlimAIPawn(Pawn).lightRadius ) //player is within range of guard's light
		{
			playerWithinVisibleRange.underLight = true;
		}
		else //check if player is lit by environment lights
		{			
			for(lightIndex=0; lightIndex < shakingLightsInLevel.Length; lightIndex++)
			{		
				tempShakingLight = shakingLightsInLevel[lightIndex];
				distLightToPlayer = VSize(playerWithinVisibleRange.Location - tempShakingLight.Location);

				if(tempShakingLight.Flashlight.Radius > distLightToPlayer) //player is within range of this shaking light
				{
					lightToPlayerDirection = Normal(playerWithinVisibleRange.Location - tempShakingLight.Location);
					angleBetweenPlayerAndLight = Acos( tempShakingLight.Flashlight.GetDirection() dot lightToPlayerDirection ) * 180/pi;					
					if(angleBetweenPlayerAndLight <= tempShakingLight.Flashlight.OuterConeAngle) //player is in FOV of light
					{
						playerWithinVisibleRange.underLight = true;						
						break;
					}
				}
			}
			if(playerWithinVisibleRange.underLight == false) // player not lit by any shaking light
			{
				//search all spot lights now
				for(lightIndex=0; lightIndex < spotLightsInLevel.Length; lightIndex++)
				{		
					tempSpotLight = spotLightsInLevel[lightIndex];
					distLightToPlayer = VSize(playerWithinVisibleRange.Location - tempSpotLight.Location);

					if(SpotLightComponent(tempSpotLight.LightComponent).Radius > distLightToPlayer) //player is within range of this spotlight
					{
						lightToPlayerDirection = Normal(playerWithinVisibleRange.Location - tempSpotLight.Location);
						angleBetweenPlayerAndLight = Acos( SpotLightComponent(tempSpotLight.LightComponent).GetDirection() dot lightToPlayerDirection ) * 180/pi;					
						if(angleBetweenPlayerAndLight <= SpotLightComponent(tempSpotLight.LightComponent).OuterConeAngle) //player is in FOV of light
						{
							playerWithinVisibleRange.underLight = true;						
							break;
						}
					}
				}
			}
		}

		if(!playerWithinVisibleRange.bInvisibletoAI && playerWithinVisibleRange.underLight == true && playerWithinVisibleRange.mistNum == 0)
		{
			visiblePlayers.InsertItem(numberOfVisiblePlayers, playerWithinVisibleRange);
			if (playerWithinVisibleRange.isGotTreasure==true)
			{
				chaseTargetIndex = numberOfVisiblePlayers;
				minimumAi2playerDistance = 0;
			}
			else if (minimumAi2playerDistance > distAItoPlayer)
			{
				minimumAi2playerDistance = distAItoPlayer;
				chaseTargetIndex = numberOfVisiblePlayers;
			}
			numberOfVisiblePlayers++;	
		}
		
		playerWithinVisibleRange.underLight = false;	
	}

	if(numberOfVisiblePlayers == 0 && SneakToSlimAIPawn(Pawn).aiState != "Investigate")
	{
		if (chaseTarget!=none && (VSize(chaseTarget.Location - Pawn.Location) > SneakToSlimAIPawn(Pawn).lightRadius))
		{
			if (isCatching == false)
			{
				if(chaseTarget.GetTeamNum() > 3)
				{
					`log("ERROR: Cannot have player team number greater than 3. Unexpected value", true, 'Ravi');
					return;
				}			
				playerBase = playerBases[chaseTarget.GetTeamNum()];						

				if(VSize(chaseTarget.Location - playerBase.Location) > chaseTarget.PlayerBaseRadius)
				{
					chaseTarget.hideSpottedIcon();
					chaseTarget = none; 
					investigationLocation = lastSeenPlayerLocation;
					`log(Pawn.Name $ ": Cannot see player anymore! Investigating last seen location: " $ lastSeenPlayerLocation, true, 'Ravi');
					GoToState('Investigate');
				}
				else
				{
					setStateVariables("Patrol");
					GotoState('Patrol');
				}
			}
			//visiblePlayers.Remove(0, visiblePlayers.Length); //remove all elements from this list
			visiblePlayers.Length = 0;
		}
	}
	//if we have a valid chaseTarget
	else if( SneakToSlimAIPawn(Pawn).aiState != "Follow" && numberOfVisiblePlayers > 0 )
	{
		chaseTarget = visiblePlayers[chaseTargetIndex];
		`log(Pawn.Name $ ": chaseTargetIndex: " $ chaseTargetIndex $ ", Visible players: " $ numberOfVisiblePlayers $ " players in the array: " $ visiblePlayers.Length, true, 'Ravi');
		if(!chaseTarget.haveBeerCurse)
			chaseTarget.showSpottedIcon();
		lastSeenPlayerLocation = chaseTarget.Location;
		GoToState('Follow','Startled');
	}	
}

function setMoveTarget()
{
	local int i, randIndex;
	local PathNode possibleDestination;

	reachablePathnodes.Remove(0, reachablePathnodes.Length); //empty the list
	timeSinceDestinationChanged = 0;	
	MoveTarget = none;
	if(isOnPatrolRoute)
	{
		MoveTarget = SneakToSlimAIPawn(Pawn).MyNavigationPoints[nextPatrolPointIndex];		

		if(currentPathNodeDestinationName == MoveTarget.Name)
		{
			nextPatrolPointIndex++;
			if (nextPatrolPointIndex >= SneakToSlimAIPawn(Pawn).MyNavigationPoints.Length)
			{
				nextPatrolPointIndex = 0;
			}
			MoveTarget = SneakToSlimAIPawn(Pawn).MyNavigationPoints[nextPatrolPointIndex];	
		}
	}
	else
	{		
		for(i = 0; i< SneakToSlimAIPawn(Pawn).MyNavigationPoints.Length; i++)
		{
			//find a reachable destination that is different from the current destination
			if( currentPathNodeDestinationName != SneakToSlimAIPawn(Pawn).MyNavigationPoints[i].Name &&
				(isWithinLineOfSight(SneakToSlimAIPawn(Pawn).MyNavigationPoints[i]) ||
				FindNavMeshPath((SneakToSlimAIPawn(Pawn).MyNavigationPoints[i]).Location))
				)
			{
				MoveTarget = SneakToSlimAIPawn(Pawn).MyNavigationPoints[i];
				nextPatrolPointIndex = i;
				isOnPatrolRoute = true;
				break; //found a target
			}
		}
		if(MoveTarget == none) //If we can't go to any of the patrol points, go to any reachable pathnode
		{
			foreach WorldInfo.AllNavigationPoints (class'PathNode', possibleDestination)
			{
				if( (InStr( string(possibleDestination.Name), "PathNode_" ) < 0) ||
					possibleDestination.Location.Z > Pawn.Location.Z + PATHNODE_HEIGHT_DIFFERENCE_FROM_PAWN ||
					currentPathNodeDestinationName == possibleDestination.Name
					) //has to be a PathNode not higher than pawn .. valid in DemoDay level. Will have to change if level has platforms at different heights
					continue;
				
				if (isWithinLineOfSight(possibleDestination) || FindNavMeshPath(possibleDestination.Location))
				{					
					reachablePathnodes.AddItem(possibleDestination);
				}
			}
			if(reachablePathnodes.Length > 0)
			{
				randIndex = rand(reachablePathnodes.Length);
				MoveTarget = reachablePathnodes[randIndex]; //get a random node from available reachable nodes
			}
		}
	}
	if(MoveTarget != None)
	{
		//`log(Pawn.Name $ " currentPathNodeDestinationName is " $ currentPathNodeDestinationName, true, 'Ravi');
		currentPathNodeDestinationName = MoveTarget.Name;		
	}
}

function bool isWithinLineOfSight(Actor other)
{
	local vector hitLoc, hitNorm;
	local vector slightlyabove;

	if(Other == None)
		return false;

	slightlyabove.X = other.Location.X;
	slightlyabove.Y = other.Location.Y;
	slightlyabove.Z = other.Location.Z + 20;

	//DrawDebugLine(Pawn.Location, slightlyabove, 255, 255, 255, true);
	return Trace(hitLoc, hitNorm, slightlyabove, Pawn.Location, true, vect(10,10,10)) == none;
	//return FastTrace(other.Location, Pawn.Location,vect(30,30,40), false);
}

function turnYaw(float angle, float rotationTime)
{
	//local int i;	
	local rotator myRotation;
	local float newAngle;
	local float sinY;
	local float cosX;
	local float newAngleX;
	local float newAngleY;
	myRotation = Rotation;
	myRotation.Yaw += angle;
	newAngle = angle/182.0444;

	LightLookDirection = vector( Pawn.Rotation );

	cosX = cos(newAngle*3.14/180);
	sinY = sin(newAngle*3.14/180);

	newAngleX = LightLookDirection.X * cosX - LightLookDirection.Z * sinY;
	newAngleY = LightLookDirection.X * sinY + LightLookDirection.Z * cosX;

	pawn.SetDesiredRotation(myRotation,false,false,rotationTime,true);

	LightLookDirection.X = newAngleX;
	LightLookDirection.Y = newAngleY;

	//For (i=0; i < (rotationTime * 1000); i++)
	//{
		//LightLookDirection.X = ((LightLookDirection.X * ((rotationTime * 1000)-i)) + (newAngleX * (i)))/(rotationTime * 1000);
		//LightLookDirection.Y = ((LightLookDirection.Y * ((rotationTime * 1000)-i)) + (newAngleY * (i)))/(rotationTime * 1000);
		//SneakToSlimAIPawn(pawn).Flashlight.SetRotation(((SneakToSlimAIPawn(pawn).Flashlight.Rotation * ((rotationTime * 1000)-i)) + (myRotation * (i)))/(rotationTime * 1000));
	//}
}

function manageStaminaAndSpeed()
{
	if( Pawn.GroundSpeed < SneakToSlimAIPawn(Pawn).ChaseSpeed && 
		currentChaseStamina < SneakToSlimAIPawn(Pawn).MaxChaseStamina )
	{
		currentChaseStamina += STAMINA_CHECK_FREQUENCY * SneakToSlimAIPawn(Pawn).ChaseStaminaRegenerationRate;
	}	
	else if(Pawn.GroundSpeed == SneakToSlimAIPawn(Pawn).ChaseSpeed)
	{
		currentChaseStamina -= STAMINA_CHECK_FREQUENCY * SneakToSlimAIPawn(Pawn).ChaseStaminaConsumptionRate;

		if(currentChaseStamina <= 0)
		{
			SneakToSlimAIPawn(Pawn).GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;
			currentChaseStamina = SneakToSlimAIPawn(Pawn).MaxChaseStamina;
			setStateVariables("Patrol");
			GotoState('Patrol');
		}
	}	
}

function float RotateTowardsLocation(vector nextMoveLocation)
{	
	local vector aiLookDirection;
	local vector aiMoveDirection;		
	local rotator aiRotator;
	local float rotationAngle;
	local float lerpedRotationTime;
	
	aiLookDirection = vector(Pawn.Rotation);	
	aiMoveDirection = Normal(nextMoveLocation - Pawn.Location);
	rotationAngle = Acos( aiLookDirection dot aiMoveDirection ) * 57.2958; //convert radians to degrees

	if(rotationAngle < 70)
		return 0; //don't turn

	lerpedRotationTime = MIN_ROTATION_TIME +  (Abs(rotationAngle) - 90) * (MAX_ROTATION_TIME - MIN_ROTATION_TIME)/90;
	aiRotator = rotator(aiMoveDirection - aiLookDirection);
	Pawn.SetDesiredRotation(aiRotator, false, false, lerpedRotationTime, true);
	return lerpedRotationTime/2; //this will be the sleep duration
}

function stopSeeingPlayers()
{
	self.ClearTimer('setVisibleSneaktoSlimPawns');
}




function accelerateToRun(float maxSpeed)
{
	while (SneakToSlimAIPawn(Pawn).GroundSpeed < maxSpeed)
	{
		SneakToSlimAIPawn(Pawn).GroundSpeed = SneakToSlimAIPawn(Pawn).GroundSpeed + (SneakToSlimAIPawn(Pawn).accelerationSpeed);
	}
}


function decelerateToWalk(float minSpeed)
{
	while (SneakToSlimAIPawn(Pawn).GroundSpeed > minSpeed)
	{
		SneakToSlimAIPawn(Pawn).GroundSpeed = SneakToSlimAIPawn(Pawn).GroundSpeed - (SneakToSlimAIPawn(Pawn).accelerationSpeed);
	}
}



function resumeSeeingPlayers()
{
	self.SetTimer(VISION_CHECK_FREQUENCY, true, 'setVisibleSneaktoSlimPawns');	
}

defaultproperties
{	
	MAX_PUSH_TO_MOVE_STATE_ITERATIONS = 3
	NAVMESH_MAX_ITERATIONS = 30
	STAMINA_CHECK_FREQUENCY = 0.3
	VISION_CHECK_FREQUENCY = 0.05
	STUCK_CHECK_FREQUENCY = 1.0
	MIN_ROTATION_TIME = 0.6
	MAX_ROTATION_TIME = 1.0
	MAX_DISTANCE = 999999
	RESPAWN_TIME = 2	
	PAWN_STUCK_TIMEOUT = 5
	UNCHANGED_DESTINATION_TIMEOUT = 20
	DISTANCE_EPSILON = 1
	JUMP_FORCE = 25000
	REACHED_DESTINATION_EPSILON = 50
	AIWantsToTurn = false
	PATHNODE_HEIGHT_DIFFERENCE_FROM_PAWN = 10

	totalCatches=0
}
