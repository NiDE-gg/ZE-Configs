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
		// Level 1
		case "lvl1_cube_line_maker": {
			RandomSpawn(caller, 0, 0, -864, 864, -864, 864, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl1_final_push_maker": {
			RandomSpawn(caller, -128, 128, -128, 128, 0, 0, 1.0, 1.0, 1.0);
			break;
		}

		// Level 2
		case "lvl2_boss_skill1_maker": {
			RandomSpawn(caller, 0, 0, -192, 192, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl2_boss_skill2_maker": {
			RandomSpawn(caller, -640, 640, -256, 256, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl2_final_cube_line_maker1": {
			RandomSpawn(caller, 0, 0, -256, 256, -768, 768, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl2_final_cube_line_maker2": {
			RandomSpawn(caller, 0, 0, -256, 256, -768, 768, 1.0, 1.0, 1.0);
			break;
		}

		// Level 3
		case "lvl3_push_line_maker1": {
			RandomSpawn(caller, -192, 192, -96, 96, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl3_push_line_maker2": {
			RandomSpawn(caller, -192, 192, -96, 96, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl3_boss_skill1_maker": {
			RandomSpawn(caller, 0, 0, -128, 128, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl3_ending_beam_maker": {
			RandomSpawn(caller, -128, 128, -128, 128, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl3_ending_maker": {
			RandomSpawn(caller, -256, 256, -256, 256, 0, 0, 1.0, 1.0, 1.0);
			break;
		}

		// Level 4
		case "lvl4_cube1_beam_maker": {
			RandomSpawn(caller, -768, 768, -768, 768, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl4_cube3_danmaku_maker": {
			RandomSpawn(caller, 0, 0, -416, 416, -32, 32, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl4_boss_skill3_maker": {
			RandomSpawn(caller, -576, 576, 0, 0, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl4_boss_skill3_maker2": {
			RandomSpawn(caller, -608, 608, 0, 0, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl4_boss_skill6_maker": {
			RandomSpawn(caller, -576, 576, 0, 0, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl4_boss_skill7_maker": {
			RandomSpawn(caller, -576, 576, 0, 0, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl4_final_push_maker": {
			RandomSpawn(caller, -128, 128, -256, 256, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl4_final_boss_danmaku_maker": {
			RandomSpawn(caller, 0, 0, -256, 256, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
		case "lvl4_final_boss_beam_maker": {
			RandomSpawn(caller, 0, 0, -192, 192, 0, 0, 1.0, 1.0, 1.0);
			break;
		}

		// RTV
		case "rtv_beam_maker": {
			RandomSpawn(caller, -540, 540, -540, 540, 0, 0, 1.0, 1.0, 1.0);
			break;
		}
	}
}

// Connect all makers on script load
local makers = [
	// Level 1
	"lvl1_cube_line_maker",
	"lvl1_final_push_maker",

	// Level 2
	"lvl2_boss_skill1_maker",
	"lvl2_boss_skill2_maker",
	"lvl2_final_cube_line_maker1",
	"lvl2_final_cube_line_maker2",

	// Level 3
	"lvl3_push_line_maker1",
	"lvl3_push_line_maker2",
	"lvl3_boss_skill1_maker",
	"lvl3_ending_beam_maker",
	"lvl3_ending_maker",

	// Level 4
	"lvl4_cube1_beam_maker",
	"lvl4_cube3_danmaku_maker",
	"lvl4_boss_skill3_maker",
	"lvl4_boss_skill3_maker2",
	"lvl4_boss_skill6_maker",
	"lvl4_boss_skill7_maker",
	"lvl4_final_push_maker",
	"lvl4_final_boss_danmaku_maker",
	"lvl4_final_boss_beam_maker",

	// RTV
	"rtv_beam_maker"
];

foreach(maker in makers)
{
	local entity = Entities.FindByName(null, maker);
	if (entity != null)
		entity.ConnectOutput("OnUser1", "OnRandomSpawn");
}
