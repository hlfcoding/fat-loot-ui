class ITrigger extends Trigger;

var string displayName;
var string PromtText;
var string PromtTextXbox;
var string eqGottenText;
var int InRangePawnNumber;
event Touch(Actor other, PrimitiveComponent otherComp, vector hitLoc, vector hitNormal)
{
	super.Touch(other, otherComp, hitLoc, hitNormal);

	if(SneaktoSlimPawn(other)!= None){
		`log("Using Gamepad (ITrigger touch): " $ SneaktoSlimPawn(other).getIsUsingXboxController());
		InRangePawnNumber=SneaktoSlimPawn(other).GetTeamNum();
		if(SneaktoSlimPawn(other).getIsUsingXboxController())
			SneaktoSlimPawn(other).showPromptUI(PromtTextXbox);
		else
			SneaktoSlimPawn(other).showPromptUI(PromtText);
	}
		//`log( Name $ " Touched by " $other.Name $ " name is " $ displayName);
		//SneaktoSlimPawn(other).staticHUDmsg.triggerPromtText = PromtText; // local only
		//SneaktoSlimPawn(other).updateStaticHUDPromtText( PromtText);
}

event UnTouch(Actor other)
{
	if(SneaktoSlimPawn(other)!= None){
		InRangePawnNumber=-1;
	    SneaktoSlimPawn(other).hidePromptUI();
	}
		//SneaktoSlimPawn(other).showPromptUI("hahaha");
		//SneaktoSlimPawn(other).staticHUDmsg.triggerPromtText = ""; // local only
		//SneaktoSlimPawn(other).updateStaticHUDPromtText("");
}

simulated function bool UsedBy(Pawn User)
{

	//write your code here
	`log("Trigger " $ Name $ " USED  by " $ User.Name);

		//SneaktoSlimPawn(user).showPromptUI(eqGottenText);
		//SneaktoSlimPawn(User).staticHUDmsg.eqGotten = eqGottenText; // local only
		//SneaktoSlimPawn(User).updateStaticHUDeq(eqGottenText);
		//`log("server tell client to do updateStaticHUDeq to " $ eqGottenText);
		return super.UsedBy(User);

}

DefaultProperties
{
	displayName = "trigger interface";
	PromtText = "trigger text default";
	PromtTextXbox = "trigger text default";
	eqGottenText = "trigger eq default"
    InRangePawnNumber = -1;
	Components.Remove(Sprite)
}
