#define PLUGIN_VERSION 		"1.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Special Infected Burn Duration
*	Author	:	SilverShot
*	Descrp	:	Control flame duration for the Tank, Witch and Special Infected.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=319621
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (11-Nov-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar g_hCvarInfected, g_hCvarFlameSpec, g_hCvarFlameTank, g_hCvarFlameWitch;
bool g_bLeft4Dead2;
float g_fCvarFlameSpec, g_fCvarFlameTank, g_fCvarFlameWitch;
int g_iCvarInfected;
int TYPE_SPECIAL = 1;
int TYPE_TANK = 5;
int TYPE_WITCH = 0;



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Special Infected Burn Duration",
	author = "SilverShot",
	description = "Control flame duration for the Tank, Witch and Special Infected.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=319621"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Cvars
	g_hCvarInfected =		CreateConVar(	"l4d_burn_duration_infected",		"63",				"Which Special Infected to affect: 1=Smoker, 2=Boomer, 4=Hunter, 8=Spitter, 16=Jockey, 32=Charger, 63=All. Add numbers together.", CVAR_FLAGS );
	g_hCvarFlameSpec =		CreateConVar(	"l4d_burn_duration_special",		"0.1",				"0.0=Game default. How long Special Infected stay ignited.", CVAR_FLAGS );
	g_hCvarFlameTank =		CreateConVar(	"l4d_burn_duration_tank",			"0.1",				"0.0=Game default. How long the Tank stays ignited.", CVAR_FLAGS );
	g_hCvarFlameWitch =		CreateConVar(	"l4d_burn_duration_witch",			"0.1",				"0.0=Game default. How long the Witch stays ignited.", CVAR_FLAGS );
	CreateConVar(							"l4d_burn_duration_version",		PLUGIN_VERSION,		"Burn Duration version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarInfected.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFlameSpec.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFlameTank.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFlameWitch.AddChangeHook(ConVarChanged_Cvars);

	if( g_bLeft4Dead2 )
		TYPE_TANK = 8;
	GetCvars();
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("witch_spawn", Event_WitchSpawn);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarInfected = g_hCvarInfected.IntValue;
	g_fCvarFlameSpec = g_hCvarFlameSpec.FloatValue;
	g_fCvarFlameTank = g_hCvarFlameTank.FloatValue;
	g_fCvarFlameWitch = g_hCvarFlameWitch.FloatValue;
}

// ====================================================================================================
//					EVENTS
// ====================================================================================================
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		if( GetClientTeam(client) == 3 )
		{
			int class = GetEntProp(client, Prop_Send, "m_zombieClass");

			if( g_fCvarFlameTank && class == TYPE_TANK )
			{
				SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageT);
			}
			else if( g_fCvarFlameSpec && g_iCvarInfected & (1 << (class - 1)) )
			{
				SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageS);
			}
		}
	}
}

public Action Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_fCvarFlameWitch )
	{
		int witch = event.GetInt("witchid");
		SDKHook(witch, SDKHook_OnTakeDamageAlive, OnTakeDamageW);
	}
}

// ====================================================================================================
//					DAMAGE
// ====================================================================================================
public Action OnTakeDamageS(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype == DMG_BURN || damagetype == DMG_SLOWBURN ) OnDamage(victim, TYPE_SPECIAL);
}
public Action OnTakeDamageT(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype == DMG_BURN || damagetype == DMG_SLOWBURN ) OnDamage(victim, TYPE_TANK);
}
public Action OnTakeDamageW(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype == DMG_BURN || damagetype == DMG_SLOWBURN ) OnDamage(victim, TYPE_WITCH);
}

void OnDamage(int victim, int type)
{
	int flame = GetEntPropEnt(victim, Prop_Send, "m_hEffectEntity");
	if( flame != -1 )
	{
		if( type == TYPE_SPECIAL )
			SetEntPropFloat(flame, Prop_Data, "m_flLifetime", GetGameTime() + g_fCvarFlameSpec);
		else if( type == TYPE_TANK )
			SetEntPropFloat(flame, Prop_Data, "m_flLifetime", GetGameTime() + g_fCvarFlameTank);
		else if( type == TYPE_WITCH )
			SetEntPropFloat(flame, Prop_Data, "m_flLifetime", GetGameTime() + g_fCvarFlameWitch);
	}
}