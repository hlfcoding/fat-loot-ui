class SneaktoSlimBuddhaPalm extends Projectile;

var StaticMeshComponent buddhaPalmMesh;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local SneaktoSlimPawn victim;
	super.Touch(Other, OtherComp, HitLocation, HitNormal);

	`log("PALM TOUCHED SOMEBODY!!");
	victim = SneaktoSlimPawn(Other);
	if (victim != None)
	{
		`log("PALM TOUCHED AN STSPAWN!!");
		victim.knockBackVector = (victim.Location - self.Location);
		victim.knockBackVector = 150 * Normal(victim.knockBackVector);
			//2000 * Normal(victim.knockBackVector);
		victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.
		
		SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');
		SneaktoSlimPlayerController(victim.Controller).attemptToChangeState('BeingBellyBumped');
	}
}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent   Name=BuddhaPalmMesh
		StaticMesh= StaticMesh'FLCharacter.Character.hand'
		CastShadow= true
		Scale= 1.00
		//Rotation=(Pitch=0,Yaw=16383,Roll=0)
        CollideActors=true
		BlockActors=true
		BlockNonZeroExtent=true
		BlockZeroExtent=true
	End Object	

	//StaticMesh= StaticMesh'FLCharacter.Character.hand'
	//StaticMesh=StaticMesh'FLInteractiveObject.treasure.Tresure'	
	Components.Add(BuddhaPalmMesh)
	buddhaPalmMesh = BuddhaPalmMesh

	bCollideActors=true
	MaxSpeed=+0800.000000
	Speed=+0800.000000
	LifeSpan=+003.000000
	bCanBeDamaged=false
}
