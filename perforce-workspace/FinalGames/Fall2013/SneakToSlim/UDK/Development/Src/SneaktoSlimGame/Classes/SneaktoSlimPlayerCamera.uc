class SneaktoSlimPlayerCamera extends Camera;

var Vector CamOffset;
var float CameraZOffset;
var float CameraScale, CurrentCameraScale; /** multiplier to default camera distance */
var float CameraScaleMin, CameraScaleMax;

var float Dist;
var float TargetFOV;
var float TargetZ;
var float Z;
var float TargetOffset;
var float Offset;
var float pival;

var name PreSprintCamera;
var name PreVaseCamera;

var bool invisFarExtent;



var array<Actor> actualHitActors;
var int lastHitAccount;

//var Actor MeshesToShow[5];
//var int NoOfMeshesToShow;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
//	SetTimer(0.04, true, 'ReShowMesh'); //Shows objects hidden due to camera-culling. Checks every 0.04 seconds
}

function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
   //Declaring local variables
	local vector            Loc, Pos, HitLocation, HitNormal;
	local rotator           Rot;
	local Actor                     HitActor;
	local CameraActor       CamActor;
	local bool                      bDoNotApplyModifiers;
	local TPOV                      OrigPOV;

	//local StaticMeshActor hitStaticMeshActor;
	//local MaterialInstanceConstant newHitMaterial;
	//local Material hitMaterial;
	//local float opacity;
	//local string desc;
	//local int i;
	//local string materialName;
	//local string packageName;
	//local int stringPos;
	local float LERPincrement;

	//local array<Actor> actualHitActors;

	//local int lastHitAccount;

	// store previous POV, in case we need it later
	OrigPOV = OutVT.POV;
 
	// Default FOV on viewtarget
	OutVT.POV.FOV = DefaultFOV;
 
	// Viewing through a camera actor.
	CamActor = CameraActor(OutVT.Target);
	if( CamActor != None )
	{
		CamActor.GetCameraView(DeltaTime, OutVT.POV);
		// Grab aspect ratio from the CameraActor.
		bConstrainAspectRatio   = bConstrainAspectRatio || CamActor.bConstrainAspectRatio;
		OutVT.AspectRatio               = CamActor.AspectRatio;
 
		// See if the CameraActor wants to override the PostProcess settings used.
		CamOverridePostProcessAlpha = CamActor.CamOverridePostProcessAlpha;
		CamPostProcessSettings = CamActor.CamOverridePostProcess;
	}
	else
	{
		// Give Pawn Viewtarget a chance to dictate the camera position.
		// If Pawn doesn't override the camera view, then we proceed with our own defaults
		if( Pawn(OutVT.Target) == None ||
		!Pawn(OutVT.Target).CalcCamera(DeltaTime, OutVT.POV.Location, OutVT.POV.Rotation, OutVT.POV.FOV) )
		{
			// don't apply modifiers when using these debug camera modes.
			bDoNotApplyModifiers = FALSE;

			switch(CameraStyle)
			{
				case 'Fixed' : // No update, keeps previous view
				OutVT.POV = OrigPOV;
				break;
				case 'ThirdPerson' :    //Third-Person Camera
				case 'IsometricCam' :   //Isometric camera
				case 'ShoulderCam' :    //Over-the-shoulder Camera
				case 'AlertCam' :
				case 'VaseCam' :
				case 'FirstPerson': //First-person
				case 'FreeCam' :
				
 
				Loc = OutVT.Target.Location; // Setting the camera location and rotation to the viewtarget's
				Rot = OutVT.Target.Rotation;
				
				if(SneaktoSlimPawn(PCOwner.Pawn).Mesh.bOwnerNoSee == true)
					SneaktoSlimPawn(PCOwner.Pawn).Mesh.SetOwnerNoSee(false);
				if (CameraStyle == 'ThirdPerson')
				{
					Rot = PCOwner.Rotation; //setting the rotation of the camera to the rotation of the pawn
					Rot.Pitch = Rot.Pitch - 2200;
					TargetZ = 0;
					TargetFOV = 60.0;
					TargetOffset = 0;
					FreeCamDistance = 256.f;
				}
				if (CameraStyle == 'IsometricCam') 
				{
					Rot = PCOwner.Rotation;
					Rot.pitch = -16384;
					//Rot.yaw = 10000;              //Fixing the camera at these rotation values
					//-8192;
					//TargetZ = 300;
					TargetFOV = 100.f;
					FreeCamDistance = 600;
 
				}
				if (CameraStyle == 'ShoulderCam')
				{
					Rot = PCOwner.Rotation;
					Rot.Pitch = Rot.Pitch - 2000;   //Might not be needed. Check it.
					FreeCamDistance = 50;           //64;
					TargetZ = 5;                    //32;
					TargetOffset = 16;
					TargetFOV = 100.f;
				}
				if (CameraStyle == 'AlertCam')  //FOV changes by 1 part, FreeCamDistance by 2 parts
				{
					Rot = PCOwner.Rotation;
					Rot.Pitch = Rot.Pitch - 2000;
					
					if (invisFarExtent == false)    
					{
						TargetFOV = 60.f;
						FreeCamDistance = 240;
						if (DefaultFOV > 59.f && DefaultFOV < 61.f)
							invisFarExtent = true;
					}
					else
					{
						TargetFOV = 80.f;
						FreeCamDistance = 200;           //64;
						if (DefaultFOV > 79.f && DefaultFOV < 81.f)
							invisFarExtent = false;
					}            
					TargetZ = 5;                    
				}
				if (CameraStyle == 'VaseCam')
				{
					Rot = PCOwner.Rotation; //setting the rotation of the camera to the rotation of the pawn
					Rot.Pitch = Rot.Pitch - 2200;
					TargetZ = 20;
					TargetFOV = 120.0;
					TargetOffset = 0;
					FreeCamDistance = 256.f;
				}
				if (CameraStyle == 'FirstPerson')       //WATCH OUT: I'm not using the mesh's eye-bone!! The camera is actually just at the top of her head, because the eyes-height felt too short.
				{
					//OutVT.Target.GetActorEyesViewPoint(Loc, Rot);
					Rot = PCOwner.Rotation;
					TargetZ = 0;
					TargetFOV = 70.0;
					TargetOffset = 0;
					FreeCamDistance = 0.f;
					if(SneaktoSlimPawn(PCOwner.Pawn).Mesh.bOwnerNoSee == false)
						SneaktoSlimPawn(PCOwner.Pawn).Mesh.SetOwnerNoSee(true);
				}
				//if(SneaktoSlimPawn(PCOwner.Pawn).s_energized == 1)
					//TargetFOV = 100.f;              // FUDGE YEA!!
 
				if(CameraStyle == 'FreeCam')
				{
				Rot = PCOwner.Rotation;
				}
 
				Loc += FreeCamOffset >> Rot;
				Loc.Z += Z; // Setting the Z coordinate offset for shoulder view
				if (CameraStyle == 'AlertCam')
					LERPincrement = 0.01;
				else
					LERPincrement = 0.05;
				//Linear interpolation algorithm. This is the "smoothing," so the camera doesn't jump between zoom levels
				if (Dist != FreeCamDistance)
				{
					Dist = Lerp(Dist,FreeCamDistance,LERPincrement); //Increment Dist towards FreeCamDistance, which is where you want your camera to be. Increments a percentage of the distance between them according to the third term, in this case, 0.15 or 15%
				}
				if (Z != TargetZ)
				{
					Z = Lerp(Z,TargetZ,LERPincrement);
				}
				if (DefaultFOV != TargetFOV)
				{
					DefaultFOV = Lerp(DefaultFOV,TargetFOV,LERPincrement);
				}
				if (Offset != TargetOffset)
				{
					Offset = Lerp(Offset,TargetOffset,LERPincrement);
				}
 
				Pos = Loc - Vector(Rot) * Dist;
				// Setting the XY camera offset for shoulder view
				Pos.X += Offset*sin(-Rot.Yaw*pival*2/65536);
				Pos.Y += Offset*cos(Rot.Yaw*pival*2/65536);
				// @fixme, respect BlockingVolume.bBlockCamera=false
 
				HitActor = Trace(HitLocation, HitNormal, Pos, Loc, FALSE, vect(12,12,12));

				//for(i=0;i<actualHitActors.Length;i++){
				//	hitMaterial = Material(StaticMeshActor(actualHitActors[i]).StaticMeshComponent.GetMaterial(0));
				//	materialName = string(hitMaterial.Name);
				//	packageName = string(hitMaterial.GetPackageName());
				//	stringPos = InStr(materialName,"_translucent");
				//	materialName = Mid(materialName,0,stringPos);
				//	packageName$=".";
				//	packageName$=materialName;
				//	//hitMaterial = Material(DynamicLoadObject(packageName,class'Material'));
				//	StaticMeshActor(actualHitActors[i]).StaticMeshComponent.SetMaterial(0,hitMaterial);
				//}

				//actualHitActors.Remove(0,actualHitActors.Length);
				

				//foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, Pos, Loc, vect(12,12,12))
				//{
				//	if (HitActor != None)
				//	{
				//		//----start temp code for making walls transparent
				//		hitStaticMeshActor = StaticMeshActor(HitActor);
				//		if(hitStaticMeshActor==None)
				//			continue;

				//		hitMaterial = Material(hitStaticMeshActor.StaticMeshComponent.GetMaterial(0));
				//		/*if (hitMaterialInstanceConstant == None)
				//			//continue ;
						
				//		hitMaterial = hitMaterialInstanceConstant.GetMaterial();

				//		if(HitActor.bHidden == false)
				//		{
				//			HitActor.SetHidden(true);
				//			MeshesToShow[NoOfMeshesToShow] = HitActor;
				//			NoOfMeshesToShow += 1;
				//			//SetTimer(0.04, false, 'ReShowMesh');
				//			//HitActor.SetHidden(false);
				//		}*/


						
				//		hitMaterial.GetParameterDesc('Opacity',desc);
				//		if(desc=="")
				//			continue;
				//		materialName = string(hitMaterial.Name); 
				//		packageName = string(hitMaterial.GetPackageName());
				//		if(hitMaterial.BlendMode != EBlendMode(BLEND_Translucent)){
				//			//newHitMaterial = new(none) class'Material'; 
				//			materialName $= "_translucent";
				//			packageName $=".";
				//			packageName $=materialName;
				//			//hitMaterial = Material(DynamicLoadObject(packageName, class'Material'));
				//			/*hitMaterialInstance.GetTextureParameterValue('Diffuse', textureValue); 
				//			matInstanceConstant.SetTextureParameterValue('Diffuse', textureValue); 
				//			hitMaterialInstance.GetTextureParameterValue('Normal', textureValue); 
				//			 matInstanceConstant.SetTextureParameterValue('Normal', textureValue); 
				//			 hitMaterialInstance.GetTextureParameterValue('NormalDetail', textureValue); 
				//			 matInstanceConstant.SetTextureParameterValue('NormalDetail', textureValue); 
				//			 hitMaterialInstance.GetTextureParameterValue('Spec', textureValue); 
				//			matInstanceConstant.SetTextureParameterValue('Spec', textureValue); */
				//			//newHitMaterialInstanceConstant.SetParent(hitMaterial);
				//			//newHitMaterialInstanceConstant.SetScalarParameterValue('Opacity',0.5);
				//			hitStaticMeshActor.StaticMeshComponent.SetMaterial(0,hitMaterial);
				//			actualHitActors.AddItem(hitActor);
				//		}
				//	}
				//}
				if (CameraStyle != 'IsometricCam')
				{
					if (HitActor != None && (HitActor.Tag == 'Wall' || HitActor.Tag == 'wall_edge' || HitActor.Tag == 'wall_pillar'))
						OutVT.POV.Location = HitLocation;
					else
						OutVT.POV.Location = Pos;
				}
				else
					OutVT.POV.Location = Pos;
				OutVT.POV.Rotation = Rot;
 
				break; //This is where our code leaves the switch-case statement, preventing it from executing the commands intended for the FirstPerson case.
 
				//case 'FirstPerson' : // Simple first person, view through viewtarget's 'eyes'
				//default : OutVT.Target.GetActorEyesViewPoint(OutVT.POV.Location, OutVT.POV.Rotation);
				//break;


			}
		}
	}
	if( !bDoNotApplyModifiers )
	{
		ApplyCameraModifiers(DeltaTime, OutVT.POV);
	}
}

simulated function ReShowMesh()
{
	
/*	local StaticMeshActor hitStaticMesh;
	local MaterialInstanceConstant hitMaterialInstance;
	local Material hitMaterial;
	local int i;
	for (i = NoOfMeshesToShow; i>0; i--)
	{
		//MeshesToShow[i - 1].SetHidden(false);
		hitStaticMesh = StaticMeshActor(MeshesToShow[i-1]);
		hitMaterialInstance = MaterialInstanceConstant(hitStaticMesh.StaticMeshComponent.GetMaterial(0));
		hitMaterial = hitMaterialInstance.GetMaterial();
		hitMaterial.BlendMode = EBlendMode(BLEND_Opaque);
		hitStaticMesh.StaticMeshComponent.SetMaterial(0,hitMaterialInstance);
	}
	//NoOfMeshesToShow -= 1;
	NoOfMeshesToShow = 0;*/



	/*local int i;
	if (NoOfMeshesToShow > 0)
	{
		MeshesToShow[0].SetHidden(false);
		/*hitStaticMesh = StaticMeshActor(MeshesToShow[0]);
		hitMaterialInstance = MaterialInstanceConstant(hitStaticMesh.StaticMeshComponent.GetMaterial(0));
		hitMaterial = hitMaterialInstance.GetMaterial();
		hitMaterial.BlendMode = EBlendMode(BLEND_Opaque);
		hitStaticMesh.StaticMeshComponent.SetMaterial(0,hitMaterialInstance);*/

		for (i = 0; i<NoOfMeshesToShow; i++)
		{
			MeshesToShow[i] = MeshesToShow[i+1];
		}
		NoOfMeshesToShow -= 1;
	}*/
}

defaultproperties
{
   CamOffset=(X=20.0,Y=0.0,Z=-50.0)
   CurrentCameraScale=1.0
   CameraScale=9.0
   CameraScaleMin=3.0
   CameraScaleMax=40.0

	FreeCamDistance = 256.f
    pival = 3.14159;

	invisFarExtent = false;

	//NoOfMeshesToShow = 0;
}
