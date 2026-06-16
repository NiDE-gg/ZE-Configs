// nefarious eltra fog script

if (!("g_szDefaultFogName" in getroottable())) { // if there is no global default fogname variable, create it
	::g_szDefaultFogName <- "" // but if it already exists, don't, as to not overwrite it every round on entspawn
}

::g_szMapFogName <- ""




// sets the current fog controller, and applies to all players
::SetMapFog <- function(sz_NewFog = "") {
	if (sz_NewFog == "") { // short-hand to apply default fog
		g_szMapFogName = g_szDefaultFogName;
	} else {
		g_szMapFogName = sz_NewFog
	}

	// apply the fog to all palyers on the map
	EntFire("player*", "SetFogController", g_szMapFogName, 0, null);

}


// gets the current fog controller's name and applies to to the activator of whatever called this function
// this only works if a fog controller has been set via SetMapFog / SetMapDefaultFog !!!!
::GetMapFog <- function() {
	
	if (g_szMapFogName != "") { 
		if (developer() > 0) {
			printl("Setting player fog to "+g_szMapFogName)
		}
		activator.AcceptInput("SetFogController", g_szMapFogName, activator, activator);
	} else {
		if (developer() > 0) {
			printl("Setting player fog to the DEFAULT FOG! which is "+g_szDefaultFogName)
		}
		activator.AcceptInput("SetFogController", g_szDefaultFogName, activator, activator);
	}
}


// set the default map fog controller.
::SetMapDefaultFog <- function(sz_NewFog) {
	::g_szDefaultFogName <- sz_NewFog;
}

// SHORTHANDS FOR THE ABOVE!!
::SetFog <- SetMapFog
::GetFog <- GetMapFog

::SetDefaultFog <- SetMapDefaultFog
::SetFogDefault <- SetMapDefaultFog


// sets fog to whatever the default is, there isn't really a reason to use this over just calling SetMapFog() with no args
::ResetFog <- function() {
	SetMapFog()
}
