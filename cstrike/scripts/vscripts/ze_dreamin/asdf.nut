function top()
{
	local pos = Vector(RandomInt(12090,14363),RandomInt(1280,3560),1500);
	self.SetOrigin(pos);
	EntFire("spike_maker","ForceSpawn","",0);
}
