class vaseFracturedActor extends FracturedSMActorSpawnable;

DefaultProperties
{
	Begin Object Name=FracturedStaticMeshComponent0
        StaticMesh=FracturedStaticMesh'FLInteractiveObject.vase.vase_1_FRACTURED'
		Scale=1.4
		Translation=(X=0.000000,Y=0.000000,Z=-32.000000)
		bUsePrecomputedShadows=True
        bspawnphysicschunks = false;
    End Object

	//Components.Add(MyMesh);
	//bCausesFracture = True
	bNoDelete=false
	bBlocksNavigation= true;
	//bCausesFracture=true;
}
