class SneaktoSlimSpawnPoint extends trigger;

var SneaktoSlimPawn tempUser;
var() byte teamID;
var() int PlayerBaseRadius;
var StaticMeshComponent CurrentMesh;
var particleSystemComponent baseParticle;
var array<color> teamColor;
var array<MaterialInstanceConstant> teamMaterial;
var PointLightComponent MyPointLight;

simulated event PostBeginPlay()
{
	if(tempUser != none)
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
		MyPointLight.SetLightProperties(1.0,teamColor[teamID]);
		
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
			playTreasureCapturedParticle();
			temp.turnBackTreasure();
		}
	}		
}

function playTreasureCapturedParticle()
{
	local SneakToSlimPawn current;
	foreach worldinfo.allactors(class 'SneakToSlimPawn', current)
	{
		current.clientSpawnParticle(ParticleSystem'flparticlesystem.treasureCaptureEffect', self.Location,rot(0,0,0));
	}
	//WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'flparticlesystem.treasureCaptureEffect',self.Location);
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
        StaticMesh=StaticMesh'FLInteractiveObject.Base.Base_indoor'
		Translation = (X=0.0,Y=0.0,Z=5.0)
		Scale = 5.0
		//Scale = (X=5.0,Y=5.0,Z=5.0)
		bUsePrecomputedShadows=True
    End Object
 
    CollisionComponent=MyMesh 
    CurrentMesh = MyMesh;
    Components.Add(MyMesh)


	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		bDynamic = TRUE
	End Object
	Components.Add(MyLightEnvironment)
//	LightEnvironment=MyLightEnvironment


	Begin Object Class=ParticleSystemComponent Name=myParticle
		template=ParticleSystem'flparticlesystem.baseParticle'
		bAutoActivate=true
	End Object
	baseParticle = myParticle
	Components.Add(myParticle)

	Begin Object Class=PointLightComponent Name=pPointLight
	  bEnabled=true
	  bCastCompositeShadow = true;
	  bAffectCompositeShadowDirection =true;
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Normal 
	  Radius=192.000000
	  Brightness=1.0
	  LightColor=(R=235,G=235,B=110)
	  Translation =(X=0.0,Y=0.0,Z=40.0)
	End Object
	Components.Add(pPointLight)
	MyPointLight = pPointLight


	/*Begin Object Class=StaticMeshComponent Name=TestMesh
        StaticMesh=StaticMesh'FLInteractiveObject.Base.Base_indoor'
		Translation =(X=0.0,Y=0.0,Z=40.0)
		//Scale = (X=5.0,Y=5.0,Z=5.0)
		bUsePrecomputedShadows=True
    End Object
	Components.Add(TestMesh)*/


	teamColor[0]=(R=128,G=0,B=0,A=255)
	teamColor[1]=(R=255,G=219,B=1,A=255)
	teamColor[2]=(R=0,G=72,B=170,A=255)
	teamColor[3]=(R=170,G=156,B=112,A=255)

	teamMaterial[0] = MaterialInstanceConstant'FLInteractiveObject.Base.base_indoor_material_Red'
	teamMaterial[1] = MaterialInstanceConstant'FLInteractiveObject.Base.base_indoor_material_Green'
	teamMaterial[2] = MaterialInstanceConstant'FLInteractiveObject.Base.base_indoor_material_Blue'
	teamMaterial[3] = MaterialInstanceConstant'FLInteractiveObject.Base.base_indoor_material_White'

    bBlockActors=true
    bHidden=false
	bNoDelete=true
	bAlwaysRelevant = true

	teamID = 0;

	Components.Remove(Sprite)

	//isSetColor = false;

}
