#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks> // 必需
#include <l4d2_ems_hud> // 必需

#define PLUGIN_VERSION "10.7.1 (Fix Compile & Align)"

// ====================================================================================================
// HUD 坐标与布局配置
// ====================================================================================================

#define POS_LEFT_X          0.02
#define POS_LEFT_Y_START    0.15
#define LINE_HEIGHT_LEFT    0.022 

#define POS_RIGHT_X         0.78
#define POS_RIGHT_Y_TOP     0.00
#define POS_RIGHT_Y_BOT     0.15

#define POS_FEED_X          0.80
#define POS_FEED_Y_START    0.50
#define LINE_HEIGHT_FEED    0.022

// 槽位分配 (0-14)
#define SLOT_HEADER         0
#define SLOT_PLAYER_START   1
#define SLOT_INFO_TOP       9
#define SLOT_INFO_BOT       10
#define SLOT_KILLFEED_START 11

// ====================================================================================================
// 变量
// ====================================================================================================

enum struct PlayerData {
    int SiKills;
    int CiKills;
    int FFReceived;
    int FriendlyFire;
}

PlayerData g_Stats[MAXPLAYERS+1];
int g_iTotalSiKills, g_iTotalCiKills; 
int g_iChapterSiKills, g_iChapterCiKills; 

int g_iGameStartTime; 
int g_iRoundStartTime;

ArrayList g_KillFeed;
ConVar g_cvLimph, g_cvRevives, g_cvShowBots;
static const char g_sWeekDays[][] = { "星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六" };

public Plugin myinfo = {
    name = "L4D2 Ultimate HUD v10.7.1",
    author = "aiou",
    description = "Fix compile error and alignment",
    version = PLUGIN_VERSION,
    url = ""
};

// ====================================================================================================
// 辅助函数声明 (前置声明，防止编译器找不到)
// ====================================================================================================
// 注意：SourcePawn某些版本需要将被调用的函数放在前面，或者显式声明，这里我把实现放在最后，确保语法正确

// ====================================================================================================
// 初始化
// ====================================================================================================

public void OnPluginStart()
{
    g_KillFeed = new ArrayList(ByteCountToCells(64));
    
    g_iGameStartTime = GetTime(); 
    g_iRoundStartTime = GetTime();

    g_cvLimph = FindConVar("survivor_limp_health");
    g_cvRevives = FindConVar("survivor_max_incapacitated_count");
    g_cvShowBots = CreateConVar("l4d2_hud_show_bots", "0", "是否在排行榜显示电脑玩家(闲置玩家始终显示)");

    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("infected_death", Event_InfectedDeath);
    HookEvent("witch_killed", Event_WitchKilled);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_start", Event_RoundStart);
    
    CreateTimer(0.33, Timer_Update, _, TIMER_REPEAT);
}

// ====================================================================================================
// 核心逻辑
// ====================================================================================================

public void OnMapStart()
{
    EnableHUD(); 
    if (L4D_GetCurrentChapter() <= 1) ResetTotalStats();
    CleanHUD();
}

void ResetTotalStats()
{
    g_iTotalSiKills = 0;
    g_iTotalCiKills = 0;
    g_iGameStartTime = GetTime();
    
    for(int i=1; i<=MaxClients; i++) {
        g_Stats[i].SiKills = 0;
        g_Stats[i].CiKills = 0;
        g_Stats[i].FFReceived = 0;
        g_Stats[i].FriendlyFire = 0;
    }
    g_KillFeed.Clear();
}

void CleanHUD() { for(int i=0; i<15; i++) RemoveHUD(i); }

public void OnClientConnected(int client) { }

// ====================================================================================================
// 事件处理
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) { 
    EnableHUD();
    g_iChapterSiKills = 0;
    g_iChapterCiKills = 0;
    g_iRoundStartTime = GetTime(); 
    
    for(int i=1; i<=MaxClients; i++) {
        g_Stats[i].CiKills = 0; 
        g_Stats[i].SiKills = 0;
        g_Stats[i].FFReceived = 0;
        g_Stats[i].FriendlyFire = 0;
    }

    g_KillFeed.Clear();
    
    // 延迟2秒初始化HUD，防止崩溃
    CreateTimer(2.0, Timer_DelayedRoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DelayedRoundStart(Handle timer) {
    UpdateAllHUD();
    return Plugin_Continue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    bool headshot = event.GetBool("headshot");
    
    if (IsValidSurvivor(attacker)) {
        int realAttacker = GetRealClient(attacker);
        if (IsValidInfected(victim)) {
            g_Stats[realAttacker].SiKills++;
            g_iTotalSiKills++;
            g_iChapterSiKills++;
            
            char sPName[64], sZName[32];
            GetClientName(realAttacker, sPName, sizeof(sPName));
            char sShortName[64];
            
            if (realAttacker != attacker) {
                // 名字截断长度设为 22
                strcopy(sShortName, sizeof(sShortName), GetDealName(sPName, 22)); 
                Format(sShortName, sizeof(sShortName), "%s(摸鱼)", sShortName);
            } else {
                strcopy(sShortName, sizeof(sShortName), GetDealName(sPName, 22));
            }
            
            int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
            GetZombieClassName(zClass, sZName, sizeof(sZName));
            
            AddKillFeed(sShortName, sZName, headshot ? "[爆头]" : "[击杀]");
            UpdateAllHUD();
        }
    }
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast) {
    int userid = event.GetInt("userid");
    int attacker = GetClientOfUserId(userid);
    
    if (IsValidSurvivor(attacker)) {
        int real = GetRealClient(attacker);
        g_Stats[real].SiKills++;
        g_iTotalSiKills++;
        g_iChapterSiKills++;
        
        char sPName[64];
        GetClientName(real, sPName, sizeof(sPName));
        char sShortName[64];
        
        if (real != attacker) {
            strcopy(sShortName, sizeof(sShortName), GetDealName(sPName, 22));
            Format(sShortName, sizeof(sShortName), "%s(摸鱼)", sShortName);
        } else {
            strcopy(sShortName, sizeof(sShortName), GetDealName(sPName, 22));
        }
        
        AddKillFeed(sShortName, "Witch", "[击杀]");
        UpdateAllHUD();
    }
}

public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast) {
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int entity = event.GetInt("infected_id");
    
    if (entity > MaxClients && IsValidEdict(entity)) {
        char cls[64];
        GetEdictClassname(entity, cls, sizeof(cls));
        if (StrEqual(cls, "witch", false)) return;
    }

    if (IsValidSurvivor(attacker)) {
        int real = GetRealClient(attacker);
        g_Stats[real].CiKills++; 
        g_iTotalCiKills++;
        g_iChapterCiKills++;
        
        UpdateAllHUD();
    }
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int dmg = event.GetInt("dmg_health");
    
    if (IsValidSurvivor(attacker) && IsValidSurvivor(victim) && attacker != victim) {
        int realAttacker = GetRealClient(attacker);
        int realVictim = GetRealClient(victim);
        g_Stats[realAttacker].FriendlyFire += dmg;
        g_Stats[realVictim].FFReceived += dmg;
        UpdateAllHUD();
    }
}

// ====================================================================================================
// HUD 绘制
// ====================================================================================================

public Action Timer_Update(Handle timer) {
    UpdateAllHUD();
    return Plugin_Continue;
}

void UpdateAllHUD() {
    DrawTopRight();
    DrawBottomRight();
    DrawLeftPanel();
}

void DrawTopRight() {
    char sDate[32], sTime[32], sWeek[8];
    FormatTime(sDate, sizeof(sDate), "%Y-%m-%d");
    FormatTime(sTime, sizeof(sTime), "%H:%M:%S");
    FormatTime(sWeek, sizeof(sWeek), "%w");
    
    int curChap = L4D_GetCurrentChapter();
    int maxChap = L4D_GetMaxChapters();
    int progress = GetMaxSurvivorCompletion(); 
    
    int now = GetTime();
    int runTotal = now - g_iGameStartTime;
    int runRound = now - g_iRoundStartTime;
    if (runTotal < 0) runTotal = 0;
    if (runRound < 0) runRound = 0;

    int cCommon = 0, cSI = 0, cTank = 0, cWitch = 0;
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "witch")) != -1) cWitch++;
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "infected")) != -1) cCommon++;
    
    for(int i=1; i<=MaxClients; i++) {
        if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) {
            int zClass = GetEntProp(i, Prop_Send, "m_zombieClass");
            if(zClass == 8) cTank++;
            else cSI++;
        }
    }

    char sInfoTop[512];
    Format(sInfoTop, sizeof(sInfoTop), 
        "%s %s %s\n \n累计:特感[%d] 丧尸[%d] 路程:[%d%%]\n章节[%d/%d] 特感[%04d] 丧尸[%04d]", 
        sDate, sTime, g_sWeekDays[StringToInt(sWeek)],
        g_iTotalSiKills, g_iTotalCiKills, progress,
        curChap, maxChap, g_iChapterSiKills, g_iChapterCiKills
    );
    HUDSetLayout(SLOT_INFO_TOP, HUD_FLAG_ALIGN_RIGHT | HUD_FLAG_NOBG | HUD_FLAG_TEXT, sInfoTop);
    HUDPlace(SLOT_INFO_TOP, POS_RIGHT_X, POS_RIGHT_Y_TOP, 0.22, 0.20);

    char sInfoBot[512];
    Format(sInfoBot, sizeof(sInfoBot), 
        "存活:僵尸[%d] 特感[%d] 坦克[%d] witch[%d]\n \n累计运行:%d时%d分%d秒\n本次运行:%d时%d分%d秒",
        cCommon, cSI, cTank, cWitch,
        runTotal / 3600, (runTotal % 3600) / 60, runTotal % 60,
        runRound / 3600, (runRound % 3600) / 60, runRound % 60
    );
    HUDSetLayout(SLOT_INFO_BOT, HUD_FLAG_ALIGN_RIGHT | HUD_FLAG_NOBG | HUD_FLAG_TEXT, sInfoBot);
    HUDPlace(SLOT_INFO_BOT, POS_RIGHT_X, POS_RIGHT_Y_BOT, 0.22, 0.20);
}

void AddKillFeed(const char[] attacker, const char[] victim, const char[] type) {
    char str[128];
    Format(str, sizeof(str), "%s   %s   %s", attacker, type, victim);
    g_KillFeed.PushString(str);
    if(g_KillFeed.Length > 4) g_KillFeed.Erase(0); 
    DrawBottomRight();
}

void DrawBottomRight() {
    int slot = SLOT_KILLFEED_START; 
    float y = POS_FEED_Y_START;
    int count = g_KillFeed.Length;
    
    for(int i=0; i<count; i++) {
        if(slot + i > 14) break; 
        char buffer[128];
        g_KillFeed.GetString(i, buffer, sizeof(buffer));
        HUDSetLayout(slot+i, HUD_FLAG_ALIGN_RIGHT | HUD_FLAG_NOBG | HUD_FLAG_TEXT, buffer);
        HUDPlace(slot+i, POS_FEED_X, y, 0.20, LINE_HEIGHT_FEED);
        y += LINE_HEIGHT_FEED; 
    }
    for(int i=slot+count; i<=14; i++) RemoveHUD(i);
}

// ----------------------------------------------------------------------------------------------------
// 左侧面板绘制 (这里你可以调整间距)
// ----------------------------------------------------------------------------------------------------
void DrawLeftPanel() {
    // 这里的空格数量是按照 %4d 的宽度估算的，你可以手动增减空格来对齐
    char sHead[] = "状态   生命   特感   丧尸   被黑   友伤     玩家";
    HUDSetLayout(SLOT_HEADER, HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEXT, sHead);
    HUDPlace(SLOT_HEADER, POS_LEFT_X, POS_LEFT_Y_START - LINE_HEIGHT_LEFT, 0.60, LINE_HEIGHT_LEFT);

    int slot = SLOT_PLAYER_START;
    float y = POS_LEFT_Y_START;
    
    for(int i=1; i<=MaxClients; i++) {
        if(!IsClientInGame(i) || GetClientTeam(i) != 2) continue;
        
        // Bot 显示逻辑修复
        if(IsFakeClient(i)) {
            bool isIdlePlayer = HasEntProp(i, Prop_Send, "m_humanSpectatorUserID");
            if (!isIdlePlayer && !g_cvShowBots.BoolValue) {
                continue; 
            }
        }

        if(slot > 8) break;

        int real = GetRealClient(i);
        char sRawName[64];
        GetClientName(real, sRawName, sizeof(sRawName));
        char sName[64];
        
        if (real != i) {
            char sShortName[64];
            strcopy(sShortName, sizeof(sShortName), GetDealName(sRawName, 22));
            Format(sName, sizeof(sName), "%s(摸鱼)", sShortName);
        } else {
            strcopy(sName, sizeof(sName), GetDealName(sRawName, 22)); 
        }
        
        char sStatus[16];
        GetPlayerStatusStr(i, sStatus, sizeof(sStatus));
        int hp = GetSurvivorRealHP(i);
        
        char line[128];
        // =======================================================================
        // 排版调整区
        // %-6s : 状态 (左对齐，占6格)
        // %4d  : 数字 (右对齐，占4格)
        // 这里的空格决定了列与列的距离。如果你觉得挤，就在 %4d 之间多加几个空格。
        // =======================================================================
        Format(line, sizeof(line), "%-6s  %4d     %4d     %4d     %4d     %4d       %s",
            sStatus, 
            (hp > 999 ? 999 : hp), 
            g_Stats[real].SiKills, 
            g_Stats[real].CiKills, 
            g_Stats[real].FFReceived,
            g_Stats[real].FriendlyFire, 
            sName);
            
        HUDSetLayout(slot, HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEXT, line);
        HUDPlace(slot, POS_LEFT_X, y, 0.60, LINE_HEIGHT_LEFT);
        y += LINE_HEIGHT_LEFT;
        slot++;
    }
    for(int i=slot; i<=8; i++) RemoveHUD(i);
}

// ====================================================================================================
// 辅助函数
// ====================================================================================================

int GetMaxSurvivorCompletion() {
    float maxFlow = L4D2Direct_GetMapMaxFlowDistance();
    if(maxFlow <= 0.0) return 0;
    float highest = 0.0;
    for(int i=1; i<=MaxClients; i++) {
        if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
            float flow = L4D2Direct_GetFlowDistance(i);
            if(flow > highest && flow > 0.0) highest = flow;
        }
    }
    int percent = 0;
    if(maxFlow > 0.0) percent = RoundToNearest((highest / maxFlow) * 100.0);
    if (percent > 96) return 100;
    return (percent > 100) ? 100 : percent;
}

int GetRealClient(int client) {
    if (!IsFakeClient(client)) return client;
    if (HasEntProp(client, Prop_Send, "m_humanSpectatorUserID")) {
        int spectator = GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
        if (spectator > 0 && IsClientInGame(spectator)) return spectator;
    }
    return client;
}

void GetPlayerStatusStr(int client, char[] buffer, int len) {
    if (!IsPlayerAlive(client)) { strcopy(buffer, len, "挂了"); return; } 
    if (GetEntProp(client, Prop_Send, "m_isIncapacitated")) {
        if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge")) strcopy(buffer, len, "挂边");
        else strcopy(buffer, len, "倒下");
        return;
    }
    if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= g_cvRevives.IntValue) { strcopy(buffer, len, "黑白"); return; }
    if (GetSurvivorRealHP(client) < g_cvLimph.IntValue) { strcopy(buffer, len, "拐了"); return; }
    strcopy(buffer, len, "正常");
}

int GetSurvivorRealHP(int client) {
    if(!IsPlayerAlive(client)) return 0;
    int hp = GetClientHealth(client);
    static ConVar cvarDecay;
    if(cvarDecay == null) cvarDecay = FindConVar("pain_pills_decay_rate");
    float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    float time = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    float decay = GetGameTime() - time;
    int temp = RoundToCeil(buffer - (decay * cvarDecay.FloatValue)) - 1;
    return (hp + (temp < 0 ? 0 : temp));
}

void GetZombieClassName(int classId, char[] buffer, int maxlen) {
    switch(classId) {
        case 1: strcopy(buffer, maxlen, "Smoker");
        case 2: strcopy(buffer, maxlen, "Boomer");
        case 3: strcopy(buffer, maxlen, "Hunter");
        case 4: strcopy(buffer, maxlen, "Spitter");
        case 5: strcopy(buffer, maxlen, "Jockey");
        case 6: strcopy(buffer, maxlen, "Charger");
        case 8: strcopy(buffer, maxlen, "Tank");
        default: strcopy(buffer, maxlen, "Infected");
    }
}

bool IsValidSurvivor(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}
bool IsValidInfected(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

// ------------------------------------------------------------------------------------
// 之前报错缺少的函数就是这个，请确保它在文件末尾
// ------------------------------------------------------------------------------------
char[] GetSplitString(char[] src, int srcindex, int length) {
    char temp[10];
    for(int i = 0; i < length; i++) {
        temp[i] = src[i + srcindex];
        if(i + srcindex >= strlen(src)) break;
    }
    temp[length] = '\0';
    return temp;
}

char[] GetDealName(char[] buffer, int minlength) {
    char sName[64];
    Format(sName, sizeof(sName), "%s", IsSplitStrings(buffer, minlength));
    return sName;
}

char[] IsSplitStrings(char[] src, int maxsize) {
    ArrayList hData = new ArrayList(ByteCountToCells(32));
    int lengthsize;
    char sInfo[32];
    for(int i=0; i<strlen(src);) {
        if(0x00<=src[i] && src[i]<=0x7f) {
            sInfo[0] = '\0'; lengthsize += strcopy(sInfo, sizeof(sInfo), GetSplitString(src,i,1));
            if(lengthsize > maxsize) break; hData.PushString(sInfo); i+=1;
        } else if(0xC0<=src[i] && src[i]<=0xDf) {
            sInfo[0] = '\0'; lengthsize += strcopy(sInfo, sizeof(sInfo), GetSplitString(src,i,2));
            if(lengthsize > maxsize) break; hData.PushString(sInfo); i+=2;
        } else if(0xE0<=src[i] && src[i]<=0xEf) {
            sInfo[0] = '\0'; lengthsize += strcopy(sInfo, sizeof(sInfo), GetSplitString(src,i,3));
            if(lengthsize > maxsize) break; hData.PushString(sInfo); i+=3;
        } else if(0xF0<=src[i] && src[i]<=0xF7) {
            sInfo[0] = '\0'; lengthsize += strcopy(sInfo, sizeof(sInfo), GetSplitString(src,i,4));
            if(lengthsize > maxsize) break; hData.PushString(sInfo); i+=4;
        }
    }
    char sString[256];
    if(hData.Length > 0) {
        char[][] sTemp = new char[hData.Length][32];
        for(int i = 0; i < hData.Length; i++) hData.GetString(i, sTemp[i], 32);
        ImplodeStrings(sTemp, hData.Length, "", sString, sizeof(sString));
    } else { strcopy(sString, sizeof(sString), src); }
    delete hData;
    return sString;
}