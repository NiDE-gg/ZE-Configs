function GetPithYawFVect3D(a, b){
	local deltaX = a.x - b.x
	local deltaY = a.y - b.y
	local yaw = atan2(deltaY, deltaX) * 180 / PI
	return yaw
}

function LerpAngle(v1, v2, t){
	return QAngle(v1.x + (v2.x - v1.x) * t,
		v1.y + (v2.y - v1.y) * t,
		v1.z + (v2.z - v1.z) * t);
}

function YawDifference(a, b){
	local diff = ((a - b) + 180) % 360 - 180

	if (diff < 180){
		return diff
	}

	return diff - 360
}

function VectorDistance(v1, v2){
	local dx = v2.x - v1.x;
	local dy = v2.y - v1.y;
	return sqrt(dx * dx + dy * dy);
}

boss_target <- null;
boss_targetorigin <- Vector(0,0,0);

boss_target_rotate <- true;

boss_angles <- QAngle(0,0,0);
boss_turn <- 0;

const TICKRATE = 0.01;

function TickRotate(){
	if (boss_target == null) return;

	if (boss_target_rotate){
		if (boss_turn >= 1){
			boss_target_rotate = false
		}else{
			local dir = GetPithYawFVect3D(boss_targetorigin, self.GetOrigin())
			boss_turn = boss_turn + 0.025

			local lerp = LerpAngle(boss_angles, QAngle(0, dir, 0), boss_turn)
			self.SetAbsAngles(QAngle(lerp.x, lerp.y, lerp.z))

			EntFireByHandle(self, "RunScriptCode", "TickRotate();", TICKRATE, null, null);

			return
		}
	}

	EntFireByHandle(self, "RunScriptCode", "TickRotate();", TICKRATE, null, null);
}

function SearchTarget(){
	local arr = [];
	boss_target = null

	local pl = null;
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam() == 3 && pl.IsAlive()){
			arr.push(pl);
		}
	}

	if (arr.len() <= 0)
		return boss_target = null;

	boss_target = arr[RandomInt(0, arr.len() - 1)]
	boss_targetorigin = boss_target.GetOrigin();

	TickRotate();
}

function dive(){
	ScreenShake(self.GetOrigin(), 640, 64, 1, 1280, 0, true)
	//DispatchParticleEffect("superjump", (self.GetOrigin() + Vector(0, 0, 8)), self.GetAbsAngles().Forward())
}

function geirskogul_1(){
	DispatchParticleEffect("geirskogul_telegraph_add", self.GetOrigin(), self.GetAbsAngles().Forward())
}

function geirskogul_2(){
	DispatchParticleEffect("geirskogul_add", self.GetOrigin(), self.GetAbsAngles().Forward())
}

function lock_in(){
	boss_angles = self.GetAbsAngles();
	boss_turn = 0;

	SearchTarget()

	EntFireByHandle(self, "RunScriptCode", "geirskogul_1();", 0.6, null, null)
	EntFireByHandle(self, "RunScriptCode", "geirskogul_2();", 4.5, null, null)
}

function fadeout(){
	for (local i=0; i<=26; ++i){
		EntFireByHandle(self, "Alpha", "" + (255-(i*10)), (i*0.02), null, null)
	}

	EntFireByHandle(self, "FireUser1", "", 0.5, null, null)
}

function fadein(){
	for (local i=0; i<=26; ++i){
		EntFireByHandle(self, "Alpha", "" + (i*10), i*0.02, null, null)
	}
}
