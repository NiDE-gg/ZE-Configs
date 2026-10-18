// ============================================================================
// Score and leaderboard. Each round is a run: grimoires and tomes the humans still carry
// when they escape, chest loot and survivors make its score. Escaped runs go on a
// leaderboard kept in cstrike/scriptdata/ (the best VT.Cfg.Score.Keep runs); every player's
// own stats (escapes, best run, loot found...) are kept in their level file.
//   !top / !leaderboard   the best runs
//   !stats                your own record
// loot.nut counts the books carried and the loot dice found; this file reads its totals.
// ============================================================================

VT.Score <- {};
VT.Keep("Board", null);    // [ { score, time, g, t, l, s, date, names } ], best first
VT.Keep("Run", null);

function VT::Score::NewRun()
{
	VT.Run = { start = Time(), credited = {}, by = {}, bombs = 0 };
}

// Someone collected something: grimoire / tome / loot / bomb. `item` = the pickup entity (credited once).
function VT::Score::Collect(p, kind, item = null)
{
	if (p == null || !p.IsValid() || !p.IsPlayer()) return;
	if (VT.Run == null) VT.Score.NewRun();
	if (item != null)
	{
		if (item in VT.Run.credited) return;      // dropped and picked up again
		VT.Run.credited[item] <- true;
	}
	if (kind != "bomb") VT.Levels.Award(p, kind);
	VT.Voice.OnCollect(p, kind);
	VT.Levels.Stat(p, kind, 1);
	local name = VT.Name(p);
	if (!(name in VT.Run.by)) VT.Run.by[name] <- 0;
	VT.Run.by[name] += (kind in VT.Cfg.Score) ? VT.Cfg.Score[kind] : 1;
}

// This round's grimoires / tomes carried by living humans and loot dice found (loot.nut)
function VT::Score::Totals()
{
	return VT.Loot.Totals();
}

function VT::Score::Today()
{
	try
	{
		local t = {};
		LocalTime(t);
		return format("%04d-%02d-%02d", t.year, t.month, t.day);
	}
	catch (e) {}
	return "";
}

function VT::Score::Clock(sec)
{
	sec = sec.tointeger();
	return format("%d:%02d", sec / 60, sec % 60);
}

// ----------------------------------------------------------------------------- the board

function VT::Score::Load()
{
	VT.Board = [];
	local text = null;
	try { text = FileToString(VT.Cfg.Score.File) } catch (e) {}
	if (text == null) return;
	foreach (line in VT.Split(text, '\n'))
	{
		local f = VT.Split(VT.Trim(line), ';');
		if (f.len() < 7) continue;
		try
		{
			VT.Board.append({ score = f[0].tointeger(), time = f[1].tointeger(), g = f[2].tointeger(), t = f[3].tointeger(),
				l = f[4].tointeger(), s = f[5].tointeger(), date = f[6], names = f.len() > 7 ? f[7] : "" });
		}
		catch (e) {}
	}
	VT.Board.sort(VT.Score.Order);
}

function VT::Score::Save()
{
	local text = "";
	foreach (r in VT.Board)
		text += r.score + ";" + r.time + ";" + r.g + ";" + r.t + ";" + r.l + ";" + r.s + ";" + r.date + ";" + r.names + "\n";
	try { StringToFile(VT.Cfg.Score.File, text) } catch (e) { printl("[VT] couldn't save the leaderboard") }
}

// best score first; a faster escape breaks a tie
function VT::Score::Order(a, b)
{
	if (a.score != b.score) return b.score <=> a.score;
	return a.time <=> b.time;
}

function VT::Score::Board()
{
	if (VT.Board == null) VT.Score.Load();
	return VT.Board;
}

// Names without the characters the file format uses
function VT::Score::Clean(name)
{
	local out = "";
	foreach (ch in name) out += (ch == ';' || ch == ',' || ch < 32) ? " " : ch.tochar();
	return out;
}

// ----------------------------------------------------------------------------- end of a round

function VT::Score::OnRoundEnd(winner)
{
	local board = VT.Score.Board();
	if (VT.Run == null) VT.Score.NewRun();
	local humans = VT.Humans();
	foreach (p in VT.Players()) if (p.GetTeam() == VT_TEAM_HUMAN || p.GetTeam() == VT_TEAM_ZOMBIE) VT.Levels.Stat(p, "runs", 1);
	if (winner != VT_TEAM_HUMAN)
	{
		VT.Chat("The humans fell - this run doesn't count. Best run so far: " + (board.len() > 0 ? board[0].score + " points" : "none yet") + ".");
		return;
	}

	local T = VT.Score.Totals(), C = VT.Cfg.Score;
	local rats = ("rats" in VT.Run) ? VT.Run.rats : 0;
	local score = T.g * C.grimoire + T.t * C.tome + T.l * C.loot + humans.len() * C.survivor + rats * C.lootrat;

	// the three who found the most
	local list = [];
	foreach (name, pts in VT.Run.by) list.append({ name = name, pts = pts });
	list.sort(@(a, b) b.pts <=> a.pts);
	local names = "";
	for (local i = 0; i < list.len() && i < 3; i++) names += (i > 0 ? ", " : "") + VT.Score.Clean(list[i].name);

	local run = { score = score.tointeger(), time = (Time() - VT.Run.start).tointeger(), g = T.g, t = T.t, l = T.l,
		s = humans.len(), date = VT.Score.Today(), names = names };
	board.append(run);
	board.sort(VT.Score.Order);
	local rank = board.find(run) + 1;
	if (board.len() > C.Keep) board.resize(C.Keep);
	if (rank <= C.Keep) VT.Score.Save();

	foreach (p in humans)
	{
		VT.Levels.Stat(p, "escapes", 1);
		VT.Levels.Stat(p, "best", run.score, true);
	}

	VT.Chat("\x07FFD700Escaped! Run score " + run.score + "\x07FFFFFF (" + T.g + " grimoires, " + T.t + " tomes, " + T.l
		+ " loot, " + run.s + " survivors" + (rats > 0 ? ", " + rats + " loot rat" + (rats > 1 ? "s" : "") : "") + ", " + VT.Score.Clock(run.time) + ")");
	if (rank == 1)
	{
		VT.Chat("\x07FFD700NEW BEST RUN ON THE LEADERBOARD!");
		foreach (p in VT.Players()) VT.Voice.Ui(p, ["ui/new_record_mvp", "ui/new_record"]);
	}
	else if (rank <= C.Keep) VT.Chat("That's #" + rank + " on the leaderboard - type !top");
}

// ----------------------------------------------------------------------------- chat

function VT::Score::ShowTop(p)
{
	local board = VT.Score.Board();
	if (board.len() == 0) { VT.Chat("No escapes on the leaderboard yet - be the first!", p); return; }
	VT.Chat("\x07FFD700Best runs:", p);
	for (local i = 0; i < board.len() && i < 5; i++)
	{
		local r = board[i];
		VT.Chat("#" + (i + 1) + "  \x07FFD700" + r.score + "\x07FFFFFF pts - " + r.g + " grim, " + r.t + " tomes, " + r.l + " loot, "
			+ r.s + " alive, " + VT.Score.Clock(r.time) + (r.names != "" ? " - " + r.names : "") + (r.date != "" ? " (" + r.date + ")" : ""), p);
	}
}

function VT::Score::ShowStats(p)
{
	local prof = VT.Levels.Get(p);
	if (prof == null) { VT.Chat("Stats need a confirmed SteamID - try again in a moment.", p); return; }
	local s = prof.stats;
	local g = @(k) (k in s) ? s[k] : 0;
	VT.Chat("Level " + VT.Levels.Level(p) + " - escapes " + g("escapes") + " / " + g("runs") + " rounds, best run " + g("best")
		+ " pts, found " + g("grimoire") + " grimoires, " + g("tome") + " tomes, " + g("loot") + " loot, " + g("bomb") + " bombs, killed "
		+ g("special") + " specials and " + g("monster") + " monsters", p);
}

function VT::Score::OnSay(p, cmd)
{
	if (cmd == "!top" || cmd == "!leaderboard" || cmd == "!best") { VT.Score.ShowTop(p); return true; }
	if (cmd == "!stats" || cmd == "!stat") { VT.Score.ShowStats(p); return true; }
	return false;
}

// ----------------------------------------------------------------------------- round summary

// What each profile had when this round started (XP, stats), so the round's gains can be shown at the end.
// Profiles load lazily, so a player first seen mid-round is recorded then.
VT.Keep("RoundStartProf", {});
function VT::Score::Snapshot(p)
{
	local prof = VT.Levels.Get(p);
	if (prof == null) return;
	local id = VT.SteamID(p);
	if (id in VT.RoundStartProf) return;
	VT.RoundStartProf[id] <- { xp = prof.xp, stats = clone prof.stats };
}
VT.EveryRound(function() { VT.RoundStartProf = {}; foreach (p in VT.Players()) VT.Score.Snapshot(p); });

function VT::Score::Summary(winner)
{
	if (!VT.Cfg.Summary) return;
	// one headline for everyone (two fixed texts)
	local e = Entities.FindByName(null, "vt_summary_text");
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = "vt_summary_text", x = -1, y = 0.18, effect = 2,
			color = "255 210 90", color2 = "255 255 255", fadein = 0.04, fadeout = 1.0, holdtime = 5.0, fxtime = 0.2,
			channel = 4, spawnflags = 1, message = " " });
	if (e != null)
	{
		e.KeyValueFromString("message", winner == VT_TEAM_HUMAN ? "THE HEROES ESCAPED" : "THE HORDE PREVAILS");
		e.KeyValueFromString("color", winner == VT_TEAM_HUMAN ? "255 210 90" : "220 60 50");
		e.AcceptInput("Display", "", null, null);
	}
	// each player's own round, in chat (chat costs no pooled strings)
	foreach (p in VT.Players())
	{
		local prof = VT.Levels.Get(p);
		if (prof == null) continue;
		local id = VT.SteamID(p);
		local st = (id in VT.RoundStartProf) ? VT.RoundStartProf[id] : { xp = prof.xp, stats = {} };
		local gained = prof.xp - st.xp;
		local diff = @(k) ((k in prof.stats) ? prof.stats[k] : 0) - ((k in st.stats) ? st.stats[k] : 0);
		local lv = VT.Levels.FromXp(prof.xp);
		local parts = [];
		foreach (k in [["special", "specials killed"], ["monster", "monsters killed"], ["grimoire", "grimoires"], ["tome", "tomes"],
			["loot", "loot"], ["lootrat", "loot rats"], ["infect", "infections"]])
		{
			local n = diff(k[0]);
			if (n > 0) parts.append(n + " " + k[1]);
		}
		local txt = "";
		foreach (i, s in parts) txt += (i > 0 ? ", " : "") + s;
		VT.Chat("\x07FFD700Your round: +" + gained + " XP\x07FFFFFF  (level " + lv.level + ", " + lv.into + "/" + lv.need + ")"
			+ (txt != "" ? "  -  " + txt : ""), p);
	}
}

// The top runs on screen for a few seconds at the start of a round (one text per round, so no string-pool growth
// worth mentioning)
function VT::Score::BoardPanel()
{
	if (!VT.Cfg.BoardPanel) return;
	local board = VT.Score.Board();
	if (board.len() == 0) return;
	local e = Entities.FindByName(null, "vt_board_text");
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = "vt_board_text", x = 0.02, y = 0.25, effect = 0,
			color = "255 210 90", color2 = "255 255 255", fadein = 0.3, fadeout = 1.0, holdtime = VT.Cfg.BoardPanelTime, fxtime = 0.0,
			channel = 5, spawnflags = 1, message = " " });
	if (e == null) return;
	local txt = "BEST RUNS";
	for (local i = 0; i < board.len() && i < 5; i++)
	{
		local r = board[i];
		txt += "\n#" + (i + 1) + "  " + r.score + " pts  " + VT.Score.Clock(r.time) + (r.names != "" ? "  " + VT.Score.Clean(r.names) : "");
	}
	if (!VT.TextOk(txt)) return;
	e.KeyValueFromString("message", txt);
	e.AcceptInput("Display", "", null, null);
}

// A reminder at the start of a round
function VT::Score::Announce()
{
	VT.Score.BoardPanel();
	local board = VT.Score.Board();
	if (board.len() > 0)
		VT.Chat("Best run: \x07FFD700" + board[0].score + "\x07FFFFFF points" + (board[0].names != "" ? " by " + board[0].names : "")
			+ ". Carry grimoires and tomes to the end, loot the chests! (!top, !stats, !career, !level)");
}
