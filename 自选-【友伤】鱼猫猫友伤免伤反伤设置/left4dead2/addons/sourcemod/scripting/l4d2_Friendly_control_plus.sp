#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <left4dhooks>
//#include <entity_prop_stocks>

#define PLUGIN_NAME		   "l4d2_Friendly_control_plus"
#define PLUGIN_VERSION	   "2.2.1"
#define PLUGIN_AUTHOR	   "JBcat & 77"
#define PLUGIN_DESCRIPTION "友伤控制"
#define IN_JUMP			   (1 << 1)
#define CVAR_FLAGS		   FCVAR_NOTIFY
#define PREFIX			   "[鱼猫猫]"
#define PLUGIN_PREFIX	   "Friendly_control"
#define PLUGIN_LINK		   "https://space.bilibili.com/13824819"
#define CUSTOM_CONFIG_FILE "configs/l4d2_Friendly_control_configs.cfg"
//  很神奇，用... PLUGIN_NAME...会导致持久化失效。。有吊大的知道原因偷偷告诉我一下（）
//#define CUSTOM_CONFIG_FILE "configs/" ... PLUGIN_NAME... "_configs.cfg"

bool
	g_bDebug,
	g_bImmuneFire,
	g_bImmuneSelf,
	g_bIsReflectingDamage,
	g_bFireEnable			  = false,
	g_bUseThresholdMode		  = false,
	g_bLeftSafeArea			  = false,
	g_bGetEnd				  = false,
	g_bCheckingStartSafeArea  = false,
	g_bGotEndSafeDoorPos	  = false,
	g_bBlockFFRoundStart	  = true,
	g_bBlockFFRoundStartPrint = true,
	g_bBlockFFInsideSafeRoom  = true,
	g_bBlockFFGetEnd		  = true,
	g_bBlockFFMeleeHurt		  = true,
	g_bBlockFFFireHurt		  = false,
	g_bBlockFFChargerCarry	  = true,
	g_bBlockFFRescuedPinned	  = true,
	g_bBlockFFHaveAliveTank	  = false,
	g_bVictimFFExempt[MAXPLAYERS + 1],
	g_bAttackerCanHurt[MAXPLAYERS + 1],
	g_bColdTimerSet[MAXPLAYERS + 1],
	g_bIsRespawning[MAXPLAYERS + 1],
	g_bWasReplaced[MAXPLAYERS + 1];

ConVar
	g_hCvarDebug,
	g_hCvarImmuneFire,
	g_hCvarImmuneSelf,
	g_hCvarExtraKey,
	g_hCvarThreshold1,
	g_hCvarThreshold2,
	g_hCvarReverse1,
	g_hCvarReverse2,
	g_hCvarScoutImmune,
	g_hCvarBlockFFRoundStart,
	g_hCvarBlockFFRoundStartPrint,
	g_hCvarBlockFFInsideSafeRoom,
	g_hCvarBlockFFGetEnd,
	g_hCvarBlockFFMeleeHurt,
	g_hCvarBlockFFFireHurt,
	g_hCvarBlockFFMinDistance,
	g_hCvarBlockFFMaxDistance,
	g_hCvarBlockFFInfectedNearRange,
	g_hCvarBlockFFChargerCarry,
	g_hCvarBlockFFRescuedPinned,
	g_hCvarBlockFFHaveAliveTank,
	g_hCvarBlockFFColdTime,
	g_hCvarBlockFFRoundMaxFF;

float
	g_fEndSafeDoorPos[3],
	g_fThreshold1				= 90.0,
	g_fThreshold2				= 180.0,
	g_fReverseRatio1			= 0.5,
	g_fReverseRatio2			= 1.0,
	g_fBlockFFMinDistance		= 128.0,
	g_fBlockFFMaxDistance		= 0.0,
	g_fBlockFFInfectedNearRange = 100.0,
	g_fBlockFFColdTime			= 0.0;

int
	g_iExtraKey,
	g_iReverseMode,
	g_iStartSafeArea	 = -1,
	g_iEndSafeArea		 = -1,
	g_iBlockFFRoundMaxFF = -1,
	g_iMyFF[MAXPLAYERS + 1],
	g_iFFStage[MAXPLAYERS + 1],
	g_iFFAccumulate[MAXPLAYERS + 1];

TopMenu
	g_hTopMenu;

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	version		= PLUGIN_VERSION,
	author		= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	url			= PLUGIN_LINK,
};

public void OnPluginStart()
{
	CreateConVar(PLUGIN_NAME, PLUGIN_VERSION, "插件版本", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);

	// 1. 调试开关
	g_hCvarDebug					= CreateConVar(PLUGIN_PREFIX... "_debug",					"1",		"是否开启调试输出 (0=关闭, 1=开启)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// 2. 自伤免疫（蹲伏时免疫自伤）
	g_hCvarImmuneSelf				= CreateConVar(PLUGIN_PREFIX... "_duck_self",				"1",		"是否在蹲伏时免疫自身对队友造成的伤害（0=禁用，1=启用）。", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// 3. 蹲伏免疫相关（燃烧免疫、额外按键）
	g_hCvarImmuneFire				= CreateConVar(PLUGIN_PREFIX... "_duck_fire",				"1",		"是否在蹲伏时免疫燃烧瓶伤害（0=禁用，1=启用）。", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarExtraKey					= CreateConVar(PLUGIN_PREFIX... "_key",						"131074",	"额外按键取消友伤（131072=Shift，参见entity_prop_stocks.inc吧）", FCVAR_NOTIFY);
	// 4. 未离开安全区
	g_hCvarBlockFFRoundStart		= CreateConVar(PLUGIN_PREFIX... "_round_start",				"1",		"启用未离开安全区前无友伤. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	g_hCvarBlockFFRoundStartPrint	= CreateConVar(PLUGIN_PREFIX... "_round_start_print",		"1",		"启用离开安全区时开启友伤文本提示. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	// 5. 安全区内
	g_hCvarBlockFFInsideSafeRoom	= CreateConVar(PLUGIN_PREFIX... "_inside_saferoom",			"1",		"启用安全区内无法造成和受到友伤. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	// 6. 已到达终点
	g_hCvarBlockFFGetEnd			= CreateConVar(PLUGIN_PREFIX... "_get_end",					"1",		"启用触碰终点安全门、到达终点安全区和救援到来时关闭友伤. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	// 7. 近战免除
	g_hCvarBlockFFMeleeHurt			= CreateConVar(PLUGIN_PREFIX... "_melee_hurt",				"1",		"启用免除近战友伤. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	// 8. 火伤免除
	g_hCvarBlockFFFireHurt			= CreateConVar(PLUGIN_PREFIX... "_fire_hurt",				"0",		"启用免除火伤友伤. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	// 9. 距离过近/过远
	g_hCvarBlockFFMinDistance		= CreateConVar(PLUGIN_PREFIX... "_min_distance",			"128.0",	"免除多近距离的友伤? (0.0 = 不启用)", _, true, 0.0);
	g_hCvarBlockFFMaxDistance		= CreateConVar(PLUGIN_PREFIX... "_max_distance",			"0.0",		"免除多远距离的友伤? (0.0 = 不启用)", _, true, 0.0);
	// 10. 附近有特感
	g_hCvarBlockFFInfectedNearRange	= CreateConVar(PLUGIN_PREFIX... "_infected_near_range",		"128.0",	"身边多近距离以内有存活特感免除友伤? (0.0 = 不启用)", _, true, 0.0);
	// 11. Charger携带
	g_hCvarBlockFFChargerCarry		= CreateConVar(PLUGIN_PREFIX... "_charger_carry",			"1",		"启用对Charger携带幸存者无友伤. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	// 12. 刚解救免疫
	g_hCvarBlockFFRescuedPinned		= CreateConVar(PLUGIN_PREFIX... "_rescued_pinned",			"1",		"启用对解控(smoker, jockey, charger)后幸存者短暂无友伤. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	// 13. 有存活Tank
	g_hCvarBlockFFHaveAliveTank		= CreateConVar(PLUGIN_PREFIX... "_have_alive_tank",			"0",		"启用有Tank存活时无友伤. (0 = 禁用, 1 = 启用)", _, true, 0.0, true, 1.0);
	// 14. 攻击者冷却期
	g_hCvarBlockFFColdTime			= CreateConVar(PLUGIN_PREFIX... "_cold_time",				"0.0",		"多少秒内第一次造成的友伤将被免除? (0.0 = 不启用)", _, true, 0.0);
	// 15. 回合友伤上限
	g_hCvarBlockFFRoundMaxFF		= CreateConVar(PLUGIN_PREFIX... "_round_max_ff",			"-1",		"设置回合友伤上限值. (-1 = 不启用)", _, true, -1.0);
	// 16. 鸟狙免疫
	g_hCvarScoutImmune				= CreateConVar(PLUGIN_PREFIX... "_scout_immune",			"0",		"鸟狙免疫友伤反伤开关 (0=不免疫, 1=免疫)", CVAR_FLAGS, true, 0.0, true, 1.0);
	// 17. 阈值反伤相关
	g_hCvarThreshold1				= CreateConVar(PLUGIN_PREFIX... "_threshold1",				"90",		"反伤一阶段阈值", CVAR_FLAGS, true, 1.0);
	g_hCvarThreshold2				= CreateConVar(PLUGIN_PREFIX... "_threshold2",				"180",		"反伤二阶段阈值", CVAR_FLAGS, true, 2.0);
	g_hCvarReverse1					= CreateConVar(PLUGIN_PREFIX... "_reverse1",				"0.5",		"一阶段反伤比例", CVAR_FLAGS, true, 0.0, true, 5.00);
	g_hCvarReverse2					= CreateConVar(PLUGIN_PREFIX... "_reverse2",				"1.0",		"二阶段反伤比例", CVAR_FLAGS, true, 0.0, true, 10.00);

	g_hCvarDebug.AddChangeHook(OnDebugCvarChanged);
	g_hCvarImmuneSelf.AddChangeHook(OnImmuneCvarChanged);
	g_hCvarImmuneFire.AddChangeHook(OnImmuneCvarChanged);
	g_hCvarExtraKey.AddChangeHook(OnExtraKeyChanged);
	g_hCvarBlockFFRoundStart.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFRoundStartPrint.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFInsideSafeRoom.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFGetEnd.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFMeleeHurt.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFFireHurt.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFMinDistance.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFMaxDistance.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFInfectedNearRange.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFChargerCarry.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFRescuedPinned.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFHaveAliveTank.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFColdTime.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarBlockFFRoundMaxFF.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarScoutImmune.AddChangeHook(ConVarChanged_BlockFF);
	g_hCvarThreshold1.AddChangeHook(OnControlCvarChanged);
	g_hCvarThreshold2.AddChangeHook(OnControlCvarChanged);
	g_hCvarReverse1.AddChangeHook(OnControlCvarChanged);
	g_hCvarReverse2.AddChangeHook(OnControlCvarChanged);

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_entered_checkpoint", Event_PlayerEnteredCheckpoint);
	HookEvent("player_left_checkpoint", Event_PlayerLeftCheckpoint);
	HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea, EventHookMode_PostNoCopy);
	HookEvent("finale_escape_start", Event_OnFinaleStart, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_incoming", Event_OnFinaleStart, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_ready", Event_OnFinaleStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("tongue_release", Event_RescuedFromInfected);
	HookEvent("jockey_ride_end", Event_RescuedFromInfected);
	HookEvent("charger_carry_end", Event_RescuedFromInfected);
	HookEvent("door_open", Event_Door_OC);
	HookEvent("door_close", Event_Door_OC);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);

	RegAdminCmd("sm_fs", Cmd_FSControl, ADMFLAG_GENERIC, "反伤控制菜单");
	RegAdminCmd("sm_fsmode", Cmd_FSMode, ADMFLAG_GENERIC, "设置反伤模式");

	ApplyImmuneCvars();
	ApplyControlCvars();
	ApplyBlockFFCvars();

	AutoExecConfig(true, PLUGIN_NAME);

	if (LibraryExists("adminmenu"))
	{
		TopMenu topmenu = GetAdminTopMenu();
		if (topmenu != null)
			OnAdminMenuReady(topmenu);
	}

	RequestFrame(OnFrameForConfig);
}

void ApplyImmuneCvars()
{
	g_bImmuneFire = g_hCvarImmuneFire.BoolValue;
	g_bImmuneSelf = g_hCvarImmuneSelf.BoolValue;
	g_iExtraKey	  = g_hCvarExtraKey.IntValue;
}

void ApplyControlCvars()
{
	g_fThreshold1	 = (g_hCvarThreshold1.IntValue < 1) ? 1.0 : float(g_hCvarThreshold1.IntValue);
	g_fThreshold2	 = (g_hCvarThreshold2.IntValue < g_fThreshold1) ? g_fThreshold1 + 1.0 : float(g_hCvarThreshold2.IntValue);
	g_fReverseRatio1 = (g_hCvarReverse1.FloatValue < 0.01) ? 0.01 : g_hCvarReverse1.FloatValue;
	g_fReverseRatio2 = (g_hCvarReverse2.FloatValue < g_fReverseRatio1) ? g_fReverseRatio1 : g_hCvarReverse2.FloatValue;
}

void ApplyBlockFFCvars()
{
	g_bDebug					= g_hCvarDebug.BoolValue;
	g_bBlockFFRoundStart		= g_hCvarBlockFFRoundStart.BoolValue;
	g_bBlockFFRoundStartPrint	= g_hCvarBlockFFRoundStartPrint.BoolValue;
	g_bBlockFFInsideSafeRoom	= g_hCvarBlockFFInsideSafeRoom.BoolValue;
	g_bBlockFFGetEnd			= g_hCvarBlockFFGetEnd.BoolValue;
	g_bBlockFFMeleeHurt			= g_hCvarBlockFFMeleeHurt.BoolValue;
	g_bBlockFFFireHurt			= g_hCvarBlockFFFireHurt.BoolValue;
	g_fBlockFFMinDistance		= g_hCvarBlockFFMinDistance.FloatValue;
	g_fBlockFFMaxDistance		= g_hCvarBlockFFMaxDistance.FloatValue;
	g_fBlockFFInfectedNearRange = g_hCvarBlockFFInfectedNearRange.FloatValue;
	g_bBlockFFChargerCarry		= g_hCvarBlockFFChargerCarry.BoolValue;
	g_bBlockFFRescuedPinned		= g_hCvarBlockFFRescuedPinned.BoolValue;
	g_bBlockFFHaveAliveTank		= g_hCvarBlockFFHaveAliveTank.BoolValue;
	g_fBlockFFColdTime			= g_hCvarBlockFFColdTime.FloatValue;
	g_iBlockFFRoundMaxFF		= g_hCvarBlockFFRoundMaxFF.IntValue;
}

public void OnImmuneCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ApplyImmuneCvars();
}

public void OnExtraKeyChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iExtraKey = convar.IntValue;
}

public void OnControlCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ApplyControlCvars();
}

public void ConVarChanged_BlockFF(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ApplyBlockFFCvars();
}

public void OnDebugCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDebug = convar.BoolValue;
	if (g_bDebug)
		PrintToChatAll("[DEBUG] 调试输出已开启");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageMerged);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAliveMerged);
}

public void OnMapStart()
{
	g_iStartSafeArea	 = -1;
	g_iEndSafeArea		 = -1;
	g_bGotEndSafeDoorPos = false;
	g_fEndSafeDoorPos	 = NULL_VECTOR;
	if (g_bDebug) PrintToChatAll("[DEBUG] OnMapStart 触发");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MaxClients; i++)
	{
		g_iFFStage[i]	   = 0;
		g_iFFAccumulate[i] = 0;
	}

	g_bLeftSafeArea			 = false;
	g_bGetEnd				 = false;
	g_bCheckingStartSafeArea = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iMyFF[i]			  = 0;
		g_bVictimFFExempt[i]  = false;
		g_bAttackerCanHurt[i] = false;
		g_bColdTimerSet[i]	  = false;
	}
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_RoundStart 触发");
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim	   = GetClientOfUserId(event.GetInt("userid"));
	int attacker   = GetClientOfUserId(event.GetInt("attacker"));
	int damage	   = event.GetInt("dmg_health");
	int damagetype = event.GetInt("type");

	if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
		return;

	if (g_iBlockFFRoundMaxFF >= 0 && IsSurvivor(attacker) && IsSurvivor(victim) && attacker != victim)
	{
		if (g_iMyFF[attacker] < g_iBlockFFRoundMaxFF)
		{
			g_iMyFF[attacker] += damage;
			if (g_iMyFF[attacker] >= g_iBlockFFRoundMaxFF)
				PrintToChatAll("\x04%s \x03%N \x05的友伤已达到上限.[ \x03%d \x05]", PREFIX, attacker, g_iMyFF[attacker]);
		}
	}

	if ((damagetype & DMG_BURN) && !g_bFireEnable) return;
	if (!IsSurvivor(victim) || !IsSurvivor(attacker) || victim == attacker) return;
	if (damage <= 0) return;

	if (g_bUseThresholdMode)
	{
		g_iFFAccumulate[attacker] += damage;
		if (g_iFFAccumulate[attacker] >= g_fThreshold1 && g_iFFStage[attacker] < 1)
		{
			g_iFFStage[attacker] = 1;
			CreateTimer(0.3, PT0, attacker);
		}
		if (g_iFFAccumulate[attacker] >= g_fThreshold2 && g_iFFStage[attacker] < 2)
		{
			g_iFFStage[attacker] = 2;
			CreateTimer(0.3, PT1, attacker);
		}
	}
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_PlayerHurt: 攻击者%N 受害者%N 伤害%d 类型%d", attacker, victim, damage, damagetype);
}

public void Event_PlayerEnteredCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bLeftSafeArea || g_bGetEnd || g_iStartSafeArea <= 0) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || g_bIsRespawning[client] || !g_bWasReplaced[client]) return;

	int area = GetEventInt(event, "area");
	if (area == g_iStartSafeArea) return;
	if (g_iEndSafeArea > 0 && area != g_iEndSafeArea) return;
	if (!g_bBlockFFGetEnd) return;

	g_bGetEnd = true;
	PrintToChatAll("\x04%s \x03%N \x05到达终点安全区, 友伤已自动关闭.", PREFIX, client);
	if (g_iEndSafeArea <= 0)
		g_iEndSafeArea = area;
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_PlayerEnteredCheckpoint: %N 到达终点安全区", client);
}

public void Event_PlayerLeftCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bLeftSafeArea || g_iStartSafeArea > 0) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || g_bIsRespawning[client]) return;
	if (g_bCheckingStartSafeArea) return;

	int area				 = GetEventInt(event, "area");
	g_bCheckingStartSafeArea = true;
	CreateTimer(0.5, Timer_ToCheckIsStartSafeArea, area, TIMER_FLAG_NO_MAPCHANGE);
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_PlayerLeftCheckpoint: %N 离开 checkpoint area=%d", client, area);
}

public void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bLeftSafeArea) return;
	GetEndSafeDoorPos();
	if (g_bBlockFFRoundStart && g_bBlockFFRoundStartPrint)
		PrintToChatAll("\x04%s \x05友伤已自动开启.", PREFIX);
	g_bLeftSafeArea = true;
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_PlayerLeftSafeArea 触发");
}

public void Event_OnFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if (L4D_GetCurrentChapter() < L4D_GetMaxChapters() || !g_bBlockFFGetEnd || g_bGetEnd) return;
	g_bGetEnd = true;
	PrintToChatAll("\x04%s \x05救援来临, 友伤已自动关闭.", PREFIX);
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_OnFinaleStart 触发，救援来临");
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bGotEndSafeDoorPos)
		GetEndSafeDoorPos();

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(client)) return;

	g_bIsRespawning[client] = true;
	CreateTimer(1.0, Timer_Recold_IsSpawning, client);
	g_bVictimFFExempt[client]  = false;
	g_bAttackerCanHurt[client] = false;
	g_bColdTimerSet[client]	   = false;
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_PlayerSpawn: %N 重生", client);
}

public void Event_RescuedFromInfected(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bBlockFFRescuedPinned) return;
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || g_bVictimFFExempt[client]) return;
	g_bVictimFFExempt[client] = true;
	CreateTimer(1.0, Timer_ReCold_IsAllowBlockFF, client);
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_RescuedFromInfected: %N 被解救，免疫友伤1秒", client);
}

public void Event_Door_OC(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bBlockFFGetEnd) return;
	if (!g_bGotEndSafeDoorPos || g_bGetEnd || !event.GetBool("checkpoint")) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || g_bIsRespawning[client]) return;

	float pos[3];
	GetClientAbsOrigin(client, pos);
	if (GetVectorDistance(pos, g_fEndSafeDoorPos) > 200.0) return;

	g_bGetEnd = true;
	PrintToChatAll("\x04%s \x03%N \x05触碰终点安全门, 友伤已自动关闭.", PREFIX, client);
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_Door_OC: %N 触碰终点门", client);
}

public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (!IsSurvivor(bot) || !IsPlayerAlive(bot)) return;

	int player = GetClientOfUserId(event.GetInt("player"));
	if (player <= 0 || player > MaxClients || !IsClientInGame(player)) return;

	if (g_bIsRespawning[bot])
	{
		g_bIsRespawning[player] = true;
		CreateTimer(1.0, Timer_Recold_IsSpawning, player);
	}
	g_bWasReplaced[player] = true;
	CreateTimer(1.0, Timer_Recold_IsBeReplaced, player);
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_PlayerBotReplace: bot %N 替换玩家 %N", bot, player);
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	if (!IsSurvivor(player) || !IsPlayerAlive(player)) return;

	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (bot <= 0 || bot > MaxClients || !IsClientInGame(bot)) return;

	if (g_bIsRespawning[player])
	{
		g_bIsRespawning[bot] = true;
		CreateTimer(1.0, Timer_Recold_IsSpawning, bot);
	}
	g_bWasReplaced[bot] = true;
	CreateTimer(1.0, Timer_Recold_IsBeReplaced, bot);
	if (g_bDebug) PrintToChatAll("[DEBUG] Event_BotPlayerReplace: 玩家 %N 替换 bot %N", player, bot);
}

public Action PT0(Handle timer, int client)
{
	if (!IsClientInGame(client)) return Plugin_Continue;
	PrintToChatAll("\x04%s \x03%N \x05累计友伤达到 \x03%.1f \x05阈值，启用 \x03%.1f%% \x05反伤喵！", PREFIX, client, g_fThreshold1, g_fReverseRatio1 * 100.0);
	return Plugin_Continue;
}

public Action PT1(Handle timer, int client)
{
	if (!IsClientInGame(client)) return Plugin_Continue;
	PrintToChatAll("\x04%s \x03%N \x05累计友伤达到 \x03%.1f \x05阈值，启用 \x03%.1f%% \x05反伤喵！", PREFIX, client, g_fThreshold2, g_fReverseRatio2 * 100.0);
	return Plugin_Continue;
}

public Action Timer_Recold_IsSpawning(Handle timer, int client)
{
	g_bIsRespawning[client] = false;
	return Plugin_Stop;
}

public Action Timer_Recold_IsBeReplaced(Handle timer, int client)
{
	g_bWasReplaced[client] = false;
	return Plugin_Stop;
}

public Action Timer_ToCheckIsStartSafeArea(Handle timer, int area)
{
	if (g_bLeftSafeArea) g_iStartSafeArea = area;
	g_bCheckingStartSafeArea = false;
	if (g_bDebug) PrintToChatAll("[DEBUG] Timer_ToCheckIsStartSafeArea: 起始安全区 area=%d", area);
	return Plugin_Stop;
}

public Action Timer_ChangeCanHurt(Handle timer, int client)
{
	g_bAttackerCanHurt[client] = true;
	if (g_bDebug) PrintToChatAll("[DEBUG] Timer_ChangeCanHurt: %N 现在可以造成友伤", client);
	return Plugin_Stop;
}

public Action Timer_Recold_CanHurt(Handle timer, int client)
{
	g_bAttackerCanHurt[client] = false;
	g_bColdTimerSet[client]	   = false;
	if (g_bDebug) PrintToChatAll("[DEBUG] Timer_Recold_CanHurt: %N 冷却结束", client);
	return Plugin_Stop;
}

public Action Timer_ReCold_IsAllowBlockFF(Handle timer, int client)
{
	g_bVictimFFExempt[client] = false;
	if (g_bDebug) PrintToChatAll("[DEBUG] Timer_ReCold_IsAllowBlockFF: %N 免疫结束", client);
	return Plugin_Stop;
}

public Action OnTakeDamageMerged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_bDebug) PrintToChatAll("[DEBUG] OnTakeDamageMerged 进入: victim=%N(%d), attacker=%N(%d), damage=%.1f, type=%d", victim, victim, attacker, attacker, damage, damagetype);

	// 1. 反射伤害检测
	if (g_bIsReflectingDamage)
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 正在反射伤害，跳过");
		return Plugin_Continue;
	}

	// 2. 无效目标/攻击者
	if (victim < 1 || victim > MaxClients)
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] victim 无效，跳过");
		return Plugin_Continue;
	}
	if (attacker < 0 || attacker > MaxClients)
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] attacker 无效，跳过");
		return Plugin_Continue;
	}
	if (!IsSurvivor(victim) || !IsSurvivor(attacker))
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 非幸存者间伤害，跳过");
		return Plugin_Continue;
	}

	// 3. 自伤处理：仅当开启自伤免疫且蹲伏时免疫
	if (victim == attacker)
	{
		if (g_bImmuneSelf)
		{
			Action result = CheckCrouchImmunity(victim, attacker, damagetype);
			if (result == Plugin_Handled)
			{
				if (g_bDebug) PrintToChatAll("[DEBUG] 蹲伏自伤免疫触发: victim==attacker=%N", victim);
				return Plugin_Handled;
			}
		}
		// 自伤免疫关闭或未蹲伏，继续后续判断
		if (g_bDebug) PrintToChatAll("[DEBUG] 自伤未免疫，继续后续判断");
	}

	// 4. 未离开安全区
	if (g_bBlockFFRoundStart && !g_bLeftSafeArea)
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 未离开安全区，阻止友伤");
		return Plugin_Handled;
	}

	// 5. 安全区内
	if (g_bBlockFFInsideSafeRoom && (L4D_IsInFirstCheckpoint(attacker) || L4D_IsInLastCheckpoint(attacker) || L4D_IsInFirstCheckpoint(victim) || L4D_IsInLastCheckpoint(victim)))
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 在安全区内，阻止友伤");
		return Plugin_Handled;
	}

	// 6. 已到达终点
	if (g_bBlockFFGetEnd && g_bGetEnd)
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 已到达终点，阻止友伤");
		return Plugin_Handled;
	}

	// 7. 近战免除
	if (g_bBlockFFMeleeHurt && IsMelee(inflictor))
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 免除近战友伤");
		return Plugin_Handled;
	}

	// 8. 火伤免除
	if (g_bBlockFFFireHurt && (damagetype & DMG_BURN))
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 免除火伤 (g_bBlockFFFireHurt=true)");
		return Plugin_Handled;
	}

	// 9. 蹲伏免疫（针对非自伤，自伤已在上一步处理过蹲伏免疫）
	if (victim != attacker)
	{
		Action result = CheckCrouchImmunity(victim, attacker, damagetype);
		if (result == Plugin_Handled)
		{
			if (g_bDebug) PrintToChatAll("[DEBUG] 蹲伏免疫触发");
			return Plugin_Handled;
		}
	}

	// 10. 距离过近/过远（仅适用于不同玩家，自伤不参与距离判断）
	if (victim != attacker)
	{
		float dist = GetVectorDistance(GetClientOrigin(attacker), GetClientOrigin(victim));
		if (g_fBlockFFMinDistance > 0.0 && dist <= g_fBlockFFMinDistance)
		{
			if (g_bDebug) PrintToChatAll("[DEBUG] 距离过近 (%.1f <= %.1f)，免除友伤", dist, g_fBlockFFMinDistance);
			return Plugin_Handled;
		}
		if (g_fBlockFFMaxDistance > 0.0 && dist >= g_fBlockFFMaxDistance)
		{
			if (g_bDebug) PrintToChatAll("[DEBUG] 距离过远 (%.1f >= %.1f)，免除友伤", dist, g_fBlockFFMaxDistance);
			return Plugin_Handled;
		}
	}

	// 11. 附近有特感
	if (g_fBlockFFInfectedNearRange > 0.0 && IsHaveInfectedCloseRange(victim))
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 附近有特感，免除友伤");
		return Plugin_Handled;
	}

	// 12. Charger携带
	if (g_bBlockFFChargerCarry && GetEntPropEnt(victim, Prop_Send, "m_carryAttacker") > 0)
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 受害者正被Charger携带，免除友伤");
		return Plugin_Handled;
	}

	// 13. 刚解救免疫
	if (g_bBlockFFRescuedPinned && g_bVictimFFExempt[victim])
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 受害者刚被解救，免疫友伤");
		return Plugin_Handled;
	}

	// 14. 有存活Tank
	if (g_bBlockFFHaveAliveTank && IsHaveAliveTank())
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 有存活Tank，阻止友伤");
		return Plugin_Handled;
	}

	// 15. 攻击者冷却期
	if (g_fBlockFFColdTime > 0.0 && !g_bAttackerCanHurt[attacker])
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 攻击者处于冷却期，免除友伤");
		if (!g_bColdTimerSet[attacker])
		{
			CreateTimer(0.1, Timer_ChangeCanHurt, attacker);
			CreateTimer(g_fBlockFFColdTime, Timer_Recold_CanHurt, attacker);
			g_bColdTimerSet[attacker] = true;
		}
		return Plugin_Handled;
	}

	// 16. 回合友伤上限
	if (g_iBlockFFRoundMaxFF >= 0)
	{
		if (g_iMyFF[attacker] >= g_iBlockFFRoundMaxFF)
		{
			if (g_bDebug) PrintToChatAll("[DEBUG] 攻击者友伤已达上限，阻止");
			return Plugin_Handled;
		}
		if (g_iMyFF[attacker] + RoundToFloor(damage) > g_iBlockFFRoundMaxFF)
		{
			float oldDamage = damage;
			damage			= float(g_iBlockFFRoundMaxFF - g_iMyFF[attacker]);
			if (g_bDebug) PrintToChatAll("[DEBUG] 限制友伤: 原伤害 %.1f 调整为 %.1f", oldDamage, damage);
		}
	}

	// 17. 鸟狙免疫（完全免疫友伤，不造成伤害也不触发反伤）
	if (g_hCvarScoutImmune.BoolValue && weapon > 0 && IsWeaponScout(weapon))
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 鸟狙免疫友伤，阻止伤害");
		return Plugin_Handled;
	}

	// 18. 阈值反伤模式
	if (g_bUseThresholdMode)
	{
		if (g_iFFStage[attacker] == 0)
		{
			if (g_bDebug) PrintToChatAll("[DEBUG] 阈值模式 stage=0，不反伤，允许伤害");
			return Plugin_Continue;
		}

		float reduceRatio	  = (g_iFFStage[attacker] == 1) ? g_fReverseRatio1 : g_fReverseRatio2;
		float reflectedDamage = damage * reduceRatio;
		damage *= (1.0 - reduceRatio);

		if (g_bDebug) PrintToChatAll("[DEBUG] 阈值反伤: 攻击者%N受到 %.1f 反伤，队友最终伤害 %.1f", attacker, reflectedDamage, damage);

		g_bIsReflectingDamage = true;
		SDKHooks_TakeDamage(attacker, 0, attacker, reflectedDamage, DMG_GENERIC);
		g_bIsReflectingDamage = false;

		if (g_bDebug && reflectedDamage > 0.0)
			PrintToChat(attacker, "[DEBUG] 受到 %.0f 点反伤", reflectedDamage);

		return Plugin_Changed;
	}

	// 19. 燃烧反伤开关
	if ((damagetype & DMG_BURN) && !g_bFireEnable)
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 燃烧反伤未开启，但允许伤害继续 (后续无反伤)");
		return Plugin_Continue;
	}

	// 20. 固定倍数反伤模式
	if (g_iReverseMode > 0)
	{
		float reflectedDamage = damage * g_iReverseMode;

		if (g_bDebug) PrintToChatAll("[DEBUG] 固定倍数反伤: 攻击者%N受到 %.1f 反伤，队友原伤害 %.1f", attacker, reflectedDamage, damage);

		g_bIsReflectingDamage = true;
		SDKHooks_TakeDamage(attacker, 0, attacker, reflectedDamage, DMG_GENERIC);
		g_bIsReflectingDamage = false;

		if (g_bDebug && reflectedDamage > 0.0)
			PrintToChat(attacker, "[DEBUG] 受到 %.0f 点反伤", reflectedDamage);

		return Plugin_Handled;
	}

	if (g_bDebug) PrintToChatAll("[DEBUG] 未进入任何反伤模式，允许伤害");
	return Plugin_Continue;
}

public Action OnTakeDamageAliveMerged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_bDebug) PrintToChatAll("[DEBUG] OnTakeDamageAliveMerged: victim=%N, attacker=%N, damage=%.1f, type=%d", victim, attacker, damage, damagetype);

	if (g_bIsReflectingDamage)
		return Plugin_Continue;

	if (!IsSurvivor(victim) || !IsSurvivor(attacker))
		return Plugin_Continue;

	if (g_bBlockFFFireHurt && (damagetype & DMG_BURN))
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] 免除火伤");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
Action CheckCrouchImmunity(int victim, int attacker, int damagetype)
{
	if ((damagetype & DMG_BURN) && g_bImmuneFire)
	{
		if ((GetClientButtons(victim) & (IN_DUCK | g_iExtraKey | IN_JUMP)) || (GetClientButtons(attacker) & (IN_DUCK | g_iExtraKey | IN_JUMP)))
		{
			if (g_bDebug) PrintToChatAll("[DEBUG] CheckCrouchImmunity: 燃烧免疫触发");
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}

	if ((GetClientButtons(victim) & (IN_DUCK | g_iExtraKey | IN_JUMP)) || (GetClientButtons(attacker) & (IN_DUCK | g_iExtraKey | IN_JUMP)))
	{
		if (g_bDebug) PrintToChatAll("[DEBUG] CheckCrouchImmunity: 蹲伏免疫触发");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool IsWeaponScout(int weapon)
{
	if (weapon <= 0) return false;
	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	return StrEqual(classname, "weapon_sniper_scout", false);
}

bool IsMelee(int inflictor)
{
	if (inflictor > MaxClients)
	{
		char classname[13];
		GetEdictClassname(inflictor, classname, sizeof(classname));
		return strcmp(classname, "weapon_melee") == 0;
	}
	return false;
}

bool IsHaveAliveTank()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}

bool IsHaveInfectedCloseRange(int client)
{
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	float infectedPos[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, infectedPos);
			if (GetVectorDistance(clientPos, infectedPos) <= g_fBlockFFInfectedNearRange)
				return true;
		}
	}
	return false;
}

void GetEndSafeDoorPos()
{
	int entity = FindEntityByClassname(MaxClients + 1, "info_changelevel");
	if (entity == -1)
		entity = FindEntityByClassname(MaxClients + 1, "trigger_changelevel");
	if (entity == -1) return;

	int door = L4D_GetCheckpointLast();
	if (door == -1 || !IsValidEdict(door)) return;

	g_bGotEndSafeDoorPos = true;
	GetEntPropVector(door, Prop_Data, "m_vecAbsOrigin", g_fEndSafeDoorPos);
	if (g_bDebug) PrintToChatAll("[DEBUG] GetEndSafeDoorPos: 终点门位置已获取");
}

float[] GetClientOrigin(int client)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	return pos;
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	if (topmenu == g_hTopMenu) return;
	g_hTopMenu			   = topmenu;

	TopMenuObject category = FindTopMenuCategory(g_hTopMenu, "OtherFeatures");
	if (category == INVALID_TOPMENUOBJECT)
		category = AddToTopMenu(g_hTopMenu, "OtherFeatures", TopMenuObject_Category, MenuHandler_Category, INVALID_TOPMENUOBJECT);

	AddToTopMenu(g_hTopMenu, "sm_fscontrol", TopMenuObject_Item, MenuHandler_FSControl, category, "sm_fscontrol", ADMFLAG_GENERIC);
}

public void MenuHandler_Category(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "★选择功能:");
	else if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "★其它功能");
}

public void MenuHandler_FSControl(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "★友伤反伤");
	else if (action == TopMenuAction_SelectOption)
		ShowFSControlMenu(param);
}

public Action Cmd_FSControl(int client, int args)
{
	ShowFSControlMenu(client);
	return Plugin_Handled;
}

void GetModeName(int mode, char[] buffer, int maxlen)
{
	switch (mode)
	{
		case 0: strcopy(buffer, maxlen, "关闭反伤");
		case 1: strcopy(buffer, maxlen, "普通模式");
		case 2: strcopy(buffer, maxlen, "双倍反伤");
		case 3: strcopy(buffer, maxlen, "三倍反伤");
		case 5: strcopy(buffer, maxlen, "五倍反伤");
		default: strcopy(buffer, maxlen, "未知");
	}
}

void ShowFSControlMenu(int client)
{
	char modeName[32];
	GetModeName(g_iReverseMode, modeName, sizeof(modeName));

	Menu menu = new Menu(MenuHandler_FSMode);
	menu.SetTitle("当前: 『%s』\n燃烧反伤: 『%s』", g_bUseThresholdMode ? "阈值反伤" : modeName, g_bFireEnable ? "开启" : "关闭");

	char display[64];

	// 关闭反伤
	Format(display, sizeof(display), "关闭反伤 %s", (g_bUseThresholdMode || g_iReverseMode != 0) ? "「☆」" : "「★」");
	menu.AddItem("0", display);

	// 阈值反伤
	Format(display, sizeof(display), "阈值反伤 %s", g_bUseThresholdMode ? "「★」" : "「☆」");
	menu.AddItem("t", display);

	// 普通模式
	Format(display, sizeof(display), "普通模式 %s", (!g_bUseThresholdMode && g_iReverseMode == 1) ? "「★」" : "「☆」");
	menu.AddItem("1", display);

	// 双倍反伤
	Format(display, sizeof(display), "双倍反伤 %s", (!g_bUseThresholdMode && g_iReverseMode == 2) ? "「★」" : "「☆」");
	menu.AddItem("2", display);

	// 三倍反伤
	Format(display, sizeof(display), "三倍反伤 %s", (!g_bUseThresholdMode && g_iReverseMode == 3) ? "「★」" : "「☆」");
	menu.AddItem("3", display);

	// 五倍反伤
	Format(display, sizeof(display), "五倍反伤 %s", (!g_bUseThresholdMode && g_iReverseMode == 5) ? "「★」" : "「☆」");
	menu.AddItem("5", display);

	// 燃烧反伤
	Format(display, sizeof(display), "燃烧反伤 %s", g_bFireEnable ? "「★」" : "「☆」");
	menu.AddItem("f", display);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_FSMode(Menu menu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(item, info, sizeof(info));

			if (StrEqual(info, "t"))
			{
				g_bUseThresholdMode = !g_bUseThresholdMode;
				g_iReverseMode		= 0;
				PrintToChatAll("\x04%s \x05已切换至 \x03%s \x05喵", PREFIX, g_bUseThresholdMode ? "阈值反伤" : "手动控制");
				SaveCustomConfig();
				if (g_bDebug) PrintToChatAll("[DEBUG] 菜单切换阈值模式: %s", g_bUseThresholdMode ? "开启" : "关闭");
			}
			else if (StrEqual(info, "f"))
			{
				if (!g_bUseThresholdMode && g_iReverseMode == 0)
				{
					PrintToChat(client, "\x04%s \x05关闭模式下无法开启燃烧反伤！", PREFIX);
					ShowFSControlMenu(client);
					return 0;
				}
				g_bFireEnable = !g_bFireEnable;
				PrintToChatAll("\x04%s \x05火伤反伤已 \x03%s", PREFIX, g_bFireEnable ? "开启" : "关闭");
				SaveCustomConfig();
				if (g_bDebug) PrintToChatAll("[DEBUG] 菜单切换火伤反伤: %s", g_bFireEnable ? "开启" : "关闭");
			}
			else
			{
				g_iReverseMode		= StringToInt(info);
				g_bUseThresholdMode = false;

				if (g_iReverseMode == 0)
				{
					g_bFireEnable = false;
					PrintToChatAll("\x04%s \x05反伤模式已设置为 \x03关闭反伤 \x05关闭 \x03燃烧反伤 \x05喵", PREFIX);
				}
				else
				{
					char modeName[32];
					GetModeName(g_iReverseMode, modeName, sizeof(modeName));
					PrintToChatAll("\x04%s \x05反伤模式已设置为 \x03%s \x05喵", PREFIX, modeName);
				}
				SaveCustomConfig();
				if (g_bDebug) PrintToChatAll("[DEBUG] 菜单设置反伤模式: %d", g_iReverseMode);
			}
			ShowFSControlMenu(client);
		}
		case MenuAction_Cancel:
		{
			if (item == MenuCancel_ExitBack && g_hTopMenu != null)
			{
				g_hTopMenu.Display(client, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public Action Cmd_FSMode(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "用法: sm_fsmode <0-3>");
		return Plugin_Handled;
	}

	char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	int mode = StringToInt(arg);

	if (mode < 0 || mode > 3)
	{
		ReplyToCommand(client, "无效模式 (0-关闭 1-普通 2-双倍 3-三倍)");
		return Plugin_Handled;
	}

	g_iReverseMode		= mode;
	g_bUseThresholdMode = false;

	if (mode == 0)
	{
		g_bFireEnable = false;
		PrintToChatAll("\x04%s \x05反伤模式已设置为: \x03关闭反伤 \x05关闭 \x03燃烧反伤 \x05喵", PREFIX);
	}
	else
	{
		char modeName[32];
		GetModeName(mode, modeName, sizeof(modeName));
		PrintToChatAll("\x04%s \x05反伤模式已设置为: \x03%s \x05喵", PREFIX, modeName);
	}

	SaveCustomConfig();
	if (g_bDebug) PrintToChatAll("[DEBUG] 命令设置反伤模式: %d", mode);

	return Plugin_Handled;
}

void OnFrameForConfig(any data)
{
	LoadCustomConfig();
}

void LoadCustomConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CUSTOM_CONFIG_FILE);
	if (!FileExists(path))
	{
		SaveCustomConfig();
		return;
	}

	KeyValues kv = new KeyValues("settings");
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		LogError("Failed to load custom config from %s", path);
		return;
	}

	int mode = kv.GetNum("mode", 6);
	int fire = kv.GetNum("fire_enable", 0);

	switch (mode)
	{
		case 0:
		{
			g_bUseThresholdMode = true;
			g_iReverseMode		= 0;
			g_bFireEnable		= (fire != 0);
		}
		case 6:
		{
			g_bUseThresholdMode = false;
			g_iReverseMode		= 0;
			g_bFireEnable		= false;
		}
		case 1, 2, 3, 5:
		{
			g_bUseThresholdMode = false;
			g_iReverseMode		= mode;
			g_bFireEnable		= (fire != 0);
		}
		default:
		{
			g_bUseThresholdMode = true;
			g_iReverseMode		= 0;
			g_bFireEnable		= (fire != 0);
		}
	}

	delete kv;
	PrintToServer("[友伤控制] 已加载自定义配置，模式=%d, 火伤=%d", mode, fire);
	if (g_bDebug) PrintToChatAll("[DEBUG] 加载自定义配置完成");
}

void SaveCustomConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CUSTOM_CONFIG_FILE);

	KeyValues kv = new KeyValues("settings");

	int		  mode;
	if (g_bUseThresholdMode)
		mode = 0;
	else
		mode = (g_iReverseMode == 0) ? 6 : g_iReverseMode;

	int fire = g_bFireEnable ? 1 : 0;
	if (!g_bUseThresholdMode && g_iReverseMode == 0)
		fire = 0;

	kv.SetNum("mode", mode);
	kv.SetNum("fire_enable", fire);

	if (!kv.ExportToFile(path))
	{
		LogError("无法保存自定义配置到 %s", path);
	}

	delete kv;
	if (g_bDebug) PrintToChatAll("[DEBUG] 保存自定义配置完成");
}