// Made by .Rushaway
// Thanks to ficool2 for review

::RandomSpawn <- function(entity, x1, x2, y1, y2, z1, z2, c1, c2, c3)
{
	local orig = entity.GetOrigin();
	local buf = Vector(
		RandomInt(x1, x2) * c1,
		RandomInt(y1, y2) * c2,
		RandomInt(z1, z2) * c3
	);
	buf += orig;
	entity.SetOrigin(buf);
	entity.AcceptInput("ForceSpawn", "", null, null)
	entity.SetOrigin(orig);
}

::OnRandomSpawn <- function()
{
	local caller = self;
	local makerName = caller.GetName();

	switch(makerName)
	{
		case "3_boss_skill_normal_maker": {
			RandomSpawn(caller, -320, 320, -320, 320, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "3_boss_skill3_maker": {
			RandomSpawn(caller, -704, 704, 0, 0, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "4_final2_laser2_maker": {
			RandomSpawn(caller, 0, 0, -128, 128, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "4_final_laser2_maker": {
			RandomSpawn(caller, 0, 0, -128, 128, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "ex2_boss_blue_maker": {
			RandomSpawn(caller, -512, 512, -512, 512, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "ex1_boss_random_fire_maker": {
			RandomSpawn(caller, -512, 512, -512, 512, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "ex2_boss_yellow_maker": {
			RandomSpawn(caller, 0, 0, -512, 512, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
	}
}

// Connect all makers on script load
local makers = [
	"3_boss_skill_normal_maker",
	"3_boss_skill3_maker",
	"4_final2_laser2_maker",
	"ex2_boss_blue_maker",
	"ex2_boss_yellow_maker",
	"ex1_boss_random_fire_maker",
	"4_final_laser2_maker"
];

foreach(maker in makers)
{
	local entity = Entities.FindByName(null, maker);
	if (entity != null)
		entity.ConnectOutput("OnUser1", "OnRandomSpawn");
}
