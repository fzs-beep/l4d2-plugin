#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

#define CVAR_FLAGS 			FCVAR_NOTIFY
#define PLUGIN_VERSION	 "1.0"

public Plugin myinfo =
{
	name = "l4d2_ss_damage",
	author = "H.M.40",
	description = "根据难度调整小僵尸打人伤害",
	version = "1.0",
	url = ""
}

ConVar CvarDamage[5];
ConVar cvar_Difficulty;

float ss_dmg;
//float origin_dmg;

public void OnPluginStart()
{
	CreateConVar("l4d2_ss_damage_version", PLUGIN_VERSION, "插件版本", CVAR_FLAGS);
	CvarDamage[1] = CreateConVar("l4d2_ss_damage_easy", "2.0" , "简单难度小僵尸正面一下的伤害(背面默认除以2)", CVAR_FLAGS, true, 0.0, true, 100.0);
	CvarDamage[2] = CreateConVar("l4d2_ss_damage_normal", "3.0" , "普通难度小僵尸正面一下的伤害(背面默认除以2)", CVAR_FLAGS, true, 0.0, true, 100.0);
	CvarDamage[3] = CreateConVar("l4d2_ss_damage_hard", "7.0" , "困难难度小僵尸正面一下的伤害(背面默认除以2)", CVAR_FLAGS, true, 0.0, true, 100.0);
	CvarDamage[4] = CreateConVar("l4d2_ss_damage_expert", "10.0" , "专家难度小僵尸正面一下的伤害(背面默认除以2)", CVAR_FLAGS, true, 0.0, true, 100.0);
	
	AutoExecConfig(true, "l4d2_ss_damage");
	
	HookEvent("round_start", Event_RoundStart);

	cvar_Difficulty = FindConVar("z_difficulty");
	HookConVarChange(cvar_Difficulty, ConVarDifficultyChange);
}

public void OnConfigsExecuted()
{
	SetDamage();
}

public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	CreateTimer(2.0, CheckDelays);
}

public void ConVarDifficultyChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetDamage();
}

public Action CheckDelays(Handle timer)
{
	SetDamage();
	return Plugin_Continue;
}

void SetDamage()
{
	ss_dmg = CvarDamage[GetCurrentDifficulty()].FloatValue;
}

int GetCurrentDifficulty()
{
	char Difficulty[32];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if(StrEqual(Difficulty, "easy", false))
	{
		//origin_dmg = 1.0;
		return 1;
	}
	else if(StrEqual(Difficulty, "normal", false))
	{
		//origin_dmg = 2.0;
		return 2;
	}
	else if(StrEqual(Difficulty, "hard", false))
	{
		//origin_dmg = 5.0;
		return 3;
	}
	else
	{
		//origin_dmg = 20.0;
		return 4;
	}
}

public void OnClientPutInServer(int client)
{ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeZombineDamage); 
} 

bool IsValidClient(int client)
{
	return (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client));
}

bool IsZombine(int attacker)
{
	if(attacker > 0 && IsValidEntity(attacker))
	{
		char classname[32];
		GetEdictClassname(attacker, classname, sizeof(classname));
		if(StrEqual(classname, "infected", false)) return true;
	}
	return false;
}

public Action OnTakeZombineDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(IsValidClient(victim) && IsZombine(attacker))
	{
		/*
		if(damage >= origin_dmg)
			damage = ss_dmg;
		else
			damage = ss_dmg * 0.5;
		*/
		damage = ss_dmg;

		return Plugin_Changed;
	}
	return Plugin_Continue;
}
