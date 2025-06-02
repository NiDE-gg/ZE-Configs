// This file is shared with ze_dreamin_v2_1 and ze_dreamin_v3_1_css

function setrandom()
{
	local pos2 = Vector(RandomInt(-768,768),RandomInt(-768,768),-2720);
	self.SetOrigin(pos2);
}
function setrandom2()
{
	local pos3=Vector(RandomInt(6300,8350),RandomInt(-1850,220),-610);
	self.SetOrigin(pos3);
}
function setAngles()
{
	self.SetAngles(0,RandomInt(0,359),0);
}