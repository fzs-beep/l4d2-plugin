#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
    name = "治疗提示",
    author = "阿骆特烦恼",
    description = "治疗提示（包含自疗）",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    HookEvent("heal_success", Event_HealSuccess);
    HookEvent("pills_used", Event_PillsUsed);
    HookEvent("adrenaline_used", Event_AdrenalineUsed);
}

public Action Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int healer = GetClientOfUserId(event.GetInt("userid"));
    int patient = GetClientOfUserId(event.GetInt("subject"));
    
    if (IsValidClient(healer) && IsValidClient(patient))
    {
        char healerName[MAX_NAME_LENGTH];
        char patientName[MAX_NAME_LENGTH];
        GetClientName(healer, healerName, sizeof(healerName));
        GetClientName(patient, patientName, sizeof(patientName));
        
        if (healer == patient)
        {
            PrintToChatAll("\x04★ \x05%s \x01治疗了自己.", healerName);
        }
        else
        {
            PrintToChatAll("\x04★ \x05%s \x01治疗了 \x05%s", healerName, patientName);
        }
    }
}

public Action Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
    int user = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(user))
    {
        char userName[MAX_NAME_LENGTH];
        GetClientName(user, userName, sizeof(userName));
        
        PrintToChatAll("\x04★ \x05%s \x01服用了 \x04止痛药", userName);
    }
}

public Action Event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
    int user = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(user))
    {
        char userName[MAX_NAME_LENGTH];
        GetClientName(user, userName, sizeof(userName));
        
        PrintToChatAll("\x04★ \x05%s \x01扎上了 \x04肾上腺素", userName);
    }
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}