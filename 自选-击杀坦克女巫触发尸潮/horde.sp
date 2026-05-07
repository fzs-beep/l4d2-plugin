#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "Horde",
	description = "击杀Tank或Witch触发尸潮",
	author = "藤野深月",
	version = PLUGIN_VERSION,
	url = "null"
};

public OnPluginStart()
{
	HookEvent("witch_killed",			Event_WitchKilled);
	HookEvent("tank_killed",			Event_TankKilled);
}

/* Witch死亡 */
public Action:Event_WitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidPlayer(Client)) ForcePanicEvent(Client);
}

/* Tank死亡 */
public Action:Event_TankKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidPlayer(Client)) ForcePanicEvent(Client);
}

/* 强迫尸潮产生 */
ForcePanicEvent(client)
{
	new String:command[] = "director_force_panic_event";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, command);
	SetCommandFlags(command, flags);
}

/* 判断玩家是否有效 */
stock bool:IsValidPlayer(Client)
{
	if (Client < 1 || Client > MaxClients) return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client)) return false;
	return true;
}