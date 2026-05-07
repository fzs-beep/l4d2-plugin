#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.5 Beta"

#define UNDO_PERM 0
#define UNDO_TEMP 1
#define UNDO_SIZE 16
#define STACK_VICTIM 0
#define STACK_DAMAGE 1
#define STACK_DISTANCE 2
#define STACK_TYPE 3
#define STACK_SIZE 4
#define FFTYPE_NOTUNDONE 0
#define FFTYPE_TOOCLOSE 1
#define FFTYPE_CHARGERCARRY 2
#define FFTYPE_STUPIDBOTS 4
#define FFTYPE_MELEEFLAG 0x8000
#define EASY 0
#define NORMAL 1
#define ADVANCED 2
#define EXPERT 3
#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))
#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

new Handle:g_cvarEnable = INVALID_HANDLE;
new g_EnabledFlags;
new Handle:g_cvarBlockZeroDmg = INVALID_HANDLE;
new g_BlockZeroDmg;
new Handle:g_cvarPermDamageFraction = INVALID_HANDLE;
new Float:g_flPermFrac;
new g_difficulty = NORMAL;
new bool:g_chargerCarryNoFF[MAXPLAYERS+1] = { false, ... };
new bool:g_stupidGuiltyBots[MAXPLAYERS+1] = { false, ... };
new bool:g_ReleaseNoFF[MAXPLAYERS+1] = { false, ... };
new g_lastHealth[MAXPLAYERS+1][UNDO_SIZE][2];
new g_lastReviveCount[MAXPLAYERS+1] = { 0, ... };
new g_currentUndo[MAXPLAYERS+1] = { 0, ... };
new g_targetTempHealth[MAXPLAYERS+1] = { 0, ... };
new g_lastPerm[MAXPLAYERS+1] = { 100, ... };
new g_lastTemp[MAXPLAYERS+1] = { 0, ... };
new Handle:g_iAnnounceStacks[MAXPLAYERS+1] = INVALID_HANDLE;

// 友伤惩罚
new Handle:FriendDamageSwitch;
new Handle:FriendDamageEffect;
new Handle:FriendDamagePunish1;
new Handle:FriendDamagePunish2;
new Handle:DamageImmuneRadius;
new FriendDamage[MAXPLAYERS+1];
new Punish1Number[MAXPLAYERS+1];
new Punish2Number[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "L4D2 队友伤害控制",
	author = "dcx2、ヾ藤野深月ゞ",
	description = "在某些情况下防止队友伤害，并对造成队伤的玩家给予一定的惩罚",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1745732#post1745732"
};

public OnPluginStart()
{
	CreateConVar							("L4D2_TeamDamageControl_Version", 	PLUGIN_VERSION, "L4D2 队友伤害控制 插件版本", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	g_cvarEnable							= 	CreateConVar("L4D2_TeamDamage_Enable",				"7",		"设置友军伤害豁免效果(相加): \n1=近距离 2=被Charger撞到时 4=电脑 7=所有 0=禁用插件", FCVAR_NOTIFY);
	g_cvarBlockZeroDmg				=		CreateConVar("L4D2_TeamDamage_Blockzerodmg",	"0",		"设置友军伤害豁免对攻击者的效果反馈(相加): \n4=电脑击中玩家时的晃动效果 2=声音和统计在所有难度 1=声音和统计在容易难度 0=关闭效果", FCVAR_NOTIFY);
	g_cvarPermDamageFraction	= 	CreateConVar("L4D2_TeamDamage_Permdmgfrac",		"1.0",	"造成真实生命值的最小伤害值", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	FriendDamageSwitch				= 	CreateConVar("L4D2_TeamDamage_Switch",				"1",		"是否开启友军伤害反伤？(0=关 1=开)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	FriendDamageEffect				= 	CreateConVar("L4D2_TeamDamage_Effect",				"1.0",	"友军伤害反伤比例(伤害 * 当前系数)", FCVAR_NOTIFY, true, 1.0, true, 50.0);
	FriendDamagePunish1				= 	CreateConVar("L4D2_TeamDamage_Punish1",				"150",	"友军伤害达到多少进行第一个惩罚？(掉地)", FCVAR_NOTIFY, true, 50.0, true, 9999.0);
	FriendDamagePunish2				= 	CreateConVar("L4D2_TeamDamage_Punish2",				"300",	"友军伤害达到多少进行第二个惩罚？(处死)\n注：设置值不能低于第一个惩罚", FCVAR_NOTIFY, true, GetConVarFloat(FriendDamagePunish1), true, 9999.0);
	DamageImmuneRadius				=		CreateConVar("L4D2_TeamDamage_Radius",				"43.0",	"友伤保护有效半径范围(免疫队友的一切伤害)", FCVAR_NOTIFY, true, 1.0, true, 300.0);
	/* 生成CFG */
	AutoExecConfig(true, "L4D2_TeamDamage_Control");
	
	/* 其他参数 */
	new Handle:difficulty = 	  FindConVar("z_difficulty");
	HookConVarChange(g_cvarEnable, 				OnUndoFFEnableChanged);
	HookConVarChange(g_cvarBlockZeroDmg, 		OnUndoFFBlockZeroDmgChanged);
	HookConVarChange(g_cvarPermDamageFraction, 	OnPermFracChanged);
	HookConVarChange(difficulty, 				OnDifficultyChanged);
	g_EnabledFlags = GetConVarInt(g_cvarEnable);
	g_BlockZeroDmg = GetConVarInt(g_cvarBlockZeroDmg);
	g_flPermFrac = GetConVarFloat(g_cvarPermDamageFraction);
	
	/* 难度检查 */
	new String:difficultyString[32];
	GetConVarString(difficulty, difficultyString, sizeof(difficultyString));
	g_difficulty = GetDifficultyValue(difficultyString);
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		for (new j=0; j<UNDO_SIZE; j++)
		{
			g_lastHealth[i][j][UNDO_PERM] = 0;
			g_lastHealth[i][j][UNDO_TEMP] = 0;
		}
		g_iAnnounceStacks[i] = CreateStack(STACK_SIZE);
	}
	
	/* 文本载入 */
	LoadTranslations("common.phrases");	
	
	/* Hook */
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("friendly_fire", Event_FriendlyFire, EventHookMode_Pre);
	HookEvent("charger_carry_start", Event_ChargerCarryStart, EventHookMode_Post);
	HookEvent("charger_carry_end", Event_ChargerCarryEnd, EventHookMode_Post);
	HookEvent("heal_begin", Event_HealBegin, EventHookMode_Pre);
	HookEvent("heal_end", Event_HealEnd, EventHookMode_Pre);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Pre);
	HookEvent("player_incapacitated_start", Event_PlayerIncapStart, EventHookMode_Pre);
	HookEvent("tongue_release", PostSurvivorRelease);
	HookEvent("pounce_end", PostSurvivorRelease);
	HookEvent("jockey_ride_end", PostSurvivorRelease);
	HookEvent("charger_pummel_end", PostSurvivorRelease);
	//反伤、惩罚部分
	HookEvent("player_hurt",		Event_PlayerHurt2, EventHookMode_Pre);
	HookEvent("round_start", 		Event_RoundStart);
	HookEvent("map_transition", Event_RoundStart);
}

public OnUndoFFEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_EnabledFlags = StringToInt(newVal);
}

public OnUndoFFBlockZeroDmgChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_BlockZeroDmg = StringToInt(newVal);
}

public OnDifficultyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_difficulty = GetDifficultyValue(newValue);
}

public GetDifficultyValue(const String:Difficulty[])
{
	new ret = NORMAL;
	if (StrEqual(Difficulty, "impossible", false)) ret = EXPERT;
	else if (StrEqual(Difficulty, "hard", false)) ret = ADVANCED;
	else if (StrEqual(Difficulty, "easy", false)) ret = EASY;
	return ret;
}

public OnPermFracChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_flPermFrac = StringToFloat(newVal);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageUndoFF);
	SDKHook(client, SDKHook_TraceAttack, TraceAttackUndoFF);
}

public Action:TraceAttackUndoFF(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	new String:victimName[MAX_TARGET_LENGTH];
	new String:attackerName[MAX_TARGET_LENGTH];
	new String:inflictorName[32];
	if (!g_EnabledFlags || !IS_VALID_SURVIVOR(victim)) return Plugin_Continue;
	GetClientOrEntityName(victim, victimName, sizeof(victimName));
	GetClientOrEntityName(attacker, attackerName, sizeof(attackerName));
	GetSafeEntityName(inflictor, inflictorName, sizeof(inflictorName));
	if ((g_BlockZeroDmg & 0x04) && IS_VALID_SURVIVOR(attacker) && IsFakeClient(attacker) && IS_VALID_SURVIVOR(victim) && !IsFakeClient(victim)) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:OnTakeDamageUndoFF(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new String:victimName[MAX_TARGET_LENGTH];
	new String:attackerName[MAX_TARGET_LENGTH];
	new String:weaponName[32];
	new String:inflictorName[32];
	new bool:undone = false;

	if (!g_EnabledFlags || !IS_VALID_SURVIVOR(victim)) return Plugin_Continue;
	
	GetClientOrEntityName(victim, victimName, sizeof(victimName));
	GetClientOrEntityName(attacker, attackerName, sizeof(attackerName));
	GetSafeEntityName(weapon, weaponName, sizeof(weaponName));
	GetSafeEntityName(inflictor, inflictorName, sizeof(inflictorName));

	new dmg = RoundToFloor(damage);
	if (IS_VALID_SURVIVOR(victim) && (dmg > 0 || (IS_VALID_SURVIVOR(attacker) && !IsFakeClient(attacker))))
	{
		if (IsSurvivorBusy(victim)) g_ReleaseNoFF[victim] = true;
		new victimPerm = GetClientHealth(victim);
		new victimTemp = L4D_GetPlayerTempHealth(victim);
		if (IS_VALID_SURVIVOR(attacker) && attacker != victim)
		{
			new Float:Distance = GetClientsDistance(victim, attacker);
			//new Float:FFDist = GetWeaponFFDist(weaponName);
			new Float:FFDist = GetConVarFloat(DamageImmuneRadius);
			new type;
			if ((g_EnabledFlags & FFTYPE_TOOCLOSE) && (Distance < FFDist))
			{
				undone = true;
				type = FFTYPE_TOOCLOSE;
			}
			else if ((g_EnabledFlags & FFTYPE_CHARGERCARRY) && (g_chargerCarryNoFF[victim] || g_ReleaseNoFF[victim]))
			{
				undone = true;
				type = FFTYPE_CHARGERCARRY;
			}
			else if ((g_EnabledFlags & FFTYPE_STUPIDBOTS) && (g_stupidGuiltyBots[victim]))
			{
				undone = true;
				type = FFTYPE_STUPIDBOTS;
			}
			else if (dmg == 0)
			{
				undone = (g_BlockZeroDmg & 0x02) || ((g_BlockZeroDmg & 0x01) && g_difficulty != EASY);
				type = FFTYPE_NOTUNDONE;
			}
			if (undone) PrepareAnnounce(weaponName, victim, attacker, dmg, type, Distance);
		}
		if (!undone && dmg > 0)
		{			
			new PermDmg = RoundToCeil(g_flPermFrac * dmg);
			if (PermDmg >= victimPerm) PermDmg = victimPerm - 1;
			new TempDmg = dmg - PermDmg;
			if (TempDmg > victimTemp)
			{
				PermDmg += (TempDmg - victimTemp);
				TempDmg = victimTemp;
			}
			if (!L4D_IsPlayerIncapacitated(victim))
			{
				new nextUndo = (g_currentUndo[victim] + 1) % UNDO_SIZE;
				if (PermDmg < victimPerm)
				{
					g_lastHealth[victim][nextUndo][UNDO_PERM] = PermDmg;
					g_lastHealth[victim][nextUndo][UNDO_TEMP] = TempDmg;
					g_lastPerm[victim] = victimPerm - PermDmg;
					g_lastTemp[victim] = victimTemp - TempDmg;
				}
				else
				{
					g_lastHealth[victim][nextUndo][UNDO_PERM] = victimPerm;
					g_lastHealth[victim][nextUndo][UNDO_TEMP] = victimTemp;
					g_lastPerm[victim] = PermDmg;
					g_lastTemp[victim] = TempDmg;
					g_lastReviveCount[victim] = L4D_GetPlayerReviveCount(victim);
				}
			}
		}
	}
	if (undone) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags) return Plugin_Continue;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IS_VALID_SURVIVOR(victim)) return Plugin_Continue;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg = GetEventInt(event, "dmg_health");
	new currentPerm = GetEventInt(event, "health");
	new String:weaponName[32];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	if (dmg > 0 && !L4D_IsPlayerIncapacitated(victim))
	{
		g_currentUndo[victim] = (g_currentUndo[victim] + 1) % UNDO_SIZE;
		new victimPerm = g_lastPerm[victim];
		new victimTemp = g_lastTemp[victim];
		new currentTemp = L4D_GetPlayerTempHealth(victim);
		if (g_flPermFrac < 1.0 && victimPerm != currentPerm)
		{
			new totalHealthOld = currentPerm + currentTemp, totalHealthNew = victimPerm + victimTemp;
			if (totalHealthOld == totalHealthNew)
			{
				SetEntityHealth(victim, victimPerm);
				L4D_SetPlayerTempHealth(victim, victimTemp);
			}
		}
	}
	if (IS_VALID_SURVIVOR(attacker))
	{
		new type;
		if ((g_EnabledFlags & FFTYPE_STUPIDBOTS) && (g_stupidGuiltyBots[victim]))
		{
			UndoDamage(victim);
			type = FFTYPE_STUPIDBOTS;
		}
		else type = FFTYPE_NOTUNDONE;
		PrepareAnnounce(weaponName, victim, attacker, dmg, type, GetClientsDistance(victim, attacker));
	}
	return Plugin_Continue;
}

public Action:Event_PlayerIncapStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	g_currentUndo[victim] = (g_currentUndo[victim] + 1) % UNDO_SIZE;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IS_VALID_SURVIVOR(attacker))
	{
		new dmg = g_lastPerm[victim] + g_lastTemp[victim];
		new type;
		new String:weaponName[32];
		GetEventString(event, "weapon", weaponName, sizeof(weaponName));
		if ((g_EnabledFlags & FFTYPE_STUPIDBOTS) && (g_stupidGuiltyBots[victim]))
		{
			UndoDamage(victim);
			type = FFTYPE_STUPIDBOTS;
		}
		else type = FFTYPE_NOTUNDONE;
		PrepareAnnounce(weaponName, victim, attacker, dmg, type, GetClientsDistance(victim, attacker));
	}
}

public PrepareAnnounce(String:weaponName[], victim, attacker, dmg, type, Float:dist)
{
	new stackArg[STACK_SIZE];
	new bool:isStackable = false;
	if (StrContains(weaponName, "shotgun") >= 0) isStackable = true;	
	else if (StrContains(weaponName, "melee") >= 0)
	{
		type |= FFTYPE_MELEEFLAG;
		isStackable = true;
	}
	stackArg[STACK_VICTIM] = victim;
	stackArg[STACK_DAMAGE] = dmg;
	stackArg[STACK_DISTANCE] = _:dist;
	stackArg[STACK_TYPE] = type;
	new bool:notYetStacked = false;
	if (IsStackEmpty(g_iAnnounceStacks[attacker])) notYetStacked = true;
	PushStackArray(g_iAnnounceStacks[attacker], stackArg);
	if (notYetStacked && !IsStackEmpty(g_iAnnounceStacks[attacker]))
	{
		if (isStackable) CreateTimer(0.1, AnnounceDelay, attacker);
		else AnnounceAttack(attacker);
	}
}

public Action:AnnounceDelay(Handle:timer, any:attacker)
{
	AnnounceAttack(attacker);
}

public AnnounceAttack(any:attacker)
{
	new types[MAXPLAYERS+1];
	new multipliers[MAXPLAYERS+1] = { -1, ... };	// -1 = not hit
	new damages[MAXPLAYERS+1];
	new Float:distances[MAXPLAYERS+1];
	while (!IsStackEmpty(g_iAnnounceStacks[attacker]))
	{
		new stackArg[STACK_SIZE];
		PopStackArray(g_iAnnounceStacks[attacker], stackArg);
		new victim = stackArg[STACK_VICTIM];
		types[victim] = stackArg[STACK_TYPE];
		distances[victim] = Float:stackArg[STACK_DISTANCE];
		if (multipliers[victim] < 0) multipliers[victim] = 0;
		if (stackArg[STACK_DAMAGE] > 0 || !(stackArg[STACK_TYPE] & FFTYPE_MELEEFLAG))
		{
			multipliers[victim]++;
			damages[victim] = stackArg[STACK_DAMAGE];
		}
	}
	for (new i=1; i<=MaxClients; i++)
	{
		if (multipliers[i] < 0) continue;
		new String:multString[32] = "";	// by default, no multiplier
		new String:damageString[64];
		types[i] &= FFTYPE_TOOCLOSE | FFTYPE_CHARGERCARRY | FFTYPE_STUPIDBOTS;
		new bool:unhurt = types[i] || damages[i]==0, bool:undone = types[i] != FFTYPE_NOTUNDONE;
		if (multipliers[i] > 1) FormatEx(multString, sizeof(multString), " (%dx%s%d\x01)", multipliers[i], (unhurt ? "\x03" : "\x05"), damages[i]);
		FormatEx(damageString, sizeof(damageString), "%s%s %d\x01%s", (unhurt ? "\x03" : "\x05"), (undone ? "Undid" : "Did"), (multipliers[i] * damages[i]), multString); // will be empty string if no multiplier
		switch(types[i])
		{
			case FFTYPE_STUPIDBOTS:		strcopy(multString, sizeof(multString), "(stupid bot)");
			case FFTYPE_CHARGERCARRY:	strcopy(multString, sizeof(multString), "(Charger carry)");
			case FFTYPE_TOOCLOSE,
					 FFTYPE_NOTUNDONE:		FormatEx(multString, sizeof(multString), "(dist %f)", distances[i]);
			default:					FormatEx(multString, sizeof(multString), "(dist %f)", distances[i]);
		}
	}
}

public Action:Event_FriendlyFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!(g_EnabledFlags & FFTYPE_STUPIDBOTS)) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "guilty"));
	if (IsFakeClient(client))
	{
		g_stupidGuiltyBots[client] = true;
		CreateTimer(0.4, StupidGuiltyBotDelay, client);
	}
	return Plugin_Continue;
}

public Action:StupidGuiltyBotDelay(Handle:timer, any:client)
{
	g_stupidGuiltyBots[client] = false;
}

public Action:Event_ChargerCarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!(g_EnabledFlags & FFTYPE_CHARGERCARRY)) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	g_chargerCarryNoFF[client] = true;
	return Plugin_Continue;
}


public Action:Event_ChargerCarryEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	CreateTimer(2.0, ChargerCarryFFDelay, client);
	return Plugin_Continue;
}

public Action:ChargerCarryFFDelay(Handle:timer, any:client)
{
	g_chargerCarryNoFF[client] = false;
}

public PostSurvivorRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"victim"));
	if (!IsClientAndInGame(victim)) return;
	if (StrContains(name, "tongue") != -1)				CreateTimer(0.3, ReleaseFFDelay, victim);
	else if (StrContains(name, "pounce") != -1)		CreateTimer(2.0, ReleaseFFDelay, victim);
	else if (StrContains(name, "jockey") != -1)		CreateTimer(0.3, ReleaseFFDelay, victim);
	else if (StrContains(name, "charger") != -1)	CreateTimer(2.0, ReleaseFFDelay, victim);
	return;
}

stock IsSurvivorBusy(client)
{
	return (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 || GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 || GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 || GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0);
}

public Action:ReleaseFFDelay(Handle:timer, any:client)
{
	g_ReleaseNoFF[client] = false;
}

stock IsClientAndInGame(client)
{
	if (0 < client && client < MaxClients) return IsClientInGame(client);
	return false;
}

public Action:Event_HealBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags) 			return Plugin_Continue;
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IS_SURVIVOR_ALIVE(subject) || !IS_SURVIVOR_ALIVE(userid)) return Plugin_Continue;
	g_targetTempHealth[userid] = subject;

	return Plugin_Continue;
}

public Action:Event_HealEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags) 			return Plugin_Continue;

	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = g_targetTempHealth[userid];
	new tempHealth;
	if (!IS_SURVIVOR_ALIVE(subject))
	{
		PrintToServer("Who did you heal? (%d)", subject);	
		return Plugin_Continue;
	}
	tempHealth =  L4D_GetPlayerTempHealth(subject);
	if (tempHealth < 0) tempHealth = 0;
	g_targetTempHealth[userid] = tempHealth;
	return Plugin_Continue;
}

public Action:Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags) 			return Plugin_Continue;
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IS_SURVIVOR_ALIVE(subject)) return Plugin_Continue;
	new nextUndo = (g_currentUndo[subject] + 1) % UNDO_SIZE;
	g_lastHealth[subject][nextUndo][UNDO_PERM] = -GetEventInt(event, "health_restored");
	g_lastHealth[subject][nextUndo][UNDO_TEMP] = g_targetTempHealth[userid];
	g_currentUndo[subject] = nextUndo;
	return Plugin_Continue;
}

/***************************************************************************************
*
*					伤害监测与惩罚（开始）
*
***************************************************************************************/
public Action:Event_PlayerHurt2(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damageDone = GetEventInt(event, "dmg_health");
	//友军伤害返回
	if (IsValidPlayer(attacker) && IsValidPlayer(victim) && GetClientTeam(attacker) == GetClientTeam(victim)) 
	{
		if (attacker == victim || !IsPlayerAlive(victim) || GetClientTeam(victim) != 2) return Plugin_Continue;
		FriendDamage[attacker] += damageDone;
		CreateTimer(0.1, FriendDamageCheck, attacker);
		//ScreenFade(attacker, 150, 10, 10, 80, 100, 1);
		//ScreenFade(attacker, 0, 0, 0, 80, 100, 1);
		DealDamage(0, attacker, RoundToNearest(damageDone * GetConVarFloat(FriendDamageEffect)), 0, "damage_reflect");
	}
	return Plugin_Handled;
}

public Action:FriendDamageCheck(Handle:timer, any:Client)
{
	if(!IsValidPlayer(Client)) return Plugin_Handled;
	
	new Punish_1 = GetConVarInt(FriendDamagePunish1);
	new Punish_2 = GetConVarInt(FriendDamagePunish2);

	if (FriendDamage[Client] >= Punish_1)
	{
		if(Punish1Number[Client] == 0)
		{
			Punish1Number[Client] = 1;
			if(!IsIncapacitated(Client)) DealDamage(0, Client, 10000, 0, "damage_reflect");
			PrintToChatAll("\x04[提示]\x03玩家 \x05%N \x03队友伤害达到 %d 进行 倒地 惩罚.", Client, Punish_1);
		}
	}
	if (FriendDamage[Client] >= Punish_2)
	{
		if(Punish2Number[Client] == 0)
		{
			ForcePlayerSuicide(Client);
			Punish2Number[Client] = 1;
			CreateTimer(0.1, ResetFriendDamageCount, Client);
			PrintToChatAll("\x04[提示]\x03玩家 \x05%N \x03队友伤害达到 %d 进行 处死 惩罚.", Client, Punish_2);
		}
	}
	return Plugin_Stop;
}

public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new i = 0; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			CreateTimer(5.0, ResetFriendDamageCount, i);
	}
}

public Action:ResetFriendDamageCount(Handle:timer, any:Client)
{
	if (IsValidPlayer(Client) && FriendDamage[Client] != 0)
	{
		FriendDamage[Client] = 0;
		Punish1Number[Client] = 0;
		Punish2Number[Client] = 0;
		PrintToChat(Client, "\x04[提示]\x03队友伤害计算次数已重置.");
	}
}

stock bool:IsValidPlayer(Client, bool:AllowBot = true, bool:AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients) return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client)) return false;
	return true;
}

stock bool IsIncapacitated(Client)
{
	return !!GetEntProp(Client, Prop_Send, "m_isIncapacitated");
}

stock DealDamage(attacker=0,victim,damage,dmg_type=0,String:weapon[]="")
{
	if(IsValidEdict(victim) && damage>0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new PointHurt1 = CreateEntityByName("point_hurt");
		if(PointHurt1)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt1,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt1,"Damage",float(damage));
			DispatchKeyValue(PointHurt1,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,"")) DispatchKeyValue(PointHurt1,"classname",weapon);
			DispatchSpawn(PointHurt1);
			if(IsValidPlayer(attacker)) AcceptEntityInput(PointHurt1, "Hurt", attacker);
			else AcceptEntityInput(PointHurt1, "Hurt", -1);
			RemoveEdict(PointHurt1);
		}
	}
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	if(IsClientInGame(target)){
		new Handle:msg = StartMessageOne("Fade", target);
		BfWriteShort(msg, 500);
		BfWriteShort(msg, duration);
		if (type == 0) BfWriteShort(msg, (0x0002 | 0x0008));
		else BfWriteShort(msg, (0x0001 | 0x0010));
		BfWriteByte(msg, red);
		BfWriteByte(msg, green);
		BfWriteByte(msg, blue);
		BfWriteByte(msg, alpha);
		EndMessage();
	}
}
/***************************************************************************************
*
*					伤害监测与惩罚（结束）
*
***************************************************************************************/

UndoDamage(client)
{
	if (IS_VALID_SURVIVOR(client))
	{
		new thisUndo = g_currentUndo[client];
		new undoPerm = g_lastHealth[client][thisUndo][UNDO_PERM];
		new undoTemp = g_lastHealth[client][thisUndo][UNDO_TEMP];

		new newHealth, newTemp;
		if (L4D_IsPlayerIncapacitated(client))
		{
			newHealth = undoPerm;
			newTemp = undoTemp;
			CheatCommand(client, "give", "health");
			SetEntProp(client, Prop_Send, "m_currentReviveCount", g_lastReviveCount[client]);
		}
		else
		{
			newHealth = GetClientHealth(client) + undoPerm;
			newTemp = undoTemp;
			if (undoPerm >= 0) newTemp += L4D_GetPlayerTempHealth(client);
			else CheatCommand(client, "give", "weapon_first_aid_kit");
		}
		if (newHealth > 100) newHealth = 100;
		if (newHealth + newTemp > 100) newTemp = 100 - newHealth;
		SetEntityHealth(client, newHealth);
		L4D_SetPlayerTempHealth(client, newTemp);
		g_lastHealth[client][thisUndo][UNDO_PERM] = 0;
		g_lastHealth[client][thisUndo][UNDO_TEMP] = 0;
		if (thisUndo <= 0) thisUndo = UNDO_SIZE;
		thisUndo = thisUndo - 1;
		g_currentUndo[client] = thisUndo;
	}
}

stock Float:GetClientsDistance(victim, attacker)
{
	new Float:attackerPos[3], Float:victimPos[3];
	new Float:mins[3], Float:maxs[3], Float:halfHeight;
	GetClientMins(victim, mins);
	GetClientMaxs(victim, maxs);
	halfHeight = maxs[2] - mins[2] + 10;
	GetClientAbsOrigin(victim,victimPos);
	GetClientAbsOrigin(attacker,attackerPos);
	new Float:posHeightDiff = attackerPos[2] - victimPos[2];
	if (posHeightDiff > halfHeight)								attackerPos[2] -= halfHeight;
	else if (posHeightDiff < (-1.0 * halfHeight))	victimPos[2] -= halfHeight;
	else																					attackerPos[2] = victimPos[2];
	return GetVectorDistance(victimPos ,attackerPos, false);
}

public Float:GetWeaponFFDist(String:weaponName[])
{
	if (StrEqual(weaponName, "weapon_melee") || StrEqual(weaponName, "weapon_pistol") || StrEqual(weaponName, "weapon_chainsaw") || StrEqual(weaponName, "weapon_pistol_magnum")) return 75.0;
	else if (StrEqual(weaponName, "weapon_smg") || StrEqual(weaponName, "weapon_smg_silenced") || StrEqual(weaponName, "weapon_smg_mp5") || StrEqual(weaponName, "weapon_rifle") || StrEqual(weaponName, "weapon_rifle_sg552") || StrEqual(weaponName, "weapon_rifle_ak47")) return 95.0;
	else if (StrEqual(weaponName, "weapon_sniper_military") || StrEqual(weaponName, "weapon_hunting_rifle") || StrEqual(weaponName, "weapon_sniper_scout") || StrEqual(weaponName, "weapon_sniper_awp") || StrEqual(weaponName, "weapon_rifle_m60") || StrEqual(weaponName, "weapon_minigun")) return 115.0;
	else if	(StrEqual(weaponName, "weapon_pumpshotgun") || StrEqual(weaponName, "weapon_autoshotgun") || StrEqual(weaponName, "weapon_shotgun_spas") || StrEqual(weaponName, "weapon_shotgun_chrome") || StrEqual(weaponName, "weapon_rifle_desert") || StrEqual(weaponName, "weapon_grenade_launcher")) return 105.0;
	return 0.0;
}

stock GetSafeEntityName(entity, String:TheName[], TheNameSize)
{
	if (entity > 0 && IsValidEntity(entity)) GetEntityClassname(entity, TheName, TheNameSize);
	else strcopy(TheName, TheNameSize, "Invalid");
}

stock GetClientOrEntityName(entity, String:TheName[], TheNameSize)
{
	if (IS_VALID_CLIENT(entity))
	{
		if (IsClientConnected(entity)) GetClientName(entity, TheName, TheNameSize);
		else strcopy(TheName, TheNameSize, "Disconnected");
	}
	else GetSafeEntityName(entity, TheName, TheNameSize);
}

stock L4D_GetPlayerTempHealth(client)
{
	if (!IS_VALID_SURVIVOR(client)) return 0;
	
	static Handle:painPillsDecayCvar = INVALID_HANDLE;
	if (painPillsDecayCvar == INVALID_HANDLE)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == INVALID_HANDLE) return -1;
	}
	new tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}

stock L4D_SetPlayerTempHealth(client, tempHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(tempHealth));
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

stock L4D_GetPlayerReviveCount(client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

stock bool:L4D_IsPlayerIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}

stock L4D_SetPlayerIncapState(client, any:incap)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", incap);
}

stock CheatCommand(client, const String:command[], const String:arguments[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}