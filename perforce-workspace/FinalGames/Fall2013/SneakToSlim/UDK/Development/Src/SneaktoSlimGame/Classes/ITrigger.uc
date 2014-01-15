class ITrigger extends Trigger;

var string displayName;
var string PromtText;
var string eqGottenText;

event Touch(Actor other, PrimitiveComponent otherComp, vector hitLoc, vector hitNormal)
{
	super.Touch(other, otherComp, hitLoc, hitNormal);
	if(string(other.Class) == "SneaktoSlimPawn")
	{
		SneaktoSlimPawn(other).showPromptUI(PromtText);
		//`log( Name $ " Touched by " $other.Name $ " name is " $ displayName);
		//SneaktoSlimPawn(other).staticHUDmsg.triggerPromtText = PromtText; // local only
		//SneaktoSlimPawn(other).updateStaticHUDPromtText( PromtText);
	}
}

event UnTouch(Actor other)
{
	if(string(other.Class) == "SneaktoSlimPawn")
	{
		SneaktoSlimPawn(other).hidePromptUI();
		//SneaktoSlimPawn(other).showPromptUI("hahaha");
		//SneaktoSlimPawn(other).staticHUDmsg.triggerPromtText = ""; // local only
		//SneaktoSlimPawn(other).updateStaticHUDPromtText("");
	}
}

simulated function bool UsedBy(Pawn User)
{

	//write your code here
	`log("Trigger " $ Name $ " USED  by " $ User.Name);

	if(string(User.Class) == "SneaktoSlimPawn")
	{
		//SneaktoSlimPawn(user).showPromptUI(eqGottenText);
		//SneaktoSlimPawn(User).staticHUDmsg.eqGotten = eqGottenText; // local only
		//SneaktoSlimPawn(User).updateStaticHUDeq(eqGottenText);
		//`log("server tell client to do updateStaticHUDeq to " $ eqGottenText);
		return super.UsedBy(User);
	}
	return false;
}

DefaultProperties
{
	displayName = "trigger interface";
	PromtText = "trigger text default";
	eqGottenText = "trigger eq default"

	Components.Remove(Sprite)
}
