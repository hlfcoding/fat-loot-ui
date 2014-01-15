class vase_staticmesh extends StaticMeshActor placeable;

DefaultProperties
{
    Begin Object Class=CylinderComponent NAME=CollisionCylinder
		CollideActors=true
		CollisionRadius=20
		CollisionHeight=20
		bAlwaysRenderIfSelected=true    
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

}
