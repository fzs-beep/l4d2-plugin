#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
    name = "女巫惊扰击杀提示",
    author = "阿骆特烦恼",
    description = "显示女巫被惊扰和被击杀的提示信息",
    version = PLUGIN_VERSION,
    url = ""
};

public OnPluginStart()
{
    HookEvent("witch_harasser_set", Event_WitchDisturbed);
    HookEvent("witch_killed", Event_WitchKilled);
}

public Event_WitchDisturbed(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (client > 0 && IsClientInGame(client))
    {
        decl String:playerName[MAX_NAME_LENGTH];
        GetClientName(client, playerName, sizeof(playerName));
        
        PrintToChatAll("\x04★ \x05%s \x01惊扰了 \x05Witch", playerName);
    }
}

public Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (client > 0 && IsClientInGame(client))
    {
        decl String:playerName[MAX_NAME_LENGTH];
        GetClientName(client, playerName, sizeof(playerName));
        
        PrintToChatAll("\x04★ \x05%s \x01击杀了 \x05Witch", playerName);
    }
}