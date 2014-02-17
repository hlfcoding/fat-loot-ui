class GuideTrigger extends ITrigger;

var SneaktoSlimGuideController guideController;
var bool IsInInteractionRange;

event Touch(Actor other, PrimitiveComponent otherComp, vector hitLoc, vector hitNormal)
{
	super.Touch(other, otherComp, hitLoc, hitNormal);

	if (Pawn(Other) != none)
    {
        //Ideally, we should also check that the touching pawn is a player-controlled one.
        //PlayerController(Pawn(Other).Controller).myHUD.AddPostRenderedActor(self);
        IsInInteractionRange = true;
    }

}

event UnTouch(Actor other)
{
	super.UnTouch(other);

	if (Pawn(Other) != none)
    {
        //PlayerController(Pawn(Other).Controller).myHUD.RemovePostRenderedActor(self);
        IsInInteractionRange = false;
    }

}

/*simulated event PostRenderFor(PlayerController PC, Canvas Canvas, Vector CameraPosition, Vector CameraDir)
{
    local Font previous_font;
    super.PostRenderFor(PC, Canvas, CameraPosition, CameraDir);
    previous_font = Canvas.Font;
    Canvas.Font = class'Engine'.Static.GetMediumFont(); 
    Canvas.SetPos(400,300);
    Canvas.SetDrawColor(0,255,0,255);
    Canvas.DrawText(Prompt); //Prompt is a string variable defined in our new actor's class.
    Canvas.Font = previous_font; 
}*/

simulated function bool UsedBy(Pawn User)
{
	local bool used;
	
	used = super.UsedBy(User);

	if (IsInInteractionRange)
    {
        //Passes tag name to guide's player controller and activates scripted event
		if(guideController != none)
		{
			guideController.talkingTo = SneakToSlimPawn(User);
			guideController.changeToTutorialState(self.Tag);
			return true;
		}
    }
    return used;
}

DefaultProperties
{
	bStatic = false
	bNoDelete = false

	displayName = "Guide";
	PromtText = "Press 'e' to talk."
	eqGottenText = ""

	Begin Object Class=CylinderComponent NAME=MyMesh
		CollideActors= true
		CollisionRadius=25.000000
        CollisionHeight=44.000000 
	End Object

    //set collision component
    CollisionComponent=MyMesh
	Components.Add(MyMesh)
	bBlockPlayers = true
}
