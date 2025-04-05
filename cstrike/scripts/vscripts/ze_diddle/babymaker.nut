	// THIS SCRIPT IS FROM CS:GO AND NOT FULLY OPTIMIZED TO CS:S SO IT'S NOT USING THE NEWEST FETURES!!!
	// IF U WANNA LEARN HOW TO WRITE VSCRIPTS DON'T COPY FROM HERE AND DON'T LEARN FROM HERE!!!

//==========================================================================================================================================================\\
//===================================\\
// Script by Luffaren (STEAM_0:1:22521282)
// (PUT THIS IN: csgo/scripts/vscripts/luffaren/_mapscripts/ze_diddle/)
//===================================\\

function CheckBabyMaker()
{
	local c = null;
	c = Entities.FindByNameWithin(c,"NO_BABY",self.GetOrigin(),512);
	if(c == null)
		EntFire("ITEMX_hich_zmboost_maker2", "ForceSpawn", "", 0.05, null)
	else
		EntFireByHandle(self,"FireUser3","",0.00,null,null);
}