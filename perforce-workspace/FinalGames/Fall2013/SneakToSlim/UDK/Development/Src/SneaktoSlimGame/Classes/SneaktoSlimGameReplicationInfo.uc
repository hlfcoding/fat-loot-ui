class SneaktoSlimGameReplicationInfo extends GameReplicationInfo;

// The time passed in the game, to be replicated to clients
var repnotify float ServerGameTime;
// Whether or not ServerGameTime is changing - if true, ServerGameTime is replicated
var bool bGameTimeChanging;

var float GoalTime;

var repnotify bool IsMatchEnd;

// Replication block
replication
{
	if (bNetDirty && Role==ROLE_Authority)
		ServerGameTime,
		IsMatchEnd;
}

simulated function increaseServerGameTime(name VarName)
{
	ServerGameTime +=1;
	
	if(ServerGameTime >= GoalTime)
	{
		IsMatchEnd = true;
	}
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	if(Role==ROLE_Authority)
		settimer(1.0,true,'increaseServerGameTime');
}

reliable server function cleanServerGameTime()
{
	ServerGameTime = 0;
}


event ReplicatedEvent(name VarName)
{
	sneaktoslimPawn(self.GetALocalPlayerController().pawn).saysometing();
	super.ReplicatedEvent(VarName);
	if( VarName == 'IsMatchEnd')
	{
		`log("Match is ended");
		sneaktoslimPawn(self.GetALocalPlayerController().pawn).saysometing();
		//wuliya = true;
	}

	if ( VarName == 'ServerGameTime')
	{
		`log("fuck you");
	}
}

DefaultProperties
{
	IsMatchEnd = false;
	GoalTime = 12;
}
