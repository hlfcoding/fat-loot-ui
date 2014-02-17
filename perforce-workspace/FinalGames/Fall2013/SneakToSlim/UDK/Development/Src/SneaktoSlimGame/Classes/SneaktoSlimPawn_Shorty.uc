class SneaktoSlimPawn_Shorty extends SneaktoSlimPawn;

var() float SHORTY_DASH_SPEED; //Speed at which Shorty starts dashing. He decelerates over time
var() float MAX_DASH_TIME;     //Max duration Shorty can Dash in one sprint
var() int DASH_ENERGY_CONSUMPTION_RATE; 
var() float DASH_CHARGE_VS_MOVE_DURATION_FACTOR; //Duration charge key is pressed VS duration Shorty dashes
var() float MIN_FIRECRACKER_CHARGE_TIME; //Player must hold the activate button at least this long to trigger a throw
var() float MAX_FIRECRACKER_CHARGE_TIME; //Charging more than this has no effect. The peak distance is reached by this charge time
var() int FIRECRACKER_SPEED_MULTIPLIER; //Firecracker launch velocity is ChargeTime * Multiplier
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
	FLWalkingSpeed=200.0
	GroundSpeed=200.0;

	Begin Object Class=SkeletalMeshComponent Name=ShortySkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.Shorty.Shorty_skeletal'
		AnimSets(0)=AnimSet'FLCharacter.Shorty.Shorty_Anims'
		AnimTreeTemplate = AnimTree'FLCharacter.Shorty.Shorty_AnimTree'		
		Translation=(Z=-52.0)
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false		
	End Object
	
	Components.Add(ShortySkeletalMesh)
	Mesh = ShortySkeletalMesh

	SHORTY_DASH_SPEED = 1000;
	MAX_DASH_TIME = 2.0;
	DASH_ENERGY_CONSUMPTION_RATE = 40;
	DASH_CHARGE_VS_MOVE_DURATION_FACTOR = 1.5;
	MIN_FIRECRACKER_CHARGE_TIME = 0.2;
	MAX_FIRECRACKER_CHARGE_TIME = 0.6;	
	FIRECRACKER_THROW_DIRECTION=(X=0,Y=0,Z=0.65)

	characterName = "Shorty";

	//Material'FLCharacter.GinsengBaby.GinsengBaby_material_0'
}
