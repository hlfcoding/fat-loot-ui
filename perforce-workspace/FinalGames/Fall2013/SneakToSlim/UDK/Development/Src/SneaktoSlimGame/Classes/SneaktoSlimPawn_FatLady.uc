class SneaktoSlimPawn_FatLady extends SneaktoSlimPawn;

simulated event ReplicatedEvent(name VarName)
{
	local SneaktoSlimPawn pa;
	super.ReplicatedEvent(VarName);
	if( VarName == 'isGotTreasure')
	{
		if(self.isGotTreasure == true)
		{
			foreach WorldInfo.AllPawns(class 'SneaktoSlimPawn', pa)
			{
				pa.showCharacterHasTreasure(self.GetTeamNum());
			}

			`log("authority"$ self.Role);
			`log(self.Mesh.GetSocketByName('treasureSocket'));
			if (self.Mesh.GetSocketByName('treasureSocket') != None){
				self.Mesh.AttachComponentToSocket(treasureComponent , 'treasureSocket');
				self.Mesh.AttachComponentToSocket(treasureLightComponent , 'treasureSocket');
			}			
			SetTreasureParticleEffectActive(true);

			if(SneaktoSlimPlayerController_FatLady(Self.Controller).IsInState('Exhausted'))
			{
				SneaktoSlimPlayerController_FatLady(Self.Controller).attemptToChangeState('HoldingTreasureExhausted');//to server
				SneaktoSlimPlayerController_FatLady(Self.Controller).GotoState('HoldingTreasureExhausted');//local
				`log("Going to HT_Exhausted");
			}
			else if(SneaktoSlimPlayerController_FatLady(Self.Controller).IsInState('Sprinting'))
			{
				SneaktoSlimPlayerController_FatLady(Self.Controller).attemptToChangeState('HoldingTreasureSprinting');//to server
				SneaktoSlimPlayerController_FatLady(Self.Controller).GotoState('HoldingTreasureSprinting');//local
				`log("Going to HT_Sprinting");
			}
			else
			{
				SneaktoSlimPlayerController_FatLady(Self.Controller).attemptToChangeState('HoldingTreasureWalking');//to server
				SneaktoSlimPlayerController_FatLady(Self.Controller).GotoState('HoldingTreasureWalking');//local
				`log("Going to HT_Walking");
			}

		}
		else
		{
			foreach WorldInfo.AllPawns(class 'SneaktoSlimPawn', pa)
			{
				pa.showCharacterLostTreasure(self.GetTeamNum());
			}

			if (self.Mesh.IsComponentAttached(treasureComponent)){
				self.Mesh.DetachComponent(treasureComponent);
				self.Mesh.DetachComponent(treasureLightComponent);
			}				
			self.changeCharacterMaterial(self,self.GetTeamNum(),"Character");
			self.SetTreasureParticleEffectActive(false);			
			SneaktoSlimPlayerController_FatLady(self.Controller).DropTreasure();
		}
	}
}

simulated event PostBeginPlay()
{
	local SneakToSlimGuideController pc;

    super.PostBeginPlay();

	foreach WorldInfo.AllControllers(class 'SneakToSlimGuideController', pc)
	{
		//Forces
		if(!pc.isActive)
		{
			pc.talkingTo = self;
			pc.changeToTutorialState('HowToMove');	
		}
		break;
	}
 }

event Bump (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitNormal)
{	
	local SneaktoSlimAIPawn HitActor;
	local SneaktoSlimAINavMeshController HitController;
	local SneaktoSlimPawn victim;

	if(!bInvulnerable)
	{
		//code for when Player belly-bumps into something else
		if(SneaktoSlimPlayerController(self.Controller).GetStateName() == 'InBellyBump')
		{

			if (SneaktoSlimPawn(Other) != none)         //If the belly-bump recipient is another Player...
			{
				victim = SneaktoSlimPawn(Other);
				if(victim.isGotTreasure){            //if the victim is holding treasure...
					victim.dropTreasure(Normal(vector(self.rotation)));         //...she drops it.
				}
				`log("bump Particle");		
				
				checkOtherFLBuff(victim);

				//Unreliable! Since bump is updated with each tick and both pawn might still be in contact for several frames
				/*if(SneaktoSlimPlayerController(victim.Controller).GetStateName() != 'BeingBellyBumped')
				{
					SneaktoSlimPlayerController(victim.Controller).incrementBellyBumpHitBys();
					`log("Hit by count: " $ SneaktoSlimPlayerController(victim.Controller).getBBHitByCount());
					self.incrementBellyBumpHits();
					`log("Hit count: " $ self.getBBHitCount());
				}*/
				
				if (SneaktoSlimPlayerController(victim.Controller).GetStateName() != 'InBellyBump')     //if the victim isn't belly-bumping too...
				{
					victim.knockBackVector = Other.Location - self.Location;
					victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.					
					SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//already done by server, no need to call server again

					//`log(victim.Name $ " is BeingBellyBumped");
					
				}
				else if (SneaktoSlimPlayerController(victim.Controller).GetStateName() == 'InBellyBump') //if the victim is belly-bumping too...
				{
					victim.knockBackVector = Other.Location - self.Location;
					victim.knockBackVector.Z = 0; //attempting to keep the hit player grounded.
					//need to deactivate dash for either here? --ANDY
					//Other.TakeDamage(0, none, victim.Location, knockBackVector * 500, class'DamageType');
					//victim.bOOM = true;
					//victim.setTimer(1,false,'FOOM');

					SneaktoSlimPlayerController(self.Controller).GoToState('BeingBellyBumped');//as above
					SneaktoSlimPlayerController(victim.Controller).GoToState('BeingBellyBumped');//as above					
					self.knockBackVector = self.Location - Other.Location;
					self.knockBackVector.Z = 0;
					
				}
			}
			else
			{
					//belly-bump stun here for self.
					//SneaktoSlimPawn(Other).StunPlayer(2);
					`log("BUMPING INTO SOMETHING ELSE!", true, 'ANDY');
					//THE FOLLOWING SECTION OF CODE SEEMS BADLY PLACED. ASK WHOEVER AND CHECK IT WHEN POSSIBLE --ANDY
					foreach CollidingActors( class'SneakToSlimAIPawn', HitActor, 200,)
					{
						HitController = SneakToSlimAINavMeshController(HitActor.Controller);
						HitController.investigateLocation(HitActor.Location);
					}
			}
		}

	}
}

//REPLICATE IN OTHER PAWNS WITH ACCORDING LOGIC
event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	local SneaktoSlimSpawnPoint playerBase;
	playerBase = SneaktoSlimSpawnPoint(Other);	

	if(playerBase != none)
	{	
		//`log("Pawn touching SpawnPoint");
		if (SneaktoSlimPlayerController(self.Controller).IsInState('HoldingTreasureExhausted'))
		{
			SneaktoSlimPlayerController(self.Controller).attemptToChangeState('Exhausted');
			SneaktoSlimPlayerController(self.Controller).GoToState('Exhausted');//local
		}
		if (SneaktoSlimPlayerController(self.Controller).IsInState('HoldingTreasureSprinting'))
		{
			SneaktoSlimPlayerController(self.Controller).attemptToChangeState('Sprinting');
			SneaktoSlimPlayerController(self.Controller).GoToState('Sprinting');//local
		}
		if (SneaktoSlimPlayerController(self.Controller).IsInState('HoldingTreasureWalking'))
		{
			SneaktoSlimPlayerController(self.Controller).attemptToChangeState('PlayerWalking');
			SneaktoSlimPlayerController(self.Controller).GoToState('PlayerWalking');//local
		}
	}		
}

DefaultProperties
{
	characterName = "FatLady";
}


