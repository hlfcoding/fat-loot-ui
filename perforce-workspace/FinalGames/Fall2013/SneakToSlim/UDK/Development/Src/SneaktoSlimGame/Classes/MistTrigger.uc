class MistTrigger extends Volume;


event Touch(Actor other, PrimitiveComponent otherComp, vector hitLoc, vector hitNormal)
{
	super.Touch(other, otherComp, hitLoc, hitNormal);
	sneaktoslimpawn(other).bInvisibletoAI = true;
	sneaktoslimpawn(other).mistNum = 1;//need to be set to mistTrigger num
}

event UnTouch(Actor other)
{
	`log("Step Out Of Mist");
	//sneaktoslimpawn(other).endinvisibleNum = other.GetTeamNum();
	sneaktoslimpawn(other).bInvisibletoAI = false;
	sneaktoslimpawn(other).mistNum = 0;
}

DefaultProperties
{
	displayName = "Mist";
	PromtText = "";//"You are in the Mist!"
	

    Begin Object Class=CylinderComponent NAME=MyMesh
		CollideActors=true
		CollisionRadius=100
		CollisionHeight=100
		bAlwaysRenderIfSelected=true    
	End Object

    //set collision component
    CollisionComponent=MyMesh 

    //add the new mesh object to trigger’s components
    Components.Add(MyMesh)
    bBlockActors=false //trigger will block players
    bHidden=false //players can see the trigger
	//bNoDelete = true
	bNoEncroachCheck = true     //Enables pawns to move even when overlapping

	scVaseBreakSound = SoundCue'SFX.vaseBreak_test_Cue';
}

