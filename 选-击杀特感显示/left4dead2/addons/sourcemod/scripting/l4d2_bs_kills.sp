#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
    name = "L4D2 个人特感击杀提示",
    author = "阿骆特烦恼",
    description = "个人特感击杀提示与计数",
    version = PLUGIN_VERSION,
    url = ""
};

// 击杀计数器
new g_iKillCount[MAXPLAYERS + 1];

// 特感名称数组
new String:g_sZombieNames[][] = 
{
    "",
    "Smoker",
    "Boomer",
    "Hunter",
    "Spitter",
    "Jockey",
    "Charger",
    "Witch",
    "Tank"
};

public OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
    
    // 注册查看击杀数的命令
    RegConsoleCmd("sm_ks", Command_ShowKills, "显示你的特感击杀数");
    
    // 初始化击杀计数
    for (new i = 1; i <= MaxClients; i++)
    {
        g_iKillCount[i] = 0;
    }
}

public Action:Command_ShowKills(client, args)
{
    if (client > 0 && IsClientInGame(client))
    {
        PrintToChat(client, "\x04★★★ \x01你本局已击杀了 \x05%d \x01只特感.", g_iKillCount[client]);
    }
    return Plugin_Handled;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    // 新回合重置计数
    for (new i = 1; i <= MaxClients; i++)
    {
        g_iKillCount[i] = 0;
    }
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    // 检查是否是玩家击杀特感
    if (victim > 0 && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsSpecialInfected(victim))
    {
        new zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        
        // 增加击杀计数
        g_iKillCount[attacker]++;
        
        // 获取特感名称
        new String:zombieName[32];
        if (zClass >= 1 && zClass <= 8)
        {
            strcopy(zombieName, sizeof(zombieName), g_sZombieNames[zClass]);
        }
        else
        {
            strcopy(zombieName, sizeof(zombieName), "特殊感染者");
        }
        
        // 仅对击杀者显示提示
        PrintToChat(attacker, "\x01+%d \x05击杀 \x04%s", g_iKillCount[attacker], zombieName);
    }
}

bool:IsSpecialInfected(client)
{
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3)
    {
        new zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
        return (zClass >= 1 && zClass <= 6) || zClass == 8; // 包括Tank
    }
    return false;
}