class SneaktoSlimPawn_Shorty extends SneaktoSlimPawn;

var() float SHORTY_DASH_SPEED;
var() float MAX_DASH_TIME;
var() float MIN_FIRECRACKER_CHARGE_TIME; //Player must hold the activate button at least this long to trigger a throw
var() float MAX_FIRECRACKER_CHARGE_TIME; //Charging more than this has no effect. The peak distance is reached by this charge time
var() int FIRECRACKER_SPEED_MULTIPLIER; //Firecracker start velocity is ChargeTime * Multiplier
var() vector FIRECRACKER_THROW_DIRECTION; //Relative to where player is looking, what direction must the firecracker be thrown

simulated event PostBeginPlay()
{   
	self.mySkelComp.SetScale(0); //don't show fat lady model
	FIRECRACKER_SPEED_MULTIPLIER = 2.6 * 250 / MAX_FIRECRACKER_CHARGE_TIME;
    Super.PostBeginPlay();
}

event Bump (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitNormal)
{		
	local SneaktoSlimPawn victim;

	if( SneaktoSlimPlayerController_Shorty(Controller).IsInState('Dashing') )
	{
		SneaktoSlimPlayerController_Shorty(Controller).StopDashing();
		if (SneaktoSlimPawn(Other) != none)         //If the belly-bump recipient is another Player...
		{
			victim = SneaktoSlimPawn(Other);
			if(victim.isGotTreasure)
			{            
				victim.dropTreasure();
			}
			checkOtherFLBuff(victim);

			if (SneaktoSlimPlayerController(victim.Controller).GetStateName() != 'InBellyBump')     //if the victim isn't belly-bumping too...
			{
				victim.knockBackVector = Other.Location - self.Location;
				victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.					
				SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//already done by server, no need to call server again
			}
			else if (SneaktoSlimPlayerController(victim.Controller).GetStateName() == 'InBellyBump') //if the victim is belly-bumping too...
			{
				victim.knockBackVector = Other.Location - self.Location;
				victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.
				SneaktoSlimPlayerController(self.Controller).GoToState('BeingBellyBumped');//as above
				SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//as above					
				self.knockBackVector = self.Location - Other.Location;
				self.knockBackVector.Z = 0;					
			}
		}
	}	
}

simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	//`log("Touched an actor", true, 'Ravi');	
}

simulated event HitWall (Object.Vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{	
	//`log("Hit a wall", true, 'Ravi');
	local SneaktoSlimPlayerController_Shorty temp;
	temp = SneaktoSlimPlayerController_Shorty(Controller);

	if( temp != none && temp.IsInState('Dashing') )
	{
		temp.StopDashing();
	}
}

server reliable function listRoles()
{
	local Actor tempA;
	local int index;
	foreach AllActors(class 'Actor', tempA)
	{
		index = InStr( string(tempA.Name), "Sneak" );
		if(  index >= 0 )
			`log("Actor: " $ tempA.Name $ ", RemoteRole: " $ tempA.RemoteRole);
	}
}

DefaultProperties
{
	Begin Object Class=SkeletalMeshComponent Name=ShortySkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.Shorty.Shorty_skeletal'
		AnimSets(0)=AnimSet'FLCharacter.Guard.Guard_Anims'
		AnimTreeTemplate = AnimTree'FLCharacter.Guard.Guard_AnimTree'		
		Translation=(Z=-48.0)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false		
	End Object
	
	Components.Add(ShortySkeletalMesh)

	SHORTY_DASH_SPEED = 500;
	MAX_DASH_TIME = 4.0;
	MIN_FIRECRACKER_CHARGE_TIME = 0.2;
	MAX_FIRECRACKER_CHARGE_TIME = 0.6;	
	FIRECRACKER_THROW_DIRECTION=(X=0,Y=0,Z=0.65)
}
