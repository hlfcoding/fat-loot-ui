class SneaktoSlimPawn_FatLady extends SneaktoSlimPawn;

var bool isGuideReady;

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

			if(self.Role == ROLE_SimulatedProxy)
			{
				foreach WorldInfo.AllPawns(class 'SneaktoSlimPawn', pa)
				{
					if(pa.Role == ROLE_AutonomousProxy)
					{
						if(pa.mistNum == self.mistNum)
						{
							self.treasureComponent.SetHidden(false);
							self.SetTreasureParticleEffectActive(true); 
						}
						else
						{
							self.treasureComponent.SetHidden(true);
							self.SetTreasureParticleEffectActive(false); 
						}
					}
				}
			}
			else if(self.Role == ROLE_AutonomousProxy)
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
			if(self.mistNum == 0)
				self.changeCharacterMaterial(self,self.GetTeamNum(),"Character");
			else
				self.changeCharacterMaterial(self,self.GetTeamNum(),"Invisible");
			self.SetTreasureParticleEffectActive(false);			
			SneaktoSlimPlayerController_FatLady(self.Controller).DropTreasure();
		}
	}
}

event Tick(float DeltaTime)
{
	local SneakToSlimGuidePawn pc;

	super.Tick(DeltaTime);

	if(self.Controller != none && !isGuideReady)
	{
		activateGuideOnce();
		isGuideReady = true;
	}
}

reliable server function activateGuideOnce()
{
	local SneakToSlimGuidePawn pc;	
	if(self.Controller != none && !isGuideReady)
	{
		foreach WorldInfo.AllPawns(class 'SneakToSlimGuidePawn', pc)
		{
			//Forces
			if(!pc.isActive)
			{
				pc.talkingTo = self;
				pc.changeToTutorialState('HowToMove');	
			}
			break;
		}
		isGuideReady = true;
	}
}

reliable client function playGuidePoofAnimation()
{
	local AnimNodePlayCustomAnim customNode;
	local SneaktoSlimGuidePawn guidePawn;
	
	foreach WorldInfo.AllPawns(class 'SneaktoSlimGuidePawn', guidePawn)
	{
		customNode = AnimNodePlayCustomAnim(guidePawn.Mesh.FindAnimNode('customVanish'));
		customNode.PlayCustomAnim('Vanish', 1, 0.1f, 0.1f, false, true);
	}
}

//Since text scrolls every # seconds, this function lets user speed read
exec function skipLine()
{
	skipGuideLine();
}

reliable server function skipGuideLine()
{
	local SneakToSlimGuidePawn pc;
	
	foreach WorldInfo.AllPawns(class 'SneakToSlimGuidePawn', pc)
	{
		if(pc.isActive)
		{
			pc.ClearTimer('readNextDialogueEntry');
			pc.SetTimer(pc.timeBetweenLines, false, 'readNextDialogueEntry');
			pc.readNextDialogueEntry();
		}
	}
}

event Bump (Actor Other, PrimitiveComponent OtherComp, Object.Vector HitNormal)
{	
	local SneaktoSlimAIPawn HitActor;
	local SneakToSlimAIController HitController;
	local SneaktoSlimPawn victim;

	super.Bump(Other, OtherComp, HitNormal);

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
						HitController = SneakToSlimAIController(HitActor.Controller);
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

	if(playerBase != none && playerBase.teamID == self.GetTeamNum())
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
	isGuideReady = false;

	Begin Object Class=PointLightComponent Name=MyPointlightBack
	  bEnabled=true
	  bCastCompositeShadow = true;
	  bAffectCompositeShadowDirection =true;
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Normal ;
	  Radius=15.000000
	  Brightness=.5
	  LightColor=(R=235,G=235,B=110)
	  Translation=(Z=-15)
	End Object
	Components.Add(MyPointlightBack)

	Begin Object Class=PointLightComponent Name=MyPointlightFront
	  bEnabled=true
	  bCastCompositeShadow = true;
	  bAffectCompositeShadowDirection =true;
	  CastShadows = true;
	  CastStaticShadows = true;
	  CastDynamicShadows = true;
	  LightShadowMode = LightShadow_Normal ;
	  Radius=15.000000
	  Brightness=.5
	  LightColor=(R=235,G=235,B=110)
	  Translation=(X=5, Z=-15)
	End Object
	Components.Add(MyPointlightFront)
}


