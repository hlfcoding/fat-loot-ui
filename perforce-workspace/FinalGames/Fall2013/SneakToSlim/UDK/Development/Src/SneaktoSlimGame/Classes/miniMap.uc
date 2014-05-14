class MiniMap extends Actor;

var bool isOn;
var array<Actor> objects;
var Vector playerLocation;

/*simulated function PostBeginPlay()
{
	super.PostBeginPlay();                                               
}*/

function getAllActors()
{
	local Actor obj;
	local int i, radius;

	i = 0;
	radius = 1000;
	//Gets all actors within a certain radius of the player
	//Can modify to grab certain objects
	foreach OverlappingActors(class'Actor', obj, radius)
	{
		objects[i] = obj;
		i++;
	}

	/*for(i = 0; i < objects.Length; i++)
	{
		obj = objects[i];
		`log(obj.Name);
	}*/
}

//Turns map on and gets all nearby actors
function toggleMap()
{
	isOn = !isOn;
	//`log(Name $ " is " $ isOn);
	//if(isOn)
		//getAllActors();
}

DefaultProperties
{
	isOn = false
}
