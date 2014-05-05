class GuideTrigger extends ITrigger;

var SneaktoSlimGuidePawn guidePawn;
var SneaktoSlimPawn fatlady;

event Touch(Actor other, PrimitiveComponent otherComp, vector hitLoc, vector hitNormal)
{
	//super.Touch(other, otherComp, hitLoc, hitNormal);

	//if (Pawn(Other) != none)
   // {
        //Ideally, we should also check that the touching pawn is a player-controlled one.
        //PlayerController(Pawn(Other).Controller).myHUD.AddPostRenderedActor(self);
    //}

}

event UnTouch(Actor other)
{
	//super.UnTouch(other);

	//if (Pawn(Other) != none)
   // {
        //PlayerController(Pawn(Other).Controller).myHUD.RemovePostRenderedActor(self);
   // }
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

    //Passes tag name to guide's player controller and activates scripted event
	if(guidePawn != none)
	{
		guidePawn.talkingTo = SneakToSlimPawn(User);
		guidePawn.changeToTutorialState(self.Tag);
		return true;
	}
    return used;
}

//Inefficiently checks if tutorial player is within range of this trigger and prints prompt text if so
event Tick(float deltaTime)
{
	local SneaktoSlimPawn pa;
	local bool isInRange;

	isInRange = false;
	foreach CollidingActors(class'SneaktoSlimPawn', pa, 100)
	{
		fatlady = pa;
		isInRange = true;
	}

	if(fatlady != none)
	{
		if(isInRange)
		{
			if(SneaktoSlimPlayerController(fatlady.Controller).PlayerInput.bUsingGamepad)
				PromtText = "Press 'A' to talk.";
			else
				PromtText = "Click 'e' to talk.";
			fatlady.showPromptUI(self.PromtText);
		}
		else
			fatlady.hidePromptUI();
	}

	super.Tick(deltaTime);
}

DefaultProperties
{
	bStatic = false
	bNoDelete = false

	displayName = "Guide";
	eqGottenText = ""

	//bBlockPlayers = true      //Needed?
}
