class BuffBottle extends actor placeable;

DefaultProperties
{
	Begin Object Class=StaticMeshComponent Name=MyMesh
        StaticMesh=StaticMesh'FLInteractiveObject.potion.potion4'
		//bUsePrecomputedShadows=True
		//LightEnvironment=MyLightEnvironment
		//CastShadow=true
    End Object
	Components.Add(MyMesh)
	bNoDelete = false;
}
