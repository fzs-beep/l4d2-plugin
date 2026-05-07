#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
    name = "复活门解救提示",
    author = "阿骆特烦恼",
    description = "显示玩家通过复活门解救队友的提示",
    version = PLUGIN_VERSION,
    url = ""
}

public void OnPluginStart()
{
    HookEvent("survivor_rescued", Event_SurvivorRescued, EventHookMode_Post);
}

public void Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
    int rescuerid = event.GetInt("rescuer");
    int survivorid = event.GetInt("victim");
    
    int rescuer = GetClientOfUserId(rescuerid);
    int survivor = GetClientOfUserId(survivorid);
    
    if (IsValidClient(rescuer) && IsValidClient(survivor))
    {
        char rescuerName[MAX_NAME_LENGTH];
        char survivorName[MAX_NAME_LENGTH];
        
        GetClientName(rescuer, rescuerName, sizeof(rescuerName));
        GetClientName(survivor, survivorName, sizeof(survivorName));
        
        PrintToChatAll("\x04★ \x05%s \x01打开复活门解救了 \x05%s", rescuerName, survivorName);
    }
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}