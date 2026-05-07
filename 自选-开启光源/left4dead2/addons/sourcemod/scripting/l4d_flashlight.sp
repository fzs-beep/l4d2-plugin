#define PLUGIN_VERSION 		"2.5.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Flashlight Package
*	Author	:	SilverShot
*	Descrp	:	Attaches an extra flashlight to survivors and spectators.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=173257

========================================================================================
	Change Log:

2.5.1 (19-Nov-2015)
	- Fix to prevent garbage being passed into SetVariantString, as suggested by "KyleS".

2.5 (25-May-2012)
	- Added more checks to events, preventing errors being logged.

2.4 (22-May-2012)
	- Fixed cvar "l4d_flashlight_spec" enums mistake, thanks to "Dont Fear The Reaper".
	- Fixed errors being logged on player spawn event when clients were not in game.

2.3 (22-May-2012)
	- Changed cvar "l4d_flashlight_spec". The cvar is now a bit flag, add the numbers together.
	- Fixed cvar "l4d_flashlight_spec" blocking alive survivors from using the flashlight.

2.2 (20-May-2012)
	- Changed cvar "l4d_flashlight_spec". You can now specify which teams can use spectator lights.
	- Added German translations - Thanks to "Dont Fear The Reaper".

2.1 (30-Mar-2012)
	- Added Spanish translations - Thanks to "Januto".
	- Added cvar "l4d_flashlight_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d_flashlight_modes_tog" same as above, but only works for L4D2.
	- Added cvar "l4d_flashlight_hints" which displays the "intro" message to spectators if spectator lights are enabled.
	- Changed the way "l4d_flashlight_flags" validates clients by checking they have one of the flags specified.
	- Fixed the "sm_lightclient" command not affecting all clients.
	- Fixed the "sm_light" command not working for spectators.
	- Fixed ghost players still having flashlights.
	- Small changes and fixes.

2.0 (02-Dec-2011)
	- Plugin separated and taken from the "Flare and Light Package" plugin.
	- Added Russian translations - Thanks to "disawar1".
	- Added personal flashlights for spectators and dead players. The light is invisible to everyone else.
	- Added cvar "l4d_flashlight_spec" to control if spectators should have personal flashlights.
	- Added the following triggers to specify colors with sm_light: red, green, blue, purple, orange, yellow, white.
	- Saves players flashlight on/off state and colors on map change.

1.0 (29-Jan-2011)
	- Initial release.

======================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Flashlight\x04] \x01"

#define ATTACH_GRENADE		"grenade"

#define MODEL_LIGHT			"models/props_lighting/flashlight_dropped_01.mdl"


static
	// Cvar Handles/Variables
	Handle:g_hCvarAllow, Handle:g_hCvarAlpha, Handle:g_hCvarColor, Handle:g_hCvarFlags, Handle:g_hCvarHints, Handle:g_hCvarIntro, Handle:g_hCvarLock,
	Handle:g_hCvarSpec, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog,
	g_iCvarAlpha, String:g_sCvarCols[12], g_iCvarFlags, bool:g_bCvarAllow, g_iCvarHints, Float:g_fCvarIntro, bool:g_bCvarLock, g_iCvarSpec,

	// Plugin Variables
	Handle:g_hMPGameMode, bool:g_bLeft4Dead2, bool:g_bRoundOver,
	g_iLightIndex[MAXPLAYERS+1], g_iModelIndex[MAXPLAYERS+1], String:g_sPlayerModel[MAXPLAYERS+1][42], g_iLights[MAXPLAYERS+1],
	g_iClientIndex[MAXPLAYERS+1], g_iClientLight[MAXPLAYERS+1], g_iClientColor[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D & L4D2] Flashlight Package",
	author = "SilverShot",
	description = "Attaches an extra flashlight to survivors and spectators.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=173257"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead2 = false;
	else if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	// Translations
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "%s", "translations/flashlight.phrases.txt");
	if( FileExists(sPath) )
		LoadTranslations("flashlight.phrases");
	else
		SetFailState("Missing required 'translations/flashlight.phrases.txt', please re-download.");

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	g_hCvarAllow =			CreateConVar(	"l4d_flashlight_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarAlpha =			CreateConVar(	"l4d_flashlight_bright",		"255.0",		"Brightness of the light <10-255> (changes Distance value).", CVAR_FLAGS, true, 10.0, true, 255.0 );
	g_hCvarColor =			CreateConVar(	"l4d_flashlight_colour",		"200 20 15",	"The default light color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hCvarFlags =			CreateConVar(	"l4d_flashlight_flags",			"",				"Players with these flags may use the sm_light command. (Empty = all).", CVAR_FLAGS );
	g_hCvarHints =			CreateConVar(	"l4d_flashlight_hints",			"1",			"0=Off, 1=Show intro message to players entering spectator.", CVAR_FLAGS );
	g_hCvarIntro =			CreateConVar(	"l4d_flashlight_intro",			"35.0",			"0=Off, Show intro message in chat this many seconds after joining.", CVAR_FLAGS, true, 0.0, true, 120.0);
	g_hCvarLock =			CreateConVar(	"l4d_flashlight_lock",			"0",			"0=Let players set their flashlight color, 1=Force to cvar specified.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_flashlight_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_flashlight_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
		g_hCvarModesTog =	CreateConVar(	"l4d_flashlight_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarSpec =			CreateConVar(	"l4d_flashlight_spec",			"7",			"0=Off, 1=Spectators, 2=Survivors, 4=Infected, 7=All. Give personal flashlights when dead which only they can see.", CVAR_FLAGS );
	CreateConVar(							"l4d_flashlight_version",		PLUGIN_VERSION,	"Flashlight plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_flashlight");

	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	if( g_bLeft4Dead2 )
		HookConVarChange(g_hCvarModesTog,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarAlpha,			ConVarChanged_LightAlpha);
	HookConVarChange(g_hCvarColor,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarFlags,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHints,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarIntro,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarLock,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpec,			ConVarChanged_Cvars);

	// Commands
	RegAdminCmd(	"sm_lightclient",	CmdLightClient,	ADMFLAG_ROOT,	"Create and toggle flashlight attachment on the specified target");
	RegConsoleCmd(	"sm_light",			CmdLight,						"Toggle the attached flashlight");
}

public OnPluginEnd()
{
	for( new i = 1; i <= MaxClients; i++ )
		DeleteLight(i);
}

public OnMapStart()
{
	PrecacheModel(MODEL_LIGHT, true);
}



// ====================================================================================================
//					INTRO
// ====================================================================================================
public OnClientPostAdminCheck(client)
{
	if( !IsValidNow() || IsFakeClient(client) )
		return;

	new clientID = GetClientUserId(client);

	// Display intro / welcome message
	if( g_fCvarIntro )
		CreateTimer(g_fCvarIntro, tmrIntro, clientID);
}

public Action:tmrIntro(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Intro", client);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
{
	GetCvars();
	IsAllowed();
}

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

public ConVarChanged_LightAlpha(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i, entity;
	g_iCvarAlpha = GetConVarInt(g_hCvarAlpha);

	// Loop through players and change their brightness
	for( i = 1; i <= MaxClients; i++ )
	{
		entity = g_iLightIndex[i];
		if( IsValidEntRef(entity) )
		{
			SetVariantEntity(entity);
			SetVariantInt(g_iCvarAlpha);
			AcceptEntityInput(entity, "distance");
		}
	}
}

GetCvars()
{
	decl String:sTemp[16];

	g_iCvarAlpha = GetConVarInt(g_hCvarAlpha);
	GetConVarString(g_hCvarColor, g_sCvarCols, sizeof(g_sCvarCols));
	GetConVarString(g_hCvarFlags, sTemp, sizeof(sTemp));
	g_iCvarFlags = ReadFlagString(sTemp);
	g_iCvarHints = GetConVarInt(g_hCvarHints);
	g_fCvarIntro = GetConVarFloat(g_hCvarIntro);
	g_bCvarLock = GetConVarBool(g_hCvarLock);
	g_iCvarSpec = GetConVarInt(g_hCvarSpec);
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvents();

		if( IsValidNow() )
		{
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					CreateLight(i);
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvents();

		for( new i = 1; i <= MaxClients; i++ )
			DeleteLight(i);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	if( g_bLeft4Dead2 )
	{
		new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
		if( iCvarModesTog != 0 )
		{
			g_iCurrentMode = 0;

			new entity = CreateEntityByName("info_gamemode");
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			AcceptEntityInput(entity, "PostSpawnActivate");
			AcceptEntityInput(entity, "Kill");

			if( g_iCurrentMode == 0 )
				return false;

			if( !(iCvarModesTog & g_iCurrentMode) )
				return false;
		}
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
HookEvents()
{
	HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("player_death",		Event_PlayerDeath);
	HookEvent("item_pickup",		Event_ItemPickup);
	HookEvent("player_spawn",		Event_Spawn);
	HookEvent("player_team",		Event_Team);
}

UnhookEvents()
{
	UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("player_death",		Event_PlayerDeath);
	UnhookEvent("item_pickup",		Event_ItemPickup);
	UnhookEvent("player_spawn",		Event_Spawn);
	UnhookEvent("player_team",		Event_Team);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundOver = false;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundOver = true;

	for( new i = 1; i <= MaxClients; i++ )
		DeleteLight(i);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( !client )
		return;

	DeleteLight(client); // Delete attached flashlight
	CreateSpecLight(client);
}

public Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if( client && IsClientInGame(client) && GetClientTeam(client) == 3 )
		DeleteLight(client);
}

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientID);
	DeleteLight(client);

	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 )
		CreateTimer(0.5, tmrDelayCreateLight, clientID); // Needed because round_start event occurs AFTER player_spawn, so IsValidNow() fails...
}

public Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientID);

	if( !client )
		return;

	DeleteLight(client);
	CreateTimer(0.1, tmrDelayCreateLight, clientID);
	CreateSpecLight(client);
}

public Action:tmrDelayCreateLight(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client && IsValidNow() && IsValidClient(client) ) // Re-create attached flashlight
		CreateLight(client);
}

CreateSpecLight(client)
{
	if( g_iCvarSpec && client && !IsFakeClient(client) && !IsPlayerAlive(client) )
	{
		new team = GetClientTeam(client);
		if( team == 4 ) team = 8;
		else if( team == 3 ) team = 4;

		if( g_iCvarSpec & team )
		{
			new entity = MakeLightDynamic(Float:{ 0.0, 0.0, -10.0 }, Float:{ 0.0, 0.0, 0.0 }, client);
			DispatchKeyValue(entity, "_light", "255 255 255 255");
			DispatchKeyValue(entity, "brightness", "2");
			g_iLights[client] = EntIndexToEntRef(entity);
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitSpec);

			if( g_iCvarHints )
			{
				CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Intro", client);
			}
		}
	}
}



// ====================================================================================================
//					COMMAND - sm_lightclient
// ====================================================================================================
// Attach flashlight onto specified client / change colors
public Action:CmdLightClient(client, args)
{
	if( args == 0 ) return Plugin_Handled;

	decl String:sArg[32], String:target_name[MAX_TARGET_LENGTH];
	GetCmdArg(1, sArg, sizeof(sArg));

	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
		sArg,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE, /* Only allow alive players */
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if( args > 1 )
	{
		GetCmdArgString(sArg, sizeof(sArg));
		// Send the args without target name
		new pos = StrContains(sArg, " ");
		if( pos != -1 )
		{
			Format(sArg, sizeof(sArg), "%s", sArg[pos+1]);
			TrimString(sArg);
			args--;
		}
	}
	else
		args = 0;

	for (new i = 0; i < target_count; i++)
	{
		if( IsValidClient(target_list[i]) )
			CommandForceLight(client, target_list[i], args, sArg);
	}
	return Plugin_Handled;
}

CommandForceLight(client, target, args, const String:sArg[])
{
	// Wrong number of arguments
	if( args != 0 && args != 1 && args != 3 )
	{
		// Display usage help if translation exists and hints turned on
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Usage", client);
		return;
	}

	// Delete flashlight and re-make if the players model has changed, CSM plugin fix...
	decl String:sTempStr[42];
	GetClientModel(target, sTempStr, sizeof(sTempStr));
	if( strcmp(g_sPlayerModel[target], sTempStr) != 0 )
	{
		DeleteLight(target);
		strcopy(g_sPlayerModel[target], 42, sTempStr);
	}

	// Check if they have a light, or try to create
	new entity = g_iLightIndex[target];
	if( !IsValidEntRef(entity) )
	{
		CreateLight(target);

		entity = g_iLightIndex[target];
		if( !IsValidEntRef(entity) )
			return;
	}

	// Toggle or set light color and turn on.
	if( args == 1 )
	{
		decl String:sTempL[12];
		if( strcmp(sArg, "red", false) == 0 )
			Format(sTempL, sizeof(sTempL), "255 0 0");
		else if( strcmp(sArg, "green", false) == 0 )
			Format(sTempL, sizeof(sTempL), "0 255 0");
		else if( strcmp(sArg, "blue", false) == 0 )
			Format(sTempL, sizeof(sTempL), "0 0 255");
		else if( strcmp(sArg, "purple", false) == 0 )
			Format(sTempL, sizeof(sTempL), "155 0 255");
		else if( strcmp(sArg, "orange", false) == 0 )
			Format(sTempL, sizeof(sTempL), "255 155 0");
		else if( strcmp(sArg, "yellow", false) == 0 )
			Format(sTempL, sizeof(sTempL), "255 255 0");
		else // if( strcmp(sArg, "white", false) == 0 )
			Format(sTempL, sizeof(sTempL), "-1 -1 -1");

		SetVariantEntity(entity);
		SetVariantString(sTempL);
		AcceptEntityInput(entity, "color");
	}
	else if( args == 3 )
	{
		// Specified colors
		decl String:sTempL[12];
		decl String:sSplit[3][4];
		ExplodeString(sArg, " ", sSplit, 3, 4);
		Format(sTempL, sizeof(sTempL), "%d %d %d", StringToInt(sSplit[0]), StringToInt(sSplit[1]), StringToInt(sSplit[2]));

		SetVariantEntity(entity);
		SetVariantString(sTempL);
		AcceptEntityInput(entity, "color");
	}

	AcceptEntityInput(entity, "toggle");

	new color = GetEntProp(entity, Prop_Send, "m_clrRender");
	if( color != g_iClientColor[target] )
		AcceptEntityInput(entity, "turnon");
	g_iClientColor[target] = color;
	g_iClientLight[target] = !g_iClientLight[target];
}



// ====================================================================================================
//					COMMAND - sm_light
// ====================================================================================================
public Action:CmdLight(client, args)
{
	decl String:sArg[25];
	GetCmdArgString(sArg, sizeof(sArg));
	CommandLight(client, args, sArg);
	return Plugin_Handled;
}

CommandLight(client, args, const String:sArg[])
{
	// Must be valid
	if( !client )
		return;

	if( !IsValidNow() )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	if( IsPlayerAlive(client) )
	{
		if( GetClientTeam(client) != 2 )
		{
			CPrintToChat(client, "[SM] %T.", "No Access", client);
			return;
		}
	}
	else
	{
		if( g_iCvarSpec == 0 )
		{
			CPrintToChat(client, "[SM] %T.", "No Access", client);
			return;
		}

		new team = GetClientTeam(client);
		if( team == 4 ) team = 8;
		else if( team == 3 ) team = 4;

		if( !(g_iCvarSpec & team) )
		{
			CPrintToChat(client, "[SM] %T.", "No Access", client);
			return;
		}
	}

	// Make sure the user has the correct permissions
	new flagc = GetUserFlagBits(client);

	if( g_iCvarFlags != 0 && !(flagc & g_iCvarFlags) && !(flagc & ADMFLAG_ROOT) )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	// Wrong number of arguments
	if( args != 0 && args != 1 && args != 3 )
	{
		// Display usage help if translation exists and hints turned on
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Usage", client);
		return;
	}

	// Delete flashlight and re-make if the players model has changed, CSM plugin fix...
	decl String:sTempStr[42];
	GetClientModel(client, sTempStr, sizeof(sTempStr));
	if( strcmp(g_sPlayerModel[client], sTempStr) != 0 )
	{
		DeleteLight(client);
		strcopy(g_sPlayerModel[client], 42, sTempStr);
	}

	// Check if they have a light, or try to create
	new entity = g_iLightIndex[client];
	if( !IsValidEntRef(entity) )
	{
		CreateLight(client);

		entity = g_iLightIndex[client];
		if( !IsValidEntRef(entity) )
			return;
	}

	// Specified colors
	if( g_bCvarLock && !(flagc & ADMFLAG_ROOT) )
		flagc = 0;
	else
		flagc = 1;

	// Toggle or set light color and turn on.
	if( flagc && args == 1 )
	{
		decl String:sTempL[12];
		if( strcmp(sArg, "red", false) == 0 )
			Format(sTempL, sizeof(sTempL), "255 0 0");
		else if( strcmp(sArg, "green", false) == 0 )
			Format(sTempL, sizeof(sTempL), "0 255 0");
		else if( strcmp(sArg, "blue", false) == 0 )
			Format(sTempL, sizeof(sTempL), "0 0 255");
		else if( strcmp(sArg, "purple", false) == 0 )
			Format(sTempL, sizeof(sTempL), "155 0 255");
		else if( strcmp(sArg, "orange", false) == 0 )
			Format(sTempL, sizeof(sTempL), "255 155 0");
		else if( strcmp(sArg, "yellow", false) == 0 )
			Format(sTempL, sizeof(sTempL), "255 255 0");
		else if( strcmp(sArg, "white", false) == 0 )
			Format(sTempL, sizeof(sTempL), "-1 -1 -1");

		SetVariantEntity(entity);
		SetVariantString(sTempL);
		AcceptEntityInput(entity, "color");
	}
	else if( flagc && args == 3 )
	{
		// Specified colors
		decl String:sTempL[12];
		decl String:sSplit[3][4];
		ExplodeString(sArg, " ", sSplit, 3, 4);
		Format(sTempL, sizeof(sTempL), "%d %d %d", StringToInt(sSplit[0]), StringToInt(sSplit[1]), StringToInt(sSplit[2]));

		SetVariantEntity(entity);
		SetVariantString(sTempL);
		AcceptEntityInput(entity, "color");
	}

	AcceptEntityInput(entity, "toggle");

	new color = GetEntProp(entity, Prop_Send, "m_clrRender");
	if( color != g_iClientColor[client] )
		AcceptEntityInput(entity, "turnon");
	g_iClientColor[client] = color;
	g_iClientLight[client] = !g_iClientLight[client];
}

// Called to attach permanent light.
CreateLight(client)
{
	DeleteLight(client);

	// Declares
	new entity, Float:vOrigin[3], Float:vAngles[3];

	// Flashlight model
	entity = CreateEntityByName("prop_dynamic");
	if( entity == -1 )
	{
		LogError("Failed to create 'prop_dynamic'");
	}
	else
	{
		SetEntityModel(entity, MODEL_LIGHT);
		DispatchSpawn(entity);

		vOrigin = Float: { 0.0, 0.0, -2.0 };
		vAngles = Float: { 180.0, 9.0, 90.0 };

		// Attach to survivor
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		SetVariantString(ATTACH_GRENADE);
		AcceptEntityInput(entity, "SetParentAttachment");

		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
		g_iModelIndex[client] = EntIndexToEntRef(entity);
	}

	// Position light
	vOrigin = Float: { 0.5, -1.5, -7.5 };
	vAngles = Float: { -45.0, -45.0, 90.0 };

	// Light_Dynamic
	entity = MakeLightDynamic(vOrigin, vAngles, client);
	g_iLightIndex[client] = EntIndexToEntRef(entity);

	if( g_iClientIndex[client] == GetClientUserId(client) )
	{
		SetEntProp(entity, Prop_Send, "m_clrRender", g_iClientColor[client]);
		if( g_iClientLight[client] == 1 )
			AcceptEntityInput(entity, "TurnOn");
		else
			AcceptEntityInput(entity, "TurnOff");
	}
	else
	{
		g_iClientIndex[client] = GetClientUserId(client);
		g_iClientLight[client] = 0;
		g_iClientColor[client] = GetEntProp(entity, Prop_Send, "m_clrRender");
		AcceptEntityInput(entity, "TurnOff");
	}
}



// ====================================================================================================
//					LIGHTS
// ====================================================================================================
MakeLightDynamic(const Float:vOrigin[3], const Float:vAngles[3], client)
{
	new entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	decl String:sTemp[16];
	Format(sTemp, sizeof(sTemp), "%s 255", g_sCvarCols);
	DispatchKeyValue(entity, "_light", sTemp);
	DispatchKeyValue(entity, "brightness", "1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", float(g_iCvarAlpha));
	DispatchKeyValue(entity, "style", "0");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");

	// Attach to survivor
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);

	if( GetClientTeam(client) == 2 )
	{
		SetVariantString(ATTACH_GRENADE);
		AcceptEntityInput(entity, "SetParentAttachment");
	}

	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	return entity;
}



// ====================================================================================================
//					DELETE ENTITIES
// ====================================================================================================
DeleteLight(client)
{
	new entity = g_iLightIndex[client];
	g_iLightIndex[client] = 0;
	DeleteEntity(entity);

	entity = g_iModelIndex[client];
	g_iModelIndex[client] = 0;
	DeleteEntity(entity);

	entity = g_iLights[client];
	g_iLights[client] = 0;
	DeleteEntity(entity);
}

DeleteEntity(entity)
{
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");
}

public Action:tmrDeleteEntity(Handle:timer, any:entity)
{
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}



// ====================================================================================================
//					BOOLEANS
// ====================================================================================================
bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

bool:IsValidClient(client)
{
	if( !client || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) )
		return false;
	return true;
}

bool:IsValidNow()
{
	if( g_bRoundOver || !g_bCvarAllow )
		return false;
	return true;
}



// ====================================================================================================
//					SDKHOOKS TRANSMIT
// ====================================================================================================
public Action:Hook_SetTransmitLight(entity, client)
{
	if( g_iModelIndex[client] == EntIndexToEntRef(entity) )
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Hook_SetTransmitSpec(entity, client)
{
	if( g_iLights[client] == EntIndexToEntRef(entity) )
		return Plugin_Continue;
	return Plugin_Handled;
}