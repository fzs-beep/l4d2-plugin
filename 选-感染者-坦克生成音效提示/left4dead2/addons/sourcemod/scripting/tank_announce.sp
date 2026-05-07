#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
new bool:g_bIsTankAlive;

public Plugin:myinfo = 
{
	name = "坦克生成提示",
	author = "",
	description = "",
	version = "",
	url = ""
};

public OnMapStart()
{
	PrecacheSound("ui/pickup_secret01.wav");
}

public OnPluginStart()
{
	HookEvent("tank_spawn", OnTankSpawn, EventHookMode_PostNoCopy);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public OnRoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	g_bIsTankAlive = false;
}

public OnTankSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	if (!g_bIsTankAlive)
	{
		g_bIsTankAlive = false;
		EmitSoundToAll("ui/pickup_secret01.wav");	
		CPrintToChatAll("\x04★★★ {blue}Tank \x05已经出现,做好应战准备.");
	}
}