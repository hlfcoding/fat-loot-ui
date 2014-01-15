class SneaktoSlimMapInfo extends Object;

DefaultProperties
{
}
/*class SneaktoSlimMapInfo extends MapInfo;

var float mapWidth, mapHeight;      //Determined at postBeginPlay()
var array<PathNode> corners;        //Placed in map editor beforehand
var int test;

reliable client function float setTest(int num)
{
	test = num;
}

unreliable client function float getMapWidth()
{
	return mapWidth;
}
//Calculates current map dimensions based on distance between corner nodes set in editor
//See "Nick P." for more details
reliable server function findMapDimensions()
{
	local PathNode topLeft, topRight, bottomLeft, node;
	local int i;
	local WorldInfo WorldInfo;

	`log("Find dimensions called");
	// Get the WorldInfo instance statically
	WorldInfo = class'WorldInfo'.static.GetWorldInfo();

	foreach WorldInfo.AllActors(class'PathNode', node)
	{
		if(InStr(node.Tag, 'Corner') != -1)
			corners[corners.Length] = node;
	}

	//Breaks if map corners at not placed in editor
	if(corners.Length == 0)
	{
		`log("WARNING: Corners not placed in map");
		return;
	}

	//Gets specify tag corners
	for(i = 0; i < 4; i++)
	{
		if(corners[i].Tag == 'topLeftCorner')
			topLeft = corners[i];
		if(corners[i].Tag == 'topRightCorner')
			topRight = corners[i];
		if(corners[i].Tag == 'bottomLeftCorner')
			bottomLeft = corners[i];
	}

	//Distance formula
	mapWidth = sqrt(square(topLeft.Location.X - topRight.Location.X) + square(topLeft.Location.Y - topRight.Location.Y));
	mapHeight = sqrt(square(topLeft.Location.X - bottomLeft.Location.X) + square(topLeft.Location.Y - bottomLeft.Location.Y));
	`log("Width: " $ mapWidth);
}

DefaultProperties
{
	test = 2;
}*/
