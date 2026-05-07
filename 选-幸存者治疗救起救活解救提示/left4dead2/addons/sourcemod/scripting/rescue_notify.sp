#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
    name = "救起提示",
    author = "阿骆特烦恼",
    description = "当玩家救起队友时显示提示信息",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    HookEvent("revive_success", Event_ReviveSuccess);
}

public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));  // 救人者
    int subject = GetClientOfUserId(event.GetInt("subject")); // 被救者
    
    if (IsValidClient(client) && IsValidClient(subject))
    {
        char clientName[MAX_NAME_LENGTH];
        char subjectName[MAX_NAME_LENGTH];
        
        GetClientName(client, clientName, sizeof(clientName));
        GetClientName(subject, subjectName, sizeof(subjectName));
        
        PrintToChatAll("\x04★ \x05%s \x01救起了 \x05%s", clientName, subjectName);
    }
    
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}