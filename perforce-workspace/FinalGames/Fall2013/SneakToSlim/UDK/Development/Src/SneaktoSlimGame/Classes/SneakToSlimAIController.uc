class SneakToSlimAIController extends AIController;

var NavigationPoint nextPatrolPoint;
var bool isTurning;
var int nextPatrolPointIndex;
var SneakToSlimPawn chaseTarget; //player the AI is trying to follow
var PlayerStart playerBase; //base that the player will be sent to when caught
var Vector aiOldLocation; //location of AI pawn a few seconds back. If current location = old location, we assume AI is stuck.

//when GetVisibleSneaktoSlimPawns function is called, this array is emptied and then filled with any visible SneakToSlimPawns
var array<SneaktoSlimPawn> visiblePlayers; 
var vector investigationLocation; //location AI has to currently investigate

event PostBeginPlay()
{
	nextPatrolPointIndex = 0;
	isTurning=false;
	super.PostBeginPlay();
}

public event Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition);	
	`log("Pawn " $ Pawn.Name $ " is now attached to controller " $ self.Name, true, 'Ravi');
    Pawn.SetMovementPhysics();
	if (Pawn.Physics == PHYS_Walking)
	{
		Pawn.SetPhysics(PHYS_Falling);
	}

	SetTimer(0.3, true, 'setVisibleSneaktoSlimPawns'); //AI is always watching for players
	aiOldLocation = vect(-2147483648, -2147483648, -2147483648); //initial location set to something the AI won't be in when game starts
	GotoState('Patrol');
}

state Idle
{
Begin:
    `log(Pawn.Name $  ": In idle state.", true, 'Nick A');	
}


state Patrol
{
 Begin:

	if(SneakToSlimAIPawn(Pawn).MyNavigationPoints.Length == 0)
	{
		`log(Pawn.Name $  ": No waypoints found. Cannot patrol", true, 'Ravi');
		GotoState('Idle');
	}
	if (nextPatrolPointIndex >= SneakToSlimAIPawn(Pawn).MyNavigationPoints.Length)
	{
		nextPatrolPointIndex = 0;
	}

	MoveTarget = SneakToSlimAIPawn(Pawn).MyNavigationPoints[nextPatrolPointIndex];
	if (ActorReachable(MoveTarget)) 
	{		
		MoveToward(MoveTarget, MoveTarget);	
	}
	else
	{
		MoveTarget = FindPathToward(SneakToSlimAIPawn(Pawn).MyNavigationPoints[nextPatrolPointIndex]);
		if (MoveTarget != none)
		{			
			MoveToward(MoveTarget, MoveTarget);
		}
		else
		{
			getAiUnstuck();
			goto 'Begin';
		}
	}
	if(Pawn.ReachedDestination(MoveTarget))
	{
		nextPatrolPointIndex++;
		GoToState('Turning');
	}
	
	goto 'Begin';
}

state Follow
{
Begin:	
	if(visiblePlayers.Length > 0)
	{		
		chaseTarget = visiblePlayers[0]; //If needed, we can decide which player to follow.		
		if(chaseTarget != none)
		{
			MoveToward(chaseTarget, chaseTarget, 0);			
			if ( (VSize(chaseTarget.Location - Pawn.Location) < SneakToSlimAIPawn(Pawn).CatchDistance) )
			{
				chaseTarget.disablePlayerMovement();
				`log(Pawn.Name $ ": has caught player " $ chaseTarget.name, true, 'Ravi');

				if( chaseTarget.isGotTreasure == true )
				{
					`log(Pawn.Name $ ": Dropping treasure from " $ chaseTarget.name, true, 'Ravi');
					chaseTarget.dropTreasure(Normal(vector(self.rotation)));
				}
				foreach WorldInfo.AllNavigationPoints (class'PlayerStart', playerBase)
				{					
					if (playerBase.TeamIndex == chaseTarget.GetTeamNum())
					{
						break;
					}
				}
				
				if(playerBase == none)
				{
					`log("ERROR!! Unable to find base of player: " $ chaseTarget.Name $ ". Can't send player to base", true, 'Ravi');
				}
				else
				{
					sleep(1.5);
					`log("Moving " $ chaseTarget.name $ " to location " $ playerBase.Name , true, 'Ravi');
					chaseTarget.SetLocation(playerBase.Location);
					chaseTarget.v_energy = 100;
					chaseTarget.enablePlayerMovement();
				}
			}
		}
	}
	else //AI cannot see any player. Go back to patrol
	{
		lostSightOfPlayer();		
	}
	goto 'Begin';

Startled:
	`log(Pawn.Name $ " has spotted player! Startled for " $ SneakToSlimAIPawn(Pawn).DetectReactionTime $ " seconds", true, 'Ravi');
	Pawn.GroundSpeed = 0; //AI should not move when it is startled
	sleep(0.2);
	turnYaw(0);
	sleep(SneakToSlimAIPawn(Pawn).DetectReactionTime);
	//SneakToSlimAIPawn(Pawn).aiPawnMesh.SetMaterial(0, Material'NodeBuddies.Materials.NodeBuddy_Red1');
	SneakToSlimAIPawn(Pawn).aiState = "Follow";
	`log(Pawn.Name $ " Going to follow player now", true, 'Ravi');
	Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).ChaseSpeed;	
	goto 'Begin';
}

state Turning
{	
	Begin:
		isTurning = true;
		Pawn.GroundSpeed = 0;
		sleep(0.25);
		turnYaw(16384);
		sleep(1.75);
		turnYaw(-16384);
		sleep(1.75);
		sleep(0.25);
		Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;
		isTurning = false;
		GoToState('Patrol');
}

state Investigate {
	local int routeNodeIndex;	

Begin:	

	`log(Pawn.Name $ " investigating location: " $ location, true, 'Ravi');
	FindPathTo(investigationLocation);

	if(RouteCache.Length == 0)
	{
		`log(Pawn.Name $ " No route found to investigation location", true, 'Ravi');
	}
	else
	{		
		routeNodeIndex = 0;
		while(routeNodeIndex < RouteCache.Length)
		{
			`log(Pawn.Name $ " investigating: Moving to location: " $ RouteCache[routeNodeIndex].Name, true, 'Ravi');
			MoveTo(RouteCache[routeNodeIndex].Location);
			routeNodeIndex ++;
		}
	}
	
	Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).PatrolSpeed;
	GotoState('Patrol');	
}

function lostSightOfPlayer()
{
	//SneakToSlimAIPawn(Pawn).aiPawnMesh.SetMaterial(0, none);
	SneakToSlimAIPawn(Pawn).aiState = "Patrol";
	`log(Pawn.Name $ ": cannot see player anymore", true, 'Ravi');
	GoToState('Turning');
}

public function bool investigateLocation(vector iLocation)
{	
	investigationLocation = iLocation;	
	if( IsInState('Follow') )
	{
		`log(Pawn.Name $ " is currently following a player. Cannot investigate location: " $ location, true, 'Ravi');
		return false;
	}
	else
	{	
		Pawn.GroundSpeed = SneakToSlimAIPawn(Pawn).ChaseSpeed;		
		GotoState('Investigate');
		return true;
	}
}

function setVisibleSneaktoSlimPawns()
{
	local SneaktoSlimPawn playerWithinVisibleRange;
	local Vector aiLocation;
	local float angleBetweenPlayerAndAI;
	local vector aiLookDirection;
	local vector aiToPlayerDirection;
	local vector hitLocation;
	local vector hitNormal;
	local int numberOfVisiblePlayers;
	local float distAItoTracehit;
	local float distAItoPlayer;

	numberOfVisiblePlayers = 0;
	aiLocation = Pawn.Location;	
	aiLookDirection = vector( Pawn.Rotation );
	
	DrawDebugLine(aiLocation, aiLocation + SneakToSlimAIPawn(Pawn).DetectDistance*aiLookDirection, 255, 0, 0, false);
		
	foreach OverlappingActors( class'SneaktoSlimPawn', playerWithinVisibleRange, SneakToSlimAIPawn(Pawn).DetectDistance, Pawn.Location,)
	{
		DrawDebugLine(aiLocation, playerWithinVisibleRange.Location, 255, 0, 0, false);
		aiToPlayerDirection = Normal(playerWithinVisibleRange.Location - Pawn.Location);
		angleBetweenPlayerAndAI = Acos( aiLookDirection dot aiToPlayerDirection ) * 180/pi;		

		if(angleBetweenPlayerAndAI <= SneakToSlimAIPawn(Pawn).DetectAngle)
		{
			//player is potentially visible, but now we need to check there are no objects between player and AI
			Trace(hitLocation, hitNormal, playerWithinVisibleRange.Location, aiLocation, true,,);
			distAItoTracehit = VSize(hitLocation - aiLocation); 
			distAItoPlayer = VSize(playerWithinVisibleRange.Location - aiLocation);
			// if ray hits the player, hitLocation is where the ray touches the player collider. since collider sphere is around the player, hitLocation will not equal the playerLocation
			DrawDebugLine(aiLocation, hitLocation + (aiToPlayerDirection * playerWithinVisibleRange.CollisionComponent.Bounds.SphereRadius/2), 0, 255, 0, false);
			
			if( (distAItoTracehit + playerWithinVisibleRange.CollisionComponent.Bounds.SphereRadius/2) > distAItoPlayer 
				&& !playerWithinVisibleRange.bInvisibletoAI)
			{
				visiblePlayers.InsertItem(numberOfVisiblePlayers, playerWithinVisibleRange);
				numberOfVisiblePlayers++;				
			}			
		}
	}
	if(numberOfVisiblePlayers == 0)
	{
		visiblePlayers.Length = 0;
		if(IsInState('Follow'))
		{
			lostSightOfPlayer();
		}
	}
	else 
	{
		if( !IsInState('Follow') && visiblePlayers.Length > 0 )
		{
			GoToState('Follow','Startled');
		}
	}
}

function getAiUnstuck()
{
	`log( Pawn.Name $ " is stuck with no reachable waypoints. Teleporting to " $ SneakToSlimAIPawn(Pawn).MyNavigationPoints[0].Name, true, 'Nick A');
	if( SneakToSlimAIPawn(Pawn).MyNavigationPoints.Length > 0 )
	{
		nextPatrolPointIndex = 0;
	}
	Pawn.SetLocation(SneakToSlimAIPawn(Pawn).MyNavigationPoints[0].Location);
}

function turnYaw(float angle)
{
	local rotator myRotation;
	myRotation = Rotation;
	myRotation.Yaw += angle;
	pawn.SetDesiredRotation(myRotation,false,false,1,true);
}

defaultproperties
{	
	
}