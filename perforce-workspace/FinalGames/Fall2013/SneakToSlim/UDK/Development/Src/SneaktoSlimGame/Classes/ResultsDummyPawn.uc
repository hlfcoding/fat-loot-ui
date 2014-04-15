class ResultsDummyPawn  extends GamePawn;

var DynamicLightEnvironmentComponent LightEnvironment;
var string characterType;
var int score;
var bool hasWon;
var int playerColorIndex;

function updateMesh(int index)
{
	playerColorIndex = index;

	if(characterType == "FatLady")
	{
		Mesh.SetSkeletalMesh(SkeletalMesh'FLCharacter.lady.new_lady_skeletalmesh');	
		Mesh.AnimSets[0] = AnimSet'FLCharacter.lady.Lady_Anims';	
		Mesh.SetAnimTreeTemplate(AnimTree'FLCharacter.lady.lady_AnimTree');
		Mesh.SetMaterial(0, Material'FLCharacter.lady.EyeMaterial');
		switch(index)
		{
			case 0: Mesh.SetMaterial(1, MaterialInstanceConstant 'FLCharacter.lady.lady_material_0');
					break;
			case 1: Mesh.SetMaterial(1, MaterialInstanceConstant 'FLCharacter.lady.lady_material_1');
					break;
			case 2: Mesh.SetMaterial(1, MaterialInstanceConstant 'FLCharacter.lady.lady_material_2');
					break;
			case 3: Mesh.SetMaterial(1, MaterialInstanceConstant 'FLCharacter.lady.lady_material_3');
					break;
		}
	}
	if(characterType == "GinsengBaby")
	{
		Mesh.SetSkeletalMesh(SkeletalMesh'FLCharacter.GinsengBaby.GinsengBaby_skeletal');	
		Mesh.AnimSets[0] = AnimSet'FLCharacter.GinsengBaby.GinsengBaby_animsets';	
		Mesh.SetAnimTreeTemplate(AnimTree'FLCharacter.GinsengBaby.GinsengBaby_anim_tree');
		switch(index)
		{
			case 0: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.GinsengBaby.GinsengBaby_material_0');
					Mesh.SetMaterial(1, MaterialInstanceConstant 'FLCharacter.GinsengBaby.GinsengBaby_material_0');
					break;
			case 1: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.GinsengBaby.GinsengBaby_material_1');
					Mesh.SetMaterial(1, MaterialInstanceConstant 'FLCharacter.GinsengBaby.GinsengBaby_material_1');
					break;
			case 2: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.GinsengBaby.GinsengBaby_material_2');
					Mesh.SetMaterial(1, MaterialInstanceConstant 'FLCharacter.GinsengBaby.GinsengBaby_material_2');
					break;
			case 3: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.GinsengBaby.GinsengBaby_material_3');
					Mesh.SetMaterial(1, MaterialInstanceConstant 'FLCharacter.GinsengBaby.GinsengBaby_material_3');
					break;
		}
	}
	if(characterType == "Rabbit")
	{
		Mesh.SetSkeletalMesh(SkeletalMesh'FLCharacter.Rabbit.rabbit_skeletal');	
		Mesh.AnimSets[0] = AnimSet'FLCharacter.Rabbit.Rabbit_Animsets';	
		Mesh.SetAnimTreeTemplate(AnimTree'FLCharacter.Rabbit.rabbit_AnimTree');
		switch(index)
		{
			case 0: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.Rabbit.Rabbit_material_0');
					break;
			case 1: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.Rabbit.Rabbit_material_1');
					break;
			case 2: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.Rabbit.Rabbit_material_2');
					break;
			case 3: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.Rabbit.Rabbit_material_3');
					break;
		}
	}
	if(characterType == "Shorty")
	{
		Mesh.SetSkeletalMesh(SkeletalMesh'FLCharacter.Shorty.Shorty_skeletal');	
		Mesh.AnimSets[0] = AnimSet'FLCharacter.Shorty.Shorty_Anims';	
		Mesh.SetAnimTreeTemplate(AnimTree'FLCharacter.Shorty.Shorty_AnimTree');
		switch(index)
		{
			case 0: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.Shorty.Shorty_material_0');
					break;
			case 1: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.Shorty.Shorty_material_1');
					break;
			case 2: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.Shorty.Shorty_material_2');
					break;
			case 3: Mesh.SetMaterial(0, MaterialInstanceConstant 'FLCharacter.Shorty.Shorty_material_3');
					break;
		}
	}
}

function playAnimation()
{
	local AnimNodePlayCustomAnim customNode;

	if(hasWon)
	{
		customNode = AnimNodePlayCustomAnim(self.Mesh.FindAnimNode('customWin'));
		if(customNode == None)
		{
			`log("Invalid custom node name",false,'Lu');
			return;
		}
		customNode.PlayCustomAnim('Win', 1, 1, 1, true, true);
	}
	else
	{
		customNode = AnimNodePlayCustomAnim(self.Mesh.FindAnimNode('customLose'));
		if(customNode == None)
		{
			`log("Invalid custom node name",false,'Lu');
			return;
		}
		customNode.PlayCustomAnim('Lose', 1, 1, 1, true, true);
	}
}

DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		bDynamic = TRUE
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object Class=SkeletalMeshComponent Name=InitialSkeletalMesh	
		SkeletalMesh = SkeletalMesh'FLCharacter.lady.new_lady_skeletalmesh'		
		AnimSets(0)=AnimSet'FLCharacter.lady.new_lady_Anims'		
		AnimTreeTemplate = AnimTree'FLCharacter.lady.lady_AnimTree_copy'		
		LightEnvironment=MyLightEnvironment
		CastShadow=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false		
	End Object

    Components.Add(InitialSkeletalMesh)	
	Mesh = InitialSkeletalMesh

	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+0044.000000
	End Object
	CylinderComponent=CollisionCylinder
}
