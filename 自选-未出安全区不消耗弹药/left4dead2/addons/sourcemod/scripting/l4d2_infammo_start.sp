#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public void OnPluginStart() { HookEvent("round_start",			Event_RoundStart,			EventHookMode_PostNoCopy); }
public void OnPluginEnd() { FindConVar("sv_infinite_ammo").IntValue = 0; }
public void OnMapEnd() { FindConVar("sv_infinite_ammo").IntValue = 0; }
public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client) { FindConVar("sv_infinite_ammo").IntValue = 0; }
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) { FindConVar("sv_infinite_ammo").IntValue = 1; }