::fadedelay <- function(ent){
	ent.KeyValueFromInt("rendermode", 1)
	local color = NetProps.GetPropInt(ent, "m_clrRender")
	local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
	local fade = 245
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
		EntFireByHandle(ent, "Kill", "", 0, null, null)
	}
}
SOURCE_NAME <- "boss_yellowdevil_spawn";
DAMAGE_FILTER <- "filter_god";
EYE <- null;
HITBOX <- null;
SOURCE <- null;
BASE <- null;
EYE_Z <- 0.0;
BLOB_Z <- 0.0;
PIECE_ENTS <- [];
OLD_PIECES <- [];
CLEAR_QUEUE <- [];
OLD_LANDINGS <- [];
ENEMY <- null;
DEAD <- false;
SPAWNING <- true;
once_wakeup <- false;
last_target_time <- 0.0;
WAKEUP_RANGE <- 1500;
WAKEUP_RANGE_SQR <- WAKEUP_RANGE * WAKEUP_RANGE;
EYE_OFFSET <- 64;
EYE_TARGET_OFFSET <- 8;
EYE_DROP <- 28;
PIECE_COUNT <- 20;
PIECE_SCALE <- 3;
PIECE_OFFSET <- Vector(0, 0, -80);
PIECE_BACK <- 16;
PIECE_SIDE <- -32;
BUILD_REVERSE <- true;
CLEAR_STEP <- 0.08;
DEATH_PARTICLE <- "yd1_death";
PIECE_GRID <- [
	[  6.5,  38.8],
	[-39.6,   6.9],
	[-21.9,  37.7],
	[-24.6,  24.1],
	[ -8.4,  40.3],
	[  7.5,  24.5],
	[-24.5,   8.6],
	[ -8.5,  24.5],
	[ 22.0,  25.7],
	[  7.5,   8.5],
	[-23.3,  -8.0],
	[ 22.7,  11.5],
	[-23.8, -23.9],
	[ -8.5,   8.5],
	[  7.7,  -7.2],
	[ 19.3,  -9.8],
	[ 24.9, -24.8],
	[ -8.7,  -6.4],
	[-13.9, -24.1],
	[ 13.3, -21.8],
];
PIECE_GRID_FLIP <- true;
BLOB_MATERIAL <- "megaman/npcs/yellowdevil/yellowdevil_body.vmt";
BLOB_SCALE <- 3;
BLOB_ANIM_FPS <- 21;
BLOB_LOOP_LAST <- 4;
BLOB_FINAL_FRAME <- 5;
BLOB_SPEED <- 9;
BLOB_INTERVAL <- 0.5;
BLOB_LIFE <- 12.0;
BLOB_DAMAGE <- 20;
BLOB_TOUCH_RANGE <- 32;
BLOB_TOUCH_CD <- 0.5;
BLOB_CARRIL <- true;
BLOB_BAJO_Z <- 20;
BLOB_BAJO_RADIO <- 24;
BLOB_ALTO_Z <- 88;
BLOB_ALTO_RADIO <- 22;
BLOB_SUBIDA <- 0.15;
BLOB_BAJADA <- 0.10;
EYE_OPEN_DELAY <- 0.4;
PASADA <- 0;
PASADA_EXTRA <- 0.15;
PASADA_MAX <- 2.0;
function Ritmo(){ local r = 1.0 + PASADA_EXTRA * PASADA; return (r > PASADA_MAX) ? PASADA_MAX : r; }
DISASSEMBLE_STEP <- 0.5;
EYE_FRAME_CLOSED <- 2;
EYE_FRAME_OPEN <- 0;
EYE_ANIM_STEP <- 0.12;
HP_THRESHOLDS <- [0.66, 0.33];
SHOT_MATERIAL <- "megaman/npcs/yellowdevil/yellowdevil_bullet.vmt";
SHOT_SOUND <- "megaman_v2/met_shoot.mp3";
SHOT_TRAIL <- "yd_bullet_trail";
SHOT_TRAIL_INTERVAL <- 0.02;
SHOT_SPEED <- 18;
SHOT_DAMAGE <- 20;
SHOT_LIFE <- 6.0;
SHOT_INTERVAL <- 1.0;
SHOT_SCALE <- 2;
ARENA_TRACE_DIST <- 3000;
WALL_MARGIN <- 96;
STATE_IDLE <- 0;
STATE_ASSEMBLING <- 1;
STATE_OPENING <- 2;
STATE_ASSEMBLED <- 3;
STATE_CLOSING <- 4;
STATE_DISASSEMBLING <- 5;
STATE <- STATE_IDLE;
state_end <- 0.0;
blobs_sent <- 0;
pieces_done <- 0;
next_blob_time <- 0.0;
next_shot_time <- 0.0;
threshold_index <- 0;
blob_touchers <- {};
local ctcount = 0;
maxhealth <- 0.0
function OnPostSpawn(){
	Precache();
	Setup();
}
function Precache(){
	PrecacheModel(BLOB_MATERIAL);
	PrecacheModel(SHOT_MATERIAL);
	for(local i=1; i<=PIECE_COUNT; i++){
		PrecacheModel(PieceMaterial(i));
	}
}
function PieceMaterial(n){
	return "megaman/npcs/yellowdevil/yellowdevil_sprite"+n+".vmt";
}
function Setup(){
	EYE = self;
	HITBOX = self.FirstMoveChild();
	::NetProps.SetPropBool(self,"m_bForcePurgeFixedupStrings",true);
	if (HITBOX != null && HITBOX.IsValid())
		::NetProps.SetPropBool(HITBOX,"m_bForcePurgeFixedupStrings",true);
	PIECE_ENTS.clear();
	OLD_PIECES.clear();
	for(local i=0; i<PIECE_COUNT; i++){
		PIECE_ENTS.push(null);
		OLD_PIECES.push(null);
	}
	BASE = self.GetOrigin();
	local src = Entities.FindByName(null, SOURCE_NAME);
	if (src != null && src.IsValid()){
		SOURCE = src.GetOrigin();
	} else {
		SOURCE = FindOppositeEnd();
	}
	EYE_Z = BASE.z;
	BLOB_Z = SOURCE.z;
	PlaceEye();
	EntFireByHandle(self, "HideSprite", "", 0, null, null);
	SetSpriteFrame(self, EYE_FRAME_CLOSED);
	SetVulnerable(false);
	EntFireByHandle(self, "CallScriptFunction", "HealthScale", 1.3, null, null);
	EntFireByHandle(self, "RunScriptCode", "SPAWNING<-false", 2.5, null, null);
	AddThinkToEnt(self, "Think");
}
function FindOppositeEnd(){
	local back = self.GetForwardVector() * -1;
	back.z = 0;
	back.Norm();
	local start = BASE + Vector(0,0,48);
	local frac = TraceLine(start, start + (back*ARENA_TRACE_DIST), self);
	local dist = (frac*ARENA_TRACE_DIST) - WALL_MARGIN;
	if (dist < 256) dist = 256;
	return BASE + (back*dist);
}
function HealthScale(){
	if (HITBOX == null || !HITBOX.IsValid()) return
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		local hscope = h.GetScriptScope()
		if(hscope.IsSprite){
			ctcount+=6
		} else {
			ctcount+=1
		}
	}
	maxhealth = HITBOX.GetHealth()+(1500*ctcount)
	HITBOX.SetHealth(maxhealth)
}
function Hurt(){
	if(HITBOX != null && HITBOX.IsValid() && maxhealth > 0){
		local perc = (HITBOX.GetHealth() * 100) / maxhealth;
		local mishp = 100 - perc;
		local bardamage = (fabs(29 * mishp/100));
		bardamage = bardamage.tointeger();
		if(bardamage==0) bardamage = 1
		SetBossHP(bardamage)
	}
}
function Death(){
	if ("LB_Llego" in getroottable()) ::LB_Llego(::LB_ETAPA_CASTILLO_B)
	DEAD <- true;
	EmitSoundEx({
		sound_name = "megaman_v2/megaman_die.mp3",
		origin = BASE
		sound_level = 0,
		pitch = 100
		volume = 1,
		channel = 6,
	});
	ClearPieces();
	EntFire("boss_yellowdevil_blob", "Kill", "", 0, null);
	EntFire("boss_yellowdevil_shot", "Kill", "", 0, null);
	if (EYE != null && EYE.IsValid())
		EntFireByHandle(EYE, "HideSprite", "", 0, null, null);
	DispatchParticleEffect(DEATH_PARTICLE, PiecePos(), self.GetAbsAngles().Forward())
	EntFire("yd1_break", "Break", "", 5, null);
	StopMusicPls("megaman_v2/megaman_yellowdevil_boss_music")
	SetBossHP(30)
}
function Think(){
	if (SPAWNING) return;
	if (DEAD) return 60
	if (EYE == null || !EYE.IsValid()) return -1
	if(once_wakeup == false){
		local target = null;
		while (target=Entities.FindByClassname(target, "player")){
			if (target.IsValid() && (target.GetCenter()-BASE).LengthSqr() < WAKEUP_RANGE_SQR && target.GetTeam() == 3 && target.GetHealth() > 0){
				once_wakeup = true
				StartAssembly();
				return -1
			}
		}
		return -1
	}
	if (ENEMY == null) LookForEnemy();
	if (Time() - last_target_time >= 5.0){
		LookForEnemy();
		last_target_time = Time();
	}
	switch(STATE){
		case STATE_ASSEMBLING:
			if (blobs_sent < PIECE_COUNT && Time() >= next_blob_time){
				SendBlob(blobs_sent);
				blobs_sent++;
				next_blob_time = Time() + BLOB_INTERVAL / Ritmo();
			}
			break;
		case STATE_ASSEMBLED:
			if (Time() >= next_shot_time){
				FireEye();
				next_shot_time = Time() + SHOT_INTERVAL;
			}
			CheckThreshold();
			break;
	}
	return -1
}
function CheckThreshold(){
	if (DEAD) return
	if (HITBOX == null || !HITBOX.IsValid()) return
	if (maxhealth <= 0) return
	if (threshold_index >= HP_THRESHOLDS.len()) return
	if (HITBOX.GetHealth() <= maxhealth * HP_THRESHOLDS[threshold_index]){
		threshold_index++;
		CloseEye();
	}
}
function StartAssembly(){
	if (DEAD) return
	STATE = STATE_ASSEMBLING;
	blobs_sent = 0;
	pieces_done = 0;
	next_blob_time = Time();
	ClearPieces(0);
	SetVulnerable(false);
	EntFireByHandle(EYE, "HideSprite", "", 0, null, null);
}
function PieceNumber(index){
	if (BUILD_REVERSE) return PIECE_COUNT - index;
	return index + 1;
}
function TravelAxis(){
	local axis = (BASE - SOURCE);
	axis.z = 0;
	axis.Norm();
	return axis;
}
function PiecePos(){
	return BASE + PIECE_OFFSET
		+ (TravelAxis() * PIECE_BACK)
		+ (SideAxis() * PIECE_SIDE);
}
function SideAxis(){
	local axis = TravelAxis();
	return Vector(-axis.y, axis.x, 0);
}
function GridRight(){
	local right = SideAxis();
	if (PIECE_GRID_FLIP) right = right * -1;
	return right;
}
function PieceLanding(n){
	local g = PIECE_GRID[n-1];
	return PiecePos()
		+ (GridRight() * (g[0] * PIECE_SCALE))
		+ Vector(0, 0, g[1] * PIECE_SCALE);
}
function CrossDistance(){
	local d = (BASE - SOURCE);
	d.z = 0;
	return d.Length();
}
function SendBlob(index){
	if (DEAD) return
	local n = PieceNumber(index);
	local landing = PieceLanding(n);
	local axis = TravelAxis();
	local dist = CrossDistance();
	local start = landing - (axis * dist);
	MakeBlob(start, axis, dist, n);
}
function TransferStep(k){
	if (DEAD) return
	if (k < 1 || k > PIECE_COUNT) return
	local arrive_n = PIECE_COUNT + 1 - k;
	local old = OLD_PIECES[k-1];
	if (old != null && old.IsValid()){
		EntFireByHandle(old, "Kill", "", 0, null, null);
	}
	OLD_PIECES[k-1] = null;
	local start = OLD_LANDINGS[k-1];
	local end = PieceLanding(arrive_n);
	local dir = (end - start);
	local dist = dir.Length();
	if (dist <= 0) return
	dir.Norm();
	MakeBlob(start, dir, dist, arrive_n);
}
function MakeBlob(start, axis, travel, index, speed=0){
	if (speed <= 0) speed = BLOB_SPEED * Ritmo();
	local blob = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows	= 1,
		disableshadows			= 1,
		model					= BLOB_MATERIAL,
		targetname				= "boss_yellowdevil_blob",
		scale					= BLOB_SCALE,
		spawnflags				= 1,
	})
	::NetProps.SetPropBool(blob,"m_bForcePurgeFixedupStrings",true);
	blob.SetOwner(self)
	blob.SetOrigin(start)
	SetSpriteFrame(blob, 0);
	blob.SetForwardVector(axis);
	blob.ValidateScriptScope();
	blob.GetScriptScope().speed			<- speed;
	blob.GetScriptScope().dist_left		<- travel;
	blob.GetScriptScope().piece_index	<- index;
	blob.GetScriptScope().boss			<- self;
	blob.GetScriptScope().damage		<- BLOB_DAMAGE;
	blob.GetScriptScope().touch_range	<- BLOB_TOUCH_RANGE;
	blob.GetScriptScope().anim_fps		<- BLOB_ANIM_FPS;
	blob.GetScriptScope().loop_last		<- BLOB_LOOP_LAST;
	blob.GetScriptScope().final_frame	<- BLOB_FINAL_FRAME;
	blob.GetScriptScope().anim_start	<- Time();
	blob.GetScriptScope().arrived		<- false;
	blob.GetScriptScope().carril		<- false;
	if (BLOB_CARRIL){
		local tr = { start = start, end = start - Vector(0,0,2000), mask = 0x400B, ignore = self };
		TraceLineEx(tr);
		local suelo = ("pos" in tr) ? tr.pos.z : start.z - 2000;
		local alto = RandomInt(0,1) == 1;
		blob.GetScriptScope().carril	<- true;
		blob.GetScriptScope().p0		<- start;
		blob.GetScriptScope().p1		<- start + (axis * travel);
		blob.GetScriptScope().total		<- travel;
		blob.GetScriptScope().carril_z	<- suelo + (alto ? BLOB_ALTO_Z : BLOB_BAJO_Z);
		blob.GetScriptScope().touch_range <- alto ? BLOB_ALTO_RADIO : BLOB_BAJO_RADIO;
		blob.GetScriptScope().bajada	<- BLOB_BAJADA;
		blob.GetScriptScope().subida	<- BLOB_SUBIDA;
	}
	blob.GetScriptScope().finished		<- false;
	blob.GetScriptScope().Think <- function(){
		if (finished) return -1;
		local step = ((Time() - anim_start) * anim_fps).tointeger();
		if (arrived){
			if (step > loop_last){
				SetSpriteFrame(self, final_frame);
				if (step > loop_last+1){
					finished = true;
					if (piece_index >= 1){
						boss.GetScriptScope().BlobArrived(piece_index);
					}
					fadedelay(self);
					return -1;
				}
			} else {
				SetSpriteFrame(self, step);
			}
			return -1;
		}
		SetSpriteFrame(self, step % (loop_last+1));
		if (dist_left <= 0){
			arrived = true;
			anim_start = Time();
			SetSpriteFrame(self, 0);
			return -1;
		}
		local adv = speed;
		if (adv > dist_left) adv = dist_left;
		dist_left -= adv;
		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		if (carril){
			local f = 1.0 - (dist_left / total);
			local pos = p0 + ((p1 - p0) * f);
			local zr = p0.z + ((p1.z - p0.z) * f);
			if (f < bajada) pos.z = zr + ((carril_z - zr) * (f / bajada));
			else if (f > 1.0 - subida) pos.z = carril_z + ((p1.z - carril_z) * ((f - (1.0 - subida)) / subida));
			else pos.z = carril_z;
			self.SetOrigin(pos);
		} else {
			self.SetOrigin(self.GetOrigin() + (self.GetForwardVector()*adv));
		}
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		boss.GetScriptScope().BlobTouch(self.GetOrigin(), touch_range, damage);
		return -1;
	};
	AddThinkToEnt(blob,"Think");
	EntFireByHandle(blob, "Kill", "", BLOB_LIFE, null, null)
}
function BlobTouch(pos, range, dmg){
	if (DEAD) return
	for(local h;h=Entities.FindInSphere(h,pos,range);){
		if(!h.IsPlayer()) continue;
		if(!h.IsAlive()) continue;
		if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
		if(h in blob_touchers && Time() < blob_touchers[h]) continue;
		blob_touchers[h] <- Time() + BLOB_TOUCH_CD;
		h.TakeDamageEx(self, self, self, Vector(0, 0, 0), h.GetOrigin(), dmg, 8);
	}
}
function BlobArrived(n){
	if (DEAD) return
	if (STATE != STATE_ASSEMBLING && STATE != STATE_DISASSEMBLING) return
	local piece = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows	= 1,
		disableshadows			= 1,
		model					= PieceMaterial(n),
		targetname				= "boss_yellowdevil_piece",
		scale					= PIECE_SCALE,
		spawnflags				= 1,
	})
	::NetProps.SetPropBool(piece,"m_bForcePurgeFixedupStrings",true);
	piece.SetOwner(self)
	piece.SetOrigin(PiecePos());
	local old = PIECE_ENTS[n-1];
	if (old != null && old.IsValid()){
		EntFireByHandle(old, "Kill", "", 0, null, null);
	}
	PIECE_ENTS[n-1] = piece;
	pieces_done++;
	if (pieces_done >= PIECE_COUNT){
		EntFireByHandle(self, "CallScriptFunction", "Assembled", EYE_OPEN_DELAY, null, null);
	}
}
function Assembled(){
	if (DEAD) return
	STATE = STATE_OPENING;
	SetSpriteFrame(EYE, EYE_FRAME_CLOSED);
	EntFireByHandle(EYE, "ShowSprite", "", 0, null, null);
	local t = 0.0;
	for(local f=EYE_FRAME_CLOSED; f>=EYE_FRAME_OPEN; f--){
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(EYE,"+f+")", t, null, null);
		t += EYE_ANIM_STEP;
	}
	EntFireByHandle(self, "CallScriptFunction", "EyeOpened", t, null, null);
}
function EyeOpened(){
	if (DEAD) return
	if (STATE != STATE_OPENING) return
	STATE = STATE_ASSEMBLED;
	next_shot_time = Time() + 0.3;
	SetVulnerable(true);
}
function CloseEye(){
	if (DEAD) return
	STATE = STATE_CLOSING;
	SetVulnerable(false);
	local t = 0.0;
	for(local f=EYE_FRAME_OPEN; f<=EYE_FRAME_CLOSED; f++){
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(EYE,"+f+")", t, null, null);
		t += EYE_ANIM_STEP;
	}
	EntFireByHandle(EYE, "HideSprite", "", t, null, null);
	EntFireByHandle(self, "CallScriptFunction", "StartDisassembly", t + 0.15, null, null);
}
function SwapSides(){
	if (DEAD) return
	if (EYE == null || !EYE.IsValid()) return
	local old_base = BASE;
	BASE = Vector(SOURCE.x, SOURCE.y, EYE_Z);
	SOURCE = Vector(old_base.x, old_base.y, BLOB_Z);
	PlaceEye();
}
function PlaceEye(){
	if (EYE == null || !EYE.IsValid()) return
	self.SetOrigin(BASE - Vector(0, 0, EYE_DROP));
}
function FireEye(){
	if (DEAD) return
	if (STATE != STATE_ASSEMBLED) return
	if (ENEMY == null) return
	if (!ENEMY.IsValid() || !ENEMY.IsAlive()) return
	local origin = EYE.GetOrigin();
	local dir = (ENEMY.GetCenter() - origin);
	dir.Norm();
	EmitSoundEx({
		sound_name = SHOT_SOUND,
		origin = origin
		sound_level = soundlevelmain,
		pitch = RandomFloat(95,105)
		volume = 1,
		channel = 6,
	});
	local shot = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows	= 1,
		disableshadows			= 1,
		model					= SHOT_MATERIAL,
		targetname				= "boss_yellowdevil_shot",
		scale					= 2,
		spawnflags				= 1,
	})
	::NetProps.SetPropBool(shot,"m_bForcePurgeFixedupStrings",true);
	shot.SetOwner(self)
	shot.SetOrigin(origin)
	shot.SetForwardVector(dir);
	shot.ValidateScriptScope();
	shot.GetScriptScope().speed			<- SHOT_SPEED;
	shot.GetScriptScope().damage		<- SHOT_DAMAGE;
	shot.GetScriptScope().damage_range	<- 26;
	shot.GetScriptScope().projowner		<- self;
	shot.GetScriptScope().trail_fx		<- SHOT_TRAIL;
	shot.GetScriptScope().trail_every	<- SHOT_TRAIL_INTERVAL;
	shot.GetScriptScope().trail_next	<- 0.0;
	shot.GetScriptScope().hit_players <- {};
	shot.GetScriptScope().Think <- function(){
		local pos = self.GetOrigin();
		pos += (self.GetForwardVector() * speed);
		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		self.SetOrigin(pos);
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		if (Time() >= trail_next){
			trail_next = Time() + trail_every;
			DispatchParticleEffect(trail_fx, self.GetOrigin(), self.GetAbsAngles().Forward());
		}
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
		{
			EntFireByHandle(self,"Kill","",0,null,null);
			return -1;
		}
		for(local h;h=Entities.FindInSphere(h,self.GetOrigin(),damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(h in hit_players) continue;
			hit_players[h] <- true;
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		return -1;
	};
	AddThinkToEnt(shot,"Think");
	EntFireByHandle(shot, "Kill", "", SHOT_LIFE, null, null)
}
HURT_PAUSA <- 3.0;
function HurtToque(on){
	if (HITBOX == null || !HITBOX.IsValid()) return
	for (local c = HITBOX.FirstMoveChild(); c != null; c = c.NextMovePeer())
		if (c.GetClassname() == "trigger_hurt") c.AcceptInput(on ? "Enable" : "Disable", "", null, null);
}
function StartDisassembly(){
	if (DEAD) return
	STATE = STATE_DISASSEMBLING;
	PASADA++;
	EntFireByHandle(EYE, "HideSprite", "", 0, null, null);
	SetVulnerable(false);
	OLD_LANDINGS.clear();
	for(local n=1; n<=PIECE_COUNT; n++){
		OLD_LANDINGS.push(PieceLanding(n));
	}
	for(local i=0; i<PIECE_COUNT; i++){
		OLD_PIECES[i] = PIECE_ENTS[i];
		PIECE_ENTS[i] = null;
	}
	SwapSides();
	HurtToque(false);
	EntFireByHandle(self, "RunScriptCode", "HurtToque(true)", HURT_PAUSA, null, null);
	pieces_done = 0;
	for(local k=1; k<=PIECE_COUNT; k++){
		EntFireByHandle(self, "RunScriptCode",
			"TransferStep("+k+")", (k-1)*DISASSEMBLE_STEP / Ritmo(), null, null);
	}
}
function ClearPieces(step=-1){
	if (PIECE_ENTS.len() != PIECE_COUNT) return
	if (step < 0) step = CLEAR_STEP;
	for(local i=0; i<PIECE_COUNT; i++){
		if (PIECE_ENTS[i] != null && PIECE_ENTS[i].IsValid()) CLEAR_QUEUE.push(PIECE_ENTS[i]);
		if (OLD_PIECES[i] != null && OLD_PIECES[i].IsValid()) CLEAR_QUEUE.push(OLD_PIECES[i]);
		PIECE_ENTS[i] = null;
		OLD_PIECES[i] = null;
	}
	if (step <= 0){
		while (CLEAR_QUEUE.len() > 0) ClearNextPiece();
		return
	}
	local t = 0.0;
	local n = CLEAR_QUEUE.len();
	for(local i=0; i<n; i++){
		EntFireByHandle(self, "CallScriptFunction", "ClearNextPiece", t, null, null);
		t += step;
	}
}
function ClearNextPiece(){
	if (CLEAR_QUEUE.len() == 0) return
	local p = CLEAR_QUEUE[0];
	CLEAR_QUEUE.remove(0);
	if (p == null || !p.IsValid()) return
	EntFireByHandle(p, "Kill", "", 0, null, null);
}
function SetVulnerable(state){
	if (HITBOX == null || !HITBOX.IsValid()) return
	if (state){
		EntFireByHandle(HITBOX, "SetDamageFilter", "", 0, null, null);
	} else {
		EntFireByHandle(HITBOX, "SetDamageFilter", DAMAGE_FILTER, 0, null, null);
	}
}
function LookForEnemy(){
	if (DEAD) return
	local players = [];
	for(local h;h=Entities.FindByClassname(h,"player");){
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		if(!IsLOS(h))continue;
		players.push(h)
	}
	if(players.len()>0){
		ENEMY = players[RandomInt(0,players.len()-1)];
	}
}
function IsLOS(target_handle){
	if (DEAD) return
	if (target_handle == null) return
	if (EYE == null || !EYE.IsValid()) return
	local start_trace = EYE.GetOrigin();
	local end_trace = target_handle.EyePosition()+Vector(0,0,EYE_TARGET_OFFSET);
	if (TraceLine(start_trace, end_trace, self) >= 1) return true
	if (TraceLine(start_trace, target_handle.GetCenter()+Vector(0,0,EYE_TARGET_OFFSET), self) >= 1) return true
	return false
}
function SpawnItem(){
	local randomchance=RandomInt(1,2)
	local itemsprite = ""
	local itemname = ""
	local itype = 0
	switch (randomchance) {
		case 1:
			itemsprite = "megaman/hobgoblin_megaman/item_lifeenergy_small"
			itemname = "item_small_health"
			itype = 1
			break;
		case 2:
			itemsprite = "megaman/hobgoblin_megaman/item_lifeenergy_big"
			itemname = "item_big_health"
			itype = 2
			break;
	}
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = itemsprite+".vmt",
		parentname              = "",
		targetname              = itemname
		scale                   = 2,
		spawnflags              = 1,
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	particle.SetOwner(self)
	particle.SetOrigin(BASE+Vector(0,0,32))
	particle.ValidateScriptScope();
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().speed <- RandomInt(3, 6);
	particle.GetScriptScope().upspeed <- 6;
	particle.GetScriptScope().tracing <- false;
	particle.GetScriptScope().pickenabled <- false;
	particle.GetScriptScope().itemtype <- itype;
	particle.GetScriptScope().Think <- function(){
		if(speed!=0){
			local pos = self.GetOrigin();
			local forward = self.GetForwardVector();
			local up = self.GetUpVector();
			pos += (forward * speed);
			pos += (up * upspeed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			upspeed-= 0.2
		}
		if(tracing){
			if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetUpVector()*-32)),self)<1.00)
			{
				upspeed=0
				speed=0
				pickenabled=true
			}
		}
		if(pickenabled){
			for(local h;h=Entities.FindInSphere(h,self.GetOrigin(),damage_range);){
				if(!h.IsPlayer()) continue;
				if(!h.IsAlive()) continue;
				if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
				if(h in touchers) continue;
				touchers[h] <- h;
				switch(itemtype){
					case 1:
						RollingHeal(h,40)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Restoring 40 HP")
						break;
					case 2:
						RollingHeal(h,100)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Restoring 100 HP")
						break;
				}
				return -1;
			}
		}
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle,"RunScriptCode","tracing=true",0.5,null,null);
	EntFireByHandle(particle, "Kill", "", 10, null, null)
}
