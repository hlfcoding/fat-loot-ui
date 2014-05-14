class SneakToSlimClothSpawner extends Actor
	placeable;

function SneaktoSlimCloth SpawnCloth()
{
	return spawn(class'SneaktoSlimCloth',,,self.Location);
}
event Touch(Actor other, PrimitiveComponent otherComp, vector hitLoc, vector hitNormal)
{
	//`log( Name $ " Touched by " $other.Name);
}

event UnTouch(Actor Other)
{
    super.UnTouch(Other);
 
    //`log(Other.Name $ " leave " $ Name);
}

defaultproperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		//Sprite = Texture2D'EditorMaterials.MatineeGroups.MAT_Groups_Slomo'
		Sprite=Texture2D'EngineMaterials.DefaultDiffuse'
		Scale = 0.05
	End Object

	Components.Add(Sprite);
}