// This file is shared with ze_dreamin_v2_1 and ze_dreamin_v3_1_css

function check()
{
	EntFire("bosshp_text", "AddOutput", "message HP: "+self.GetHealth().tostring(), 0.00, null);
	EntFire("bosshp_text", "Display", "", 0.02, null);
	EntFireByHandle(self, "RunScriptCode", " check(); ", 0.10, null, null);
}

function top()
{
	local pos = Vector(RandomInt(12090,14363),RandomInt(1280,3560),1500);
	self.SetOrigin(pos);
	EntFire("spike_maker","ForceSpawn","",0);
}
