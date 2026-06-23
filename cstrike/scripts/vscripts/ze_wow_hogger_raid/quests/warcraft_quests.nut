IncludeScript("warcraft/common.nut");

// -----------------------------------------------------------------------
// Warcraft Quest System
//
// Load once on a dedicated relay (e.g. "quest_relay") via RunScriptFile.
// Call the public API functions from map logic to advance objectives.
//
// Required map entities:
//   quest_relay   — logic_relay that hosts this script
//   quest_display — game_text, X=0.75 Y=0.05, Channel=2, HoldTime=3,
//                   SpawnFlags=1 (all players), FadeIn=0, FadeOut=0
// -----------------------------------------------------------------------

// -----------------------------------------------------------------------
// One-time global state initialisation
// -----------------------------------------------------------------------
{
    local rt = getroottable();
    if (!("WARCRAFT_QUESTS" in rt)) {

        // Quest definitions — objectives are iterated in the 'order' array.
        ::WARCRAFT_QUESTS <- {
            quest1 = {
                title    = "Rescue Ysera",
                complete = false,
                order    = ["escort_ysera", "rescue_whelps"],
                objectives = {
                    escort_ysera  = { text = "Escort Ysera from the cave",  type = "bool",    done = false               },
                    rescue_whelps = { text = "Dragon Whelps Rescued",        type = "counter", done = false, current = 0, target = 3 }
                }
            },
            quest2 = {
                title    = "The Captain's Mission",
                complete = false,
                order    = ["escort_captain", "open_gate", "find_rum", "find_map", "find_bible"],
                objectives = {
                    escort_captain = { text = "Escort Captain to Nide City",  type = "bool", done = false },
                    open_gate      = { text = "Open the Castle Gate",          type = "bool", done = false },
                    find_rum       = { text = "Bottle of Rum",                 type = "bool", done = false },
                    find_map       = { text = "Map",                           type = "bool", done = false },
                    find_bible     = { text = "Bible",                         type = "bool", done = false }
                }
            }
        };

        // Display order for the HUD (tables have no guaranteed iteration order).
        ::WARCRAFT_QUEST_ORDER <- ["quest1", "quest2"];

        ::WARCRAFT_QUEST_DISPLAY_ACTIVE <- false;
    }
}

// Store relay handle for the display think loop (updated each RunScriptFile).
::WARCRAFT_QUEST_RELAY <- self;

// -----------------------------------------------------------------------
// Internal helpers  (root table — callable from anywhere)
// -----------------------------------------------------------------------

::_WQBuildText <- function() {
        local text = "";
        foreach (qKey in ::WARCRAFT_QUEST_ORDER) {
            if (!(qKey in ::WARCRAFT_QUESTS)) { continue; }
            local q = ::WARCRAFT_QUESTS[qKey];

            if (text != "") { text += "\n"; }

            if (q.complete) {
                text += "[" + q.title + " - DONE]\n";
            } else {
                text += "[" + q.title + "]\n";
            }

            foreach (objKey in q.order) {
                local obj = q.objectives[objKey];
                local mark = obj.done ? "+" : "-";
                if (obj.type == "counter") {
                    text += " " + mark + " " + obj.text + ": " + obj.current + "/" + obj.target + "\n";
                } else {
                    text += " " + mark + " " + obj.text + "\n";
                }
            }
        }
        // Trim trailing newline.
        if (text.len() > 0 && text[text.len() - 1] == '\n') {
            text = text.slice(0, text.len() - 1);
        }
        return text;
    };

    ::_WQAllObjectivesDone <- function(q) {
        foreach (objKey in q.order) {
            if (!q.objectives[objKey].done) { return false; }
        }
        return true;
    };

    ::_WQAwardQuestExp <- function() {
        if (!("WARCRAFTAwardExp" in getroottable())) { return; }
        for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
            if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
            ::WARCRAFTAwardExp(p, 500, false);
        }
    };

    ::_WQCheckCompletion <- function(questKey) {
        local q = ::WARCRAFT_QUESTS[questKey];
        if (q.complete || !::_WQAllObjectivesDone(q)) { return; }
        q.complete = true;
        ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFD700[Quest Complete] \x07FFFFFF" + q.title + "!");
        ::_WQAwardQuestExp();
        if ("WARCRAFT_QUEST_CALLBACKS" in getroottable() && questKey in ::WARCRAFT_QUEST_CALLBACKS) {
            ::WARCRAFT_QUEST_CALLBACKS[questKey]();
        }
        ::WARCRAFTQuestRefreshDisplay();
        // Stop the HUD once every quest is complete — the game_text fades out on its own.
        local allDone = true;
        foreach (qk in ::WARCRAFT_QUEST_ORDER) {
            if (!::WARCRAFT_QUESTS[qk].complete) { allDone = false; break; }
        }
        if (allDone) { ::WARCRAFT_QUEST_DISPLAY_ACTIVE = false; }
    };

// -----------------------------------------------------------------------
// Quest completion callbacks — all entity I/O fired directly from script.
// Redefined on every RunScriptFile so edits take effect without a full
// map restart.
// -----------------------------------------------------------------------

// Helper: fire an input on ALL entities matching entName (supports wildcards).
::_WQFire <- function(entName, action, value, delay) {
    for (local e = null; e = Entities.FindByName(e, entName); ) {
        EntFireByHandle(e, action, value, delay, null, null);
    }
};

::WARCRAFT_QUEST_CALLBACKS <- {

    // Quest 1 — Rescue Ysera
    quest1 = function() {
        ::_WQFire("quest_complete_sound", "PlaySound",     "",                                       0.0);
        ::_WQFire("Hold_Print_Case",      "InValue",       "20",                                     0.0);
        ::_WQFire("npc_spawn_4*",          "Trigger",       "",                                      19.0);
        ::_WQFire("warpgate_teleport",    "Enable",        "",                                      20.0);
        ::_WQFire("server",    "Command",        "say <> The Portal is active <>",                                      21.0);
        ::_WQFire("human_music",      "PickRandomShuffle",       "",                                     20.0);
        ::_WQFire("server",    "Command",        "say <> Follow the road to the castle and accept the quest on the way there <>",                                      25.0);
        ::_WQFire("server",    "Command",        "sv_enablebunnyhopping 1",                                      25.0);
        ::_WQFire("main_script",          "RunScriptCode", "WARCRAFTScheduleAfkTeleportNotice(15)", 30.0);
        ::_WQFire("afk_teleport_4",       "Enable",        "",                                      45.0);
        ::_WQFire("ysera_model",          "Kill",          "",                                      60.0);
    },

    // Quest 2 — The Captain's Mission
    quest2 = function() {
        ::_WQFire("npc_spawn_5*",          "Trigger",             "",                      15.0);
        ::_WQFire("quest_complete_sound", "PlaySound",           "",                       0.0);
        ::_WQFire("guard_2*",              "Kill",                "",                      35.0);
        ::_WQFire("guard2_sound",         "Kill",                "",                      35.0);
        ::_WQFire("barricade_3",          "Kill",                "",                      15.0);
        ::_WQFire("guard_2*",              "SetDefaultAnimation", "dead",                  14.05);
        ::_WQFire("guard2_sound",         "PlaySound",           "",                      14.0);
        ::_WQFire("guard_2*",              "SetAnimation",        "death",                 14.0);
        ::_WQFire("captain_model",        "RunScriptCode",       "ResumeEscortWalking()",  8.0);
    }
};

// -----------------------------------------------------------------------
// Display  (root table — no guard so the latest code always applies)
// -----------------------------------------------------------------------

::WARCRAFTQuestRefreshDisplay <- function() {
    local ent = Entities.FindByName(null, "quest_display");
    if (!WARCRAFTIsValidEntity(ent)) {
        // Only warn once per session so we don't spam chat every 2.5 s.
        if (!("_wqMissingWarned" in getroottable())) {
            ::_wqMissingWarned <- true;
            printl("[Quest] WARNING: 'quest_display' game_text entity not found in map.");
            ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FF4444[Quest] WARNING: Add a 'quest_display' game_text entity to your map.");
        }
        return;
    }
    local text = ::_WQBuildText();
    ent.KeyValueFromString("message", text);
    ent.KeyValueFromString("holdtime", "120");
    // Fire Display per player — bypasses spawnflag requirement entirely.
    local fired = false;
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!p.IsValid()) { continue; }
        EntFireByHandle(ent, "Display", "", 0.0, p, p);
        fired = true;
    }
    if (!fired) {
        EntFireByHandle(ent, "Display", "", 0.0, null, null);
    }
};

// -----------------------------------------------------------------------
// Display think loop  (relay scope — scheduled via RunScriptCode)
// -----------------------------------------------------------------------

function WARCRAFTQuestDisplayThink() {
    if (!::WARCRAFT_QUEST_DISPLAY_ACTIVE || !WARCRAFTIsValidEntity(self)) { return; }
    ::WARCRAFTQuestRefreshDisplay();
    EntFireByHandle(self, "RunScriptCode", "WARCRAFTQuestDisplayThink()", 30.0, null, null);
}

// -----------------------------------------------------------------------
// Public API  (root table — call from map logic via RunScriptCode)
// -----------------------------------------------------------------------

// Start the continuous HUD display.  Call once when the map section begins.
if (!("WARCRAFTStartQuestDisplay" in getroottable())) {
    ::WARCRAFTStartQuestDisplay <- function() {
        if (::WARCRAFT_QUEST_DISPLAY_ACTIVE) { return; }
        ::WARCRAFT_QUEST_DISPLAY_ACTIVE = true;
        if (WARCRAFTIsValidEntity(::WARCRAFT_QUEST_RELAY)) {
            EntFireByHandle(::WARCRAFT_QUEST_RELAY, "RunScriptCode",
                "WARCRAFTQuestDisplayThink()", 0.1, null, null);
        }
        ::WARCRAFTQuestRefreshDisplay();
    };
}

// Mark a boolean objective as complete.
// Example: WARCRAFTQuestObjectiveDone("quest1", "escort_ysera")
if (!("WARCRAFTQuestObjectiveDone" in getroottable())) {
    ::WARCRAFTQuestObjectiveDone <- function(questKey, objKey) {
        if (!(questKey in ::WARCRAFT_QUESTS)) { return; }
        local q   = ::WARCRAFT_QUESTS[questKey];
        if (q.complete) { return; }
        if (!(objKey in q.objectives)) { return; }
        local obj = q.objectives[objKey];
        if (obj.done) { return; }
        obj.done = true;
        ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFD700[Quest] \x07AAFFAA" + obj.text + " \x07FFFFFF— complete!");
        ::_WQCheckCompletion(questKey);
        ::WARCRAFTQuestRefreshDisplay();
    };
}

// Increment a counter objective by 1.
// Example: WARCRAFTQuestObjectiveIncrement("quest1", "rescue_whelps")
if (!("WARCRAFTQuestObjectiveIncrement" in getroottable())) {
    ::WARCRAFTQuestObjectiveIncrement <- function(questKey, objKey) {
        if (!(questKey in ::WARCRAFT_QUESTS)) { return; }
        local q   = ::WARCRAFT_QUESTS[questKey];
        if (q.complete) { return; }
        if (!(objKey in q.objectives)) { return; }
        local obj = q.objectives[objKey];
        if (obj.done) { return; }
        obj.current += 1;
        if (obj.current >= obj.target) {
            obj.current = obj.target;
            obj.done    = true;
            ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FFD700[Quest] \x07AAFFAA" + obj.text + ": " +
                obj.current + "/" + obj.target + " \x07FFFFFF— complete!");
        } else {
            ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FFD700[Quest] \x07FFFFFF" + obj.text + ": " +
                obj.current + "/" + obj.target);
        }
        ::_WQCheckCompletion(questKey);
        ::WARCRAFTQuestRefreshDisplay();
    };
}

// Reset all quests back to their starting state (e.g. on round restart).
if (!("WARCRAFTQuestReset" in getroottable())) {
    ::WARCRAFTQuestReset <- function() {
        foreach (qKey in ::WARCRAFT_QUEST_ORDER) {
            local q = ::WARCRAFT_QUESTS[qKey];
            q.complete = false;
            foreach (objKey in q.order) {
                local obj = q.objectives[objKey];
                obj.done = false;
                if (obj.type == "counter") { obj.current = 0; }
            }
        }
        ::WARCRAFT_QUEST_DISPLAY_ACTIVE = false;
        ::WARCRAFTQuestRefreshDisplay();
    };
}

// -----------------------------------------------------------------------
// VMF-safe wrappers — no parameters, no quotes needed in Hammer I/O.
// Call these directly from RunScriptCode in the map file.
// -----------------------------------------------------------------------

// Lifecycle
function QuestStart() {
    // Silent reset: wipe objective state without sending a display flash.
    foreach (qKey in ::WARCRAFT_QUEST_ORDER) {
        local q = ::WARCRAFT_QUESTS[qKey];
        q.complete = false;
        foreach (objKey in q.order) {
            local obj = q.objectives[objKey];
            obj.done = false;
            if (obj.type == "counter") { obj.current = 0; }
        }
    }
    ::WARCRAFT_QUEST_DISPLAY_ACTIVE = false;
    ::WARCRAFTStartQuestDisplay();
}
function QuestReset()  { ::WARCRAFTQuestReset(); }

// Quest 1 — Rescue Ysera
function Quest1EscortYseraDone()     { ::WARCRAFTQuestObjectiveDone("quest1", "escort_ysera"); }
function Quest1RescueWhelpProgress() { ::WARCRAFTQuestObjectiveIncrement("quest1", "rescue_whelps"); }

// Quest 2 — The Captain's Mission
function Quest2EscortCaptainDone() { ::WARCRAFTQuestObjectiveDone("quest2", "escort_captain"); }
function Quest2OpenGateDone()      { ::WARCRAFTQuestObjectiveDone("quest2", "open_gate"); }
function Quest2FindRumDone()       { ::WARCRAFTQuestObjectiveDone("quest2", "find_rum"); }
function Quest2FindMapDone()       { ::WARCRAFTQuestObjectiveDone("quest2", "find_map"); }
function Quest2FindBibleDone()     { ::WARCRAFTQuestObjectiveDone("quest2", "find_bible"); }
