//--------------------------------------------------
// Contest_map_2026_lardy.nut
//--------------------------------------------------

::SelectionPortal <- {};

//--------------------------------------------------
// CONFIG HAMMER
//--------------------------------------------------

::SelectionPortal.scriptEntityName <- "script_contest_map_2026_lardy";

::SelectionPortal.makerName <- "maker_selection";
::SelectionPortal.templateName <- "temp_selection";

::SelectionPortal.triggerName <- "selection_trigger";
::SelectionPortal.modelName <- "selection_trigger_model";

::SelectionPortal.hurtName <- "selection_hurt";

::SelectionPortal.endRelayWildcard <- "relay_end_trigger_*";

// Si true : tue les entités du portail à la fin.
// Attention : avec plusieurs portails ayant le même nom, ça tuera tout.
::SelectionPortal.cleanupPortalOnEnd <- false;

// Si true : Disable le trigger quand la sélection est finie.
::SelectionPortal.disableTriggerOnEnd <- true;

//--------------------------------------------------
// CONFIG SELECTION
//--------------------------------------------------

::SelectionPortal.selectionDuration <- 30.0;
::SelectionPortal.thinkInterval <- 0.25;
::SelectionPortal.maxSelectedPlayers <- 7;
::SelectionPortal.proportionalSelectionPercent <- 25.0;
::SelectionPortal.proportionalSelectionMin <- 1;

//--------------------------------------------------
// CONFIG JUDGEMENT / !KILL
//--------------------------------------------------

// La commande !kill s'ouvre après la moitié du temps total de sélection.
::SelectionPortal.killVoteOpenFraction <- 0.5;

// Délai de grâce adaptatif après validation du vote :
// ceil(temps restant * facteur), limité entre le minimum et le maximum.
// Exemple avec facteur 0.4 : 25s -> 10s, 20s -> 8s, 15s -> 6s, 12s -> 5s.
::SelectionPortal.killVoteGraceTimeLeftFactor <- 0.4;
::SelectionPortal.killVoteGraceMinDelay <- 5.0;
::SelectionPortal.killVoteGraceMaxDelay <- 10.0;

// Pendant les 5 dernières secondes, le vote validé tue immédiatement.
::SelectionPortal.killVoteInstantWindow <- 5.0;

// Canal distinct du HUD principal (canal 3) et du HUD RaDodgeTrial (canal 4).
// Le canal 2 sert uniquement à remplacer en rouge la ligne du joueur jugé.
::SelectionPortal.judgementHudChannel <- 2;

//--------------------------------------------------
// ETAT
//--------------------------------------------------


::SelectionPortal.selectionPunishDelay <- 3.0;
::SelectionPortal.selectionPunishIgniteTime <- 2.0;
::SelectionPortal.nextSelectionDuration <- null;
::SelectionPortal.selectionActive <- false;
::SelectionPortal.selectionSessionId <- 0;

::SelectionPortal.selectedPlayers <- {};
::SelectionPortal.insidePlayers <- {};
::SelectionPortal.touchCounts <- {};
::SelectionPortal.userIdToSelectionKey <- {};

::SelectionPortal.selectedCountAtStart <- 0;

::SelectionPortal.dynamicHudIndex <- 0;

::SelectionPortal.selectionTextName <- null;
::SelectionPortal.selectionTextEnt <- null;

::SelectionPortal.hudRefreshInterval <- 0.25;
::SelectionPortal.selectionEndTime <- 0.0;
::SelectionPortal.selectionVoteOpenTime <- 0.0;

// Votes : targetKey -> { target = player, voters = { voterKey = true } }
::SelectionPortal.killVotes <- {};

// Un joueur ne peut soutenir qu'une seule cible à la fois.
::SelectionPortal.killVoteByVoter <- {};

// Jugement avec délai de grâce.
::SelectionPortal.judgedTargetKey <- "";
::SelectionPortal.judgedTargetPlayer <- null;
::SelectionPortal.judgementEndTime <- 0.0;
::SelectionPortal.judgementSessionId <- 0;

// Verrou très court pour éviter un second !kill pendant une exécution instantanée.
::SelectionPortal.instantExecutionTargetKey <- "";
::SelectionPortal.instantExecutionSessionId <- 0;

// HUD rouge affiché uniquement pendant le délai de grâce.
// Il ne contient qu'une ligne et se place exactement sur la ligne masquée du HUD vert.
::SelectionPortal.judgementTextName <- null;
::SelectionPortal.judgementTextEnt <- null;
::SelectionPortal.judgementHudLeadingLines <- -1;

//--------------------------------------------------
// OUTILS GENERAUX
//--------------------------------------------------

//--------------------------------------------------
// HUD GAME_TEXT
//--------------------------------------------------

::SelectionPortal.ClearSelectionHudForPlayer <- function(player)
{
    if (!this.IsValidPlayer(player))
        return;

    if (this.selectionTextEnt == null || !this.selectionTextEnt.IsValid())
        return;

    this.selectionTextEnt.__KeyValueFromString("message", "");
    EntFireByHandle(this.selectionTextEnt, "Display", "", 0.00, player, null);
}

::SelectionPortal.FormatIndex <- function(i)
{
    if (i < 10) return "000" + i;
    if (i < 100) return "00" + i;
    if (i < 1000) return "0" + i;
    return "" + i;
}

::SelectionPortal.CreateGameTextEntity <- function(targetname, x, y, color, color2, channel, effect = 0, fxtime = 0.0, holdtime = 1.0, fadein = 0.0, fadeout = 0.0, spawnflags = 0)
{
    local gt = SpawnEntityFromTable("game_text", {
        targetname = targetname,
        message = "",
        x = x,
        y = y,
        effect = effect,
        color = color,
        color2 = color2,
        fadein = fadein,
        fadeout = fadeout,
        holdtime = holdtime,
        fxtime = fxtime,
        channel = channel,
        spawnflags = spawnflags
    });

    return gt;
}

::SelectionPortal.CreateSelectionHudText <- function()
{
    this.KillSelectionHudText();

    this.dynamicHudIndex += 1;
    local idx = this.FormatIndex(this.dynamicHudIndex);

    this.selectionTextName = "gt_selection_portal_" + idx;

    this.selectionTextEnt = this.CreateGameTextEntity(
        this.selectionTextName,
        0.02, 0.23,
        "100 255 100",
        "255 255 255",
        3,
        0,
        0.0,
        1.0,
        0.0,
        0.0,
        0
    );
}


::SelectionPortal.CreateJudgementHudText <- function()
{
    this.KillJudgementHudText();

    this.dynamicHudIndex += 1;
    local idx = this.FormatIndex(this.dynamicHudIndex);

    this.judgementTextName = "gt_selection_judgement_" + idx;

    this.judgementTextEnt = this.CreateGameTextEntity(
        this.judgementTextName,
        0.02, 0.23,
        "255 60 60",
        "255 60 60",
        this.judgementHudChannel,
        0,
        0.0,
        1.0,
        0.0,
        0.0,
        0
    );
}

::SelectionPortal.KillJudgementHudText <- function()
{
    if (this.judgementTextEnt != null && this.judgementTextEnt.IsValid())
    {
        this.judgementTextEnt.__KeyValueFromString("message", "");
        this.ShowGameTextToAllPlayers(this.judgementTextEnt);
        EntFireByHandle(this.judgementTextEnt, "Kill", "", 0.05, null, null);
    }

    this.judgementTextEnt = null;
    this.judgementTextName = null;
}

::SelectionPortal.KillSelectionHudText <- function()
{
    if (this.selectionTextEnt != null && this.selectionTextEnt.IsValid())
    {
        this.selectionTextEnt.__KeyValueFromString("message", "");
        this.ShowGameTextToAllPlayers(this.selectionTextEnt);
        EntFireByHandle(this.selectionTextEnt, "Kill", "", 0.05, null, null);
    }

    this.selectionTextEnt = null;
    this.selectionTextName = null;
}

::SelectionPortal.ShowGameTextToAllHumans <- function(ent)
{
    if (ent == null || !ent.IsValid())
        return;

    local p = null;

    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (!this.IsHumanPlayer(p))
            continue;

        EntFireByHandle(ent, "Display", "", 0.00, p, null);
    }
}

::SelectionPortal.ShowGameTextToAllPlayers <- function(ent)
{
    if (ent == null || !ent.IsValid())
        return;

    local p = null;

    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (!this.IsValidPlayer(p))
            continue;

        EntFireByHandle(ent, "Display", "", 0.00, p, null);
    }
}

::SelectionPortal.ShortName <- function(name, maxLen)
{
    if (name == null)
        return "";

    local s = name.tostring();

    if (s.len() <= maxLen)
        return s;

    return s.slice(0, maxLen);
}

::SelectionPortal.UpdateJudgementHudText <- function()
{
    if (this.judgedTargetKey == "")
        return;

    if (this.judgementTextEnt == null || !this.judgementTextEnt.IsValid())
        return;

    if (this.judgementHudLeadingLines < 0)
        return;

    local target = this.judgedTargetPlayer;

    if (!this.IsValidPlayer(target))
        return;

    local timeLeft = this.judgementEndTime - Time();
    if (timeLeft < 0.0)
        timeLeft = 0.0;

    local seconds = this.GetCeilSeconds(timeLeft);

    // Les sauts de ligne placent la ligne rouge exactement à la même hauteur
    // que la ligne volontairement vide dans le HUD vert.
    local msg = "";

    for (local i = 0; i < this.judgementHudLeadingLines; i++)
        msg += "\n";

    msg += "[WILL DIE: " + seconds + "s] ";
    msg += this.ShortName(this.GetPlayerDisplayName(target), 18);

    this.judgementTextEnt.__KeyValueFromString("message", msg);
    this.ShowGameTextToAllPlayers(this.judgementTextEnt);
}

::SelectionPortal.UpdateSelectionHudText <- function()
{
    if (!this.selectionActive)
        return;

    if (this.selectionTextEnt == null || !this.selectionTextEnt.IsValid())
        return;

    local timeLeft = this.GetSelectionTimeLeft();
    local insideCount = this.CountEligibleKillVoters();
    local selectedCount = this.CountTable(this.selectedPlayers);

    local msg = "RA'S TRIAL";
    msg += "\nChosen souls must reach the Portal";
    msg += "\nTime: " + this.GetCeilSeconds(timeLeft) + "s";
    msg += "\nSafe: " + insideCount + "/" + selectedCount;

    if (this.IsKillVoteOpen())
    {
        if (this.HasPendingKillAction())
            msg += "\nJudgement: ACTIVE";
        else
            msg += "\nJudgement: OPEN";
    }
    else
    {
        local voteOpenIn = this.selectionVoteOpenTime - Time();
        if (voteOpenIn < 0.0)
            voteOpenIn = 0.0;

        msg += "\nJudgement opens: " + this.GetCeilSeconds(voteOpenIn) + "s";
    }

    local voteThreshold = this.GetKillVoteThreshold();

    // Le bloc vert contient toujours cinq lignes avant la liste des sélectionnés :
    // titre, consigne, timer, safe count, état du jugement.
    local hudLineIndex = 5;
    this.judgementHudLeadingLines = -1;

    foreach (key, player in this.selectedPlayers)
    {
        if (!this.IsValidPlayer(player))
            continue;

        // Pendant le jugement, on conserve une ligne vide dans le HUD vert.
        // Le game_text rouge écrit ensuite à exactement cette même hauteur.
        if (key == this.judgedTargetKey)
        {
            this.judgementHudLeadingLines = hudLineIndex;
            msg += "\n";
            hudLineIndex++;
            continue;
        }

        local status = "[OUT] ";
        local suffix = "";

        if (this.insidePlayers.rawin(key))
        {
            status = "[SAFE] ";
        }
        else if (this.killVotes.rawin(key))
        {
            local votes = this.GetKillVoteCountForTarget(key);
            if (votes > 0)
                suffix = " Vote: " + votes + "/" + voteThreshold;
        }

        msg += "\n" + status + this.ShortName(this.GetPlayerDisplayName(player), 18) + suffix;
        hudLineIndex++;
    }

    this.selectionTextEnt.__KeyValueFromString("message", msg);
    this.ShowGameTextToAllPlayers(this.selectionTextEnt);
    this.UpdateJudgementHudText();
}

::SelectionPortal.SelectionHudThink <- function(sessionId)
{
    if (sessionId != this.selectionSessionId)
        return;

    if (!this.selectionActive)
        return;

    this.UpdateSelectionHudText();

    this.Schedule("SelectionPortal.SelectionHudThink(" + sessionId + ");", this.hudRefreshInterval);
}

::SelectionPortal.Schedule <- function(code, delay)
{
    EntFire(this.scriptEntityName, "RunScriptCode", code, delay, null);
}

::SelectionPortal.IsValidPlayer <- function(player)
{
    if (player == null)
        return false;

    if (!player.IsValid())
        return false;

    if (player.GetClassname() != "player")
        return false;

    return true;
}

::SelectionPortal.IsPlayerAlive <- function(player)
{
    if (!this.IsValidPlayer(player))
        return false;

    try
    {
        return player.IsAlive();
    }
    catch (e)
    {
        return false;
    }
}

::SelectionPortal.IsHumanPlayer <- function(player)
{
    if (!this.IsValidPlayer(player))
        return false;

    local team = 0;

    try
    {
        team = player.GetTeam();
    }
    catch (e)
    {
        team = 0;
    }

    return team == 3;
}

::SelectionPortal.IsAliveHuman <- function(player)
{
    if (!this.IsHumanPlayer(player))
        return false;

    if (!this.IsPlayerAlive(player))
        return false;

    return true;
}

::SelectionPortal.GetPlayerUniqueKey <- function(player)
{
    if (!this.IsValidPlayer(player))
        return "";

    return player.entindex().tostring();
}

::SelectionPortal.GetPlayerUserID <- function(player)
{
    if (!this.IsValidPlayer(player))
        return 0;

    try
    {
        return NetProps.GetPropInt(player, "m_iUserID");
    }
    catch (e)
    {
        return 0;
    }
}

::SelectionPortal.GetPlayerDisplayName <- function(player)
{
    if (!this.IsValidPlayer(player))
        return "Unknown";

    local n = "";

    try
    {
        n = player.GetName();
    }
    catch (e)
    {
        n = "";
    }

    if (n == null || n == "")
    {
        try
        {
            n = NetProps.GetPropString(player, "m_szNetname");
        }
        catch (e2)
        {
            n = "";
        }
    }

    if (n == null || n == "")
        n = "Unnamed player";

    return n;
}

::SelectionPortal.GetAllAliveHumans <- function()
{
    local arr = [];
    local p = null;

    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (this.IsAliveHuman(p))
            arr.append(p);
    }

    return arr;
}

::SelectionPortal.CountTable <- function(tbl)
{
    local count = 0;

    foreach (k, v in tbl)
        count++;

    return count;
}

::SelectionPortal.HurtPlayer <- function(player)
{
    if (!this.IsValidPlayer(player))
        return;

    EntFire(this.hurtName, "Hurt", "", 0.00, player);
}

//--------------------------------------------------
// JUDGEMENT VOTE / !KILL
//--------------------------------------------------

::SelectionPortal.TrimString <- function(str)
{
    if (str == null)
        return "";

    local s = str.tostring();
    local start = 0;
    local finish = s.len() - 1;

    while (start < s.len())
    {
        local c = s.slice(start, start + 1);
        if (c != " " && c != "\t")
            break;
        start++;
    }

    while (finish >= start)
    {
        local c = s.slice(finish, finish + 1);
        if (c != " " && c != "\t")
            break;
        finish--;
    }

    if (finish < start)
        return "";

    return s.slice(start, finish + 1);
}

::SelectionPortal.GetSelectionTimeLeft <- function()
{
    local timeLeft = this.selectionEndTime - Time();

    if (timeLeft < 0.0)
        timeLeft = 0.0;

    return timeLeft;
}

::SelectionPortal.GetCeilSeconds <- function(value)
{
    if (value <= 0.0)
        return 0;

    local whole = value.tointeger();

    if (value > whole.tofloat())
        whole++;

    return whole;
}

// Le jugement est plus long lorsqu'il démarre tôt, puis diminue avec le temps restant.
// Le résultat est arrondi à la seconde supérieure afin que le HUD et la vraie durée correspondent.
::SelectionPortal.GetAdaptiveKillVoteGraceDelay <- function(timeLeft)
{
    if (timeLeft <= this.killVoteInstantWindow)
        return 0.0;

    local delay = timeLeft * this.killVoteGraceTimeLeftFactor;
    delay = this.GetCeilSeconds(delay).tofloat();

    if (delay < this.killVoteGraceMinDelay)
        delay = this.killVoteGraceMinDelay;

    if (delay > this.killVoteGraceMaxDelay)
        delay = this.killVoteGraceMaxDelay;

    // Sécurité : ne jamais planifier la fin du jugement après la fin de sélection.
    if (delay > timeLeft)
        delay = timeLeft;

    return delay;
}

::SelectionPortal.IsKillVoteOpen <- function()
{
    if (!this.selectionActive)
        return false;

    return Time() >= this.selectionVoteOpenTime;
}

::SelectionPortal.HasPendingKillAction <- function()
{
    if (this.judgedTargetKey != "")
        return true;

    if (this.instantExecutionTargetKey != "")
        return true;

    return false;
}

::SelectionPortal.IsSelectedPlayer <- function(player)
{
    if (!this.IsValidPlayer(player))
        return false;

    local key = this.GetPlayerUniqueKey(player);

    if (key == "")
        return false;

    return this.selectedPlayers.rawin(key);
}

// Votant valide : sélectionné, humain vivant et déjà dans le portail.
::SelectionPortal.IsEligibleKillVoter <- function(player)
{
    if (!this.IsAliveHuman(player))
        return false;

    local key = this.GetPlayerUniqueKey(player);

    if (key == "")
        return false;

    if (!this.selectedPlayers.rawin(key))
        return false;

    if (!this.insidePlayers.rawin(key))
        return false;

    return true;
}

// Cible valide : sélectionnée, humaine vivante et encore hors du portail.
::SelectionPortal.IsEligibleKillTarget <- function(player)
{
    if (!this.IsAliveHuman(player))
        return false;

    local key = this.GetPlayerUniqueKey(player);

    if (key == "")
        return false;

    if (!this.selectedPlayers.rawin(key))
        return false;

    if (this.insidePlayers.rawin(key))
        return false;

    return true;
}

::SelectionPortal.CountEligibleKillVoters <- function()
{
    local count = 0;

    foreach (key, player in this.selectedPlayers)
    {
        if (this.IsEligibleKillVoter(player))
            count++;
    }

    return count;
}

// Majorité stricte des sélectionnés actuellement à l'abri dans le portail.
::SelectionPortal.GetKillVoteThreshold <- function()
{
    local voterCount = this.CountEligibleKillVoters();

    if (voterCount <= 0)
        return 0;

    return (voterCount / 2).tointeger() + 1;
}

::SelectionPortal.GetKillVoteCountForTarget <- function(targetKey)
{
    if (!this.killVotes.rawin(targetKey))
        return 0;

    return this.CountTable(this.killVotes[targetKey].voters);
}

::SelectionPortal.ResetKillVotes <- function()
{
    this.killVotes = {};
    this.killVoteByVoter = {};
}

::SelectionPortal.RemoveVoteForVoter <- function(voterKey)
{
    if (voterKey == "")
        return;

    if (!this.killVoteByVoter.rawin(voterKey))
        return;

    local oldTargetKey = this.killVoteByVoter[voterKey];

    if (this.killVotes.rawin(oldTargetKey))
    {
        local voters = this.killVotes[oldTargetKey].voters;

        if (voters.rawin(voterKey))
            voters.rawdelete(voterKey);

        if (this.CountTable(voters) <= 0)
            this.killVotes.rawdelete(oldTargetKey);
    }

    this.killVoteByVoter.rawdelete(voterKey);
}

// Supprime les votes devenus invalides si un votant sort du portail, meurt,
// change d'équipe, ou si la cible entre dans le portail.
::SelectionPortal.CleanupKillVotes <- function()
{
    local cleanedVotes = {};
    local cleanedVoteByVoter = {};

    foreach (targetKey, data in this.killVotes)
    {
        if (!this.selectedPlayers.rawin(targetKey))
            continue;

        local target = this.selectedPlayers[targetKey];

        if (!this.IsEligibleKillTarget(target))
            continue;

        local voters = {};

        foreach (voterKey, value in data.voters)
        {
            if (!this.selectedPlayers.rawin(voterKey))
                continue;

            local voter = this.selectedPlayers[voterKey];

            if (!this.IsEligibleKillVoter(voter))
                continue;

            // Sécurité : un votant ne peut être conservé que pour une seule cible.
            if (cleanedVoteByVoter.rawin(voterKey))
                continue;

            voters[voterKey] <- true;
            cleanedVoteByVoter[voterKey] <- targetKey;
        }

        if (this.CountTable(voters) > 0)
        {
            cleanedVotes[targetKey] <- {
                target = target,
                voters = voters
            };
        }
    }

    this.killVotes = cleanedVotes;
    this.killVoteByVoter = cleanedVoteByVoter;
}

::SelectionPortal.FindSelectedKillTargetByName <- function(inputName)
{
    local wanted = inputName.tolower();
    local exact = null;
    local partial = null;
    local partialCount = 0;

    foreach (key, player in this.selectedPlayers)
    {
        if (!this.IsEligibleKillTarget(player))
            continue;

        local playerName = this.GetPlayerDisplayName(player).tolower();

        if (playerName == wanted)
        {
            exact = player;
            break;
        }

        if (playerName.find(wanted) != null)
        {
            partial = player;
            partialCount++;
        }
    }

    if (exact != null)
        return exact;

    if (partialCount == 1)
        return partial;

    return null;
}

::SelectionPortal.ExtractKillTargetName <- function(message)
{
    if (message.len() <= 5)
        return "";

    local rest = this.TrimString(message.slice(5, message.len()));

    if (rest.len() >= 2 && rest.slice(0, 1) == "\"" && rest.slice(rest.len() - 1, rest.len()) == "\"")
        rest = rest.slice(1, rest.len() - 1);

    return this.TrimString(rest);
}

::SelectionPortal.IsKillCommand <- function(message)
{
    local msg = this.TrimString(message).tolower();

    if (msg.len() < 5)
        return false;

    if (msg.slice(0, 5) != "!kill")
        return false;

    if (msg.len() == 5)
        return true;

    local separator = msg.slice(5, 6);
    return separator == " " || separator == "\t";
}

::SelectionPortal.StartInstantVoteExecution <- function(target)
{
    if (!this.IsEligibleKillTarget(target))
        return;

    local targetKey = this.GetPlayerUniqueKey(target);
    if (targetKey == "")
        return;

    this.ResetKillVotes();

    this.instantExecutionTargetKey = targetKey;
    this.instantExecutionSessionId += 1;
    local executionId = this.instantExecutionSessionId;
    local sessionId = this.selectionSessionId;

    ClientPrint(null, 3, "\x07FF0000[Ra] " + this.GetPlayerDisplayName(target) + " was judged too late and executed.");

    this.HurtPlayer(target);
    this.Schedule("SelectionPortal.ClearInstantExecutionLock(" + sessionId + "," + executionId + ");", 0.25);
}

::SelectionPortal.ClearInstantExecutionLock <- function(selectionSessionId, executionId)
{
    if (selectionSessionId != this.selectionSessionId)
        return;

    if (executionId != this.instantExecutionSessionId)
        return;

    this.instantExecutionTargetKey = "";
}

::SelectionPortal.StartJudgement <- function(target)
{
    if (this.HasPendingKillAction())
        return;

    if (!this.IsEligibleKillTarget(target))
        return;

    local timeLeft = this.GetSelectionTimeLeft();
    local graceDelay = this.GetAdaptiveKillVoteGraceDelay(timeLeft);

    if (graceDelay <= 0.0)
    {
        this.StartInstantVoteExecution(target);
        return;
    }

    local targetKey = this.GetPlayerUniqueKey(target);
    if (targetKey == "")
        return;

    this.ResetKillVotes();

    this.judgedTargetKey = targetKey;
    this.judgedTargetPlayer = target;
    this.judgementEndTime = Time() + graceDelay;
    this.judgementHudLeadingLines = -1;
    this.judgementSessionId += 1;

    local judgementId = this.judgementSessionId;
    local selectionSessionId = this.selectionSessionId;

    this.CreateJudgementHudText();
    this.UpdateSelectionHudText();

    local targetName = this.GetPlayerDisplayName(target);
    local graceSeconds = this.GetCeilSeconds(graceDelay);
    ClientPrint(null, 3, "\x07FF3300[Ra] " + targetName + " is judged. Reach the Portal in " + graceSeconds + " seconds.");
    ClientPrint(target, 3, "\x07FF0000[Ra] You are judged. Enter the Portal immediately or die.");

    this.Schedule("SelectionPortal.ResolveJudgement(" + selectionSessionId + "," + judgementId + ");", graceDelay);
}

::SelectionPortal.CancelJudgement <- function(reachedPortal = false)
{
    if (this.judgedTargetKey == "")
        return;

    local target = this.judgedTargetPlayer;

    this.judgedTargetKey = "";
    this.judgedTargetPlayer = null;
    this.judgementEndTime = 0.0;
    this.judgementHudLeadingLines = -1;
    this.judgementSessionId += 1;

    this.KillJudgementHudText();
    this.ResetKillVotes();

    if (reachedPortal && this.IsValidPlayer(target))
        ClientPrint(null, 3, "\x0700FF00[Ra] " + this.GetPlayerDisplayName(target) + " reached the Portal. Judgement cancelled.");

    if (this.selectionActive)
        this.UpdateSelectionHudText();
}

::SelectionPortal.ResolveJudgement <- function(selectionSessionId, judgementId)
{
    if (selectionSessionId != this.selectionSessionId)
        return;

    if (judgementId != this.judgementSessionId)
        return;

    if (!this.selectionActive)
        return;

    local target = this.judgedTargetPlayer;

    if (!this.IsEligibleKillTarget(target))
    {
        this.CancelJudgement(false);
        return;
    }

    ClientPrint(null, 3, "\x07FF0000[Ra] " + this.GetPlayerDisplayName(target) + " was executed by judgement.");
    this.HurtPlayer(target);

    // Normalement player_death nettoie le HUD immédiatement. Ce fallback évite
    // toute alerte rouge bloquée si le point_hurt ne tue pas pour une raison externe.
    this.Schedule("SelectionPortal.ClearJudgementAfterExecution(" + selectionSessionId + "," + judgementId + ");", 0.25);
}

::SelectionPortal.ClearJudgementAfterExecution <- function(selectionSessionId, judgementId)
{
    if (selectionSessionId != this.selectionSessionId)
        return;

    if (judgementId != this.judgementSessionId)
        return;

    this.CancelJudgement(false);
}

::SelectionPortal.CheckKillVoteThresholds <- function()
{
    if (!this.IsKillVoteOpen())
        return;

    if (this.HasPendingKillAction())
        return;

    this.CleanupKillVotes();

    local threshold = this.GetKillVoteThreshold();
    if (threshold <= 0)
        return;

    local targetToJudge = null;

    foreach (targetKey, data in this.killVotes)
    {
        if (!this.IsEligibleKillTarget(data.target))
            continue;

        if (this.GetKillVoteCountForTarget(targetKey) >= threshold)
        {
            targetToJudge = data.target;
            break;
        }
    }

    if (targetToJudge != null)
        this.StartJudgement(targetToJudge);
}

::SelectionPortal.HandleKillChatCommand <- function(player, text)
{
    if (!this.IsKillCommand(text))
        return false;

    if (!this.selectionActive)
        return false;

    if (!this.IsKillVoteOpen())
    {
        ClientPrint(player, 3, "\x07FFCC00[Ra] Judgement votes open after half of the selection time.");
        return true;
    }

    if (this.HasPendingKillAction())
    {
        ClientPrint(player, 3, "\x07FFCC00[Ra] A judgement is already in progress.");
        return true;
    }

    if (!this.IsEligibleKillVoter(player))
    {
        ClientPrint(player, 3, "\x07FF0000[Ra] Only selected players inside the Portal may use !kill.");
        return true;
    }

    local msg = this.TrimString(text);
    local targetName = this.ExtractKillTargetName(msg);

    if (targetName == "")
    {
        ClientPrint(player, 3, "\x07FFCC00[Ra] Usage: !kill \"player name\"");
        return true;
    }

    local target = this.FindSelectedKillTargetByName(targetName);

    if (target == null)
    {
        ClientPrint(player, 3, "\x07FF0000[Ra] Target not found, already safe, not selected, dead, or ambiguous.");
        return true;
    }

    local voterKey = this.GetPlayerUniqueKey(player);
    local targetKey = this.GetPlayerUniqueKey(target);

    if (voterKey == "" || targetKey == "" || voterKey == targetKey)
    {
        ClientPrint(player, 3, "\x07FF0000[Ra] Invalid target.");
        return true;
    }

    this.CleanupKillVotes();

    if (this.killVoteByVoter.rawin(voterKey) && this.killVoteByVoter[voterKey] == targetKey)
    {
        ClientPrint(player, 3, "\x07FFCC00[Ra] You already voted against " + this.GetPlayerDisplayName(target) + ".");
        return true;
    }

    // Un seul vote actif par joueur : un nouveau choix retire le précédent.
    this.RemoveVoteForVoter(voterKey);

    if (!this.killVotes.rawin(targetKey))
    {
        this.killVotes[targetKey] <- {
            target = target,
            voters = {}
        };
    }

    this.killVotes[targetKey].voters[voterKey] <- true;
    this.killVoteByVoter[voterKey] <- targetKey;

    local votes = this.GetKillVoteCountForTarget(targetKey);
    local threshold = this.GetKillVoteThreshold();

    ClientPrint(null, 3, "\x07FFCC00[Ra] " + this.GetPlayerDisplayName(target) + ": " + votes + "/" + threshold + " judgement votes.");

    this.UpdateSelectionHudText();
    this.CheckKillVoteThresholds();
    return true;
}

//--------------------------------------------------
// DIVINE PUNISHMENT - SELECTION TIMEOUT
//--------------------------------------------------

::SelectionPortal.StartDivinePunishment <- function(player)
{
    if (!this.IsAliveHuman(player))
        return;

    ClientPrint(player, 3, "\x07FF6600[Ra] Your soul burns under Ra's judgement.");

    // Equivalent Hammer :
    // OnStartTouch -> !activator -> IgniteLifetime -> 1.5
    EntFireByHandle(
        player,
        "IgniteLifetime",
        "3.0",
        0.00,
        player,
        player
    );

    // Kill via le point_hurt comme avant, mais après 2 secondes.
    // Le joueur est passé comme activator.
    EntFire(
        this.hurtName,
        "Hurt",
        "",
        this.selectionPunishDelay,
        player
    );
}

//--------------------------------------------------
// START / SPAWN
//--------------------------------------------------
::SelectionPortal.StartSelectionAndSpawn <- function(count)
{
    local duration = this.selectionDuration;

    if (this.nextSelectionDuration != null)
    {
        duration = this.nextSelectionDuration;
        this.nextSelectionDuration = null;
    }

    this.pendingSelectionCount <- count;
    this.pendingSelectionDuration <- duration;

    this.Schedule("SelectionPortal.StartPendingSelection();", 0.10);
}

::SelectionPortal.GetProportionalSelectionCount <- function(percent = null)
{
    local players = this.GetAllAliveHumans();
    local aliveCount = players.len();

    if (aliveCount <= 0)
        return 0;

    local p = this.proportionalSelectionPercent;

    if (percent != null)
        p = percent.tofloat();

    if (p <= 0.0)
        p = this.proportionalSelectionPercent;

    local rawCount = (aliveCount.tofloat() * p) / 100.0;
    local count = rawCount.tointeger();

    // Sécurité : au moins 1 joueur si des humains sont vivants.
    if (count < this.proportionalSelectionMin)
        count = this.proportionalSelectionMin;

    // Sécurité HUD : jamais plus que maxSelectedPlayers.
    if (count > this.maxSelectedPlayers)
        count = this.maxSelectedPlayers;

    // Sécurité logique : jamais plus que le nombre d'humains vivants.
    if (count > aliveCount)
        count = aliveCount;

    return count;
}

::SelectionPortal.StartSelectionProportionalAndSpawn <- function(percent = null)
{
    local count = this.GetProportionalSelectionCount(percent);

    this.StartSelectionAndSpawn(count);
}

::SelectionPortal.TriggerEndRelay <- function()
{
    EntFire(this.endRelayWildcard, "Trigger", "", 0.00, null);
}


::SelectionPortal.GetSelectionCountByAliveRatio <- function(ratio = 8)
{
    local players = this.GetAllAliveHumans();
    local aliveCount = players.len();

    if (aliveCount <= 0)
        return 0;

    if (ratio <= 0)
        ratio = 8;

    local rawCount = aliveCount.tofloat() / ratio.tofloat();
    local count = rawCount.tointeger();

    // Minimum 1 sélectionné si au moins 1 humain est vivant.
    if (count < 1)
        count = 1;

    // Sécurité HUD : jamais plus que maxSelectedPlayers.
    if (count > this.maxSelectedPlayers)
        count = this.maxSelectedPlayers;

    // Sécurité logique : jamais plus que le nombre d'humains vivants.
    if (count > aliveCount)
        count = aliveCount;

    return count;
}

::SelectionPortal.StartSelectionByAliveRatioAndSpawn <- function(ratio = 8)
{
    local count = this.GetSelectionCountByAliveRatio(ratio);

    this.StartSelectionAndSpawn(count);
}

::SelectionPortal.StartPendingSelection <- function()
{
    if (!("pendingSelectionCount" in this))
        return;

    if (!("pendingSelectionDuration" in this))
        return;

    local count = this.pendingSelectionCount;
    local duration = this.pendingSelectionDuration;

    this.rawdelete("pendingSelectionCount");
    this.rawdelete("pendingSelectionDuration");

    this.StartSelection(count, duration);
}

::SelectionPortal.SetNextSelectionDuration <- function(duration)
{
    if (duration <= 0)
        duration = this.selectionDuration;

    this.nextSelectionDuration = duration + 0.0;
}

::SelectionPortal.StartSelectionRandomAndSpawn <- function(minCount, maxCount)
{
    // Le portail est déjà spawn par Hammer.
    this.Schedule("SelectionPortal.StartSelectionRandom(" + minCount + "," + maxCount + ");", 0.10);
}

::SelectionPortal.StartSelectionRandom <- function(minCount, maxCount)
{
    if (minCount < 1)
        minCount = 1;

    if (maxCount < minCount)
        maxCount = minCount;

    local count = RandomInt(minCount, maxCount);
    this.StartSelection(count);
}

::SelectionPortal.StartSelection <- function(count, duration = null)
{
    this.ResetSelectionOnly();

    local activeDuration = this.selectionDuration;

    if (duration != null)
        activeDuration = duration.tofloat();

    if (activeDuration <= 0.0)
        activeDuration = this.selectionDuration;

    local players = this.GetAllAliveHumans();

    if (players.len() <= 0)
    {
        ClientPrint(null, 3, "\x07FF0000[Ra] No living humans remain for the trial.");
        return;
    }

    if (count < 1)
    count = 1;

    if (count > this.maxSelectedPlayers)
    count = this.maxSelectedPlayers;

    if (count > players.len())
    count = players.len();

    this.selectionSessionId += 1;
    local sessionId = this.selectionSessionId;

    this.selectionActive = true;
    this.selectedCountAtStart = count;
    this.selectionEndTime = Time() + activeDuration;
    this.selectionVoteOpenTime = Time() + (activeDuration * this.killVoteOpenFraction);
    this.CreateSelectionHudText();

    EntFire(this.triggerName, "Enable", "", 0.00, null);

    local temp = [];

    for (local i = 0; i < players.len(); i++)
        temp.append(players[i]);

    for (local j = 0; j < count; j++)
    {
        if (temp.len() <= 0)
            break;

        local idx = RandomInt(0, temp.len() - 1);
        local picked = temp[idx];
        local key = this.GetPlayerUniqueKey(picked);

        if (key != "")
        {
            this.selectedPlayers[key] <- picked;

            local uid = this.GetPlayerUserID(picked);
            if (uid > 0)
                this.userIdToSelectionKey[uid] <- key;
        }

        temp.remove(idx);
    }

    this.PrintSelectedPlayers();
    this.UpdateSelectionHudText();
    this.Schedule("SelectionPortal.SelectionHudThink(" + sessionId + ");", this.hudRefreshInterval);

    ClientPrint(null, 3, "\x07FFCC00[Ra] The chosen must reach the small Portal in " + activeDuration.tointeger() + " seconds.");

    this.Schedule("SelectionPortal.SelectionThink(" + sessionId + ");", this.thinkInterval);
    this.Schedule("SelectionPortal.OnSelectionTimeout(" + sessionId + ");", activeDuration);
}

::SelectionPortal.PrintSelectedPlayers <- function()
{
    foreach (k, player in this.selectedPlayers)
    {
        if (this.IsValidPlayer(player))
            ClientPrint(player, 3, "\x07FFCC00[Ra] You are chosen. Reach the Portal or be punished.");
    }
}
//--------------------------------------------------
// TRIGGER TOUCH
//--------------------------------------------------

::SelectionPortal.OnTriggerStartTouch <- function(player)
{
    if (!this.selectionActive)
        return;

    if (!this.IsHumanPlayer(player))
        return;

    if (!this.IsPlayerAlive(player))
        return;

    local key = this.GetPlayerUniqueKey(player);

    if (key == "")
        return;

    if (!this.selectedPlayers.rawin(key))
    {
        this.HurtPlayer(player);
        return;
    }

    if (!this.touchCounts.rawin(key))
        this.touchCounts[key] <- 0;

    this.touchCounts[key] += 1;
    this.insidePlayers[key] <- player;

    if (key == this.judgedTargetKey)
        this.CancelJudgement(true);

    this.CleanupKillVotes();
    this.UpdateSelectionHudText();
    this.CheckSelectionComplete();
}

::SelectionPortal.OnTriggerEndTouch <- function(player)
{
    if (!this.selectionActive)
        return;

    if (!this.IsValidPlayer(player))
        return;

    local key = this.GetPlayerUniqueKey(player);

    if (key == "")
        return;

    if (!this.selectedPlayers.rawin(key))
        return;

    if (!this.touchCounts.rawin(key))
        return;

    this.touchCounts[key] -= 1;

    if (this.touchCounts[key] <= 0)
    {
        this.touchCounts.rawdelete(key);

        if (this.insidePlayers.rawin(key))
            this.insidePlayers.rawdelete(key);

        this.CleanupKillVotes();
        this.UpdateSelectionHudText();
    }
}

//--------------------------------------------------
// CHECK COMPLETION
//--------------------------------------------------

::SelectionPortal.CheckSelectionComplete <- function()
{
    if (!this.selectionActive)
        return;

    this.CleanupInvalidSelectedPlayers();

    local selectedCount = this.CountTable(this.selectedPlayers);

    if (selectedCount <= 0)
    {
        this.TriggerEndRelay();
        this.ClearCurrentSelection();
        return;
    }

    foreach (key, player in this.selectedPlayers)
    {
        if (!this.insidePlayers.rawin(key))
            return;
    }

    this.CompleteSelection();
}

::SelectionPortal.CompleteSelection <- function()
{
    if (!this.selectionActive)
        return;

    ClientPrint(null, 3, "\x0700FF00[Ra] The chosen have reached the Portal. Ra is satisfied.");

    this.TriggerEndRelay();

    this.ClearCurrentSelection();
}

::SelectionPortal.FailSelection <- function(showMessage)
{
    if (showMessage)
        ClientPrint(null, 3, "\x07FF0000[Ra] The trial has failed.");

    this.ClearCurrentSelection();
}

//--------------------------------------------------
// TIMER
//--------------------------------------------------

::SelectionPortal.OnSelectionTimeout <- function(sessionId)
{
    if (sessionId != this.selectionSessionId)
        return;

    if (!this.selectionActive)
        return;

    this.CleanupInvalidSelectedPlayers();

    local selectedCount = this.CountTable(this.selectedPlayers);

    if (selectedCount <= 0)
    {
        ClientPrint(null, 3, "\x07FFCC00[Ra] The trial ends. No chosen souls remain.");

        this.TriggerEndRelay();
        this.ClearCurrentSelection();
        return;
    }

    local missingPlayers = [];

    foreach (key, player in this.selectedPlayers)
    {
        if (!this.insidePlayers.rawin(key))
            missingPlayers.append(player);
    }

    if (missingPlayers.len() <= 0)
    {
        this.CompleteSelection();
        return;
    }

    ClientPrint(null, 3, "\x07FF3300[Ra] Ra will take the souls of the players outside the zone.");

    for (local i = 0; i < missingPlayers.len(); i++)
    {
        local p = missingPlayers[i];

        if (!this.IsAliveHuman(p))
            continue;

        this.StartDivinePunishment(p);
    }

    this.TriggerEndRelay();
    this.ClearCurrentSelection();
}

::SelectionPortal.SelectionThink <- function(sessionId)
{
    if (sessionId != this.selectionSessionId)
        return;

    if (!this.selectionActive)
        return;

    this.CleanupInvalidSelectedPlayers();
    this.CleanupKillVotes();
    this.CheckKillVoteThresholds();
    this.CheckSelectionComplete();

    if (!this.selectionActive)
        return;

    this.Schedule("SelectionPortal.SelectionThink(" + sessionId + ");", this.thinkInterval);
}

//--------------------------------------------------
// CLEANUP JOUEURS
//--------------------------------------------------

::SelectionPortal.RemovePlayerByKey <- function(key)
{
    if (key == "")
        return;

    if (key == this.judgedTargetKey)
        this.CancelJudgement(false);

    if (key == this.instantExecutionTargetKey)
        this.instantExecutionTargetKey = "";

    this.RemoveVoteForVoter(key);

    if (this.killVotes.rawin(key))
        this.killVotes.rawdelete(key);

    if (this.selectedPlayers.rawin(key))
        this.selectedPlayers.rawdelete(key);

    if (this.insidePlayers.rawin(key))
        this.insidePlayers.rawdelete(key);

    if (this.touchCounts.rawin(key))
        this.touchCounts.rawdelete(key);

    local toDelete = [];

    foreach (uid, storedKey in this.userIdToSelectionKey)
    {
        if (storedKey == key)
            toDelete.append(uid);
    }

    for (local i = 0; i < toDelete.len(); i++)
        this.userIdToSelectionKey.rawdelete(toDelete[i]);

    if (this.selectionActive)
    {
        this.CleanupKillVotes();
        this.UpdateSelectionHudText();
    }
}

::SelectionPortal.RemovePlayerFromSelection <- function(player)
{
    if (!this.IsValidPlayer(player))
        return;

    this.ClearSelectionHudForPlayer(player);

    local key = this.GetPlayerUniqueKey(player);

    if (key == "")
        return;

    this.RemovePlayerByKey(key);
}

::SelectionPortal.RemovePlayerByUserID <- function(userid)
{
    if (userid <= 0)
        return;

    if (!this.userIdToSelectionKey.rawin(userid))
        return;

    local key = this.userIdToSelectionKey[userid];

    this.RemovePlayerByKey(key);
}

::SelectionPortal.CleanupInvalidSelectedPlayers <- function()
{
    local toRemove = [];

    foreach (key, player in this.selectedPlayers)
    {
        if (!this.IsAliveHuman(player))
            toRemove.append(key);
    }

    for (local i = 0; i < toRemove.len(); i++)
        this.RemovePlayerByKey(toRemove[i]);
}

//--------------------------------------------------
// RESET
//--------------------------------------------------

::SelectionPortal.ResetSelectionOnly <- function()
{
    this.selectionSessionId += 1;

    this.selectionActive = false;
    this.selectedPlayers = {};
    this.insidePlayers = {};
    this.touchCounts = {};
    this.userIdToSelectionKey = {};
    this.selectedCountAtStart = 0;
    this.selectionVoteOpenTime = 0.0;

    this.ResetKillVotes();

    this.judgedTargetKey = "";
    this.judgedTargetPlayer = null;
    this.judgementEndTime = 0.0;
    this.judgementHudLeadingLines = -1;
    this.judgementSessionId += 1;

    this.instantExecutionTargetKey = "";
    this.instantExecutionSessionId += 1;

    this.KillJudgementHudText();
}

::SelectionPortal.ClearCurrentSelection <- function()
{
    this.ResetSelectionOnly();

    if (this.disableTriggerOnEnd)
        EntFire(this.triggerName, "Disable", "", 0.00, null);

    if (this.cleanupPortalOnEnd)
    {
        EntFire(this.triggerName, "Kill", "", 0.05, null);
        EntFire(this.modelName, "Kill", "", 0.05, null);
    }

    this.KillSelectionHudText();
}

::SelectionPortal.ResetAll <- function()
{
    this.nextSelectionDuration = null;
    this.selectionEndTime = 0.0;

    if ("pendingSelectionCount" in this)
        this.rawdelete("pendingSelectionCount");

    if ("pendingSelectionDuration" in this)
        this.rawdelete("pendingSelectionDuration");

    this.ClearCurrentSelection();
}
//--------------------------------------------------
// DEBUG
//--------------------------------------------------


::SelectionPortal.DebugStart <- function()
{
    this.StartSelection(1);
}

::SelectionPortal.DebugStartSpawn <- function()
{
    this.StartSelectionAndSpawn(1);
}

//--------------------------------------------------
// GAME EVENTS
//--------------------------------------------------

if (!("selectionPortalCallbacksRegistered" in getroottable()))
    ::selectionPortalCallbacksRegistered <- false;

if (!("selectionPortalCallbacks" in getroottable()))
    ::selectionPortalCallbacks <- {};

::selectionPortalCallbacks.OnGameEvent_player_say <- function(params)
{
    if (!("userid" in params) || !("text" in params))
        return;

    local player = GetPlayerFromUserID(params.userid);

    if (player == null || !player.IsValid())
        return;

    ::SelectionPortal.HandleKillChatCommand(player, params.text);
};

::selectionPortalCallbacks.OnGameEvent_player_death <- function(params)
{
    if (!("userid" in params))
        return;

    if (!::SelectionPortal.selectionActive)
        return;

    local p = GetPlayerFromUserID(params.userid);

    if (p != null && p.IsValid())
        ::SelectionPortal.RemovePlayerFromSelection(p);
    else
        ::SelectionPortal.RemovePlayerByUserID(params.userid);

    ::SelectionPortal.CheckSelectionComplete();
};

::selectionPortalCallbacks.OnGameEvent_player_disconnect <- function(params)
{
    if (!("userid" in params))
        return;

    if (!::SelectionPortal.selectionActive)
        return;

    ::SelectionPortal.RemovePlayerByUserID(params.userid);
    ::SelectionPortal.CheckSelectionComplete();
};

::selectionPortalCallbacks.OnGameEvent_player_team <- function(params)
{
    if (!("userid" in params))
        return;

    if (!::SelectionPortal.selectionActive)
        return;

    local newTeam = ("team" in params) ? params.team : 0;

    if (newTeam == 3)
        return;

    local p = GetPlayerFromUserID(params.userid);

    if (p != null && p.IsValid())
        ::SelectionPortal.RemovePlayerFromSelection(p);
    else
        ::SelectionPortal.RemovePlayerByUserID(params.userid);

    ::SelectionPortal.CheckSelectionComplete();
};
::selectionPortalCallbacks.OnGameEvent_round_end <- function(params)
{
    ::SelectionPortal.ResetAll();
};

::selectionPortalCallbacks.OnGameEvent_round_start <- function(params)
{
    ::SelectionPortal.ResetAll();
};

if (!::selectionPortalCallbacksRegistered)
{
    __CollectGameEventCallbacks(::selectionPortalCallbacks);
    ::selectionPortalCallbacksRegistered = true;
}

//Boss attacks


//gravity

::GravityPullToCenter <- function()
{
    local player = activator;
    local trigger = caller;

    if (player == null || !player.IsValid())
    return;

    if (player.GetClassname() != "player")
    return;

    if (!player.IsAlive())
    return;

    if (trigger == null || !trigger.IsValid())
        return;

    local center = trigger.GetOrigin();
    local pos = player.GetOrigin();

    local dir = center - pos;
    local dist = dir.Length();

    if (dist <= 80.0)
        return;

    if (dist <= 0.01)
        return;

    dir = dir * (1.0 / dist);
    dir.z += -0.05;

    local dirLen = dir.Length();
    if (dirLen <= 0.01)
        return;

    dir = dir * (1.0 / dirLen);
    local strength = 230.0;

    player.SetVelocity(dir * strength);
};

//boost from trigger after gravity

//------------------------------------------------------------
// PUSH HUMANS OUTSIDE TRIGGER
//------------------------------------------------------------
::PushHumansOutsideTrigger <- function()
{
    local player = activator;
    local trigger = caller;

    if (player == null || !player.IsValid())
    return;

    if (player.GetClassname() != "player")
    return;

    if (!player.IsAlive())
    return;

    if (trigger == null || !trigger.IsValid())
        return;

    // Humains / CT uniquement
    if (player.GetTeam() != 3)
        return;

    local center = trigger.GetOrigin();
    local pos = player.GetOrigin();

    // Direction inverse du pull :
    // au lieu de center - pos, on fait pos - center
    local dir = pos - center;

    // On force une direction horizontale propre
    dir.z = 0.0;

    local dist = dir.Length();

    // Si le joueur est exactement au centre, on utilise sa direction de vue comme fallback
    if (dist <= 0.01)
    {
        dir = player.EyeAngles().Forward();
        dir.z = 0.0;
        dist = dir.Length();

        if (dist <= 0.01)
            return;
    }

    dir = dir * (1.0 / dist);

    // Force horizontale forte
    local pushStrength = 900.0;
    local upBoost = 650.0;

    local velocity = dir * pushStrength;
    velocity.z = upBoost;

    player.SetVelocity(velocity);
};

//sun ultima

//------------------------------------------------------------
// SUN MODEL SCALE
//------------------------------------------------------------

//------------------------------------------------------------
// SUN MODEL SCALE - SAFE VERSION
//------------------------------------------------------------

::StartSunScale <- function()
{
    local sun = Entities.FindByName(null, "sun_model");

    if (sun == null || !sun.IsValid())
    {
        return;
    }

    // Scale initial
    EntFireByHandle(sun, "SetModelScale", "0.1", 0.0, null, null);

    // Grossissement progressif moteur : scale final + durée
    // Format généralement supporté : "scale duration"
    EntFireByHandle(sun, "SetModelScale", "2.0 3.0", 0.05, null, null);
};

// ===============================
// RANDOM BOSS LASER ROTATION
// Target: laser_boss_move_rot_*
// ===============================

::StartsWith <- function(str, prefix)
{
    if (str == null) return false;
    if (str.len() < prefix.len()) return false;

    return str.slice(0, prefix.len()) == prefix;
}

::RandomBossLaserRot <- function()
{
    local ent = null;
    local count = 0;

    while ((ent = Entities.FindByClassname(ent, "func_rotating")) != null)
    {
        local name = ent.GetName();

        if (!StartsWith(name, "laser_boss_move_rot_"))
            continue;

        local startDelay = RandomFloat(0.0, 0.25);
        local stopDelay  = RandomFloat(0.25, 0.5);
        local speed      = RandomInt(400, 1000);

        // Sécurité : on stoppe d'abord si l'entité était déjà en rotation
        EntFireByHandle(ent, "Stop", "", 0.00, null, null);

        // Set de la vitesse max du func_rotating
        EntFireByHandle(ent, "AddOutput", "maxspeed " + speed.tostring(), 0.01, null, null);

        // Démarrage aléatoire entre 0s et 0.5s
        EntFireByHandle(ent, "Start", "", startDelay, null, null);

        // Arrêt aléatoire entre 0.6s et 1s
        EntFireByHandle(ent, "Stop", "", stopDelay, null, null);
    }
}



//============================================================
// BOSS DISAPPEAR AFTERIMAGE / TP VIBRATION
// Boss: Boss_final_arena
//============================================================

if (!("BossAfterImage" in getroottable()))
    ::BossAfterImage <- {};
::BossAfterImage.cloneAnimation <- "glide";
::BossAfterImage.scriptEntityName <- "script_contest_map_2026_lardy"; // nom de ton logic_script
::BossAfterImage.bossName <- "Boss_final_arena";

::BossAfterImage.ghostPrefix <- "boss_disappear_ghost_";
::BossAfterImage.ghostIndex <- 0;

//------------------------------------------------------------
// CONFIG VISUELLE
//------------------------------------------------------------

::BossAfterImage.modelScale <- 3.0;        // ton boss est scale 3
::BossAfterImage.color <- "255 255 255";

::BossAfterImage.effectDuration <- 1.0;    // apparition répartie sur 1 seconde
::BossAfterImage.cloneCount <- 10;         // nombre total de clones pendant l'effet

::BossAfterImage.offsetXY <- 18.0;         // dispersion horizontale des clones
::BossAfterImage.offsetZ <- 8.0;           // petite variation verticale au spawn

::BossAfterImage.cloneAlpha <- 145;        // alpha des clones
::BossAfterImage.cloneLife <- 0.35;        // durée de vie de chaque clone

::BossAfterImage.fadeSteps <- 5;
::BossAfterImage.fadeInterval <- 0.045;

//------------------------------------------------------------
// VIBRATION VERTICALE DES CLONES
//------------------------------------------------------------

::BossAfterImage.verticalShakeAmount <- 34.0;   // force haut/bas
::BossAfterImage.verticalShakeSteps <- 8;       // nombre de mouvements par clone
::BossAfterImage.verticalShakeInterval <- 0.025; // vitesse du tremblement

//------------------------------------------------------------
// ALPHA DU VRAI BOSS PENDANT LE TP
//------------------------------------------------------------

::BossAfterImage.bossAlphaDuringEffect <- 65;
::BossAfterImage.bossAlphaAfterEffect <- 255;

//------------------------------------------------------------
// OUTILS
//------------------------------------------------------------

::BossAfterImage.FormatIndex <- function(i)
{
    if (i < 10) return "000" + i;
    if (i < 100) return "00" + i;
    if (i < 1000) return "0" + i;
    return "" + i;
}

::BossAfterImage.Schedule <- function(code, delay)
{
    EntFire(this.scriptEntityName, "RunScriptCode", code, delay, null);
}

::BossAfterImage.GetBoss <- function()
{
    local boss = Entities.FindByName(null, this.bossName);

    if (boss == null || !boss.IsValid())
    {
        return null;
    }

    return boss;
}

::BossAfterImage.SafeSetAngles <- function(ent, ang)
{
    if (ent == null || !ent.IsValid())
        return;

    try
    {
        ent.SetAngles(ang.x, ang.y, ang.z);
        return;
    }
    catch (e)
    {
    }

    EntFireByHandle(ent, "AddOutput", "angles " + ang.x + " " + ang.y + " " + ang.z, 0.00, null, null);
}

//------------------------------------------------------------
// ALPHA DU BOSS REEL
//------------------------------------------------------------

::BossAfterImage.SetBossAlpha <- function(alpha)
{
    local boss = this.GetBoss();

    if (boss == null)
        return;

    EntFireByHandle(boss, "AddOutput", "rendermode 1", 0.00, null, null);
    EntFireByHandle(boss, "Alpha", alpha.tostring(), 0.01, null, null);
}

::BossAfterImage.RestoreBossAlpha <- function()
{
    local boss = this.GetBoss();

    if (boss == null)
        return;

    EntFireByHandle(boss, "AddOutput", "rendermode 0", 0.00, null, null);
    EntFireByHandle(boss, "Alpha", this.bossAlphaAfterEffect.tostring(), 0.01, null, null);
}

//------------------------------------------------------------
// SPAWN D'UN CLONE
//------------------------------------------------------------

::BossAfterImage.SpawnGhost <- function(origin, angles)
{
    local boss = this.GetBoss();

    if (boss == null)
        return null;

    local model = "";

    try
    {
        model = boss.GetModelName();
    }
    catch (e)
    {
        model = "";
    }

    if (model == null || model == "")
    {
        return null;
    }

    this.ghostIndex++;

    local ghostName = this.ghostPrefix + this.FormatIndex(this.ghostIndex);

    local ghost = SpawnEntityFromTable("prop_dynamic", {
        targetname = ghostName,
        model = model,
        solid = "0",
        disableshadows = "1",
        rendermode = "1",
        renderamt = this.cloneAlpha.tostring(),
        rendercolor = this.color,
        modelscale = this.modelScale.tostring(),
        DefaultAnim = this.cloneAnimation
    });

    if (ghost == null || !ghost.IsValid())
    {
        return null;
    }

    ghost.SetOrigin(origin);
    this.SafeSetAngles(ghost, angles);

    EntFireByHandle(ghost, "SetAnimation", this.cloneAnimation, 0.00, null, null);
    EntFireByHandle(ghost, "SetModelScale", this.modelScale.tostring() + " 0.0", 0.00, null, null);

    EntFireByHandle(ghost, "DisableShadow", "", 0.00, null, null);
    EntFireByHandle(ghost, "AddOutput", "solid 0", 0.00, null, null);
    EntFireByHandle(ghost, "AddOutput", "rendermode 1", 0.00, null, null);
    EntFireByHandle(ghost, "AddOutput", "renderamt " + this.cloneAlpha.tostring(), 0.00, null, null);
    EntFireByHandle(ghost, "Color", this.color, 0.00, null, null);
    EntFireByHandle(ghost, "Alpha", this.cloneAlpha.tostring(), 0.01, null, null);

    this.StartVerticalShake(ghostName, origin);

    for (local s = 1; s <= this.fadeSteps; s++)
    {
        local t = s * this.fadeInterval;
        local a = this.cloneAlpha - ((this.cloneAlpha.tofloat() / this.fadeSteps.tofloat()) * s).tointeger();

        if (a < 0)
            a = 0;

        EntFireByHandle(ghost, "Alpha", a.tostring(), t, null, null);
    }

    EntFireByHandle(ghost, "Kill", "", this.cloneLife, null, null);

    return ghost;
}

//------------------------------------------------------------
// VIBRATION VERTICALE D'UN CLONE
//------------------------------------------------------------

::BossAfterImage.StartVerticalShake <- function(ghostName, baseOrigin)
{
    for (local i = 1; i <= this.verticalShakeSteps; i++)
    {
        local delay = i * this.verticalShakeInterval;

        local dir = 1.0;

        if ((i % 2) == 0)
            dir = -1.0;

        local z = dir * this.verticalShakeAmount;
        local pos = baseOrigin + Vector(0.0, 0.0, z);

        this.Schedule(
            "BossAfterImage.MoveGhost(\"" + ghostName + "\"," +
            pos.x + "," + pos.y + "," + pos.z + ");",
            delay
        );
    }
}

::BossAfterImage.MoveGhost <- function(ghostName, x, y, z)
{
    local ghost = Entities.FindByName(null, ghostName);

    if (ghost == null || !ghost.IsValid())
        return;

    ghost.SetOrigin(Vector(x, y, z));
}

//------------------------------------------------------------
// EFFET TP / DISPARITION
//------------------------------------------------------------

::BossAfterImage.DisappearVibration <- function()
{
    local boss = this.GetBoss();

    if (boss == null)
        return;

    this.SetBossAlpha(this.bossAlphaDuringEffect);

    local interval = this.effectDuration / this.cloneCount.tofloat();

    for (local i = 0; i < this.cloneCount; i++)
    {
        local delay = i * interval;

        this.Schedule("BossAfterImage.SpawnDisappearClone();", delay);
    }

    this.Schedule("BossAfterImage.RestoreBossAlpha();", this.effectDuration + 0.05);
}

::BossAfterImage.SpawnDisappearClone <- function()
{
    local boss = this.GetBoss();

    if (boss == null)
        return;

    local origin = boss.GetOrigin();
    local angles = boss.GetAngles();

    local x = RandomFloat(-this.offsetXY, this.offsetXY);
    local y = RandomFloat(-this.offsetXY, this.offsetXY);
    local z = RandomFloat(-this.offsetZ, this.offsetZ);

    local pos = origin + Vector(x, y, z);

    this.SpawnGhost(pos, angles);
}

// ===============================
// FINAL BOSS DYNAMIC LASER SPAWN
// HORIZONTAL + VERTICAL SET
// Boss: Boss_final_arena
// ===============================

::FinalBossLaser <- {
    scriptName = "script_contest_map_2026_lardy",

    bossName = "Boss_final_arena",

    // Makers horizontaux random
    makerNames = [
        "maker_lasers_final_top",
        "maker_lasers_final",
        "maker_lasers_final_down"
    ],

    // Maker vertical
    verticalMakerName = "maker_lasers_final_vertical",

    index = 0,
    maxIndex = 256,

    // Models horizontaux
    doorModel = "*182",
    hurtModel = "*181",

    verticalDoorModel = "*186",
    verticalHurtModel = "*185",

    particleEffect = "custom_particle_113",
    filterName = "filter_ct",

    laserSpeedMin = 1500,
    laserSpeedMax = 2200,

    openDelay = 0.10,
    fallbackKillDelay = 5.0,

    // 1 laser horizontal obligatoire
    // + entre 1 et 4 lasers verticaux
    verticalMin = 5,
    verticalMax = 15,

    // Tous les lasers verticaux spawnent dans cette fenêtre
    totalBurstTime = 1.2,

    // Direction générale du laser
    moveYawOffset = 0.0,

    // Correction trigger horizontal
    hurtYawOffset = 90.0,

    // Correction trigger vertical
    verticalHurtYawOffset = 90.0,

    Pad3 = function(n)
    {
        if (n < 10) return "00" + n.tostring();
        if (n < 100) return "0" + n.tostring();
        return n.tostring();
    },

    NormalizeYaw = function(yaw)
    {
        while (yaw < 0.0) yaw += 360.0;
        while (yaw >= 360.0) yaw -= 360.0;
        return yaw;
    },

    VecToStr = function(v)
    {
        return v.x.tostring() + " " + v.y.tostring() + " " + v.z.tostring();
    },

    AngToStr = function(pitch, yaw, roll)
    {
        return pitch.tostring() + " " + yaw.tostring() + " " + roll.tostring();
    },

    NextIndex = function()
    {
        this.index++;

        if (this.index > this.maxIndex)
            this.index = 1;

        return this.index;
    },

    GetRandomMaker = function()
    {
        local available = [];

        for (local i = 0; i < this.makerNames.len(); i++)
        {
            local maker = Entities.FindByName(null, this.makerNames[i]);

            if (maker != null)
            {
                available.append(maker);
            }
            else
            {
            }
        }

        if (available.len() <= 0)
            return null;

        local randomIndex = RandomInt(0, available.len() - 1);
        return available[randomIndex];
    },

    GetVerticalMaker = function()
    {
        return Entities.FindByName(null, this.verticalMakerName);
    },

    KillByName = function(name)
    {
        local ent = null;

        while ((ent = Entities.FindByName(ent, name)) != null)
        {
            EntFireByHandle(ent, "Kill", "", 0.00, null, null);
        }
    },

    CleanupBySuffix = function(suffix)
    {
        this.KillByName("laser_final_" + suffix);
        this.KillByName("laser_final_hurt_" + suffix);
        this.KillByName("laser_final_part_" + suffix);
    },

    Spawn = function()
    {
        // Laser horizontal obligatoire
        this.SpawnSingle(false);

        // Lasers verticaux en plus
        local verticalCount = RandomInt(this.verticalMin, this.verticalMax);

        for (local i = 0; i < verticalCount; i++)
        {
            local delay = RandomFloat(0.0, this.totalBurstTime);

            EntFire(
                this.scriptName,
                "RunScriptCode",
                "::FinalBossLaser.SpawnSingle(true);",
                delay,
                null
            );
        }
    },

    SpawnSingle = function(isVertical)
    {
        local boss = Entities.FindByName(null, this.bossName);

        if (boss == null)
        {
            return;
        }

        local spawnOrigin = boss.GetOrigin();
        local makerUsed = "boss_fallback";

        local maker = null;

        if (isVertical)
            maker = this.GetVerticalMaker();
        else
            maker = this.GetRandomMaker();

        if (maker != null)
        {
            spawnOrigin = maker.GetOrigin();
            makerUsed = maker.GetName();
        }

        local bossAngles = boss.GetAngles();

        local bossYaw = bossAngles.y;
        local moveYaw = this.NormalizeYaw(bossYaw + this.moveYawOffset);

        local idx = this.NextIndex();
        local suffix = "";

        if (isVertical)
            suffix = "v_" + this.Pad3(idx);
        else
            suffix = "h_" + this.Pad3(idx);

        local doorName = "laser_final_" + suffix;
        local hurtName = "laser_final_hurt_" + suffix;
        local partName = "laser_final_part_" + suffix;

        local doorSpeed = RandomInt(this.laserSpeedMin, this.laserSpeedMax);

        local currentDoorModel = this.doorModel;
        local currentHurtModel = this.hurtModel;

        local doorPitch = 0.0;
        local doorRoll = 0.0;

        local hurtPitch = 0.0;
        local hurtRoll = 0.0;

        local partPitch = 0.0;
        local partRoll = 0.0;

        local hurtYaw = this.NormalizeYaw(moveYaw + this.hurtYawOffset);

        if (isVertical)
        {
            currentDoorModel = this.verticalDoorModel;
            currentHurtModel = this.verticalHurtModel;

            // Le set vertical est déjà construit verticalement dans Hammer.
            // On ne force donc pas pitch 90 ici.
            doorPitch = 0.0;
            doorRoll = 0.0;

            hurtPitch = 0.0;
            hurtRoll = 0.0;

            // D'après ton Hammer: laser_final_part1 angles "0 270 90"
            partPitch = 0.0;
            partRoll = 90.0;

            hurtYaw = this.NormalizeYaw(moveYaw + this.verticalHurtYawOffset);
        }

        // ===============================
        // FUNC_DOOR LASER
        // ===============================

        local door = SpawnEntityFromTable("func_door", {
            targetname = doorName,
            model = currentDoorModel,
            origin = this.VecToStr(spawnOrigin),
            angles = this.AngToStr(doorPitch, moveYaw, doorRoll),
            movedir = this.AngToStr(0.0, moveYaw, 0.0),
            speed = doorSpeed.tostring(),
            spawnpos = "0",
            spawnflags = "1036",
            rendermode = "0",
            renderfx = "0",
            rendercolor = "252 255 255",
            renderamt = "255",
            loopmovesound = "0",
            locked_sentence = "0",
            unlocked_sentence = "0",
            lip = "-3800",
            ignoredebris = "0",
            health = "0",
            forceclosed = "0",
            dmg = "0",
            disableshadows = "0",
            disablereceiveshadows = "0"
        });

        // ===============================
        // TRIGGER_HURT
        // ===============================

        local hurt = SpawnEntityFromTable("trigger_hurt", {
            targetname = hurtName,
            model = currentHurtModel,
            origin = this.VecToStr(spawnOrigin),
            angles = this.AngToStr(hurtPitch, hurtYaw, hurtRoll),
            StartDisabled = "1",
            spawnflags = "1",
            parentname = doorName,
            filtername = this.filterName,
            nodmgforce = "0",
            damagetype = "0",
            damagemodel = "0",
            damagecap = "99999",
            damage = "99999"
        });

        // ===============================
        // PARTICLE
        // ===============================

        local part = SpawnEntityFromTable("info_particle_system", {
            targetname = partName,
            origin = this.VecToStr(spawnOrigin),
            angles = this.AngToStr(partPitch, moveYaw, partRoll),
            parentname = doorName,
            effect_name = this.particleEffect,
            start_active = "1"
        });

        if (door == null || hurt == null || part == null)
        {
            if (door != null && door.IsValid())
                EntFireByHandle(door, "Kill", "", 0.00, null, null);

            if (hurt != null && hurt.IsValid())
                EntFireByHandle(hurt, "Kill", "", 0.00, null, null);

            if (part != null && part.IsValid())
                EntFireByHandle(part, "Kill", "", 0.00, null, null);

            return;
        }
        EntFireByHandle(hurt, "AddOutput", "filtername " + this.filterName, 0.00, null, null);
        EntFireByHandle(hurt, "Enable", "", 0.02, null, null);

        // Parent sécurité
        EntFireByHandle(hurt, "SetParent", doorName, 0.01, null, null);
        EntFireByHandle(part, "SetParent", doorName, 0.01, null, null);
        EntFireByHandle(door, "AddOutput", "OnFullyOpen " + hurtName + ":Kill::0:-1", 0.00, null, null);
        EntFireByHandle(door, "AddOutput", "OnFullyOpen " + partName + ":Kill::0:-1", 0.00, null, null);
        EntFireByHandle(door, "AddOutput", "OnFullyOpen !self:Kill::0:-1",             0.00, null, null);
        EntFireByHandle(door, "AddOutput", "speed " + doorSpeed.tostring(), 0.00, null, null);
        EntFireByHandle(part, "Start", "", 0.02, null, null);
        EntFireByHandle(door, "Open", "", this.openDelay, null, null);

        // Sécurité cleanup
        EntFire(
            this.scriptName,
            "RunScriptCode",
            "::FinalBossLaser.CleanupBySuffix(\"" + suffix + "\");",
            this.fallbackKillDelay,
            null
        );

        local typeName = "horizontal";
        if (isVertical)
            typeName = "vertical";
    }
};

//============================================================
// RA DODGE TRIAL - STAGE 3 / BOSS SELECTIONS -> FINAL DODGE
//============================================================
//
// A coller APRES SelectionPortal et APRES FinalBossLaser.
//
// Fonctionnement :
// - StartStage3Counter() reset le compteur UNE SEULE FOIS au début du stage 3.
// - StartSelectionCharge() démarre le calcul pour UNE sélection.
// - Chaque sélection ajoute du temps au compteur global.
// - Le compteur ne reset PAS entre les sélections.
// - +0.2 seconde toutes les secondes pendant une sélection active.
// - +0.5 seconde si un joueur meurt car il n'était pas dans le portail à temps.
// - +0.5 seconde si un humain meurt d'une autre raison pendant une sélection.
// - StartFinalDodge() lance l'épreuve finale avec le temps cumulé.
//============================================================

if (!("RaDodgeTrial" in getroottable()))
    ::RaDodgeTrial <- {};

//------------------------------------------------------------
// CONFIG
//------------------------------------------------------------

::RaDodgeTrial.scriptEntityName <- "script_contest_map_2026_lardy";

// Temps de dodge de départ.
// Laisse 0.0 si tu veux que tout dépende uniquement des sélections.
::RaDodgeTrial.baseDodgeTime <- 0.0;

// Gain automatique pendant chaque sélection.
::RaDodgeTrial.timeGainPerSecond <- 0.2;

// Gain par mort.
::RaDodgeTrial.deathGain <- 0.5;

// Limites optionnelles.
// minimumFinalDodgeTime : temps minimum garanti.
// maximumFinalDodgeTime : 0.0 = aucune limite.
::RaDodgeTrial.minimumFinalDodgeTime <- 0.0;
::RaDodgeTrial.maximumFinalDodgeTime <- 0.0;

// HUD top-right.
::RaDodgeTrial.hudName <- "gt_ra_dodge_trial";
::RaDodgeTrial.hudEnt <- null;
::RaDodgeTrial.hudX <- 0.72;
::RaDodgeTrial.hudY <- 0.08;
::RaDodgeTrial.hudChannel <- 4;
::RaDodgeTrial.hudRefreshInterval <- 0.25;


// Relay déclenché quand le dodge final est terminé.
// Crée un logic_relay avec ce nom dans Hammer, ou change ce nom ici.
::RaDodgeTrial.finalWinRelayName <- "relay_ra_final_dodge_win";

//------------------------------------------------------------
// ETAT GLOBAL
//------------------------------------------------------------



::RaDodgeTrial.stage3Enabled <- false;

::RaDodgeTrial.finalDodgeTime <- 0.0;

::RaDodgeTrial.selectionDeathCount <- 0;
::RaDodgeTrial.otherDeathCount <- 0;

::RaDodgeTrial.pendingSelectionPunishUserIDs <- {};
::RaDodgeTrial.countedDeathUserIDs <- {};
::RaDodgeTrial.lastKnownHumanUserIDs <- {};

//------------------------------------------------------------
// ETAT CHARGE SELECTION
//------------------------------------------------------------

::RaDodgeTrial.chargeActive <- false;
::RaDodgeTrial.chargeSessionId <- 0;
::RaDodgeTrial.chargeThinkInterval <- 0.25;
::RaDodgeTrial.chargeAccum <- 0.0;
::RaDodgeTrial.hasSeenSelectionActive <- false;
::RaDodgeTrial.chargeWaitUntil <- 0.0;

//------------------------------------------------------------
// ETAT HUD
//------------------------------------------------------------

::RaDodgeTrial.hudSessionId <- 0;

//------------------------------------------------------------
// ETAT FINAL DODGE
//------------------------------------------------------------

::RaDodgeTrial.finalActive <- false;
::RaDodgeTrial.finalSessionId <- 0;
::RaDodgeTrial.finalEndTime <- 0.0;

//------------------------------------------------------------
// OUTILS
//------------------------------------------------------------

::RaDodgeTrial.Schedule <- function(code, delay)
{
    EntFire(this.scriptEntityName, "RunScriptCode", code, delay, null);
}

::RaDodgeTrial.IsValidPlayer <- function(player)
{
    if (player == null)
        return false;

    if (!player.IsValid())
        return false;

    if (player.GetClassname() != "player")
        return false;

    return true;
}

::RaDodgeTrial.IsPlayerAlive <- function(player)
{
    if (!this.IsValidPlayer(player))
        return false;

    try
    {
        return player.IsAlive();
    }
    catch (e)
    {
        return false;
    }
}

::RaDodgeTrial.IsHumanPlayer <- function(player)
{
    if (!this.IsValidPlayer(player))
        return false;

    local team = 0;

    try
    {
        team = player.GetTeam();
    }
    catch (e)
    {
        team = 0;
    }

    return team == 3;
}

::RaDodgeTrial.IsAliveHuman <- function(player)
{
    if (!this.IsHumanPlayer(player))
        return false;

    if (!this.IsPlayerAlive(player))
        return false;

    return true;
}

::RaDodgeTrial.GetUserID <- function(player)
{
    if (!this.IsValidPlayer(player))
        return 0;

    try
    {
        return NetProps.GetPropInt(player, "m_iUserID");
    }
    catch (e)
    {
        return 0;
    }
}

::RaDodgeTrial.IsSelectionCurrentlyActive <- function()
{
    if (!("SelectionPortal" in getroottable()))
        return false;

    return ::SelectionPortal.selectionActive;
}

::RaDodgeTrial.FormatTime <- function(value)
{
    if (value < 0.0)
        value = 0.0;

    local tenths = ((value * 10.0) + 0.5).tointeger();
    local sec = tenths / 10;
    local dec = tenths % 10;

    return sec.tostring() + "." + dec.tostring();
}

::RaDodgeTrial.ClampFinalTime <- function()
{
    if (this.finalDodgeTime < this.minimumFinalDodgeTime)
        this.finalDodgeTime = this.minimumFinalDodgeTime;

    if (this.maximumFinalDodgeTime > 0.0 && this.finalDodgeTime > this.maximumFinalDodgeTime)
        this.finalDodgeTime = this.maximumFinalDodgeTime;
}

::RaDodgeTrial.AddDodgeTime <- function(amount)
{
    if (amount <= 0.0)
        return;

    this.finalDodgeTime += amount;
    this.ClampFinalTime();

    this.UpdateHudText();
}

::RaDodgeTrial.UpdateKnownHumans <- function()
{
    this.lastKnownHumanUserIDs = {};

    local p = null;

    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (!this.IsAliveHuman(p))
            continue;

        local uid = this.GetUserID(p);

        if (uid > 0)
            this.lastKnownHumanUserIDs[uid] <- true;
    }
}

//------------------------------------------------------------
// HUD
//------------------------------------------------------------

::RaDodgeTrial.CreateHud <- function()
{
    this.KillHud();

    this.hudEnt = SpawnEntityFromTable("game_text", {
        targetname = this.hudName,
        message = "",
        x = this.hudX,
        y = this.hudY,
        effect = 0,
        color = "255 190 40",
        color2 = "255 255 255",
        fadein = 0.0,
        fadeout = 0.0,
        holdtime = 1.0,
        fxtime = 0.0,
        channel = this.hudChannel,
        spawnflags = 0
    });
}

::RaDodgeTrial.KillHud <- function()
{
    if (this.hudEnt != null && this.hudEnt.IsValid())
    {
        this.hudEnt.__KeyValueFromString("message", "");
        this.ShowHudToAllHumans();
        EntFireByHandle(this.hudEnt, "Kill", "", 0.05, null, null);
    }

    this.hudEnt = null;
}

::RaDodgeTrial.ShowHudToAllHumans <- function()
{
    if (this.hudEnt == null || !this.hudEnt.IsValid())
        return;

    local p = null;

    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (!this.IsHumanPlayer(p))
            continue;

        EntFireByHandle(this.hudEnt, "Display", "", 0.00, p, null);
    }
}

::RaDodgeTrial.UpdateHudText <- function()
{
    if (!this.stage3Enabled)
        return;

    if (this.hudEnt == null || !this.hudEnt.IsValid())
        return;

    local msg = "RA'S FINAL JUDGEMENT";
    msg += "\nSolar dodge: " + this.FormatTime(this.finalDodgeTime) + "s";
    msg += "\nPortal deaths: " + this.selectionDeathCount;
    msg += "\nOther deaths: " + this.otherDeathCount;

    if (this.chargeActive)
    {
        msg += "\nSelection charge active";
        msg += "\n+" + this.FormatTime(this.timeGainPerSecond) + "s each second";
    }
    else if (this.finalActive)
    {
        local left = this.finalEndTime - Time();

        if (left < 0.0)
            left = 0.0;

        msg += "\nFinal trial: " + this.FormatTime(left) + "s left";
    }
    else
    {
        msg += "\nAwaiting Ra's trial";
    }

    this.hudEnt.__KeyValueFromString("message", msg);
    this.ShowHudToAllHumans();
}

::RaDodgeTrial.StartHudLoop <- function()
{
    this.hudSessionId += 1;

    local sid = this.hudSessionId;

    this.UpdateHudText();
    this.Schedule("RaDodgeTrial.HudThink(" + sid + ");", this.hudRefreshInterval);
}

::RaDodgeTrial.HudThink <- function(sessionId)
{
    if (sessionId != this.hudSessionId)
        return;

    if (!this.stage3Enabled)
        return;

    this.UpdateHudText();

    this.Schedule("RaDodgeTrial.HudThink(" + sessionId + ");", this.hudRefreshInterval);
}

::RaDodgeTrial.EnableStage3Hud <- function()
{
    this.stage3Enabled = true;

    if (this.hudEnt == null || !this.hudEnt.IsValid())
        this.CreateHud();

    this.StartHudLoop();
}

//------------------------------------------------------------
// RESET AU DEBUT DU STAGE 3
//------------------------------------------------------------

::RaDodgeTrial.StartStage3Counter <- function()
{
    this.stage3Enabled = true;

    this.chargeActive = false;
    this.chargeSessionId += 1;
    this.chargeAccum = 0.0;
    this.hasSeenSelectionActive = false;
    this.chargeWaitUntil = 0.0;

    this.finalActive = false;
    this.finalSessionId += 1;
    this.finalEndTime = 0.0;

    this.finalDodgeTime = this.baseDodgeTime;
    this.ClampFinalTime();

    this.selectionDeathCount = 0;
    this.otherDeathCount = 0;

    this.pendingSelectionPunishUserIDs = {};
    this.countedDeathUserIDs = {};
    this.lastKnownHumanUserIDs = {};

    if (this.hudEnt == null || !this.hudEnt.IsValid())
        this.CreateHud();

    this.StartHudLoop();

    ClientPrint(null, 3, "\x07FFCC00[Ra] Stage 3 solar judgement counter has started.");
}

//------------------------------------------------------------
// START CHARGE POUR UNE SELECTION
//------------------------------------------------------------

::RaDodgeTrial.StartSelectionCharge <- function()
{
    this.stage3Enabled = true;

    // IMPORTANT :
    // On ne reset PAS finalDodgeTime ici.
    // Chaque sélection ajoute au compteur global du stage 3 / boss.

    if (this.finalDodgeTime < this.baseDodgeTime)
        this.finalDodgeTime = this.baseDodgeTime;

    this.ClampFinalTime();

    // Données temporaires propres à CETTE sélection uniquement.
    this.pendingSelectionPunishUserIDs = {};
    this.lastKnownHumanUserIDs = {};

    this.chargeActive = true;
    this.hasSeenSelectionActive = false;
    this.chargeAccum = 0.0;
    this.chargeWaitUntil = Time() + 5.0;

    this.chargeSessionId += 1;

    local sid = this.chargeSessionId;

    this.UpdateKnownHumans();

    if (this.hudEnt == null || !this.hudEnt.IsValid())
        this.CreateHud();

    this.StartHudLoop();

    ClientPrint(null, 3, "\x07FFCC00[Ra] This selection feeds the final solar trial.");

    this.Schedule("RaDodgeTrial.ChargeThink(" + sid + ");", this.chargeThinkInterval);
}

::RaDodgeTrial.ChargeThink <- function(sessionId)
{
    if (sessionId != this.chargeSessionId)
        return;

    if (!this.chargeActive)
        return;

    local selectionNow = this.IsSelectionCurrentlyActive();

    if (selectionNow)
    {
        this.hasSeenSelectionActive = true;
        this.UpdateKnownHumans();

        this.chargeAccum += this.chargeThinkInterval;

        while (this.chargeAccum >= 1.0)
        {
            this.chargeAccum -= 1.0;
            this.AddDodgeTime(this.timeGainPerSecond);
        }
    }
    else
    {
        if (this.hasSeenSelectionActive)
        {
            this.chargeActive = false;
            this.chargeAccum = 0.0;

            ClientPrint(null, 3, "\x07FFCC00[Ra] Selection charge complete. Solar dodge is now " + this.FormatTime(this.finalDodgeTime) + "s.");

            this.UpdateHudText();
            return;
        }

        if (Time() >= this.chargeWaitUntil)
        {
            this.chargeActive = false;
            this.chargeAccum = 0.0;

            ClientPrint(null, 3, "\x07FF0000[Ra] Dodge charge stopped: no active selection detected.");

            this.UpdateHudText();
            return;
        }
    }

    this.Schedule("RaDodgeTrial.ChargeThink(" + sessionId + ");", this.chargeThinkInterval);
}

//------------------------------------------------------------
// DETECTION DES MORTS PAR TIMEOUT DE SELECTION
//------------------------------------------------------------

::RaDodgeTrial.MarkSelectionTimeoutVictims <- function(sessionId)
{
    if (!this.stage3Enabled && !this.chargeActive)
        return;

    if (!("SelectionPortal" in getroottable()))
        return;

    if (sessionId != ::SelectionPortal.selectionSessionId)
        return;

    if (!::SelectionPortal.selectionActive)
        return;

    foreach (key, player in ::SelectionPortal.selectedPlayers)
    {
        if (::SelectionPortal.insidePlayers.rawin(key))
            continue;

        if (!this.IsAliveHuman(player))
            continue;

        local uid = this.GetUserID(player);

        if (uid <= 0)
            continue;

        this.pendingSelectionPunishUserIDs[uid] <- true;
        this.lastKnownHumanUserIDs[uid] <- true;
    }
}

::RaDodgeTrial.OnPlayerDeath <- function(userid)
{
    if (userid <= 0)
        return;

    if (this.countedDeathUserIDs.rawin(userid))
        return;

    // Mort causée par le timeout de sélection :
    // joueur sélectionné mais pas dans le portail à temps.
    if (this.pendingSelectionPunishUserIDs.rawin(userid))
    {
        this.pendingSelectionPunishUserIDs.rawdelete(userid);
        this.countedDeathUserIDs[userid] <- true;

        this.selectionDeathCount += 1;
        this.AddDodgeTime(this.deathGain);

        ClientPrint(null, 3, "\x07FF6600[Ra] A chosen soul failed the portal. Final dodge +" + this.FormatTime(this.deathGain) + "s.");
        return;
    }

    // Autre mort humaine pendant une sélection active.
    if (!this.chargeActive)
        return;

    if (!this.IsSelectionCurrentlyActive())
        return;

    if (!this.lastKnownHumanUserIDs.rawin(userid))
        return;

    this.countedDeathUserIDs[userid] <- true;

    this.otherDeathCount += 1;
    this.AddDodgeTime(this.deathGain);

    ClientPrint(null, 3, "\x07FF6600[Ra] A human soul has fallen. Final dodge +" + this.FormatTime(this.deathGain) + "s.");
}

//------------------------------------------------------------
// FINAL BOSS DODGE
//------------------------------------------------------------

::RaDodgeTrial.GetFinalDodgeDuration <- function()
{
    this.ClampFinalTime();

    return this.finalDodgeTime;
}

::RaDodgeTrial.StartFinalDodge <- function(durationOverride = null)
{
    this.stage3Enabled = true;

    local duration = this.finalDodgeTime;

    if (durationOverride != null)
        duration = durationOverride.tofloat();

    if (duration < this.minimumFinalDodgeTime)
        duration = this.minimumFinalDodgeTime;

    if (this.maximumFinalDodgeTime > 0.0 && duration > this.maximumFinalDodgeTime)
        duration = this.maximumFinalDodgeTime;

    this.finalDodgeTime = duration;

    if (this.hudEnt == null || !this.hudEnt.IsValid())
        this.CreateHud();

    this.StartHudLoop();

    this.finalActive = true;
    this.finalSessionId += 1;

    local sid = this.finalSessionId;

    this.finalEndTime = Time() + duration;

    ClientPrint(null, 3, "\x07FFCC00[Ra] Final solar timer begins: survive " + this.FormatTime(duration) + " seconds.");

    if (duration <= 0.0)
    {
        this.FinishFinalDodge(sid);
        return;
    }

    this.Schedule("RaDodgeTrial.FinishFinalDodge(" + sid + ");", duration);
}

::RaDodgeTrial.FinishFinalDodge <- function(sessionId)
{
    if (sessionId != this.finalSessionId)
        return;

    if (!this.finalActive)
        return;

    this.finalActive = false;

    ClientPrint(null, 3, "\x0700FF00[Ra] The solar judgement timer is complete.");

    if (this.finalWinRelayName != "")
        EntFire(this.finalWinRelayName, "Trigger", "", 0.00, null);

    this.UpdateHudText();
}


::RaDodgeTrial.StopFinalDodge <- function()
{
    this.finalSessionId += 1;
    this.finalActive = false;

    this.UpdateHudText();
}

//------------------------------------------------------------
// RESET GLOBAL
//------------------------------------------------------------

::RaDodgeTrial.ResetAll <- function()
{
    this.stage3Enabled = false;

    this.chargeActive = false;
    this.chargeSessionId += 1;
    this.chargeAccum = 0.0;
    this.hasSeenSelectionActive = false;
    this.chargeWaitUntil = 0.0;

    this.finalActive = false;
    this.finalSessionId += 1;
    this.finalEndTime = 0.0;

    this.finalDodgeTime = this.baseDodgeTime;

    this.selectionDeathCount = 0;
    this.otherDeathCount = 0;

    this.pendingSelectionPunishUserIDs = {};
    this.countedDeathUserIDs = {};
    this.lastKnownHumanUserIDs = {};

    this.hudSessionId += 1;
    this.KillHud();
}

//------------------------------------------------------------
// PATCH SAFE DE SelectionPortal.OnSelectionTimeout
//------------------------------------------------------------
//
// On ne remplace pas ta logique.
// On marque seulement les joueurs qui vont être punis par le timeout,
// puis on laisse ton OnSelectionTimeout original faire son travail.
//------------------------------------------------------------

if ("SelectionPortal" in getroottable())
{
    if (!("RaDodgeTrial_OriginalOnSelectionTimeout" in ::SelectionPortal))
    {
        ::SelectionPortal.RaDodgeTrial_OriginalOnSelectionTimeout <- ::SelectionPortal.OnSelectionTimeout;

        ::SelectionPortal.OnSelectionTimeout <- function(sessionId)
        {
            ::RaDodgeTrial.MarkSelectionTimeoutVictims(sessionId);

            this.RaDodgeTrial_OriginalOnSelectionTimeout(sessionId);
        };
    }
}

//------------------------------------------------------------
// GAME EVENTS RA DODGE
//------------------------------------------------------------

if (!("raDodgeTrialCallbacksRegistered" in getroottable()))
    ::raDodgeTrialCallbacksRegistered <- false;

if (!("raDodgeTrialCallbacks" in getroottable()))
    ::raDodgeTrialCallbacks <- {};

::raDodgeTrialCallbacks.OnGameEvent_player_death <- function(params)
{
    if (!("userid" in params))
        return;

    ::RaDodgeTrial.OnPlayerDeath(params.userid);
};

::raDodgeTrialCallbacks.OnGameEvent_round_start <- function(params)
{
    ::RaDodgeTrial.ResetAll();
};

::raDodgeTrialCallbacks.OnGameEvent_round_end <- function(params)
{
    ::RaDodgeTrial.ResetAll();
};

if (!::raDodgeTrialCallbacksRegistered)
{
    __CollectGameEventCallbacks(::raDodgeTrialCallbacks);
    ::raDodgeTrialCallbacksRegistered = true;
}

::FinalBossLaser.KillAllActiveLasers <- function()
{
    local ent = null;
    local prefix = "laser_final";

    // Kill les func_door lasers
    while ((ent = Entities.FindByClassname(ent, "func_door")) != null)
    {
        local name = ent.GetName();

        if (name != null && name.len() >= prefix.len() && name.slice(0, prefix.len()) == prefix)
        {
            EntFireByHandle(ent, "Kill", "", 0.00, null, null);
        }
    }

    ent = null;

    // Kill les triggers hurt lasers
    while ((ent = Entities.FindByClassname(ent, "trigger_hurt")) != null)
    {
        local name = ent.GetName();

        if (name != null && name.len() >= prefix.len() && name.slice(0, prefix.len()) == prefix)
        {
            EntFireByHandle(ent, "Kill", "", 0.00, null, null);
        }
    }

    ent = null;

    // Kill les particules lasers
    while ((ent = Entities.FindByClassname(ent, "info_particle_system")) != null)
    {
        local name = ent.GetName();

        if (name != null && name.len() >= prefix.len() && name.slice(0, prefix.len()) == prefix)
        {
            EntFireByHandle(ent, "Kill", "", 0.00, null, null);
        }
    }
};


if (!("finalBossLaserCallbacksRegistered" in getroottable()))
    ::finalBossLaserCallbacksRegistered <- false;

if (!("finalBossLaserCallbacks" in getroottable()))
    ::finalBossLaserCallbacks <- {};

::finalBossLaserCallbacks.OnGameEvent_round_start <- function(params)
{
    ::FinalBossLaser.KillAllActiveLasers();
};

::finalBossLaserCallbacks.OnGameEvent_round_end <- function(params)
{
    ::FinalBossLaser.KillAllActiveLasers();
};

if (!::finalBossLaserCallbacksRegistered)
{
    __CollectGameEventCallbacks(::finalBossLaserCallbacks);
    ::finalBossLaserCallbacksRegistered = true;
}
//============================================================

//------------------------------------------------------------
// CONFIG
//------------------------------------------------------------

if (!("ContestItem" in getroottable()))
    ::ContestItem <- {};

::ContestItem.scriptName <- "script_contest_map_2026_lardy";

// Touche E / USE
::ContestItem.IN_USE <- 32;
::ContestItem.triggerModel <- "*189";

// Durée des effets.
::ContestItem.healEffectDuration <- 8.0;
::ContestItem.windEffectDuration <- 6.0;
::ContestItem.rapidFireZoneDuration <- 7.0;
::ContestItem.rapidFireBuffDuration <- 8.0;
::ContestItem.spawnForwardDistance <- 64.0;
::ContestItem.spawnZOffset <- -8.0;
::ContestItem.thinkInterval <- 0.05;


//------------------------------------------------------------
// ITEM CONFIGS
//------------------------------------------------------------

::ContestItem.configs <- {
    heal = {
        displayName = "HEAL",
        weaponName = "heal_weapon",
        readyParticleName = "heal_part",
        worldTextName = "heal_worldtext",
        worldTextDefaultColor = "255 190 40",
        entwatchButtonName = "heal_button",
        cooldown = 50.0,
        team = 3
    },

    rapid_fire = {
        displayName = "RAPID FIRE",
        weaponName = "rapid_fire_weapon",
        readyParticleName = "rapid_fire_part",
        worldTextName = "rapid_fire_worldtext",
        worldTextDefaultColor = "255 40 75",
        entwatchButtonName = "rapid_fire_button",
        cooldown = 60.0,
        team = 3
    },

    wind = {
        displayName = "WIND",
        weaponName = "wind_weapon",
        readyParticleName = "wind_part",
        worldTextName = "wind_worldtext",
        worldTextDefaultColor = "0 120 255",
        entwatchButtonName = "wind_button",
        cooldown = 60.0,
        team = 3
    }
};

//------------------------------------------------------------
// STATE
//------------------------------------------------------------

::ContestItem.owners <- {};
::ContestItem.cooldowns <- {};
::ContestItem.effectIndex <- 0;
::ContestItem.activeEffects <- {};
::ContestItem.healDamageFilterName <- "Filter_Team_Zombies_Ignore";
::ContestItem.healZoneMembers <- {};
::ContestItem.healImmunityPlayers <- {};
::ContestItem.debug <- false;
if (!("contestItemCallbacksRegistered" in getroottable()))
    ::contestItemCallbacksRegistered <- false;

if (!("contestItemCallbacks" in getroottable()))
    ::contestItemCallbacks <- {};

//------------------------------------------------------------
// BASIC TOOLS
//------------------------------------------------------------

::ContestItem.Log <- function(msg)
{
    if (!("debug" in this) || !this.debug)
        return;

    ClientPrint(null, 3, "\x07AAAAAA[ContestItem] " + msg);
};

::ContestItem.IsValidPlayer <- function(p)
{
    if (p == null) return false;
    if (!p.IsValid()) return false;
    if (p.GetClassname() != "player") return false;
    return true;
};

::ContestItem.IsAlivePlayer <- function(p)
{
    if (!this.IsValidPlayer(p)) return false;

    try
    {
        return p.IsAlive();
    }
    catch (e)
    {
        return false;
    }
};

::ContestItem.IsValidEntity <- function(e)
{
    if (e == null) return false;
    if (!e.IsValid()) return false;
    return true;
};

::ContestItem.GetUserID <- function(p)
{
    if (!this.IsValidPlayer(p))
        return 0;

    try
    {
        local uid = NetProps.GetPropInt(p, "m_iUserID");

        if (uid > 0)
            return uid;
    }
    catch (e)
    {
    }

    // Fallback CS:S :
    // si m_iUserID ne marche pas, on utilise entindex.
    return p.entindex();
};

::ContestItem.GetPlayerKey <- function(p)
{
    if (!this.IsValidPlayer(p))
        return "";

    return p.entindex().tostring();
};

::ContestItem.GetItemKeyFromWeapon <- function(weapon)
{
    if (!this.IsValidEntity(weapon))
        return null;

    local weaponName = weapon.GetName();

    foreach (itemKey, cfg in this.configs)
    {
        if (weaponName == cfg.weaponName)
            return itemKey;
    }

    return null;
};

::ContestItem.FindEnt <- function(name)
{
    if (name == null || name == "")
        return null;

    local e = Entities.FindByName(null, name);

    if (e == null || !e.IsValid())
        return null;

    return e;
};

::ContestItem.NextIndex <- function()
{
    this.effectIndex++;

    if (this.effectIndex > 999)
        this.effectIndex = 1;

    return format("%03d", this.effectIndex);
};

::ContestItem.Schedule <- function(code, delay)
{
    EntFire(this.scriptName, "RunScriptCode", code, delay, null);
};

::ContestItem.GetSpawnPos <- function(player)
{
    local forward = player.EyeAngles().Forward();
    return player.GetOrigin() + forward * this.spawnForwardDistance + Vector(0, 0, this.spawnZOffset);
};

::ContestItem.TrackEffectEnt <- function(owner, ent)
{
    if (!this.IsValidPlayer(owner))
        return;

    if (!this.IsValidEntity(ent))
        return;

    local key = this.GetPlayerKey(owner);

    if (key == "")
        return;

    if (!this.activeEffects.rawin(key))
        this.activeEffects[key] <- [];

    this.activeEffects[key].append(ent);
};

::ContestItem.KillTrackedEffectsForPlayer <- function(player)
{
    if (!this.IsValidPlayer(player))
        return;

    local key = this.GetPlayerKey(player);

    if (key == "")
        return;

    if (!this.activeEffects.rawin(key))
        return;

    foreach (ent in this.activeEffects[key])
    {
        if (ent != null && ent.IsValid())
        {
            local entKey = ent.entindex().tostring();

            // Si cette entité est un trigger Heal, retire l'immunité
            // de tous les humains encore présents avant de le supprimer.
            if (this.healZoneMembers.rawin(entKey))
                this.ClearHealImmunityForTrigger(ent.entindex());

            EntFireByHandle(ent, "Kill", "", 0.0, null, null);
        }
    }

    this.activeEffects.rawdelete(key);
};

::ContestItem.KillAllTrackedEffects <- function()
{
    foreach (key, arr in this.activeEffects)
    {
        foreach (ent in arr)
        {
            if (ent != null && ent.IsValid())
                EntFireByHandle(ent, "Kill", "", 0.0, null, null);
        }
    }

    this.activeEffects.clear();
};

//------------------------------------------------------------
// HEAL IMMUNITY AGAINST ZOMBIES
//------------------------------------------------------------

::ContestItem.SetHealImmunity <- function(player, enabled)
{
    if (!this.IsValidPlayer(player))
        return;

    local filterName = "";

    if (enabled)
        filterName = this.healDamageFilterName;

    EntFireByHandle(
        player,
        "SetDamageFilter",
        filterName,
        0.00,
        null,
        null
    );
};

::ContestItem.GrantHealImmunity <- function(player, trigger)
{
    if (!this.IsAlivePlayer(player))
        return;

    if (player.GetTeam() != 3)
        return;

    if (!this.IsValidEntity(trigger))
        return;

    local playerKey = this.GetPlayerKey(player);
    local triggerKey = trigger.entindex().tostring();

    if (playerKey == "" || triggerKey == "")
        return;

    if (!this.healZoneMembers.rawin(triggerKey))
        this.healZoneMembers[triggerKey] <- {};

    // Le même joueur ne doit compter qu'une fois dans cette zone précise.
    if (this.healZoneMembers[triggerKey].rawin(playerKey))
        return;

    this.healZoneMembers[triggerKey][playerKey] <- true;

    if (!this.healImmunityPlayers.rawin(playerKey))
    {
        this.healImmunityPlayers[playerKey] <- {
            player = player,
            userID = this.GetUserID(player),
            count = 0
        };
    }

    local data = this.healImmunityPlayers[playerKey];

    data.count += 1;

    // Première zone Heal : activation réelle du filtre.
    if (data.count == 1)
        this.SetHealImmunity(player, true);
};

::ContestItem.RemoveHealImmunityByKeys <- function(playerKey, triggerKey)
{
    if (!this.healZoneMembers.rawin(triggerKey))
        return;

    if (!this.healZoneMembers[triggerKey].rawin(playerKey))
        return;

    this.healZoneMembers[triggerKey].rawdelete(playerKey);

    if (this.healZoneMembers[triggerKey].len() <= 0)
        this.healZoneMembers.rawdelete(triggerKey);

    if (!this.healImmunityPlayers.rawin(playerKey))
        return;

    local data = this.healImmunityPlayers[playerKey];

    data.count -= 1;

    // Le joueur reste protégé s'il est encore dans une autre zone Heal.
    if (data.count > 0)
        return;

    if ("player" in data && this.IsValidPlayer(data.player))
        this.SetHealImmunity(data.player, false);

    this.healImmunityPlayers.rawdelete(playerKey);
};

::ContestItem.RemoveHealImmunity <- function(player, trigger)
{
    if (!this.IsValidPlayer(player))
        return;

    if (!this.IsValidEntity(trigger))
        return;

    local playerKey = this.GetPlayerKey(player);
    local triggerKey = trigger.entindex().tostring();

    if (playerKey == "" || triggerKey == "")
        return;

    this.RemoveHealImmunityByKeys(playerKey, triggerKey);
};

::ContestItem.ClearHealImmunityForTrigger <- function(triggerEntIndex)
{
    local triggerKey = triggerEntIndex.tostring();

    if (!this.healZoneMembers.rawin(triggerKey))
        return;

    local playerKeys = [];

    foreach (playerKey, value in this.healZoneMembers[triggerKey])
        playerKeys.append(playerKey);

    foreach (playerKey in playerKeys)
        this.RemoveHealImmunityByKeys(playerKey, triggerKey);
};

::ContestItem.ClearHealImmunityByPlayerKey <- function(playerKey)
{
    if (playerKey == "")
        return;

    local triggerKeys = [];

    foreach (triggerKey, members in this.healZoneMembers)
    {
        if (members.rawin(playerKey))
            triggerKeys.append(triggerKey);
    }

    foreach (triggerKey in triggerKeys)
        this.RemoveHealImmunityByKeys(playerKey, triggerKey);

    // Sécurité si une table est restée incohérente.
    if (this.healImmunityPlayers.rawin(playerKey))
    {
        local data = this.healImmunityPlayers[playerKey];

        if ("player" in data && this.IsValidPlayer(data.player))
            this.SetHealImmunity(data.player, false);

        this.healImmunityPlayers.rawdelete(playerKey);
    }
};

::ContestItem.ClearHealImmunityByUserID <- function(userid)
{
    if (userid <= 0)
        return;

    local playerKeys = [];

    foreach (playerKey, data in this.healImmunityPlayers)
    {
        if ("userID" in data && data.userID == userid)
            playerKeys.append(playerKey);
    }

    foreach (playerKey in playerKeys)
        this.ClearHealImmunityByPlayerKey(playerKey);
};

::ContestItem.ClearAllHealImmunity <- function()
{
    local playerKeys = [];

    foreach (playerKey, data in this.healImmunityPlayers)
        playerKeys.append(playerKey);

    foreach (playerKey in playerKeys)
        this.ClearHealImmunityByPlayerKey(playerKey);

    this.healZoneMembers.clear();
    this.healImmunityPlayers.clear();
};

//------------------------------------------------------------
// READY PARTICLE
//------------------------------------------------------------

::ContestItem.SetReadyParticle <- function(itemKey, enabled)
{
    if (!this.configs.rawin(itemKey))
        return;

    local cfg = this.configs[itemKey];
    local part = this.FindEnt(cfg.readyParticleName);

    if (part == null)
        return;

    if (enabled)
        EntFireByHandle(part, "Start", "", 0.0, null, null);
    else
        EntFireByHandle(part, "Stop", "", 0.0, null, null);
};

//------------------------------------------------------------
// WORLD TEXT COOLDOWN COLOR
//------------------------------------------------------------

::ContestItem.worldTextCooldownColor <- "0 0 0";

::ContestItem.SetWorldTextColor <- function(itemKey, color)
{
    if (!this.configs.rawin(itemKey))
        return;

    local cfg = this.configs[itemKey];

    if (!("worldTextName" in cfg))
        return;

    local txt = this.FindEnt(cfg.worldTextName);

    if (txt == null)
        return;

    EntFireByHandle(txt, "AddOutput", "color " + color, 0.00, null, null);
    EntFireByHandle(txt, "Color", color, 0.01, null, null);
};

::ContestItem.SetWorldTextCooldownColor <- function(itemKey)
{
    this.SetWorldTextColor(itemKey, this.worldTextCooldownColor);
};

::ContestItem.RestoreWorldTextColor <- function(itemKey)
{
    if (!this.configs.rawin(itemKey))
        return;

    local cfg = this.configs[itemKey];

    if (!("worldTextDefaultColor" in cfg))
        return;

    this.SetWorldTextColor(itemKey, cfg.worldTextDefaultColor);
};

::ContestItem.RefreshReadyParticles <- function()
{
    foreach (itemKey, cfg in this.configs)
    {
        local ready = true;

        if (this.cooldowns.rawin(itemKey))
        {
            if (Time() < this.cooldowns[itemKey])
                ready = false;
        }

        this.SetReadyParticle(itemKey, ready);
    }
};


::ContestItem.PlayerStillHasWeapon <- function(player, weapon)
{
    if (!this.IsAlivePlayer(player))
        return false;

    if (!this.IsValidEntity(weapon))
        return false;

    // Méthode 1 : parent direct.
    // Si ça marche, c'est le meilleur cas.
    try
    {
        local parent = weapon.GetMoveParent();

        if (parent == player)
            return true;
    }
    catch (e)
    {
    }

    // Méthode 2 : vérifier dans m_hMyWeapons.
    // Plus fiable pour CS:S quand GetMoveParent() ne donne pas le joueur.
    for (local i = 0; i < 64; i++)
    {
        local w = null;

        try
        {
            w = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
        }
        catch (e2)
        {
            w = null;
        }

        if (w == null || !w.IsValid())
            continue;

        if (w == weapon)
            return true;
    }

    return false;
};

//------------------------------------------------------------
// PICKUP / OWNER
//------------------------------------------------------------

::ContestItem_RegisterPickup <- function(player, weapon, itemKey = null)
{
    ::ContestItem.RegisterPickup(player, weapon, itemKey);
};

::PickupHeal <- function()
{
    ::ContestItem.RegisterPickup(activator, caller, "heal");
};

::PickupRapidFire <- function()
{
    ::ContestItem.RegisterPickup(activator, caller, "rapid_fire");
};

::PickupWind <- function()
{
    ::ContestItem.RegisterPickup(activator, caller, "wind");
};

::ContestItem.RegisterPickup <- function(player, weapon, itemKey = null)
{
    if (!this.IsAlivePlayer(player))
        return;

    if (!this.IsValidEntity(weapon))
        return;

    if (itemKey == null || itemKey == "")
        itemKey = this.GetItemKeyFromWeapon(weapon);

    if (itemKey == null || itemKey == "")
        return;

    if (!this.configs.rawin(itemKey))
        return;

    local cfg = this.configs[itemKey];

    if (player.GetTeam() != cfg.team)
        return;

    local playerKey = this.GetPlayerKey(player);
    local uid = this.GetUserID(player);

    if (playerKey == "")
        return;

    if (uid <= 0)
        uid = player.entindex();

    this.ClearOwner(player, false);

    this.owners[playerKey] <- {
        player = player,
        userID = uid,
        weapon = weapon,
        itemKey = itemKey,
        buttonsLast = 0,
        thinkSession = 1
    };

    this.RefreshReadyParticles();
    this.StartPlayerThink(playerKey, 1);
};

::ContestItem.StartPlayerThink <- function(playerKey, session)
{
    this.Schedule("ContestItem.PlayerThink(\"" + playerKey + "\"," + session + ");", this.thinkInterval);
};

::ContestItem.PlayerThink <- function(playerKey, session)
{
    if (!this.owners.rawin(playerKey))
        return;

    local data = this.owners[playerKey];

    if (!("thinkSession" in data) || data.thinkSession != session)
        return;

    local player = data.player;
    local weapon = data.weapon;
    local itemKey = data.itemKey;

    if (!this.IsAlivePlayer(player))
    {
        this.ClearOwnerByKey(playerKey, false);
        return;
    }

    if (!this.IsValidEntity(weapon))
    {
        this.ClearOwnerByKey(playerKey, false);
        return;
    }

    if (!this.configs.rawin(itemKey))
    {
        this.ClearOwnerByKey(playerKey, false);
        return;
    }

    local cfg = this.configs[itemKey];

    if (player.GetTeam() != cfg.team)
    {
        this.ClearOwnerByKey(playerKey, false);
        return;
    }

    if (!this.PlayerStillHasWeapon(player, weapon))
    {
        this.ClearOwnerByKey(playerKey, false);
        return;
    }

    local buttons = 0;

    try
    {
        buttons = NetProps.GetPropInt(player, "m_nButtons");
    }
    catch (e)
    {
        buttons = 0;
    }

    if (!("buttonsLast" in data))
        data.buttonsLast <- 0;

    local changed = buttons ^ data.buttonsLast;
    local pressed = changed & buttons;

    if ((pressed & this.IN_USE) != 0)
        this.TryUseItem(playerKey);

    data.buttonsLast = buttons;

    this.StartPlayerThink(playerKey, session);
};

::ContestItem.ClearOwner <- function(player, showMsg = true)
{
    if (!this.IsValidPlayer(player))
        return;

    local key = this.GetPlayerKey(player);

    if (key == "")
        return;

    this.ClearOwnerByKey(key, showMsg);
};

::ContestItem.ClearOwnerByKey <- function(playerKey, showMsg = true)
{
    if (!this.owners.rawin(playerKey))
        return;

    local data = this.owners[playerKey];

    if ("player" in data && this.IsValidPlayer(data.player) && showMsg)
        ClientPrint(data.player, 3, "\x07FF6600[Item] Item ownership removed.");

    this.KillTrackedEffectsForPlayer(data.player);

    data.thinkSession += 1;

    this.owners.rawdelete(playerKey);
};

::ContestItem.ClearOwnerByUserID <- function(userid)
{
    if (userid <= 0)
        return;

    local toDelete = [];

    foreach (key, data in this.owners)
    {
        if ("userID" in data && data.userID == userid)
        {
            toDelete.append(key);
            continue;
        }

        if ("player" in data && this.IsValidPlayer(data.player))
        {
            try
            {
                if (data.player.entindex() == userid)
                    toDelete.append(key);
            }
            catch (e)
            {
            }
        }
    }

    foreach (key in toDelete)
        this.ClearOwnerByKey(key, false);
};

//------------------------------------------------------------
// COOLDOWN
//------------------------------------------------------------

::ContestItem.IsReady <- function(itemKey)
{
    if (!this.cooldowns.rawin(itemKey))
        return true;

    return Time() >= this.cooldowns[itemKey];
};

::ContestItem.GetCooldownLeft <- function(itemKey)
{
    if (!this.cooldowns.rawin(itemKey))
        return 0.0;

    local left = this.cooldowns[itemKey] - Time();

    if (left < 0.0)
        left = 0.0;

    return left;
};

::ContestItem.StartCooldown <- function(itemKey)
{
    if (!this.configs.rawin(itemKey))
        return;

    local cfg = this.configs[itemKey];

    this.cooldowns[itemKey] <- Time() + cfg.cooldown;

    this.SetReadyParticle(itemKey, false);
    this.SetWorldTextCooldownColor(itemKey);

    this.Schedule("ContestItem.OnCooldownFinished(\"" + itemKey + "\");", cfg.cooldown);
};

::ContestItem.OnCooldownFinished <- function(itemKey)
{
    if (!this.configs.rawin(itemKey))
        return;

    if (!this.IsReady(itemKey))
        return;

    this.SetReadyParticle(itemKey, true);
    this.RestoreWorldTextColor(itemKey);
};

//------------------------------------------------------------
// USE ITEM
//------------------------------------------------------------

//------------------------------------------------------------
// ENTWATCH FAKE BUTTON
//------------------------------------------------------------

::ContestItem.TriggerEntwatchButton <- function(player, buttonName)
{
    if (!this.IsAlivePlayer(player))
        return false;

    if (buttonName == null || buttonName == "")
        return false;

    local button = Entities.FindByName(null, buttonName);

    if (button == null || !button.IsValid())
        return false;
    EntFireByHandle(button, "Press", "", 0.01, player, player);

    return true;
};

::ContestItem.TryUseItem <- function(playerKey)
{
    if (!this.owners.rawin(playerKey))
        return false;

    local data = this.owners[playerKey];
    local player = data.player;
    local itemKey = data.itemKey;

    if (!this.IsAlivePlayer(player))
        return false;

    if (!this.configs.rawin(itemKey))
        return false;

    local cfg = this.configs[itemKey];

    if (player.GetTeam() != cfg.team)
        return false;

    if (!this.IsReady(itemKey))
    {
        local left = this.GetCooldownLeft(itemKey).tointeger();
        ClientPrint(player, 3, "\x07FF0000[Item] " + cfg.displayName + " cooldown: " + left + "s.");
        return false;
    }

    local used = false;

    if (itemKey == "heal")
        used = this.SpawnHealEffect(player);
    else if (itemKey == "wind")
        used = this.SpawnWindEffect(player);
    else if (itemKey == "rapid_fire")
        used = this.SpawnRapidFireEffect(player);

    if (!used)
    return false;

    if ("entwatchButtonName" in cfg)
        this.TriggerEntwatchButton(player, cfg.entwatchButtonName);

    this.StartCooldown(itemKey);
    return true;
};

//------------------------------------------------------------
// DYNAMIC EFFECTS - HEAL
//------------------------------------------------------------

::ContestItem.SpawnHealEffect <- function(player)
{
    if (!this.IsAlivePlayer(player) || player.GetTeam() != 3)
        return false;

    local idx = this.NextIndex();
    local spawnPos = this.GetSpawnPos(player);
    local particleName = "contest_heal_particle_" + idx;
    local triggerName = "contest_heal_trigger_" + idx;
    local sndName = "contest_heal_snd_" + idx;

    this.KillTrackedEffectsForPlayer(player);

    local particle = SpawnEntityFromTable("info_particle_system", {
        targetname = particleName,
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_198",
        start_active = 1
    });

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(spawnPos + Vector(0, 0, 16));
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop", "", this.healEffectDuration);
        EntFire(particleName, "Kill", "", this.healEffectDuration + 0.05);
        this.TrackEffectEnt(player, particle);
    }

    local trigger = SpawnEntityFromTable("trigger_multiple", {
        targetname = triggerName,
        model = this.triggerModel,
        origin = spawnPos.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 0.2,
        filtername = "filter_ct",

        "OnStartTouch#1": this.scriptName + ",RunScriptCode,ContestItem_HealTouch(),0,-1",
        "OnEndTouch#1": this.scriptName + ",RunScriptCode,ContestItem_HealEndTouch(),0,-1"
    });

    if (trigger != null && trigger.IsValid())
    {
        trigger.SetOrigin(spawnPos);

        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", this.healEffectDuration);

        // Reset garanti à la fin des 5 secondes, même si OnEndTouch
        // n'est pas appelé pendant la suppression du trigger.
        this.Schedule(
            "ContestItem.ClearHealImmunityForTrigger(" + trigger.entindex() + ");",
            this.healEffectDuration
        );

        this.TrackEffectEnt(player, trigger);
    }

    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message = "npc/vort/health_charge.wav",
        health = 10,
        pitch = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(player.EyePosition() + Vector(0, 0, -8));
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "StopSound", "", 2.9, null, null);
        EntFireByHandle(snd, "Kill", "", 3.0, null, null);
        this.TrackEffectEnt(player, snd);
    }

    return (trigger != null || particle != null || snd != null);
};
::ContestItem_HealTouch <- function()
{
    local p = activator;
    local trigger = caller;

    if (p == null || !p.IsValid())
        return;

    if (p.GetClassname() != "player")
        return;

    if (!p.IsAlive())
        return;

    if (p.GetTeam() != 3)
        return;

    if (trigger == null || !trigger.IsValid())
        return;

    local hp = p.GetHealth();

    if (hp < 250)
        p.SetHealth(250);

    // Applique Filter_Team_Zombies_Ignore au joueur.
    ::ContestItem.GrantHealImmunity(p, trigger);
};

::ContestItem_HealEndTouch <- function()
{
    local p = activator;
    local trigger = caller;

    if (p == null || !p.IsValid())
        return;

    if (p.GetClassname() != "player")
        return;

    if (trigger == null || !trigger.IsValid())
        return;
    ::ContestItem.RemoveHealImmunity(p, trigger);
};

//------------------------------------------------------------
// DYNAMIC EFFECTS - WIND
//------------------------------------------------------------

::ContestItem.SpawnWindEffect <- function(player)
{
    if (!this.IsAlivePlayer(player) || player.GetTeam() != 3)
        return false;

    local idx = this.NextIndex();
    local spawnPos = this.GetSpawnPos(player);
    local particleName = "contest_wind_particle_" + idx;
    local triggerName = "contest_wind_trigger_" + idx;
    local sndName = "contest_wind_snd_" + idx;

    this.KillTrackedEffectsForPlayer(player);

    local particle = SpawnEntityFromTable("info_particle_system", {
        targetname = particleName,
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_084",
        start_active = 1
    });

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(spawnPos + Vector(0, 0, -48));
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop", "", this.windEffectDuration);
        EntFire(particleName, "Kill", "", this.windEffectDuration + 0.05);
        this.TrackEffectEnt(player, particle);
    }

    local trigger = SpawnEntityFromTable("trigger_multiple", {
        targetname = triggerName,
        model = this.triggerModel,
        origin = spawnPos.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 1.0,
        filtername = "filter_t",
        "OnStartTouch#1": this.scriptName + ",RunScriptCode,ContestItem_WindTouch(),0,-1",
    });

    if (trigger != null && trigger.IsValid())
    {
        trigger.SetOrigin(spawnPos);
        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", this.windEffectDuration);
        this.TrackEffectEnt(player, trigger);
    }

    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message = "ambient/wind/wind_gust_2.wav",
        health = 10,
        pitch = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(player.EyePosition() + Vector(0, 0, -8));
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "Kill", "", this.windEffectDuration, null, null);
        this.TrackEffectEnt(player, snd);
    }

    return (trigger != null || particle != null || snd != null);
};

::ContestItem_WindTouch <- function()
{
    local p = activator;
    local trig = caller;

    if (p == null || !p.IsValid())
    return;

    if (p.GetClassname() != "player")
    return;

    if (!p.IsAlive())
    return;

    if (trig == null || !trig.IsValid())
        return;

    if (p.GetTeam() != 2)
        return;

    local center = trig.GetOrigin();
    local pos = p.GetOrigin();

    local dir = pos - center;
    local len = dir.Length();

    if (len <= 0.01)
        return;

    dir = dir * (1.0 / len);
    dir.z += -0.2;

    local len2 = dir.Length();

    if (len2 <= 0.01)
        return;

    dir = dir * (1.0 / len2);

    local strength = 1000.0;

    p.SetVelocity(dir * strength);
};

//------------------------------------------------------------
// DYNAMIC EFFECTS - RAPID FIRE ZONE
//------------------------------------------------------------

::ContestItem.SpawnRapidFireEffect <- function(player)
{
    if (!this.IsAlivePlayer(player) || player.GetTeam() != 3)
        return false;

    local idx = this.NextIndex();
    local spawnPos = this.GetSpawnPos(player);
    local particleName = "contest_rf_particle_" + idx;
    local triggerName = "contest_rf_trigger_" + idx;
    local sndName = "contest_rf_snd_" + idx;

    this.KillTrackedEffectsForPlayer(player);

    local particle = SpawnEntityFromTable("info_particle_system", {
        targetname = particleName,
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_089",
        start_active = 1
    });

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(spawnPos + Vector(0, 0, 16));
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop", "", this.rapidFireZoneDuration);
        EntFire(particleName, "Kill", "", this.rapidFireZoneDuration + 0.05);
        this.TrackEffectEnt(player, particle);
    }

    local trigger = SpawnEntityFromTable("trigger_multiple", {
        targetname = triggerName,
        model = this.triggerModel,
        origin = spawnPos.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 0.2,
        filtername = "filter_ct",
        "OnStartTouch#1": this.scriptName + ",RunScriptCode,ContestItem_RapidFireTouch(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.01,-1",
        "OnStartTouch#3": "!self,Enable,,0.02,-1"
    });

    if (trigger != null && trigger.IsValid())
    {
        trigger.SetOrigin(spawnPos);
        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", this.rapidFireZoneDuration);
        this.TrackEffectEnt(player, trigger);
    }

    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message = "charge up cannon.mp3",
        health = 10,
        pitch = 120,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(player.EyePosition() + Vector(0, 0, -8));
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "Kill", "", 2.0, null, null);
        this.TrackEffectEnt(player, snd);
    }

    return (trigger != null || particle != null || snd != null);
};

::ContestItem_RapidFireTouch <- function()
{
    local p = activator;

    if (p == null || !p.IsValid())
        return;

    if (p.GetClassname() != "player")
        return;

    if (!p.IsAlive())
        return;

    if (p.GetTeam() != 3)
        return;

    ::ContestItem.ApplyRapidFireToPlayer(p);
};

//------------------------------------------------------------
// RAPID FIRE CORE
//------------------------------------------------------------

if (!("rf_runner" in getroottable())) ::rf_runner <- null;
if (!("rfEnabled" in getroottable())) ::rfEnabled <- false;
if (!("rfRunning" in getroottable())) ::rfRunning <- false;
if (!("rfPlayers" in getroottable())) ::rfPlayers <- {};
if (!("rfWeaponMaxClip" in getroottable())) ::rfWeaponMaxClip <- {};

if (!("rfMult" in getroottable())) ::rfMult <- 1.5;
if (!("rfTick" in getroottable())) ::rfTick <- 0.06;

if (!("CONTEST_IN_ATTACK" in getroottable()))
    ::CONTEST_IN_ATTACK <- 1;

::ContestItem.GetIntSafe <- function(ent, prop, defv = 0)
{
    try { return NetProps.GetPropInt(ent, prop); } catch(e) { return defv; }
};

::ContestItem.GetFloatSafe <- function(ent, prop, defv = 0.0)
{
    try { return NetProps.GetPropFloat(ent, prop); } catch(e) { return defv; }
};

::ContestItem.SetFloatSafe <- function(ent, prop, v)
{
    try { NetProps.SetPropFloat(ent, prop, v); } catch(e) {}
};

::ContestItem.SetIntSafe <- function(ent, prop, v)
{
    try { NetProps.SetPropInt(ent, prop, v); } catch(e) {}
};

::ContestItem.GetActiveWeaponSafe <- function(p)
{
    try { return NetProps.GetPropEntity(p, "m_hActiveWeapon"); } catch(e) { return null; }
};

::ContestItem.EnsureRFRunnable <- function()
{
    if (::rf_runner != null && ::rf_runner.IsValid())
        return true;

    ::rf_runner = Entities.FindByName(null, "rapidfire_runner");

    if (::rf_runner == null)
        ::rf_runner = SpawnEntityFromTable("logic_script", { targetname = "rapidfire_runner" });

    return (::rf_runner != null && ::rf_runner.IsValid());
};

::ContestItem.RF_ApplyInfiniteAmmo <- function(p, w)
{
    if (p == null || w == null || !w.IsValid())
        return;

    local wepId = w.entindex();
    local clip = this.GetIntSafe(w, "m_iClip1", -1);

    if (clip < 0)
        return;

    if (!(wepId in ::rfWeaponMaxClip))
    {
        if (clip > 0 && clip <= 200)
            ::rfWeaponMaxClip[wepId] <- clip;
    }

    if (wepId in ::rfWeaponMaxClip)
    {
        local maxClip = ::rfWeaponMaxClip[wepId];

        if (clip < maxClip)
            this.SetIntSafe(w, "m_iClip1", maxClip);
    }

    local ammoType = this.GetIntSafe(w, "m_iPrimaryAmmoType", -1);

    if (ammoType >= 0)
    {
        try { NetProps.SetPropInt(p, "m_iAmmo[" + ammoType + "]", 999); } catch(e) {}
    }
};

::ContestItem.ApplyRapidFireToPlayer <- function(p)
{
    if (!this.IsAlivePlayer(p))
        return false;

    if (p.GetTeam() != 3)
        return false;

    if (!this.EnsureRFRunnable())
        return false;

    ::rfPlayers[p.entindex()] <- Time() + this.rapidFireBuffDuration;
    ::rfEnabled = true;

    if (!::rfRunning)
    {
        ::rfRunning = true;
        EntFireByHandle(::rf_runner, "RunScriptCode", "ContestItem_RapidFireTick()", ::rfTick, null, null);
    }

    return true;
};

::ContestItem_RapidFireTick <- function()
{
    if (!("ContestItem" in getroottable()))
        return;

    ::ContestItem.RapidFireTick();
};

::ContestItem.RapidFireTick <- function()
{
    if (!::rfEnabled)
    {
        ::rfRunning = false;
        return;
    }

    if (::rf_runner == null || !::rf_runner.IsValid())
    {
        ::rfEnabled = false;
        ::rfRunning = false;
        return;
    }

    local now = Time();
    local aliveCount = 0;
    local toDelete = [];

    foreach (id, endTime in ::rfPlayers)
    {
        local p = EntIndexToHScript(id);

        if (p == null || !p.IsValid())
    {
    toDelete.append(id);
    continue;
    }

    if (p.GetClassname() != "player")
    {
    toDelete.append(id);
    continue;
    }

    if (!p.IsAlive())
    {
    toDelete.append(id);
    continue;
    }

        if (p.GetTeam() != 3)
        {
            toDelete.append(id);
            continue;
        }

        if (now >= endTime)
        {
            toDelete.append(id);
            continue;
        }

        aliveCount++;

        local buttons = this.GetIntSafe(p, "m_nButtons", 0);

        if ((buttons & ::CONTEST_IN_ATTACK) == 0)
            continue;

        local w = this.GetActiveWeaponSafe(p);

        if (w == null || !w.IsValid())
            continue;

        this.RF_ApplyInfiniteAmmo(p, w);

        local nextW = this.GetFloatSafe(w, "m_flNextPrimaryAttack", now);

        if (nextW > now)
        {
            local remain = nextW - now;
            this.SetFloatSafe(w, "m_flNextPrimaryAttack", now + (remain / ::rfMult));
        }

        local nextP = this.GetFloatSafe(p, "m_flNextAttack", now);

        if (nextP > now)
        {
            local remainP = nextP - now;
            this.SetFloatSafe(p, "m_flNextAttack", now + (remainP / ::rfMult));
        }
    }

    foreach (id in toDelete)
    {
        if (id in ::rfPlayers)
            ::rfPlayers.rawdelete(id);
    }

    if (aliveCount <= 0)
    {
        ::rfEnabled = false;
        ::rfRunning = false;
        return;
    }

    EntFireByHandle(::rf_runner, "RunScriptCode", "ContestItem_RapidFireTick()", ::rfTick, null, null);
};

//------------------------------------------------------------
// RESET / CLEANUP
//------------------------------------------------------------

::ContestItem.ResetAll <- function()
{
    this.ClearAllHealImmunity();
    foreach (key, data in this.owners)
    {
        if ("player" in data)
            this.KillTrackedEffectsForPlayer(data.player);
    }

    this.owners.clear();
    this.cooldowns.clear();
    this.KillAllTrackedEffects();

    foreach (itemKey, cfg in this.configs)
    {
        this.SetReadyParticle(itemKey, true);
    }

    if ("rfPlayers" in getroottable())
    ::rfPlayers.clear();

    if ("rfWeaponMaxClip" in getroottable())
    ::rfWeaponMaxClip.clear();

    ::rfEnabled = false;
    ::rfRunning = false;
};

::contestItemCallbacks.OnGameEvent_player_death <- function(params)
{
    if ("userid" in params)
        ::ContestItem.ClearHealImmunityByUserID(params.userid);

    if ("userid" in params)
        ::ContestItem.ClearOwnerByUserID(params.userid);

    local p = null;

    if ("userid" in params)
    {
        try { p = GetPlayerFromUserID(params.userid); } catch(e) { p = null; }
    }

    if (p != null && p.IsValid())
        ::ContestItem.ClearOwner(p, false);
};

::contestItemCallbacks.OnGameEvent_player_disconnect <- function(params)
{
    if ("userid" in params)
        ::ContestItem.ClearHealImmunityByUserID(params.userid);

    if ("userid" in params)
        ::ContestItem.ClearOwnerByUserID(params.userid);
};

::contestItemCallbacks.OnGameEvent_player_team <- function(params)
{
    if ("userid" in params)
        ::ContestItem.ClearHealImmunityByUserID(params.userid);

    if ("userid" in params)
        ::ContestItem.ClearOwnerByUserID(params.userid);

    local p = null;

    if ("userid" in params)
    {
        try { p = GetPlayerFromUserID(params.userid); } catch(e) { p = null; }
    }

    if (p != null && p.IsValid())
        ::ContestItem.ClearOwner(p, false);
};

::contestItemCallbacks.OnGameEvent_round_start <- function(params)
{
    ::ContestItem.ResetAll();
};

::contestItemCallbacks.OnGameEvent_round_end <- function(params)
{
    ::ContestItem.ResetAll();
};

if (!::contestItemCallbacksRegistered)
{
    __CollectGameEventCallbacks(::contestItemCallbacks);
    ::contestItemCallbacksRegistered = true;
}

// Start les particules ready au chargement.
::ContestItem.RefreshReadyParticles();

::PickupHeal <- function()
{
    ::ContestItem.RegisterPickup(activator, caller, "heal");
};

::PickupRapidFire <- function()
{
    ::ContestItem.RegisterPickup(activator, caller, "rapid_fire");
};

::PickupWind <- function()
{
    ::ContestItem.RegisterPickup(activator, caller, "wind");
};

//debug items
