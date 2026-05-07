#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsSurvivor(attacker) || !IsSurvivor(victim)) return;
	int damage = GetEventInt(event, "dmg_health");
	if (attacker != victim && damage > 0)
		CPrintToChatAll("{green}%N {default}黑了 {olive}%N {default}-> {blue}%d点 {default}血", attacker, victim, damage);
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}