#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
    name = "电击器救活提示",
    author = "阿骆特烦恼",
    description = "显示玩家使用电击器救活队友的提示",
    version = PLUGIN_VERSION,
    url = ""
}

public void OnPluginStart()
{
    HookEvent("defibrillator_used", Event_DefibUsed, EventHookMode_Post);
}

public void Event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int subject = event.GetInt("subject");
    
    int client = GetClientOfUserId(userid);
    int victim = GetClientOfUserId(subject);
    
    if (IsValidClient(client) && IsValidClient(victim))
    {
        char clientName[MAX_NAME_LENGTH];
        char victimName[MAX_NAME_LENGTH];
        
        GetClientName(client, clientName, sizeof(clientName));
        GetClientName(victim, victimName, sizeof(victimName));
        
        // 更醒目的提示格式
        PrintToChatAll("\x04★ \x05%s \x01使用电击器救活了 \x05%s", clientName, victimName);
        
        // 可选：在控制台也显示记录
        PrintToServer("[电击器] %s 使用电击器救活了 %s", clientName, victimName);
    }
}

bool IsValidClient(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client))
        return false;
    return IsClientInGame(client);
}