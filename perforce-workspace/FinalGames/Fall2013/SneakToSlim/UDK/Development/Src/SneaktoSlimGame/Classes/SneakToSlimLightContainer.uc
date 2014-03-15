class SneakToSlimLightContainer extends ITrigger
	placeable;

var () lightsource Light;
var () Spotlight Spotlight1;
var () pointlight Pointlight1;
var () StaticMeshActor LightMesh;

var Material TurnOffTexture;
var Material TurnOnTexture;
var bool IsOn;
var float SpotlightBrightness;
var float PointlightBrightness;

simulated function bool UsedBy(Pawn User)
{
	super.UsedBy(User);
	//write your code here
	`log("Trigger " $ Name $ " USED  by " $ User.Name);

	if(string(User.Class) == "SneaktoSlimPawn")
	{
		SneaktoSlimPawn(user).ToggleLight();
		//SneaktoSlimPawn(User).staticHUDmsg.eqGotten = eqGottenText; // local only
		//SneaktoSlimPawn(User).updateStaticHUDeq(eqGottenText);
		//`log("server tell client to do updateStaticHUDeq to " $ eqGottenText);
		return true;
	}
	return false;
}

Server reliable function ServerToggleLight()
{
	if(Light!=none)
	{
		Light.Toggle();
		if(IsOn==true)
		{
			SpotlightBrightness=Spotlight1.LightComponent.Brightness;
			`Log("i get this light" @Spotlight1.LightComponent.Brightness@Pointlight1,true,'alex');
			Spotlight1.LightComponent.SetLightProperties(0);
			`Log("i get this light" @Spotlight1.LightComponent.Brightness@Pointlight1,true,'alex');
			PointlightBrightness=Pointlight1.LightComponent.Brightness;
			Pointlight1.LightComponent.SetLightProperties(0);
			ClientChangeLightIntensity(Spotlight1,Pointlight1,LightMesh,0,0,TurnOffTexture);
			Spotlight1.LightComponent.UpdateColorAndBrightness();
			Pointlight1.LightComponent.UpdateColorAndBrightness();
			LightMesh.StaticMeshComponent.SetMaterial(0,TurnOffTexture);
			IsOn=false;
		}
		else 
		{
			Spotlight1.LightComponent.SetLightProperties(SpotlightBrightness);
			Pointlight1.LightComponent.SetLightProperties(PointlightBrightness);
			ClientChangeLightIntensity(Spotlight1,Pointlight1,LightMesh,SpotlightBrightness,PointlightBrightness,TurnOnTexture);
			Spotlight1.LightComponent.UpdateColorAndBrightness();
			Pointlight1.LightComponent.UpdateColorAndBrightness();
			LightMesh.StaticMeshComponent.SetMaterial(0,TurnOnTexture);
			IsOn=true;
		}
	}
}

function ClientChangeLightIntensity(Spotlight SpotlightIn, Pointlight PointlightIn, StaticMeshActor LightMeshIn, float SpotlightBrightnessIn, float PointlightBrightnessIn, Material NewMaterialIn)
{
	Local SneaktoSlimPawn Player;

	foreach AllActors(class'SneaktoSlimPawn',Player)
	{
		if(Player!=none)
			Player.ClientChangeLightIntensity(SpotlightIn, PointlightIn, LightMeshIn, SpotlightBrightnessIn, PointlightBrightnessIn, NewMaterialIn);
	}
}

DefaultProperties
{
	displayName = "switch";
	PromtText = "Press E to toggle light";
	PromtTextXbox = "Press 'A' to toggle light";
	eqGottenText = ""

	Begin Object Class=SkeletalMeshComponent Name=LightContainerSkeletalMesh
		SkeletalMesh=SkeletalMesh'EditorMeshes.SkeletalMesh.DefaultSkeletalMesh'
		scale=0.1
	End Object
	Components.Add(LightContainerSkeletalMesh);

	RemoteRole=ROLE_AutonomousProxy
	bAlwaysRelevant=true
	bHidden=false
	IsOn=true
	TurnOffTexture=Material'mypackage.Materials.M_ES_Phong_Opaque_Master_01'
	TurnOnTexture=Material'mypackage.Materials.NodeBuddy_Target_copy'
}
