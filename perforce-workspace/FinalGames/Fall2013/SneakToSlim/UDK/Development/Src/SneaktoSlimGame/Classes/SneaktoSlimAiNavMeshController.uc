class SneakToSlimAINavMeshController extends AIController;

var int nextPatrolPointIndex;
var SneakToSlimPawn chaseTarget;                //player the AI is trying to follow
var int alreadyStartled;
var Vector investigationLocation;               //location AI has to currently investigate
var array<SneaktoSlimPawn> visiblePlayers;      //stores currently visible SneakToSlimPawns
var float currentChaseStamina;
var bool rotateTowardsMoveDirection;	
var Vector lastSeenPlayerLocation;              //when AI is following player, he stores the last seen location.
var SneakToSlimDestination currentDestinationActor;	
var bool isOnPatrolRoute;
var vector lastPawnLocation;                    //to keep track of guard getting stuck
var float pawnStuckDuration;                    //how long in seconds is guard stuck
var int jumpCount;                              //number of times pawn tried to jump from one stuck location
var bool pawnWantsToMove;
var bool isCatching;
var array<PathNode> reachablePathnodes;         //nodes directly reachable from current location. choose a random node from here when pawn is lost.

var float MIN_ROTATION_TIME;                        //time taken to rotate when guard has to face new direction
var float MAX_ROTATION_TIME;
var float STAMINA_CHECK_FREQUENCY;              //how often to update stamina
var float VISION_CHECK_FREQUENCY;               //how often guard "sees" things in the environment
var float STUCK_CHECK_FREQUENCY;                //how often to check if guard is stuck
var int NAVMESH_MAX_ITERATIONS;                 //we don't want navigation loops to run infinitely in case the destination cannot be reached
var int MAX_DISTANCE;                           //used in setting initial value of distance between AI and any player
var int RESPAWN_TIME;
var float PAWN_STUCK_TIMEOUT;                   //duration in seconds that guard has not moved to be considered stuck
var float DISTANCE_EPSILON;                     //non-zero distance
var float JUMP_FORCE;                           //pawn's jumping strength
var float REACHED_DESTINATION_EPSILON;          //if pawn is this distance away from destination, it is approximated to have reached the destination
var int totalCatches;

event PostBeginPlay()
{
	nextPatrolPointIndex = 0;
	chaseTarget = none;
	super.PostBeginPlay();
}





public event Possess(Pawn inPawn, bool bVehicleTransition)
{	
	super.Possess(inPawn, bVehicleTransition);	
	`log("Pawn " $ Pawn.Name $ " is attached to controller " $ self.Name, true, 'Ravi');
    Pawn.SetMovementPhysics();

    isOnPatrolRoute = true;                                                 //Initially Guard is on Patrol (can find next destination)	
	jumpCount = 0;
	isCatching = false;
	alreadyStartled = 0;
	pawnWantsToMove = true;
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
	turnYaw(16384, 1);
	sleep(2);
	turnYaw(-16384, 1);
	sleep(2);
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
	
 Begin:	
	pawnWantsToMove = true;
	SneakToSlimAIPawn(Pawn).aiState = "Patrol";	
	performPatrolChecks();	
	setMoveTarget();
	currentDestinationActor = Spawn(class'SneakToSlimDestination',,,MoveTarget.Location,,,);

	
	if(MoveTarget == none)
	{
		`log(Pawn.Name $ ": Cannot find any pathnode that is reachable!", true, 'Ravi');
		GotoState('Idle');
	}
	moveDestination = MoveTarget.Location;
	Sleep(RotateTowardsLocation(MoveTarget.Location));
	//MoveToward(MoveTarget, MoveTarget);
	PushState('MoveToLocation');	

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
			turnYaw(16384, 1);
			sleep(2);
			turnYaw(-16384, 1);
			sleep(2);			
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

	currentDestinationActor.Destroy(); //after destination has been reached, we don't need this actor anymore	


	goto 'Begin';
}





state Follow
{
	local PlayerStart playerBase;  //base that the player will be sent to when caught	

Begin:		
	pawnWantsToMove = true;
	if(visiblePlayers.Length > 0)
	{			
		MoveTarget = chaseTarget;
		currentDestinationActor = Spawn(class'SneakToSlimDestination',,,chaseTarget.Location,,,);

		//if AI is close enough to player, player is caught
		if((VSize(chaseTarget.Location - Pawn.Location) < SneakToSlimAIPawn(Pawn).CatchDistance))
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
				SneaktoslimPlayerController(chaseTarget.Controller).HoldTime = SneakToSlimAIPawn(Pawn).HoldTime;					
				SneaktoslimPlayerController(chaseTarget.Controller).GotoState('caughtByAI');
				SneaktoslimPlayerController(chaseTarget.Controller).clientAttemptToState('caughtByAI');
			}

			pawnWantsToMove = false;
			sleep(SneakToSlimAIPawn(Pawn).HoldTime);
			pawnWantsToMove = true;
			goto 'End';
		}
		else
		{
			if( isWithinLineOfSight(MoveTarget)) 
			{
				Sleep(RotateTowardsLocation(MoveTarget.Location));
				MoveToward(MoveTarget, MoveTarget);
				//PushState('MoveToLocation');
			}
			else
			{
				Sleep(RotateTowardsLocation(MoveTarget.Location));
				//MoveToward(MoveTarget, MoveTarget);
				PushState('MoveToLocation');
			}
		}
	}
	goto 'Begin';

End:	
	chaseTarget = none;
	isCatching = false;
	currentDestinationActor.Destroy(); //after destination has been reached, we don't need this actor anymore	
	setStateVariables("Patrol");
	alreadyStartled = 0;
	GoToState('Patrol');

Startled:	
	SneakToSlimAIPawn(Pawn).aiState = "Follow";
	if (alreadyStartled == 0)
	{
		alreadyStartled = 1;
		`log(Pawn.Name $ " has spotted player! Startled for " $ SneakToSlimAIPawn(Pawn).DetectReactionTime $ " seconds", true, 'Ravi');	
		pawnWantsToMove = false;
		Pawn.GroundSpeed = 0; //AI should not move when it is startled
		MoveToward(chaseTarget, chaseTarget); //Rotate toward player
		sleep(SneakToSlimAIPawn(Pawn).DetectReactionTime);	
	}
	setStateVariables("Follow");
	goto 'Begin';
}








state Investigate {
	local bool goToDestination;
	local bool reachedDestination;
		
Begin:	
	SneakToSlimAIPawn(Pawn).aiState = "Investigate";
	pawnWantsToMove = false;
	Pawn.GroundSpeed = 0;
	pawnWantsToMove = true;
	rotateTowardsMoveDirection = true;

	setStateVariables("Investigate");

	currentDestinationActor = Spawn(class'SneakToSlimDestination',,,investigationLocation,,,);
	MoveTarget = currentDestinationActor;
	
	if(isWithinLineOfSight(currentDestinationActor))
	{
		MoveToward(currentDestinationActor, currentDestinationActor);
		//PushState('MoveToLocation');
	}
	else if( FindNavMeshPath(currentDestinationActor.Location) )
	{	
		if(NavigationHandle.CalculatePathDistance() < SneakToSlimAIPawn(Pawn).MaxInvestigationDistance)
		{
			`log(Pawn.Name $ ": Investigating location: " $ currentDestinationActor.Location, true, 'Ravi');
			PushState('MoveToLocation');
			//MoveToward(MoveTarget, MoveTarget);
		}
		else //too far away. 
		{
			`log(Pawn.Name $ ": Distance to event (" $ NavigationHandle.CalculatePathDistance() $ ") exceeds MaxInvestigationDistance (" $ SneakToSlimAIPawn(Pawn).MaxInvestigationDistance $ ").", true, 'Ravi');
		}
	}
	else
	{
		`log(Pawn.Name $ " could not find path towards investigation location", true, 'Ravi');
	}
	currentDestinationActor.Destroy(); //after destination has been reached, we don't need this actor anymore	
	
	pawnWantsToMove = false;
	Pawn.GroundSpeed = 0;
	turnYaw(32764, 2);
	sleep(2);
	turnYaw(-32764, 2);
	sleep(2);	
	setStateVariables("Patrol");
	rotateTowardsMoveDirection = true;
	alreadyStartled = 0;
	GotoState('Patrol');
}








state MoveToLocation
{
	local vector aiNextMoveLocation;
	local int navmeshIteration;		
	local Vector tempDestination;
Begin:
	pawnWantsToMove = true;
	NavigationHandle.SetFinalDestination(currentDestinationActor.Location);
		
	if( !isWithinLineOfSight(currentDestinationActor) ) 
	{
		if( !FindNavMeshPath(currentDestinationActor.Location) ) //calculate path
		{	
			`log(Pawn.Name $ ": Could not find a path to " $ currentDestinationActor.Name, true, 'Ravi');
			if(SneakToSlimAIPawn(Pawn).aiState == "Follow")
			{
				PushState('MoveToLocation');
				//MoveToward(MoveTarget, MoveTarget);
			}
			else
			{
				isOnPatrolRoute = false; //Cannot find path to patrol route			
			}
			goto 'End';
		}
		else //found a path
		{
			if(rotateTowardsMoveDirection)
			{
				NavigationHandle.GetNextMoveLocation(aiNextMoveLocation, 0);
				rotateTowardsMoveDirection = false; //rotate only first time the path is found
			}
			//FlushPersistentDebugLines();
			//NavigationHandle.DrawPathCache(,true,);			
		}
	}
	else //destination is directly reachable (no need to calculate path)
	{	
        if(rotateTowardsMoveDirection)
		{
			pawnWantsToMove = false;
			Sleep(RotateTowardsLocation(currentDestinationActor.Location));
			pawnWantsToMove = true;
			//rotateTowardsMoveDirection = false; //rotate only first time the path is found
		}		
		MoveToward(currentDestinationActor, currentDestinationActor);
		//PushState('MoveToLocation');
	}

	navmeshIteration=0;
	//Move towards destination using calculated path
	while( currentDestinationActor != None && !Pawn.ReachedDestination(currentDestinationActor) )
	{	
		if( NavigationHandle.GetNextMoveLocation(tempDestination, Pawn.GetCollisionRadius()) )
		{			
			if (!NavigationHandle.SuggestMovePreparation(tempDestination,self))
			{
				//PushState('MoveToLocation');
				MoveTo(tempDestination);
			}
		}

		if( currentDestinationActor!= none && isWithinLineOfSight(currentDestinationActor) ) //destination is reachable directly
		{
			MoveToward(currentDestinationActor, currentDestinationActor);
			//PushState('MoveToLocation');
			break; //get out of loop
		}
		navmeshIteration++;
		if(navmeshIteration > NAVMESH_MAX_ITERATIONS)
		{
			`log(Pawn.Name $ ": Reached max navmesh iteration limit trying to reach " $ currentDestinationActor.Name, true, 'Ravi');
			break; //stop searching for path
		}
	}
	goto 'End';

End:
	PopState();
}







function checkPawnStuck()
{
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
			if(jumpCount == 0)
			{
				jump();
				jumpCount = 1;
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
		//SneakToSlimAIPawn(Pawn).controlAIAnimation('UDKAnimBlendByIdle_1', 'Walk', 1.0f, true, 0, 0, true, false);
		Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;
	}
	else if(state == "Follow")
	{		
		//SneakToSlimAIPawn(Pawn).controlAIAnimation('CustomSpeed', 'Run', 1.0f, true, 0, 0, true, false);
		Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).ChaseSpeed;
	}
	else if(state == "Investigate")
	{		
		Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).ChaseSpeed;

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
	class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, destination);
	
	return NavigationHandle.FindPath();
}





public function bool investigateLocation(vector iLocation)
{		
	investigationLocation = iLocation;
	
	if( SneakToSlimAIPawn(Pawn).aiState == "Follow" || SneakToSlimAIPawn(Pawn).aiState == "Investigate" )
	{
		`log(Pawn.Name $ " is either following a player or already investigating. Cannot investigate location: " $ location, true, 'Ravi');
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
	local SpotLight lightOnTopOfPlayer;	
	local Vector aiLocation;	
	local float angleBetweenPlayerAndAI;
	local float angleBetweenPlayerAndLight;
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

	numberOfVisiblePlayers = 0;	
	aiLocation = Pawn.Location;
	aiLookDirection = vector( Pawn.Rotation );
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
		foreach WorldInfo.AllNavigationPoints (class'PlayerStart', playerBase)
		{					
			if(playerBase.TeamIndex == playerWithinVisibleRange.GetTeamNum())
			{
				break; //got the base of this player
			}
		}

		if( playerBase != none && VSize(playerWithinVisibleRange.Location - playerBase.Location) < playerWithinVisibleRange.PlayerBaseRadius )
		{
			continue; //don't "see" this player since she is in her base area
		}		
				
		aiToPlayerDirection = Normal(playerWithinVisibleRange.Location - aiLocation);
		angleBetweenPlayerAndAI = Acos( aiLookDirection dot aiToPlayerDirection ) * 180/pi;

		if(angleBetweenPlayerAndAI > SneakToSlimAIPawn(Pawn).DetectAngle)
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
		else //check if player is lighted by environment lights
		{				
			foreach WorldInfo.AllActors(class'SpotLight', lightOnTopOfPlayer)
			{				
				distLightToPlayer = VSize(playerWithinVisibleRange.Location - lightOnTopOfPlayer.Location);

				if(SpotLightComponent(lightOnTopOfPlayer.LightComponent).Radius > distLightToPlayer) //player is within range of this spotlight
				{
					lightToPlayerDirection = Normal(playerWithinVisibleRange.Location - lightOnTopOfPlayer.Location);
					angleBetweenPlayerAndLight = Acos( SpotLightComponent(lightOnTopOfPlayer.LightComponent).GetDirection() dot lightToPlayerDirection ) * 180/pi;					
					if(angleBetweenPlayerAndLight <= SpotLightComponent(lightOnTopOfPlayer.LightComponent).OuterConeAngle) //player is in FOV of light
					{
						playerWithinVisibleRange.underLight = true;						
						break;
					}
				}
			}
		}

		if(!playerWithinVisibleRange.bInvisibletoAI && playerWithinVisibleRange.underLight == true)
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
				chaseTarget.hideSpottedIcon();
				chaseTarget = none;
				investigationLocation = lastSeenPlayerLocation;
				`log(Pawn.Name $ ": Cannot see player anymore! Investigating last seen location: " $ lastSeenPlayerLocation, true, 'Ravi');
				GoToState('Investigate');
			}
			visiblePlayers.Remove(0, visiblePlayers.Length); //remove all elements from this list
		}
	}
	//if we have a valid chaseTarget
	else if( SneakToSlimAIPawn(Pawn).aiState != "Follow" && visiblePlayers.Length > 0 )
	{
		chaseTarget = visiblePlayers[chaseTargetIndex];
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

	MoveTarget = none;
	if(isOnPatrolRoute)
	{
		MoveTarget = SneakToSlimAIPawn(Pawn).MyNavigationPoints[nextPatrolPointIndex];		
	}
	else
	{		
		for(i = 0; i< SneakToSlimAIPawn(Pawn).MyNavigationPoints.Length; i++)
		{
			if( isWithinLineOfSight(SneakToSlimAIPawn(Pawn).MyNavigationPoints[i]) ||
				FindNavMeshPath((SneakToSlimAIPawn(Pawn).MyNavigationPoints[i]).Location)
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
					possibleDestination.Location.Z > Pawn.Location.Z + 10
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
}

function bool isWithinLineOfSight(Actor other)
{
	//return Trace(hitLoc, hitNorm, groundLevelDestination, Pawn.Location, true, vect(30,30,40)) == none;
	return FastTrace(other.Location, Pawn.Location,vect(30,30,40), false);
}

function turnYaw(float angle, float rotationTime)
{
	local rotator myRotation;
	myRotation = Rotation;
	myRotation.Yaw += angle;
	pawn.SetDesiredRotation(myRotation,false,false,rotationTime,true);
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
			Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;
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

	if(rotationAngle < 90)
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

function resumeSeeingPlayers()
{
	self.SetTimer(VISION_CHECK_FREQUENCY, true, 'setVisibleSneaktoSlimPawns');	
}

defaultproperties
{	
	NAVMESH_MAX_ITERATIONS = 50
	STAMINA_CHECK_FREQUENCY = 0.3
	VISION_CHECK_FREQUENCY = 0.05
	STUCK_CHECK_FREQUENCY = 1.0
	MIN_ROTATION_TIME = 0.6
	MAX_ROTATION_TIME = 1.0
	MAX_DISTANCE = 999999
	RESPAWN_TIME = 2	
	PAWN_STUCK_TIMEOUT = 3
	DISTANCE_EPSILON = 1
	JUMP_FORCE = 25000
	REACHED_DESTINATION_EPSILON = 100

	totalCatches=0
}
