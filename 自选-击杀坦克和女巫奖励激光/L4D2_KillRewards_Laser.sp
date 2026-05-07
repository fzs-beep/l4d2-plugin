#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

/* 感染者CLASS */
#define CLASS_SMOKER		1
#define CLASS_BOOMER		2
#define CLASS_HUNTER		3
#define CLASS_SPITTER	4
#define CLASS_JOCKEY		5
#define CLASS_CHARGER	6
#define CLASS_WITCH		7
#define CLASS_TANK		8

#define WITCH_LEN 32
new witchCUR = 0;
new witchID[WITCH_LEN];

new Handle:KillRewards_Switch1 = INVALID_HANDLE;
new Handle:KillRewards_Switch2 = INVALID_HANDLE;
new Handle:KillRewards_Mode = INVALID_HANDLE;
new Handle:KillRewards_AIBot = INVALID_HANDLE;

new Player[MAXPLAYERS+1];
new DamageToTank[MAXPLAYERS+1][MAXPLAYERS+1];
new DamageToWitch[MAXPLAYERS+1][WITCH_LEN];
new PlayerDamageTank[MAXPLAYERS+1];
new PlayerDamageWitch[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "击杀Tank或Witch奖励",
	description = "击杀Tank或Witch给予玩家奖励",
	author = "藤野深月",
	version = PLUGIN_VERSION,
	url = "null"
};

public OnPluginStart()
{
	/* 插件参数 */
	CreateConVar("L4D2_KillRewards_Version", PLUGIN_VERSION, "[L4D2] 击杀Tank或Witch奖励 插件版本");
	
	KillRewards_Mode		= CreateConVar("L4D2_KillRewards_Mode", 	"2", "设置奖励模式 (0=禁用 1=击杀者 2=伤害最高)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	KillRewards_AIBot		= CreateConVar("L4D2_KillRewards_AIBot", 	"0", "奖励是否计算AI电脑玩家？ (0=计算 1=过滤)\n启用 过滤 后自动忽略 AI 电脑玩家\nAI玩家无法获得 击杀 或 伤害最高 奖励", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	KillRewards_Switch1	= CreateConVar("L4D2_KillRewards_Switch1", "1", "击杀[伤害最高] Tank 给予玩家激光？ (0=禁用 1=开启)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	KillRewards_Switch2	= CreateConVar("L4D2_KillRewards_Switch2", "1", "击杀[伤害最高] Witch 给予玩家激光？ (0=禁用 1=开启)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookEvent("infected_hurt",		Event_InfectedHurt);
	HookEvent("witch_killed",			Event_WitchKilled);
	HookEvent("tank_killed",			Event_TankKilled);
	HookEvent("player_hurt",			Event_PlayerHurt);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("witch_spawn", OnWitchSpawn);
	
	AutoExecConfig(true, "L4D2_KillRewards_Laser");
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	witchCUR = 0;
	for(new i=0; i < WITCH_LEN; i++)
	{
		witchID[i] = -1;
	}
	return Plugin_Continue;
}

public Action:OnWitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "witchid");
	witchID[witchCUR] = entity;
	witchCUR = (witchCUR + 1) % WITCH_LEN;
	
	return Plugin_Continue;
}

/* Witch 伤害计算 */
public Action:Event_InfectedHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damageDone = GetEventInt(event, "amount");
	
	if (GetConVarInt(KillRewards_Mode) == 2)
	{
		new entity = GetEventInt(event, "entityid");
		for(new i=0; i < WITCH_LEN; i++)
		{
			if(witchID[i] == entity)
			{
				DamageToWitch[attacker][i] += damageDone;
			}
		}
	}
	return Plugin_Handled;
}

/* Witch死亡 */
public Action:Event_WitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetConVarInt(KillRewards_Switch2) == 1)
	{
		if (GetConVarInt(KillRewards_Mode) == 1)
		{
			if (IsValidPlayer(attacker) && GetClientTeam(attacker) == 2)
			{
				CheatCommand(attacker, "upgrade_add", "laser_sight");
				PrintToChatAll("\x04[提示]\x03玩家 \x05%N \x03击杀 \x05Witch \x03获得激光奖励.", attacker);
			}
		}
	}
	
	new entity = GetEventInt(event, "witchid");
	//排名奖励
	if (GetConVarInt(KillRewards_Switch2) == 1)
	{
		if (GetConVarInt(KillRewards_Mode) == 2)
		{
			//执行排名
			new index=0;
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsValidPlayer(client) && GetClientTeam(client) == 2)
				{
					Player[index++] = client;
					//对Witch伤害进行赋值
					for(new Witch = 0; Witch < WITCH_LEN; Witch++)
					{
						if(witchID[Witch] == entity)
						{
							PlayerDamageWitch[client] = DamageToWitch[client][Witch];
						}
					}
				}
			}
			SortCustom1D(Player, sizeof(Player), SortKillWitchInfo);
			//发放奖励
			for(int i = 0; i < index; i++)
			{
				if(IsClientInGame(Player[i]) && GetClientTeam(Player[i]) == 2)
				{
					if(i == 0 && PlayerDamageWitch[Player[i]] > 0)
					{
						CheatCommand(Player[i], "upgrade_add", "laser_sight");
						PrintToChatAll("\x04[提示]\x03玩家 \x05%N \x03对 \x05Witch \x03造成伤害最高, 获得激光奖励.", Player[i]);
					}
				}
			}
		}
	}
	//清除数据
	for(new Witch = 0; Witch < WITCH_LEN; Witch++)
	{
		if(witchID[Witch] == entity)
		{
			CreateTimer(1.0, ResetPlayerWitchDamage, Witch);
		}
	}
	return Plugin_Handled;
}
//执行伤害清除
public Action:ResetPlayerWitchDamage(Handle:timer, any:Client)
{
	witchID[Client] = -1;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(PlayerDamageWitch[i] > 0)
		{
			PlayerDamageWitch[i] = 0;
			DamageToWitch[i][Client] = 0;
		}
	}
}

public int SortKillWitchInfo(int elem1, int elem2, const char[] array, Handle hndl)
{
	if (PlayerDamageWitch[elem1] != PlayerDamageWitch[elem2])
	{
		if (PlayerDamageWitch[elem1] > PlayerDamageWitch[elem2])
			return -1;
		else if (PlayerDamageWitch[elem2] > PlayerDamageWitch[elem1])
			return 1;
		else if (elem1 > elem2) 
			return -1;
		else if (elem2 > elem1) 
			return 1;
	}
	return 0;
}

/* 玩家受伤 */
public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim	 = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damageDone = GetEventInt(event, "dmg_health");
	new eventhealth = GetEventInt(event, "health");
	new bool:IsVictimDead;
	
	if(eventhealth <= 0)	
		IsVictimDead = true;
	else
		IsVictimDead = false;
	
	if (GetConVarInt(KillRewards_Mode) == 2)
	{
		/* 坦克伤害计算 */
		if(IsValidPlayer(attacker, false) && GetClientTeam(victim) == 3)
		{
			new ZombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			
			if(ZombieClass == CLASS_TANK && !IsVictimDead)
			{
				DamageToTank[attacker][victim] += damageDone;
			}
		}
	}
	return Plugin_Handled;
}

/* Tank死亡 */
public Action:Event_TankKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (GetConVarInt(KillRewards_Switch1) == 1)
	{
		if (GetConVarInt(KillRewards_Mode) == 1)
		{
			if (IsValidPlayer(attacker) && GetClientTeam(attacker) == 2)
			{
				CheatCommand(attacker, "upgrade_add", "laser_sight");
				PrintToChatAll("\x04[提示]\x03玩家 \x05%N \x03击杀 \x05Tank \x03获得激光奖励.", attacker);
			}
		}
		if (GetConVarInt(KillRewards_Mode) == 2)
		{
			//执行排名
			new index=0;
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsValidPlayer(client) && GetClientTeam(client) == 2)
				{
					Player[index++] = client;
					PlayerDamageTank[client] = DamageToTank[client][victim];
				}
			}
			SortCustom1D(Player, sizeof(Player), SortKillTankInfo);
			//发放奖励
			for(int i = 0; i < index; i++)
			{
				if(IsClientInGame(Player[i]) && GetClientTeam(Player[i]) == 2)
				{
					if(i == 0 && PlayerDamageTank[Player[i]] > 0)
					{
						CheatCommand(Player[i], "upgrade_add", "laser_sight");
						CreateTimer(1.0, ResetPlayerTankDamage);
						PrintToChatAll("\x04[提示]\x03玩家 \x05%N \x03对 \x05Tank \x03造成伤害最高, 获得激光奖励.", Player[i]);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

//执行伤害清除
public Action:ResetPlayerTankDamage(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		PlayerDamageTank[i] = 0;
		for (new j = 1; j <= MaxClients; j++)
		{
			DamageToTank[i][j] = 0;
		}
	}
}

public int SortKillTankInfo(int elem1, int elem2, const char[] array, Handle hndl)
{
	if (PlayerDamageTank[elem1] != PlayerDamageTank[elem2])
	{
		if (PlayerDamageTank[elem1] > PlayerDamageTank[elem2])
			return -1;
		else if (PlayerDamageTank[elem2] > PlayerDamageTank[elem1])
			return 1;
		else if (elem1 > elem2) 
			return -1;
		else if (elem2 > elem1) 
			return 1;
	}
	return 0;
}

/* 判断玩家是否有效 */
stock bool:IsValidPlayer(Client, bool:AllowBot = true, bool:AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients)
		return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return false;
	//设置过滤AI玩家
	if (GetConVarInt(KillRewards_AIBot) == 1)
	{
		if (!AllowBot)
		{
			if (IsFakeClient(Client))
				return false;
		}
	}
	
	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
			return false;
	}	
	return true;
}

/* 作弊参数 */
stock CheatCommand(Client, const String:command[], const String:arguments[])
{
	if (!Client) return;
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

stock bool:IsWitch(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}
