z <- 50000;
tz <- 50000;
r <- 255.00;
g <- 255.00;
b <- 255.00;
tr <- 255.00;
tg <- 255.00;
tb <- 255.00;
ds <- 500.00;
tds <- 500.00;
de <- 20000.00;
tde <- 20000.00;
speed <- 0.25;
speed_dist <- 5.0;
speed_z <- 5.0;
ticking <- false;

//-----------------------------------
function SetFarzTarget(amount)
{
	tz = amount;
	StartTick();
}
function SetFarz(amount)
{
	z = amount;
	tz = amount;
	self.__KeyValueFromInt("farz",z);
}
function SetSpeedZ(amount)
{
	speed_z = amount;
}
//-----------------------------------
function SetFogColorTarget(_r, _g, _b)
{
	tr = _r;
	tg = _g;
	tb = _b;
	StartTick();
}
function SetFogColor(_r, _g, _b)
{
	r = _r;
	g = _g;
	b = _b;
	tr = _r;
	tg = _g;
	tb = _b;
	// same value as the old Vector(r,g,b) round trip, without allocating a Vector
	local color = (b.tofloat().tointeger() << 16) | (g.tofloat().tointeger() << 8) | r.tofloat().tointeger();
	NetProps.SetPropInt(self,"m_fog.colorPrimary",color);

}
function SetSpeedColor(amount)
{
	speed = amount;
}
//-----------------------------------
function SetDistanceTarget(start,end)
{
	tds = start;
	tde = end;
	StartTick();
}
function SetDistance(start,end)
{
	ds = start;
	de = end;
	tds = start;
	tde = end;
	self.__KeyValueFromInt("fogstart",ds);
	self.__KeyValueFromInt("fogend",de);
}
function SetSpeedDistance(amount)
{
	speed_dist = amount;
}
//-----------------------------------
function Initialize()
{
	ticking = false;
}
function StartTick()
{
	if(!ticking)
	{
		ticking = true;
		Tick();
	}
}
function Tick()
{
	if(abs(r-tr)<speed)r=tr;else if(r<tr)r+=speed;else if(r>tr)r-=speed;
	if(abs(g-tg)<speed)g=tg;else if(g<tg)g+=speed;else if(g>tg)g-=speed;
	if(abs(b-tb)<speed)b=tb;else if(b<tb)b+=speed;else if(b>tb)b-=speed;
	if(abs(z-tz)<speed_z)z=tz;else if(z<tz)z+=speed_z;else if(z>tz)z-=speed_z;
	if(abs(ds-tds)<speed_dist)ds=tds;else if(ds<tds)ds+=speed_dist;else if(ds>tds)ds-=speed_dist;
	if(abs(de-tde)<speed_dist)de=tde;else if(de<tde)de+=speed_dist;else if(de>tde)de-=speed_dist;
	self.__KeyValueFromInt("fogstart",ds);
	self.__KeyValueFromInt("fogend",de);
	self.__KeyValueFromInt("farz",z);
	// same value as the old Vector(r,g,b) round trip, without allocating a Vector
	local color = (b.tofloat().tointeger() << 16) | (g.tofloat().tointeger() << 8) | r.tofloat().tointeger();
	NetProps.SetPropInt(self,"m_fog.colorPrimary",color);
	EntFireByHandle(self, "CallScriptFunction", "Tick", 0.01, null, null);
}
