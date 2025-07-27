::SetEntityColor <- function(entity, r, g, b, a)
{
    local color = (r) | (g << 8) | (b << 16) | (a << 24)
    NetProps.SetPropInt(entity, "m_clrRender", color)
}

::fadedelay <- function(ent){
	ent.KeyValueFromInt("rendermode", 1)
	local color = NetProps.GetPropInt(ent, "m_clrRender")
	local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
	local fade = 10
	if(alpha-fade<=0)
	{
		alpha = 0; fade = 0
	}
	local newcolor = ((red) | (green << 8) | (blue << 16) | (alpha-fade << 24))
	NetProps.SetPropInt(ent, "m_clrRender", newcolor)
	if(alpha>=1)
	{
		EntFireByHandle(ent, "RunScriptCode", "fadedelay(self)", 0.05, null, null)
	} else{
		ent.Destroy()
	}
}

::fadedelaynokill <- function(ent=self){
	ent.KeyValueFromInt("rendermode", 1)
	local color = NetProps.GetPropInt(ent, "m_clrRender")
	local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
	local fade = 15
	if(alpha-fade<=0)
	{
		alpha = 0; fade = 0
	}
	local newcolor = ((red) | (green << 8) | (blue << 16) | (alpha-fade << 24))
	NetProps.SetPropInt(ent, "m_clrRender", newcolor)
	if(alpha>=1)
	{
		EntFireByHandle(ent, "RunScriptCode", "fadedelaynokill(self)", 0.05, null, null)
	} else{
		ent.DisableDraw() // this is the same as sending Disable input
	}
}

::fadedelay_reverse <- function(ent){
	ent.KeyValueFromInt("rendermode", 1)
	local color = NetProps.GetPropInt(ent, "m_clrRender")
	local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
	local fade = 5
	if(alpha+fade>=255)
	{
		alpha = 255; fade = 255
	}
	local newcolor = ((red) | (green << 8) | (blue << 16) | (alpha+fade << 24))
	NetProps.SetPropInt(ent, "m_clrRender", newcolor)
	if(alpha<=255)
	{
		EntFireByHandle(ent, "RunScriptCode", "fadedelay_reverse(self)", 0.05, null, null)
	}
}

PrecacheSound("kh2/defeated.mp3");

MODEL <- null;
TRIGGER <- null;

function OnPostSpawn(){

	EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_PREGAME<-true", 0, null);
	MODEL = self
	TRIGGER = MODEL.FirstMoveChild();
	MODEL.KeyValueFromInt("rendermode", 1)
	MODEL.KeyValueFromInt("renderamt", 0)

	MODEL.ValidateScriptScope();
	MODEL.GetScriptScope().puzzleplayer <- null;
	MODEL.GetScriptScope().MaxCrystals <- 16;
	MODEL.GetScriptScope().crystals_on <- 0;
	MODEL.GetScriptScope().puzzle_size <- 5;
	MODEL.GetScriptScope().PUZZLE_START <- true;
	MODEL.GetScriptScope().PUZZLE_DONE <- false;
	MODEL.GetScriptScope().crystals <- {}

	MODEL.GetScriptScope().PuzThink <- function(){
		if (PUZZLE_START) return

		if (PUZZLE_DONE) return

		if(crystals_on == MaxCrystals){
			//printl("Puzzle complete!")
			EntFireByHandle(self,"RunScriptCode","PuzzleComplete()",0,null,null);
		}else{
			//printl("Crystals on: "+crystals_on+" / "+MaxCrystals);
		}

		return 0.1
	};

	MODEL.GetScriptScope().PuzzleStart <- function(player){
		puzzleplayer = player;
		SpawnCrystals(puzzle_size);
		NetProps.SetPropFloat(puzzleplayer, "m_flLaggedMovementValue", 2.0);
		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_PREGAME<-false", 0, null);
	}

	MODEL.GetScriptScope().AddSubtract <- function(on=true){
		if(on==true){
			crystals_on++
		} else {
			crystals_on--
		}
	}

	MODEL.GetScriptScope().PuzzleComplete <- function(){
		PUZZLE_DONE <- true
		printl("Puzzle complete, locking crystals")
		LockCrys()
		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_OVER<-true", 0, null);
		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_STARTED<-false", 0, null);
		EntFire("puzzle_manager", "RunScriptCode", "CT_READY<-false", 0.1, null);
		EntFire("puzzle_manager", "RunScriptCode", "ZM_READY<-false", 0.1, null);
		EntFire("puzzle_manager", "RunScriptCode", "once_ready<-false", 0.1, null);
		local myname = self.GetName();
		if(myname == "puzzle_start_model_ct"){
			EntFire("puzzle_manager", "RunScriptCode", "SetWinner(3)", 0, null);
		} else if (myname == "puzzle_start_model_zm"){
			EntFire("puzzle_manager", "RunScriptCode", "SetWinner(2)", 0, null);
		}
		EntFire("puzzle_start_model_zm", "CallScriptFunction", "CleanCrystals", 1, null);
		EntFire("puzzle_start_model_ct", "CallScriptFunction", "CleanCrystals", 1, null);
		EntFire("puzzle_start_model_ct", "Kill", "", 3, null);
		EntFire("puzzle_start_model_zm", "Kill", "", 3, null);
	}

	MODEL.GetScriptScope().LockCrys <- function(){
		foreach(c in crystals){
			DispatchParticleEffect("achieved", c.GetOrigin(), QAngle(0, 0, 0).Forward())
			EntFireByHandle(c,"RunScriptCode","over<-true",0.0,null,null);
			fadedelay(c)
		}
	}

	MODEL.GetScriptScope().CleanCrystals <- function(){
		foreach(c in crystals){
			EntFireByHandle(c,"RunScriptCode","over<-true",0.0,null,null);
			fadedelay(c)
		}
	}

	MODEL.GetScriptScope().SpawnCrystals <- function(size=3){
		switch (size) {
			case 3:
				MaxCrystals = 9
				crystals_on = 9
				break;
			case 4:
				MaxCrystals = 16
				crystals_on = 16
				break;
			case 5:
				MaxCrystals = 25
				crystals_on = 25
				break;
		}

		for (local i=0; i < MaxCrystals; i++) {
			local crystalpos = self.GetOrigin()+Vector(0,0,52);

			if (MaxCrystals == 9 ){
				if (i < 3)
					crystalpos += self.GetRightVector() * -128;
				else if (i >= 3 && i <= 5)
					crystalpos += self.GetRightVector() * -0;
				else if (i >= 6 && i <= 8)
					crystalpos += self.GetRightVector() * 128;
				crystalpos.x += (i % 3) * 128 - 128;
			} else if (MaxCrystals == 16) {
				if (i < 4)
					crystalpos += self.GetRightVector() * -192;
				else if (i >= 5 && i <= 8)
					crystalpos += self.GetRightVector() * -64;
				else if (i >= 9 && i <= 12)
					crystalpos += self.GetRightVector() * 64;
				else
					crystalpos += self.GetRightVector() * 192;
				crystalpos.x += (i % 4) * 128 - 192;
			} else if (MaxCrystals == 25) {
				if (i < 5)
					crystalpos += self.GetRightVector() * -256;
				else if (i >= 6 && i <= 10)
					crystalpos += self.GetRightVector() * -128;
				else if (i >= 11 && i <= 15)
					crystalpos += self.GetRightVector() * 0;
				else if (i >= 16 && i <= 20)
					crystalpos += self.GetRightVector() * 128;
				else
					crystalpos += self.GetRightVector() * 256;
				crystalpos.x += (i % 5) * 128 - 256;
			}


			// GREEN SKIN = 2
			// RED SKIN = 6
			local crystal = SpawnEntityFromTable("prop_door_rotating",{
				model = "models/touhou/crystal.mdl",
				disableshadows = 1,
				disablereceiveshadows = 1,
				angles = "-90 0 0",
				spawnflags = 8192
				origin = crystalpos
				soundmoveoverride = "buttons/latchunlocked2.wav"
				returndelay = -1
				speed = 300
				distance = 0.01
				skin = 2
				"OnOpen#1" : "!self,CallScriptFunction,ChangeAdjacent,0,-1"
				"OnClose#1" : "!self,CallScriptFunction,ChangeAdjacent,0,-1"
			});
			::NetProps.SetPropBool(crystal,"m_bForcePurgeFixedupStrings",true);

			crystal.SetModelScale(2.5, RandomFloat(0.5, 1.5))
			SetEntityColor(crystal, 100, 255, 100, 255);
			crystal.SetSolid(0)

			crystal.ValidateScriptScope();
			crystal.GetScriptScope().state <- true;
			crystal.GetScriptScope().over <- false;
			crystal.GetScriptScope().speed <- 0.1;
			crystal.GetScriptScope().wave_rate <- 0.01;
			crystal.GetScriptScope().wave_amplitude <- 0.1;
			crystal.GetScriptScope().sine <- -1.00;
			crystal.GetScriptScope().main <- MODEL;

			crystal.GetScriptScope().ChangeState <- function(){
				if(state == true){
					EntFireByHandle(main, "RunScriptCode", "AddSubtract(false)", 0, null, null)
					self.SetSkin(6)
					DispatchParticleEffect("puzzle_red", self.GetOrigin(), QAngle(0, 0, 0).Forward())
					SetEntityColor(self, 255, 100, 100, 255);
					state = false
				}else{
					EntFireByHandle(main, "RunScriptCode", "AddSubtract(true)", 0, null, null)
					self.SetSkin(2)
					DispatchParticleEffect("puzzle_green", self.GetOrigin(), QAngle(0, 0, 0).Forward())
					SetEntityColor(self, 100, 255, 100, 255);
					state = true
				}
			}

			crystal.GetScriptScope().ChangeAdjacent <- function(){
				if(over) return
				EntFireByHandle(self, "CallScriptFunction", "ChangeState", 0, null, null)

				for (local i=1; i < 5; i++) {

					local checkpos = self.GetOrigin()
					switch (i) {
						case 1:
							checkpos = self.GetOrigin()+(self.GetRightVector()*128)
							break;
						case 2:
							checkpos = self.GetOrigin()+(self.GetRightVector()*-128)
							break;
						case 3:
							checkpos = self.GetOrigin()+(self.GetUpVector()*128)
							break;
						case 4:
							checkpos = self.GetOrigin()+(self.GetUpVector()*-128)
							break;
					}

					local h = null;
					h = Entities.FindByClassnameNearest("prop_door_rotating", checkpos, 8.0)
					if (h) {
						EntFireByHandle(h, "CallScriptFunction", "ChangeState", 0, null, null)
					}

				}
			}

			crystal.GetScriptScope().Think <- function(){
				local pos = self.GetOrigin();
				local forward = self.GetForwardVector();
				if(over){
					pos += (forward * speed);
					speed*=1.01
					self.SetOrigin(pos);
					return -1
				} 

				sine += wave_rate;

				pos += (forward * (sin(sine) * wave_amplitude));
				self.SetOrigin(pos);

				return -1
			};
			AddThinkToEnt(crystal,"Think");
			crystals[i] <- crystal;
		}

		for (local i=0; i < 100; i++) {
			EntFireByHandle(crystals[RandomInt(0,MaxCrystals-1)], "CallScriptFunction", "ChangeAdjacent", 0, null, null)
		}

	}

	AddThinkToEnt(MODEL,"PuzThink");
	EntFireByHandle(self,"RunScriptCode","fadedelay_reverse(activator)",0.1,MODEL,null);
}

// function Start() {
// 	EntFireByHandle(MODEL,"RunScriptCode","PuzzleStart(activator)",0.1,activator,null);
// 	fadedelaynokill(MODEL)
// 	EntFireByHandle(MODEL,"RunScriptCode","PUZZLE_START<-false",2.0,null,null);
// }