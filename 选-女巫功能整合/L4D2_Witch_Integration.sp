#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define PLUGIN_VERSION "1.2.2"

#define ANIM_WITCH_PRE_RETREAT		5
#define ANIM_WITCH_RUN_INTENSE		6
#define ANIM_WITCH_RUN_ONFIRE_INT	7
#define ANIM_WITCH_RUN_RETREAT		8
#define ANIM_WITCH_WANDER_WALK		11
#define ANIM_WITCH_WANDER_ACQUIRE	30
#define ANIM_WITCH_KILLING_BLOW		31
#define ANIM_WITCH_RUN_ONFIRE		39

static Handle SDKOnHitByVomitJar 	= INVALID_HANDLE;

/* Relentless Witch */
Handle relentlesswitchincap, relentlesswitchrange, relentlessextinguish;
int bRelentlessWitchIncap, iRelentlessWitchRange, brelentlessextinguish;

// No Witch Hunting
Handle g_hWitchIncapAction, g_hSurvivorMaxIncapCount;
int g_iSurvivorMaxIncapCount = 2;

/* Witch Attacker Damage*/
Handle g_hWitchattackerdmg;
float fWitchAttackerDamage;

/* Witch Allow In Safezone */
Handle rWitchInCheckPoints;
int iWitchInCheckPoints;

Handle rWitchCheckDistance;
float fWitchCheckDistance;

Handle rWitchCheckTipMode;
int iWitchCheckTipMode;

Handle rWitch_HarasserSet;
int bWitch_HarasserSet;

public Plugin myinfo =
{
	name = "[L4D2] Witch 整合插件",
	author = "Lux & Harry Potter、Machine、Mr. Zero、ヾ藤野深月ゞ 【由：ヾ藤野深月ゞ 整合修正汉化】",
	description = "Witch整合强化插件(进入安全区、连续追杀、免疫火、攻击效果、爪击造成伤害、惊扰提示、范围提示)",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

public void OnPluginStart()
{
	CreateConVar("L4D2_Witch_Integration_Version", PLUGIN_VERSION,		"[L4D2] Witch 整合插件版本", FCVAR_NONE|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	relentlesswitchincap	=	CreateConVar("L4D2_relentless_witch_incap",		"1", 				"设置 Witch 击倒幸存者后是否杀死倒地的幸存者再进行追击？(0=禁止 1=允许)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	relentlesswitchrange	=	CreateConVar("L4D2_relentless_witch_range",		"3000", 		"设置 Witch 继续追杀多大范围内的幸存者？", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	relentlessextinguish	=	CreateConVar("L4D2_relentless_extinguish",		"1", 				"设置 Witch 免疫火焰类别的相关伤害？(0=禁止 1=允许)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hWitchIncapAction		=	CreateConVar("L4D2_survivormax_incapaction",	"1",				"设置 Witch 爪子击倒幸存者后附加哪种效果？(0=禁用 1=黑白 2=死亡)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hWitchattackerdmg		=	CreateConVar("L4D2_witchattacker_damage",			"1000",			"设置 Witch 爪子每次攻击能够造成多少的伤害？(0=禁用)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	rWitchInCheckPoints		=	CreateConVar("L4D2_WitchInCheck_Points",			"1", 				"设置 Witch 是否可以进入安全区？(0=禁止 1=允许)\n注：禁用后进入安全区将会持续触发追杀幸存者功能！", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	rWitch_HarasserSet		=	CreateConVar("L4D2_WitchHarasserSet_Info",		"1", 				"设置 是否提示 玩家 惊扰 Witch？(0=禁止 1=允许)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	rWitchCheckDistance		=	CreateConVar("L4D2_WitchInCheck_Distance",		"500.0", 		"设置 玩家距离 Witch 多近的时候提示？(0=禁止 1=允许)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	rWitchCheckTipMode		=	CreateConVar("L4D2_WitchInCheck_TipMode",			"2", 				"设置 玩家接近 Witch 的提示模式？(1=Witch头顶 2=屏幕中间)", FCVAR_NONE|FCVAR_NOTIFY, true, 1.0, true, 2.0);
	/* Hook */
	HookEvent("player_incapacitated", 			Event_PlayerIncapacitated);
	HookEvent("player_death", 							Event_PlayerDeath);
	HookEvent("player_incapacitated_start", Event_WitchIncapacitated);
	HookEvent("witch_harasser_set",					Event_HarasserSet);
	HookEvent("witch_spawn",								Event_WitchSpawn);
	/* 设置参数 */
	g_hSurvivorMaxIncapCount	= 	FindConVar("survivor_max_incapacitated_count");
	bRelentlessWitchIncap 		= 	GetConVarBool(relentlesswitchincap);
	iRelentlessWitchRange  		= 	GetConVarInt(relentlesswitchrange);
	brelentlessextinguish 		= 	GetConVarBool(relentlessextinguish);
	fWitchAttackerDamage 			= 	GetConVarFloat(g_hWitchattackerdmg);
	iWitchInCheckPoints	  		= 	GetConVarInt(rWitchInCheckPoints);
	g_iSurvivorMaxIncapCount	= 	GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	bWitch_HarasserSet				= 	GetConVarBool(rWitch_HarasserSet);
	fWitchCheckDistance				= 	GetConVarFloat(rWitchCheckDistance); 
	iWitchCheckTipMode	  		= 	GetConVarInt(rWitchCheckTipMode);
	/* 参数更改设置 */
	HookConVarChange(g_hSurvivorMaxIncapCount,	CvarsChanged);
	HookConVarChange(g_hWitchattackerdmg, 			CvarsChanged);
	HookConVarChange(relentlesswitchincap,			CvarsChanged);
	HookConVarChange(relentlesswitchrange,			CvarsChanged);
	HookConVarChange(rWitchInCheckPoints,				CvarsChanged);
	HookConVarChange(rWitch_HarasserSet,				CvarsChanged);
	HookConVarChange(rWitchCheckDistance,				CvarsChanged);
	HookConVarChange(rWitchCheckTipMode,				CvarsChanged);
	/* 生成CFG */
	AutoExecConfig(true, "[L4D2]Witch_Integration_CHS");
	/* SDKCall */
	InitSDKCalls();
	WitchAllowCalls();
}

public void OnMapStart()
{
	/* 预载音频 */
	PrecacheSound("npc/witch/voice/idle/female_cry_1.wav", true);
}

//=============================
// SDKCalls
//=============================
void InitSDKCalls()
{
	Handle ConfigFile = LoadGameConfigFile("L4D2_Witch_Integration");
	Handle MySDKCall = INVALID_HANDLE;
	///////////////////
	//OnHitByVomitJar//
	///////////////////
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "Infected_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
		SetFailState("Cant initialize Infected_OnHitByVomitJar SDKCall");
	SDKOnHitByVomitJar = CloneHandle(MySDKCall, SDKOnHitByVomitJar);
	CloseHandle(ConfigFile);
	CloseHandle(MySDKCall);
}

/* Witch Allow In Safezone */
void WitchAllowCalls()
{
	Handle hGamedata = LoadGameConfigFile("L4D2_Witch_Integration");
	if(hGamedata == null) 
		SetFailState("Failed to load \"L4D2_Witch_Integration.txt\" gamedata.");
	
	Handle hDetour;
	
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		hDetour = DHookCreateFromConf(hGamedata, "CDirector::AllowWitchesInCheckpoints");
		if(!hDetour)
			SetFailState("Failed to find \"CDirector::AllowWitchesInCheckpoints\" signature.");
			
		if(!DHookEnableDetour(hDetour, true, AllowWitchesInCheckpoints))
			SetFailState("Failed to detour \"CDirector::AllowWitchesInCheckpoints\".");
	}
	else
	{
		hDetour = DHookCreateFromConf(hGamedata, "WitchLocomotion::IsAreaTraversable");
		if(!hDetour)
			SetFailState("Failed to find \"WitchLocomotion::IsAreaTraversable\" signature.");
			
		if(!DHookEnableDetour(hDetour, true, AllowWitchesInCheckpoints))
			SetFailState("Failed to detour \"WitchLocomotion::IsAreaTraversable\".");
	}
	delete hGamedata;
}

stock void SDKCallOnHitByVomitJar(int target, int client)
{
	SDKCall(SDKOnHitByVomitJar, target, client);
}

public MRESReturn AllowWitchesInCheckpoints(Handle hReturn)
{
	if(iWitchInCheckPoints == 0) return MRES_Ignored;
	DHookSetReturn(hReturn, true);
	return MRES_Override;
}


public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bRelentlessWitchIncap 		= 	GetConVarBool(relentlesswitchincap);
	iRelentlessWitchRange  		= 	GetConVarInt(relentlesswitchrange);
	brelentlessextinguish 		= 	GetConVarBool(relentlessextinguish);
	fWitchAttackerDamage			= 	GetConVarFloat(g_hWitchattackerdmg);
	g_iSurvivorMaxIncapCount 	= 	GetConVarInt(g_hSurvivorMaxIncapCount);
	iWitchInCheckPoints  			= 	GetConVarInt(rWitchInCheckPoints);
	bWitch_HarasserSet 				= 	GetConVarBool(rWitch_HarasserSet);
	fWitchCheckDistance 			= 	GetConVarFloat(rWitchCheckDistance);
	iWitchCheckTipMode  			= 	GetConVarInt(rWitchCheckTipMode);
}

public Action Event_WitchIncapacitated(Event event, const char[] event_name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(GetEventInt(event, "userid"));
	int type = GetEventInt(event, "type");
	int IncapAction = GetConVarInt(g_hWitchIncapAction);
	if( IncapAction == 0 || type != 4) return Plugin_Handled;
	if( IsSurvivor(Client) )
	{
		if(IncapAction == 1)
		{
			int count = GetEntProp(Client, Prop_Send, "m_currentReviveCount");
			if( count > g_iSurvivorMaxIncapCount - 1)  return Plugin_Handled;
			SetEntProp(Client, Prop_Send, "m_currentReviveCount", g_iSurvivorMaxIncapCount - 1);
		}
		else ForcePlayerSuicide(Client);
	}
	return Plugin_Handled;
}

public Action Event_WitchSpawn(Event event, const char[] event_name, bool dontBroadcast)
{
	int Witch = GetEventInt(event, "witchid");
	if (IsWitch(Witch) && IsValidEntity(Witch))
	{
		SDKHook(Witch, SDKHook_OnTakeDamage, OnTakeDamage);
		EmitSoundToAll("npc/witch/voice/idle/female_cry_1.wav");
		CreateTimer(1.0, DisplayHintInfo, Witch, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public Action DisplayHintInfo(Handle timer, any iEntity)
{
	if (!IsWitch(iEntity) || !IsValidEntity(iEntity))
	{
		KillTimer(timer);
		return Plugin_Stop;
	}
	char Message[256];
	float iEntityPos[3], PlayerPos[3], Distance, MaxRange = fWitchCheckDistance;
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", iEntityPos);
	for (int Client = 1; Client <= MaxClients; Client++)
	{
		if(!IsClientInGame(Client) || !IsSurvivor(Client) || IsFakeClient(Client)) continue;
		GetClientAbsOrigin(Client, PlayerPos);
		Distance = GetVectorDistance(PlayerPos, iEntityPos);
		if (Distance <= MaxRange)
		{
			if(iWitchCheckTipMode == 1)
			{
				Format(Message, sizeof(Message), "前方发现有 Witch 出没！距离：%.1f", Distance);
				DisplayInstructorHint(iEntity, 0.0, 40.0, MaxRange, true, false, "icon_skull", "", "", false, {255, 0, 0}, Message);
			} else 
			if(iWitchCheckTipMode == 2) DisplayInstructorHint2(Client, MaxRange, "前方发现有 Witch 出没！", "icon_skull", "", {255, 0, 0}, 1);
		}
	}
	return Plugin_Handled;
}

public Action Event_HarasserSet(Event event, const char[] event_name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(GetEventInt(event, "userid"));
	//玩家惊扰提示
	if(IsSurvivor(Client) && bWitch_HarasserSet)
		PrintToChatAll("\x04【害群之马】 \x05%N \x03这个菜逼没事去惹\x05 Witch ！\x03正在被追杀中....", Client);
	return Plugin_Handled;
}

public Action Event_PlayerIncapacitated(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int entity = GetEventInt(event,"attackerentid");
	if (IsWitch(entity) && IsSurvivor(victim))
	{
		if (!bRelentlessWitchIncap)
		{
			int target = GetNearestSurvivorDist(entity);
			if (target <= 0) target = GetNearestIncapSurvivorDist(entity);
			if (target > 0)
			{
				SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_INTENSE);
				WitchAttackFunc(entity, target);
			}
		}
	}
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int entity = GetEventInt(event,"attackerentid");
	if (IsWitch(entity) && IsSurvivor(victim))
	{
		int target = GetNearestSurvivorDist(entity);
		if (target <= 0) target = GetNearestIncapSurvivorDist(entity);
		if (target > 0)
		{
			SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_INTENSE);
			WitchAttackFunc(entity, target);
		}
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int Client)
{
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "witch", false))
		SDKHook(entity, SDKHook_ThinkPost, WitchAttackHook);
}

public Action OnTakeDamage(int Victim, int &Attacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if (brelentlessextinguish && IsWitch(Victim))
	{
		if (iDamagetype & DMG_BURN)
			return Plugin_Handled;
	}
	if(IsWitch(Attacker) && fWitchAttackerDamage != 0.0)
	{
		fDamage = fWitchAttackerDamage;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool IsWitchBurning(int entity)
{
	if (IsWitch(entity))
	{
		int isBurning = GetEntProp(entity, Prop_Send, "m_bIsBurning");
		if (isBurning > 0) return true;
	}
	return false;
}

public void WitchAttackHook(int entity)
{
	if (IsWitch(entity))
	{
		int target = GetNearestSurvivorDist(entity);
		int targetincap = GetNearestIncapSurvivorDist(entity);
		int clone = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		float rage = GetEntPropFloat(entity, Prop_Send, "m_rage");
		float wanderrage = GetEntPropFloat(entity, Prop_Send, "m_wanderrage");
		int sequence = GetEntProp(entity, Prop_Send, "m_nSequence");
		if (target == 0 && targetincap == 0)
		{
			if (IsWitchBurning(entity))
			{
				ExtinguishEntity(entity);
				SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_INTENSE);
				WitchAttackFunc(entity, target);
			}
		}
		else if (sequence == ANIM_WITCH_RUN_ONFIRE || sequence == ANIM_WITCH_RUN_RETREAT || sequence == ANIM_WITCH_RUN_ONFIRE_INT)
		{
			if (target <= 0) target = targetincap;
			if (target > 0)
			{
				if (IsWitchBurning(entity)) ExtinguishEntity(entity);
				SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_INTENSE);
				WitchAttackFunc(entity, target);
			}
		}
		else if (clone > 0 && (rage < 0.4 || wanderrage < 0.4))
		{
			if (target <= 0) target = targetincap;
			if (target > 0)
			{
				SetEntPropFloat(entity, Prop_Send, "m_wanderrage", 1.0);
				SetEntPropFloat(entity, Prop_Send, "m_rage", 1.0);
				SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_INTENSE);
				WitchAttackFunc(entity, target);
			}
		}
	}
}

stock void WitchAttackFunc(int entity, int target)
{
	if (IsWitch(entity))
	{
		SDKCallOnHitByVomitJar(entity, target);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
	}
}

stock int GetNearestSurvivorDist(int entity)
{
	int target = 0;
	if (IsWitch(entity))
	{
		int range = iRelentlessWitchRange;
		float Origin[3], TOrigin[3], distance = 0.0, savedDistance = 0.0;
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i) && !IsPlayerIncap(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (range >= distance)
				{
					if (savedDistance == 0.0 || savedDistance > distance)
					{
						savedDistance = distance;
						target = i;
					}
				}
			}
		}
	}
	return target;
}

stock int GetNearestIncapSurvivorDist(int entity)
{
	int target = 0;
	if (IsWitch(entity))
	{
		int range = iRelentlessWitchRange;
		float Origin[3], TOrigin[3], distance = 0.0, savedDistance = 0.0;
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
		for (int i = 1; i <= MaxClients; i++)
    {
			if (IsSurvivor(i) && IsPlayerAlive(i) && IsPlayerIncap(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (range >= distance)
				{
					if (savedDistance == 0.0 || savedDistance > distance)
					{
						savedDistance = distance;
						target = i;
					}
				}
			}
		}
	}
	return target;
}

stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2) return true;
	return false;
}

stock bool IsPlayerIncap(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) || GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) return true;
	return false;
}

stock bool IsWitch(int entity)
{
	if (entity > 32 && IsValidEdict(entity) && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false)) return true;
	}
	return false;
}

/* 提示参数——1 */
stock void DisplayInstructorHint(int target, float fTime, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char[] sText)
{
	int entity =  CreateEntityByName("env_instructor_hint");
	static char sBuffer[32];
	float vPos[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
	DispatchKeyValueVector(entity, "origin", vPos);
	GetEntPropString(target, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));
	if(strlen(sBuffer) == 0)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "targethint%d", target);
		DispatchKeyValue(target, "targetname", sBuffer);
	}
	DispatchKeyValue(entity, "hint_target", sBuffer);
	DispatchKeyValue(entity, "hint_name", sBuffer);
	DispatchKeyValue(entity, "hint_replace_key", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);
	DispatchKeyValue(entity, "hint_static", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fTime));
	DispatchKeyValue(entity, "hint_timeout", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));
	DispatchKeyValue(entity, "hint_icon_offset", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));
	DispatchKeyValue(entity, "hint_range", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);
	DispatchKeyValue(entity, "hint_nooffscreen", sBuffer);
	DispatchKeyValue(entity, "hint_icon_onscreen", sIconOnScreen);
	DispatchKeyValue(entity, "hint_icon_offscreen", sIconOffScreen);
	DispatchKeyValue(entity, "hint_binding", sCmd);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", bShowTextAlways);
	DispatchKeyValue(entity, "hint_forcecaption", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
	DispatchKeyValue(entity, "hint_color", sBuffer);
	DispatchKeyValue(entity, "hint_caption", sText);
	DispatchKeyValue(entity, "hint_activator_caption", sText);
	DispatchKeyValue(entity, "hint_flags", "0");
	DispatchKeyValue(entity, "hint_display_limit", "0");
	DispatchKeyValue(entity, "hint_suppress_rest", "1");// no show in face
	DispatchKeyValue(entity, "hint_auto_start", "1");
	DispatchKeyValue(entity, "hint_allow_nodraw_target", "true");
	DispatchKeyValue(entity, "hint_instance_type", "2");//2
	DispatchSpawn(entity);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target, entity);
	AcceptEntityInput(entity, "ShowHint");
	
	if (IsValidEntity(entity))
		CreateTimer(0.5, RemoveInstructorHint, entity);
}

public Action RemoveInstructorHint(Handle h_Timer, any entity)
{
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "stop");
		AcceptEntityInput(entity, "kill");
		RemoveEdict(entity);
	}
	return Plugin_Continue;
}

/* 提示参数——2 */
stock void DisplayInstructorHint2(int client, float fRange, char s_Message[256], char[] s_Icon, char[] s_Binding, int color[3], int showtime=5)
{
	if (IsClientInGame(client)) ClientCommand(client, "gameinstructor_enable 1");
	
	Handle h_RemovePack;
	char s_TargetName[32], sTemp[64];
	
	int i_Ent = CreateEntityByName("env_instructor_hint");
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", client);
	ReplaceString(s_Message, sizeof(s_Message), "\n", "");
	DispatchKeyValue(client, "targetname", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
	Format(sTemp, sizeof(sTemp), "%d",showtime);	
	DispatchKeyValue(i_Ent, "hint_timeout",sTemp );
	
	FormatEx(sTemp, sizeof(sTemp), "%d", RoundToFloor(fRange));
	DispatchKeyValue(i_Ent, "hint_range", sTemp);
	
	Format(sTemp, sizeof(sTemp), "%d %d %d",color[0],color[1],color[2]);
	DispatchKeyValue(i_Ent, "hint_color", sTemp);
	DispatchKeyValue(i_Ent, "hint_caption", s_Message);
	if (StrEqual(s_Icon,"use_binding") && !StrEqual(s_Binding,""))
	{
		DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding");	
		DispatchKeyValue(i_Ent, "hint_binding", s_Binding);
	}
	else DispatchKeyValue(i_Ent, "hint_icon_onscreen", s_Icon);	
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "ShowHint");
	h_RemovePack = CreateDataPack();
	WritePackCell(h_RemovePack, client);
	WritePackCell(h_RemovePack, i_Ent);
	CreateTimer(float(showtime), RemoveInstructorHint2, h_RemovePack);
}

public Action RemoveInstructorHint2(Handle h_Timer, Handle h_Pack)
{
	int i_Ent, i_Client;
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	if (!i_Client || !IsClientInGame(i_Client)) return Plugin_Handled;
	if (IsValidEntity(i_Ent)) RemoveEdict(i_Ent);
	DispatchKeyValue(i_Client, "targetname", "");
	return Plugin_Continue;
}