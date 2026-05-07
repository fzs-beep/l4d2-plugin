#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


public Plugin myinfo = 
{
	name 			= "Simple give item",
	author 			= "东",
	description 	= "开局回满血和给包",
	version 		= "2022.11.08",
	url 			= "https://github.com/fantasylidong/L4d2_plugins"
}

public void OnPluginStart()
{
	HookEvent("player_left_safe_area", event_GameStart);
}

public void event_GameStart(Handle event, char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsSurvivor(client)) 
		{
			BypassAndExecuteCommand(client, "give","first_aid_kit"); 
			BypassAndExecuteCommand(client, "give","health"); 
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);		
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", false);
		}
	}
}

void BypassAndExecuteCommand(int client, char[] strCommand, char[] strParam1 = "")
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

//判断是否为生还者
stock bool IsSurvivor(int client) 
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2) 
	{
		return true;
	} 
	else 
	{
		return false;
	}
}

stock int GetRandomClient()
{
	for(int i =1; i <= MaxClients; i++){
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			return i;
		}
	}
	return -1;
}

//特感激进进攻
public Action L4D_OnFirstSurvivorLeftSafeArea(int firstSurvivor) 
{
	CreateTimer( 0.3, Timer_ForceInfectedAssault, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
	return Plugin_Continue;
}

public Action Timer_ForceInfectedAssault( Handle timer) 
{
	BypassAndExecuteCommand(GetRandomClient(),"nb_assault");
	return Plugin_Continue;
}