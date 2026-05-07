#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#pragma semicolon 1
#pragma newdecls required

#define CVAR_FLAGS 					FCVAR_NOTIFY
#define TEAM_SPECTATOR 	1
#define TEAM_SURVIVOR 	2
#define SERVER_INDEX 	0
#define NO_INDEX 		-1
#define NO_PLAYER 		-2
#define BLUE_INDEX 		2
#define RED_INDEX 		3
#define NON_FLAMMABLE 	1
#define FLAMMABLE 		2
#define FULL_ADS 		1
#define LIFE_STATUS 	2
#define IGNITION_STATUS 3

static ConVar hCvar_Enabled;
static ConVar hCvar_IgnitionModes;
static ConVar hCvar_TankHpMulti;
static ConVar hCvar_BasicTankHP;
static ConVar hCvar_TankIncludeBots;
static ConVar hCvar_TankSurvivorMultipler;
static ConVar hCvar_EnabledAds;
static ConVar hCvar_Difficult;
ConVar hBarLEN;
ConVar hCharHealth;
ConVar hCharDamage;
ConVar hShowType;
ConVar hShowNum;
ConVar hTank;

static bool bCvar_Enabled;
static bool bCvar_TankIncludeBots;
static bool bCvar_TankSurvivorMultipler;
static bool bLeft4DeadTwo;
static float TankBurnIndex;
static float fCvar_TankHpMulti;
static int iCvar_IgnitionModes;
static int iCvar_EnabledAds;
static int BasicTankHP;

int prevMAX[MAXPLAYERS+1];
int prevHP[MAXPLAYERS+1];
int nCharLength;
int nShowType;
int nShowNum;
int nShowTank;

char sCharHealth[8] = "#";
char sCharDamage[8] = "=";

public Plugin myinfo =
{
	name        = "坦克|自动控血20亿上限",
	author      = "Ernecio (Satanael)，NiCo-op，24の节气缝合",
	description = "Multiply HP of the Tank according to the number of players.",
	version     = "2.0",
	url         = "-"
}

public APLRes AskPluginLoad2( Handle hMyself, bool bLate, char[] sError, int Error_Max )
{
	EngineVersion Engine = GetEngineVersion();
	if ( Engine != Engine_Left4Dead && Engine != Engine_Left4Dead2 /* || !IsDedicatedServer() */ )
	{
		strcopy( sError, Error_Max, "This plugin \"HP Tank Multiplier\" only runs in the \"Left 4 Dead 1/2\" Games!" );
		return APLRes_SilentFailure;
	}
	
	bLeft4DeadTwo = ( Engine == Engine_Left4Dead2 );
	return APLRes_Success;
}

public void OnPluginStart()
{	/* 魔改的话8人 最好2w血 0.2系数     公式：总血量=血量基数+（总人数-4）x 系数 x 血量基数*/
	hCvar_Enabled 				= CreateConVar("director_enabled_plugin", 		"1", 		"Enables/Disables The plugin. 0 = Plugin OFF, 1 = Plugin ON.", CVAR_FLAGS);
	hCvar_IgnitionModes 		= CreateConVar("director_ignition_modes", 		"2", 		"启用/禁用坦克着火。\n0 =什么都不做。允许坦克不着火，但他接触火会受到伤害。n2 =允许坦克根据他的生命数量着火。", CVAR_FLAGS);
	hCvar_TankHpMulti   		= CreateConVar("director_tank_hpmultiplier",	"0.5",		"血量系数.", CVAR_FLAGS);
	hCvar_BasicTankHP 			= CreateConVar("director_basic_tankhp", 		"1000000", 	"血量基数 总血量=血量基数+（总人数-4）x 系数 x 血量基数", CVAR_FLAGS);
	hCvar_TankIncludeBots 		= CreateConVar("director_include_bots", 		"0", 		"把机器人加入乘数。\n0 =不包括机器人。\n1 =包括机器人。",CVAR_FLAGS);
	hCvar_TankSurvivorMultipler = CreateConVar("director_survivor_multipler", 	"1", 		"如果有更多的幸存者，增加坦克的HP，或者从一个幸存者开始。\n0 =从1开始相乘。\n1 =从4开始乘。",CVAR_FLAGS);
	hCvar_EnabledAds			= CreateConVar("director_enabled_ads", 			"1", 		"在聊天中禁用坦克生命状态广告。\n0 = Ads关闭。\n1 =显示完整Ads。\n2 =只显示运行状况。\n3 =只显示点火状态", CVAR_FLAGS);
	hCvar_Difficult 			= FindConVar("z_difficulty");
	hBarLEN 					= CreateConVar("director_infectedhp_bar", 		"20",		"生命条长度(默认100). 最小:10 / 最大:200", CVAR_FLAGS);
	hCharHealth 				= CreateConVar("director_infectedhp_health", 	"|",		"设置血量符号.", CVAR_FLAGS );
	hCharDamage 				= CreateConVar("director_infectedhp_damage", 	" ", 		"设置去血符号.", CVAR_FLAGS );
	hShowType 					= CreateConVar("director_infectedhp_type", 		"0", 		"设置血条的显示位置和类型. 0=屏幕中心 1=屏幕中下.", CVAR_FLAGS);
	hShowNum 					= CreateConVar("director_infectedhp_num", 		"0", 		"启用血量数字显示? 0=禁用, 1=启用.", CVAR_FLAGS);
	hTank 						= CreateConVar("director_infectedhp_tank", 		"0", 		"启用坦克血条显示? 0=禁用, 1=启用.", CVAR_FLAGS);

	hCvar_Enabled.AddChangeHook( Event_ConVarChanged );
	hCvar_IgnitionModes.AddChangeHook( Event_ConVarChanged );
	hCvar_TankHpMulti.AddChangeHook( Event_ConVarChanged ); 
	hCvar_BasicTankHP.AddChangeHook( Event_ConVarChanged );
	hCvar_TankIncludeBots.AddChangeHook( Event_ConVarChanged );
	hCvar_TankSurvivorMultipler.AddChangeHook( Event_ConVarChanged );
	hCvar_EnabledAds.AddChangeHook( Event_ConVarChanged );
	hCvar_Difficult.AddChangeHook( Event_OnCVarChange );
	
	HookEvent("round_start",			Event_RoundStart, 	EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", 			Event_TankSpawn, 	EventHookMode_Post);
	HookEvent("player_death",			Event_PlayerDeath, 	EventHookMode_Pre);
	HookEvent("player_hurt", 			Event_PlayerHurt);
	HookEvent("player_spawn", 			Event_InfectedSpawn, EventHookMode_Post);

	AutoExecConfig( true, "TankHP" );
}

public void OnConfigsExecuted()
{
	GetCvars();
	DFF_OnCvarChange();
}

void Event_ConVarChanged( Handle hCvar, const char[] sOldValue, const char[] sNewValue )
{
	GetCvars();
}

void Event_OnCVarChange( Handle hCvar, const char[] sOldValue, const char[] sNewValue )
{
	DFF_OnCvarChange();
}

void GetCvars()
{
	bCvar_Enabled = hCvar_Enabled.BoolValue;
	iCvar_IgnitionModes = hCvar_IgnitionModes.IntValue;

	fCvar_TankHpMulti = hCvar_TankHpMulti.FloatValue;
	BasicTankHP = hCvar_BasicTankHP.IntValue;
	bCvar_TankIncludeBots = hCvar_TankIncludeBots.BoolValue;
	bCvar_TankSurvivorMultipler = hCvar_TankSurvivorMultipler.BoolValue;
	iCvar_EnabledAds = hCvar_EnabledAds.IntValue;
}

void DFF_OnCvarChange()
{
	static char sBuffer[64];
	hCvar_Difficult.GetString( sBuffer, sizeof( sBuffer ) );
	
	if ( strncmp( sBuffer, "Easy", sizeof( sBuffer ), false ) == 0 ) TankBurnIndex = 0.011666;
	else if ( strncmp( sBuffer, "Hard", sizeof( sBuffer ), false ) == 0 ) TankBurnIndex = 0.013333;
	else if ( strncmp( sBuffer, "Impossible", sizeof( sBuffer ), false ) == 0 ) TankBurnIndex = 0.014166;
	else TankBurnIndex = 0.0125;
}

public void Event_RoundStart( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	for( int i = 1; i <= MaxClients; i ++ )
		if( IsClientInGame( i ) )
			SDKUnhook( i, SDKHook_OnTakeDamage, OnTakeDamage );

	nShowTank = 0;
	for(int i = 0; i < MAXPLAYERS + 1; i ++)
	{
		prevMAX[i] = -1;
		prevHP[i] = -1;
	}
}

public void Event_TankSpawn( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if ( !bCvar_Enabled ) return;
	
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( client && IsClientInGame( client ) )
		CreateTimer( 0.3, TankSpawnTimer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
}

public void Event_PlayerDeath( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( client ) SDKUnhook( client, SDKHook_OnTakeDamage, OnTakeDamage );
}

public Action TankSpawnTimer( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if( client == 0 || !IsTank( client ) || !IsClientInGame( client ) || !IsClientConnected( client ) ) return;
	
	static char sBuffer[64];
	hCvar_Difficult.GetString( sBuffer, sizeof( sBuffer ) );
	
	int ExtraSurvivors = bCvar_TankSurvivorMultipler ? ( GetSurvivorTeam() - 4 ) : GetSurvivorTeam();
	ExtraSurvivors = ( ExtraSurvivors > 0 ) ? ExtraSurvivors : 0;
	
	float TankHp_Multi = 1 + fCvar_TankHpMulti * ExtraSurvivors;
	int TankHP = RoundFloat( BasicTankHP * TankHp_Multi );
	// if ( TankHP > 65535 ) TankHP = 65535;
	float TankBurnTime = float( TankHP ) * TankBurnIndex;
	int TankBurnHP = RoundToCeil( TankBurnTime );
	
	SetEntProp( client, Prop_Data, "m_iMaxHealth", TankHP );
	SetEntProp( client, Prop_Data, "m_iHealth", TankHP );
	
	/** 	修复坦克燃烧的时间	 **/
	if ( iCvar_IgnitionModes == NON_FLAMMABLE )
		SDKHook( client, SDKHook_OnTakeDamage, OnTakeDamage );
	
	if ( iCvar_IgnitionModes == FLAMMABLE && strncmp( sBuffer, "Easy", sizeof( sBuffer ), false ) == 0 ) FindConVar(bLeft4DeadTwo ? "tank_burn_duration" : "tank_burn_duration_normal").IntValue = TankBurnHP;
	else if ( iCvar_IgnitionModes == FLAMMABLE && strncmp( sBuffer, "Hard", sizeof( sBuffer ), false ) == 0 ) FindConVar("tank_burn_duration_hard" ).IntValue = TankBurnHP;
	else if ( iCvar_IgnitionModes == FLAMMABLE && strncmp( sBuffer, "Impossible", sizeof( sBuffer ), false ) == 0 ) FindConVar("tank_burn_duration_expert" ).IntValue = TankBurnHP;
	else if ( iCvar_IgnitionModes == FLAMMABLE ) FindConVar(bLeft4DeadTwo ? "tank_burn_duration" : "tank_burn_duration_normal").IntValue = TankBurnHP;
	
	switch( iCvar_EnabledAds ) 
	{
		case FULL_ADS: 
		{
			CPrintToChatAll( "	{green}[{red}%N{Green}] {orange}HP {red}%i", client, TankHP );
			
			if( iCvar_IgnitionModes == FLAMMABLE )
				CPrintToChatAll( "	{Green}[{red}%N{Green}] {orange}最大燃烧时间 {red}%i {orange} 秒", client, TankBurnHP );
			else if( iCvar_IgnitionModes == NON_FLAMMABLE )
				CPrintToChatAll( "	{Green}[{red}%N{Green}] Takes Fire Damage But Doesn't {orange} {red}Burn", client );
		}
		case LIFE_STATUS:
		{
			CPrintToChatAll( "	{Green}[{red}%N{Green}] {orange}HP {Green}%i", client, TankHP );
		}
		case IGNITION_STATUS:
		{
			if( iCvar_IgnitionModes == FLAMMABLE )
				CPrintToChatAll( "	{Green}[{red}%N{Green}] {orange}最大燃烧时间 {red}%i {orange} 秒", client, TankBurnHP );
			else if( iCvar_IgnitionModes == NON_FLAMMABLE )
				CPrintToChatAll( "	{Green}[{red}%N{Green}] Takes Fire Damage But Doesn't {orange} {red}Burn", client );
		}
	}
}

public Action OnTakeDamage( int client, int &attacker, int &inflictor, float &damage, int &damagetype )
{
	if( damage > 0.0 && IsValidClient( client ) && ( damagetype == DMG_BURN || damagetype == DMG_PREVENT_PHYSICS_FORCE + DMG_BURN || damagetype == DMG_DIRECT + DMG_BURN ) )
	{		
		HurtTarget( attacker, 25.0, DMG_NERVEGAS, client );
		return Plugin_Handled;
	}
	
	return Plugin_Changed;
}
public void Event_PlayerHurt( Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!attacker || !IsClientConnected(attacker) || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2) return;
	
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!client || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 3) return;

	char class[128];
	GetClientModel(client, class, sizeof(class));

	if(!nShowTank || (nShowTank && StrContains(class, "tank", false) == -1 && StrContains(class, "hulk", false) == -1)) return;

	int maxBAR = hBarLEN.IntValue;
	int nowHP = GetEntProp(client, Prop_Data, "m_iHealth");
	int maxHP = GetEntProp(client, Prop_Data, "m_iMaxHealth");

	if(nowHP <= 0 || prevMAX[client] < 0) 	nowHP = 0;
	
	if(nowHP && nowHP > prevHP[client]) 	nowHP = prevHP[client];
	else 									prevHP[client] = nowHP;
	
	if(maxHP < prevMAX[client]) 			maxHP = prevMAX[client];
	
	if(maxHP < nowHP){
		maxHP = nowHP;
		prevMAX[client] = nowHP;
	}
	
	if(maxHP < 1) maxHP = 1;

	char clName[MAX_NAME_LENGTH];
	GetClientName(client, clName, sizeof(clName));
	ShowHealthGauge(attacker, maxBAR, maxHP, nowHP, clName);
}
public void Event_InfectedSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	GetConfig();

	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if( client > 0 && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		TimerSpawn(INVALID_HANDLE, client);
		CreateTimer(0.5, TimerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action TimerSpawn(Handle timer, any client)
{
	if(IsValidEntity(client))
	{
		int val = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		prevMAX[client] = ( val <= 0 ) ? val : 1;
		prevHP[client] = 2000000000;//int值上限21亿
	}
	return Plugin_Stop;
}
void GetConfig()
{
	char bufA[8];
	char bufB[8];
	hCharHealth.GetString( bufA, sizeof( bufA ) );
	hCharDamage.GetString( bufB, sizeof( bufB ) );
	nCharLength = strlen(bufA);
	if(!nCharLength || nCharLength != strlen(bufB))
	{
		nCharLength = 1;
		sCharHealth[0] = '#';
		sCharHealth[1] = '\0';
		sCharDamage[0] = '=';
		sCharDamage[1] = '\0';
	}
	else
	{
		strcopy(sCharHealth, sizeof(sCharHealth), bufA);
		strcopy(sCharDamage, sizeof(sCharDamage), bufB);
	}

	nShowType = hShowType.BoolValue;
	nShowNum = hShowNum.BoolValue;
	nShowTank = hTank.BoolValue;
}

void ShowHealthGauge(int client, int maxBAR, int maxHP, int nowHP, char[] clName)
{
	int percent = RoundToCeil((float(nowHP) / float(maxHP)) * float(maxBAR));
	int i; 
	int length = maxBAR * nCharLength + 2;
	static char showBAR[256];
	
	showBAR[0] = '\0';
	for(i = 0; i < percent && i < maxBAR; i ++) StrCat(showBAR, length, sCharHealth);
	for(; i < maxBAR; i ++) 					StrCat(showBAR, length, sCharDamage);

	if(nShowType)
	{
		if(!nShowNum) 	PrintHintText(client, "HP: -%s- %s", showBAR, clName);
		else 			PrintHintText(client, "HP: -%s- [%d / %d]  %s", showBAR, nowHP, maxHP, clName);
	}
	else
	{
		if(!nShowNum) 	PrintCenterText(client, "HP: -%s- %s", showBAR, clName);
		else 			PrintCenterText(client, "HP: -%s- [%d / %d]  %s", showBAR, nowHP, maxHP, clName);
	}
}

void HurtTarget( int attacker, float fDamage, int DMGType, int victim )
{
	if( victim > 0 /*&& attacker > 0*/ )
	{
		char sDamage[16];
		char sDMGType[16];
		FloatToString( fDamage, sDamage, sizeof( sDamage ));
		IntToString( DMGType, sDMGType, sizeof( sDMGType ));
		
		int PointHurt = CreateEntityByName( "point_hurt" );
		if( PointHurt )
		{
			DispatchKeyValue( victim, "targetname", "hurtme" );
			DispatchKeyValue( PointHurt, "DamageTarget", "hurtme" );
			DispatchKeyValue( PointHurt, "Damage", sDamage );
			DispatchKeyValue( PointHurt, "DamageType", sDMGType );
			DispatchKeyValue( PointHurt, "classname", "weapon_rifle" );
			DispatchSpawn( PointHurt );
			AcceptEntityInput( PointHurt, "Hurt",( attacker > 0 ) ? attacker : -1 );
			DispatchKeyValue( PointHurt, "classname", "point_hurt" );
			DispatchKeyValue( victim, "targetname", "donthurtme" );
			RemoveEdict( PointHurt );
		}
	}
}

int GetSurvivorTeam()
{
	return GetTeamPlayers( TEAM_SURVIVOR, bCvar_TankIncludeBots );
}

int GetTeamPlayers( int Team, bool bIncludeBots )
{
	int Players = 0;
	for ( int i = 1; i <= MaxClients; i ++ )
	{
		if ( IsClientInGame( i ) && GetClientTeam( i ) == Team && IsPlayerAlive( i ) )
		{
			if( IsFakeClient( i ) && !bIncludeBots )
				continue;
			
			if( GetIdlePlayer( i ) && !bIncludeBots )
				continue;
			
			Players ++;
		}
	}
	return Players;
}

stock int GetIdlePlayer( int bot )
{
	if ( IsClientInGame( bot ) && GetClientTeam( bot ) == TEAM_SURVIVOR && IsPlayerAlive( bot ) && IsFakeClient( bot ) )
	{
		char sNetClass[12];
		GetEntityNetClass( bot, sNetClass, sizeof( sNetClass ) );

		if ( strcmp( sNetClass, "SurvivorBot" ) == 0 )
		{
			int client = GetClientOfUserId( GetEntProp( bot, Prop_Send, "m_humanSpectatorUserID" ) );	
			if( client > 0 && IsClientInGame( client ) && GetClientTeam( client ) == TEAM_SPECTATOR )
			{
				return client;
			}
		}
	}
	
	return 0;
}

stock bool IsValidClient(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) )
		return true;
	
	return false;
}

stock bool IsPlayerIncapped( int client )
{
	if ( GetEntProp( client, Prop_Send, "m_isIncapacitated", 1 ) ) 
		return true;
		
	return false;
}

stock bool IsTank( int client )
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) && GetClientTeam( client ) == 3 )
		if( GetEntProp( client, Prop_Send, "m_zombieClass" ) == ( bLeft4DeadTwo ? 8 : 5 ) )
			return true;
	
	return false;
}