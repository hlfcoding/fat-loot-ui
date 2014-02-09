class SneaktoSlimSpawnPoint extends trigger;

var SneaktoSlimPawn tempUser;
var() byte teamID;
var() int PlayerBaseRadius;
var StaticMeshComponent CurrentMesh;
var particleSystemComponent baseParticle;
var array<color> teamColor;
var array<Material> teamMaterial;

simulated event PostBeginPlay()
{
	tempUser.PlayerBaseRadius = PlayerBaseRadius;

}


simulated function SetColor()
{
	//	local string materialName;
		//local Material baseMaterial;
	    `log("set coloring of player");
		//CurrentMesh.SetMaterial(0, Material'mypackage.Materials.NodeBuddy_Target_copy');
		//materialName = "NodeBuddies.Materials.NodeBuddy_Player_";
		//materialName $= teamID;	
		//baseMaterial = Material(DynamicLoadObject(materialName, class'Material'));
		baseParticle.SetColorParameter('baseParticleColor', teamColor[teamID]);
		CurrentMesh.SetMaterial(0, teamMaterial[teamID]);
		
}


/*reliable server function ServerSetColors
	CurrentMesh.SetMaterial(0, Material'mypackage.Materials.NodeBuddy_Target_copy');
	ClientSetColor();
}

reliable client function ClientSetColor(){
	`log("client@!#!@#$#!@$");
	CurrentMesh.SetMaterial(0, Material'mypackage.Materials.NodeBuddy_Target_copy');

}*/

event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	local SneaktoSlimPawn temp;
	temp = SneaktoSlimPawn(Other);	

	//`log("SpawnPoint touched",true,'Lu');

	if(temp != none)
	{
		super.Touch(temp, OtherComp, HitLocation, HitNormal);
	   
		//cation! check Actor and team
		//`log("team ID:"@teamID);	
		//`log(temp.GetTeamNum());
	
		if(temp.isGotTreasure == true && temp.GetTeamNum() == teamID)
		{
			temp.turnBackTreasure();
		}
	}		
}

event UnTouch(Actor Other)
{
    super.UnTouch(Other);
 
    //`log("SpawnPoint Untouch",true,'Lu');
}

function bool UsedBy(Pawn User)
{
   `log("SpawnPoint usedBy"@User.Name, true,'Lu');   

   return true;
}



exec function myFunction()
{
   `log("myFunction");
	self.Destroy();

    return;
}

DefaultProperties
{
    
	Begin Object Class=StaticMeshComponent Name=MyMesh
        StaticMesh=StaticMesh'FLInteractiveObject.Base.Base'
		bUsePrecomputedShadows=True
    End Object
 
    CollisionComponent=MyMesh 
    CurrentMesh = MyMesh;
    Components.Add(MyMesh)

	Begin Object Class=ParticleSystemComponent Name=myParticle
		template=ParticleSystem'flparticlesystem.baseParticle'
		bAutoActivate=true
	End Object

	baseParticle = myParticle

	Components.Add(myParticle)

	teamColor[0]=(R=255,G=0,B=0,A=255)
	teamColor[1]=(R=255,G=219,B=1,A=255)
	teamColor[2]=(R=0,G=108,B=255,A=255)
	teamColor[3]=(R=255,G=235,B=170,A=255)

	teamMaterial[0] = Material'NodeBuddies.Materials.NodeBuddy_Player_0'
	teamMaterial[1] = Material'NodeBuddies.Materials.NodeBuddy_Player_1'
	teamMaterial[2] = Material'NodeBuddies.Materials.NodeBuddy_Player_2'
	teamMaterial[3] = Material'NodeBuddies.Materials.NodeBuddy_Player_3'

    bBlockActors=true
    bHidden=false
	bNoDelete=true
	bAlwaysRelevant = true

	teamID = 0;

	Components.Remove(Sprite)

	//isSetColor = false;

}
