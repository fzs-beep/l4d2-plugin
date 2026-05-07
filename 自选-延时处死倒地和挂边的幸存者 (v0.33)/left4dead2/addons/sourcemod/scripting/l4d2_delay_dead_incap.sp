#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define CVAR_FLAGS		FCVAR_NOTIFY

int
    Dead_Fallen_Type,
	Dead_Falling_Type,
	Dead_Fallen_Rule,
	Dead_Falling_Rule,
	Dead_Fallen_Time,
	Dead_Falling_Time,
	Dead_Fallen_View,
	Dead_Falling_View;

float
    Dead_Fallen_Range,
	Dead_Falling_Range,
	Dead_Fallen_Health,
	Dead_Falling_Health;

ConVar
    GDead_Fallen_Type,
	GDead_Falling_Type,
	GDead_Fallen_Rule,
	GDead_Falling_Rule,
	GDead_Fallen_Range,
	GDead_Falling_Range,
	GDead_Fallen_Health,
	GDead_Falling_Health,
	GDead_Fallen_Time,
	GDead_Falling_Time,
	GDead_Fallen_View,
	GDead_Falling_View;

int
    incap_player_health[32],
	incap_player_timer[32];

bool
    player_canfalling[32];

Handle
    player_dead[32];

public Plugin myinfo =
{
	name        = "l4d2_delay_dead_incap",
	author      = "77",
	description = "延时处死倒地和挂边的幸存者.",
	version     = "0.33"
};

public void OnPluginStart()
{
	GDead_Fallen_Type		= CreateConVar("l4d2_ddi_dead_fallen_a_type",		"0",		"倒地处死类型. (0 = 不处死, 1 = 处死, 2 = 倒地即死)", CVAR_FLAGS, true, 0.0, true, 2.0);
	GDead_Fallen_Rule		= CreateConVar("l4d2_ddi_dead_fallen_b_rule",		"1",		"倒地处死规则. \n 0 = 其他幸存者均无行动能力\n 1 = 被特感控制且周围一定距离内无其他幸存者\n 2 = 周围一定距离内无其他幸存者\n 3 = 无条件", CVAR_FLAGS, true, 0.0, true, 3.0);
	GDead_Fallen_Range		= CreateConVar("l4d2_ddi_dead_fallen_c_range",		"800.0",	"倒地处死距离. (仅限处死规则为1或者2时生效)", CVAR_FLAGS, true, 100.0);
	GDead_Fallen_Health		= CreateConVar("l4d2_ddi_dead_fallen_d_health",		"100.0",	"倒地处死血限. \n 0.0 = 任何血量都可以直接处死\n 0.01 ~ 0.99 = 血量小于等于这个百分比才会处死 \n >= 1.0 血量小于等于这个数才会处死", CVAR_FLAGS, true, 0.0);
	GDead_Fallen_Time		= CreateConVar("l4d2_ddi_dead_fallen_e_time",		"15",		"倒地处死时间. (0 = 立即处死)", CVAR_FLAGS, true, 0.0);
	GDead_Fallen_View		= CreateConVar("l4d2_ddi_dead_fallen_f_view",		"0",		"倒地处死提示. (-1 = 不提示, 0 = 正常提示, 大于0 = 最后N秒进行提示)", CVAR_FLAGS, true, -1.0);
	GDead_Falling_Type		= CreateConVar("l4d2_ddi_dead_falling_h_type",		"0",		"挂边处死类型. (0 = 不处死, 1 = 处死, 2 = 自由落体, 3 = 挂边即死)", CVAR_FLAGS, true, 0.0, true, 3.0);
	GDead_Falling_Rule		= CreateConVar("l4d2_ddi_dead_falling_i_rule",		"1",		"挂边处死规则. \n 0 = 其他幸存者均无行动能力\n 1 = 周围一定距离内无其他幸存者\n 2 = 无条件", CVAR_FLAGS, true, 0.0, true, 3.0);
	GDead_Falling_Range		= CreateConVar("l4d2_ddi_dead_falling_j_range",		"800.0",	"挂边处死距离. (仅限处死规则为1时生效)", CVAR_FLAGS, true, 100.0);
	GDead_Falling_Health	= CreateConVar("l4d2_ddi_dead_falling_k_health",	"100.0",	"挂边处死血限. \n 0.0 = 任何血量都可以直接处死\n 0.01 ~ 0.99 = 血量小于等于这个百分比才会处死 \n >= 1.0 血量小于等于这个数才会处死", CVAR_FLAGS, true, 0.0);
	GDead_Falling_Time		= CreateConVar("l4d2_ddi_dead_falling_l_time",		"15",		"挂边处死时间. (0 = 立即处死)", CVAR_FLAGS, true, 0.0);
	GDead_Falling_View		= CreateConVar("l4d2_ddi_dead_falling_m_view",		"0",		"挂边处死提示. (-1 = 不提示, 0 = 正常提示, 大于0 = 最后N秒进行提示)", CVAR_FLAGS, true, -1.0);

	GDead_Fallen_Type.AddChangeHook(ConVarChanged);
	GDead_Falling_Type.AddChangeHook(ConVarChanged);
	GDead_Fallen_Rule.AddChangeHook(ConVarChanged);
	GDead_Falling_Rule.AddChangeHook(ConVarChanged);
	GDead_Fallen_Range.AddChangeHook(ConVarChanged);
	GDead_Falling_Range.AddChangeHook(ConVarChanged);
	GDead_Fallen_Health.AddChangeHook(ConVarChanged);
	GDead_Falling_Health.AddChangeHook(ConVarChanged);
	GDead_Fallen_Time.AddChangeHook(ConVarChanged);
	GDead_Falling_Time.AddChangeHook(ConVarChanged);
	GDead_Fallen_View.AddChangeHook(ConVarChanged);
	GDead_Falling_View.AddChangeHook(ConVarChanged);

	HookEvent("round_start",			Event_RoundStart);			//回合开始.
	HookEvent("player_ledge_grab",		Event_PlayerLedgeGrab);		//玩家挂边.
	HookEvent("player_incapacitated",	Event_Incapacitate);		//玩家倒地.
	HookEvent("revive_success",			Event_ReviveSuccess);		//救起玩家.
	HookEvent("player_death",			Event_PlayerDeath);			//玩家死亡

	AutoExecConfig(true, "l4d2_delay_dead_incap");//生成指定文件名的CFG.
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	Dead_Fallen_Type    = GDead_Fallen_Type.IntValue;
	Dead_Fallen_Rule    = GDead_Fallen_Rule.IntValue;
	Dead_Fallen_Range   = GDead_Fallen_Range.FloatValue;
	Dead_Fallen_Health  = GDead_Fallen_Health.FloatValue;
	Dead_Fallen_Time    = GDead_Fallen_Time.IntValue;
	Dead_Fallen_View    = GDead_Fallen_View.IntValue;
	Dead_Falling_Type   = GDead_Falling_Type.IntValue;
	Dead_Falling_Rule   = GDead_Falling_Rule.IntValue;
	Dead_Falling_Range  = GDead_Falling_Range.FloatValue;
	Dead_Falling_Health = GDead_Falling_Health.FloatValue;
	Dead_Falling_Time   = GDead_Falling_Time.IntValue;
	Dead_Falling_View   = GDead_Falling_View.IntValue;
}

//回合开始.
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < 32 ; i++)
	{
		DeletePlayerDead(i);
	}
}

//玩家挂边.
public void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsSurvivor(client) && IsPlayerAlive(client) && IsPlayerFalling(client))
	{
		if (Dead_Falling_Type == 3)
		{
			DeadPlayer(client);
		}
		else if (Dead_Falling_Type == 1 || Dead_Falling_Type == 2)
		{
			incap_player_health[client] = GetClientHealth(client);
			if (player_dead[client] == null)
			{
				player_dead[client] = CreateTimer(1.0, CPCD, client, TIMER_REPEAT);
				Check_Player_Can_Dead(client);
			}
		}
	}
}

//玩家倒地.
public void Event_Incapacitate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsSurvivor(client) && IsPlayerAlive(client) && IsPlayerFallen(client))
	{
		if (Dead_Fallen_Type == 2)
		{
			DeadPlayer(client);
		}
		else if (Dead_Fallen_Type == 1)
		{
			incap_player_health[client] = GetClientHealth(client);
			if (player_dead[client] == null)
			{
				player_dead[client] = CreateTimer(1.0, CPCD, client, TIMER_REPEAT);
				Check_Player_Can_Dead(client);
			}
		}
	}
}

//救起玩家
public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client  = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));

	if (Dead_Fallen_Type > 0 || Dead_Falling_Type > 0)
	{
		if (IsSurvivor(client))
		{
			DeletePlayerDead(client);
		}
		if (IsSurvivor(subject))
		{
			DeletePlayerDead(subject);
		}
	}
}

//玩家死亡
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (Dead_Fallen_Type > 0 || Dead_Falling_Type > 0)
	{
		if (IsSurvivor(client))
		{
			DeletePlayerDead(client);
		}
	}
}

public Action L4D_OnFatalFalling(int client, int camera)
{
	if (!player_canfalling[client])
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action CPCD(Handle timer, int client)
{
	Check_Player_Can_Dead(client);
	return Plugin_Continue;
}

void Check_Player_Can_Dead(int client)
{
	bool RuleCan   = false;
	//bool RangeCan  = false;
	bool HealthCan = false;
	//bool TimerCan  = false;

	if (IsSurvivor(client) && IsPlayerAlive(client) && IsPlayerFallen(client))
	{
		if (Dead_Fallen_Rule == 0)
		{
			if (IsNoHaveStateSurvivor(client))
			{
				RuleCan = true;
			}
		}
		else if (Dead_Fallen_Rule == 1)
		{
			if (IsPinned(client) && IsNoSurvivorNear(client, Dead_Fallen_Range))
			{
				RuleCan = true;
			}
		}
		else if (Dead_Fallen_Rule == 2)
		{
			if (IsNoSurvivorNear(client, Dead_Fallen_Range))
			{
				RuleCan = true;
			}
		}
		else if (Dead_Fallen_Rule == 3)
		{
			RuleCan = true;
		}

		if (RuleCan)
		{
			if (Dead_Fallen_Health < 0.01)
			{
				HealthCan = true;
			}
			else if (Dead_Fallen_Health < 1.0)
			{
				int now_player_health = GetClientHealth(client);
				float health_percent = float(now_player_health) / float(incap_player_health[client]);
				if (health_percent <= Dead_Fallen_Health)
				{
					HealthCan = true;
				}
			}
			else
			{
				if (float(GetClientHealth(client)) <= Dead_Fallen_Health)
				{
					HealthCan = true;
				}
			}

			if (HealthCan)
			{
				if (Dead_Fallen_Time == 0)
				{
					DeadPlayer(client);
				}
				else
				{
					int sub_timer = Dead_Fallen_Time - incap_player_timer[client];

					if (sub_timer <= 0)
					{
						DeadPlayer(client);
					}
					else
					{
						if (Dead_Fallen_View == 0)
						{
							if (!IsFakeClient(client))
							{
								PrintHintText(client, "你将在%d秒后因为倒地被处死", sub_timer);
							}
						}
						else if (Dead_Fallen_View >= 1)
						{
							if (sub_timer <= Dead_Fallen_View)
							{
								if (!IsFakeClient(client))
								{
									PrintHintText(client, "你将在%d秒后因为倒地被处死", sub_timer);
								}
							}
						}
					}

					incap_player_timer[client] ++;
				}
			}
		}
	}
	else if (IsSurvivor(client) && IsPlayerAlive(client) && IsPlayerFalling(client))
	{
		if (Dead_Falling_Rule == 0)
		{
			if (IsNoHaveStateSurvivor(client))
			{
				RuleCan = true;
			}
		}
		else if (Dead_Falling_Rule == 1)
		{
			if (IsNoSurvivorNear(client, Dead_Falling_Range))
			{
				RuleCan = true;
			}
		}
		else if (Dead_Falling_Rule == 2)
		{
			RuleCan = true;
		}

		if (RuleCan)
		{
			if (Dead_Falling_Health < 0.01)
			{
				HealthCan = true;
			}
			else if (Dead_Falling_Health < 1.0)
			{
				int now_player_health = GetClientHealth(client);
				float health_percent = float(now_player_health) / float(incap_player_health[client]);
				if (health_percent <= Dead_Falling_Health)
				{
					HealthCan = true;
				}
			}
			else
			{
				if (float(GetClientHealth(client)) <= Dead_Falling_Health)
				{
					HealthCan = true;
				}
			}

			if (HealthCan)
			{
				if (Dead_Falling_Time == 0)
				{
					DeadPlayer(client);
				}
				else
				{
					int sub_timer = Dead_Falling_Time - incap_player_timer[client];

					if (sub_timer <= 0)
					{
						DeadPlayer(client);
					}
					else
					{
						if (Dead_Falling_View == 0)
						{
							if (Dead_Falling_Type == 1)
							{
								if (!IsFakeClient(client))
								{
									PrintHintText(client, "你将在%d秒后因为挂边被处死", sub_timer);
								}
							}
							else if (Dead_Falling_Type == 2)
							{
								if (!IsFakeClient(client))
								{
									PrintHintText(client, "你将在%d秒后自由落体", sub_timer);
								}
							}
						}
						else if (Dead_Falling_View >= 1)
						{
							if (sub_timer <= Dead_Falling_View)
							{
								if (Dead_Falling_Type == 1)
								{
									if (!IsFakeClient(client))
									{
										PrintHintText(client, "你将在%d秒后因为挂边被处死", sub_timer);
									}
								}
								else if (Dead_Falling_Type == 2)
								{
									if (!IsFakeClient(client))
									{
										PrintHintText(client, "你将在%d秒后自由落体", sub_timer);
									}
								}
							}
						}
					}

					incap_player_timer[client] ++;
				}
			}
		}
	}

	if (!RuleCan || !HealthCan)
	{
		incap_player_timer[client] = 0;
	}
}

void DeadPlayer(int client)
{
	if (IsSurvivor(client) && IsPlayerAlive(client))
	{
		if (IsPlayerFallen(client))
		{
			ForcePlayerSuicide(client);
			PrintToChatAll("\x04[提示] \x03%N \x05因为\x03倒地\x05被处死.", client);
		}
		else if(IsPlayerFalling(client))
		{
			if (Dead_Falling_Type == 1 || Dead_Falling_Type == 3)
			{
				ForcePlayerSuicide(client);
				PrintToChatAll("\x04[提示] \x03%N \x05因为\x03挂边\x05被处死.", client);
			}
			else if (Dead_Falling_Type == 2)
			{
				SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
				SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
				player_canfalling[client] = false;
				incap_player_timer[client] = 0;
				CreateTimer(3.0, ReCold, client);
			}
		}
	}
}

public Action ReCold(Handle timer, int client)
{
	DeletePlayerDead(client);
	return Plugin_Continue;
}

void DeletePlayerDead(int client)
{
	if (player_dead[client] != null)
	{
		delete player_dead[client];
	}
	incap_player_timer[client] = 0;
	player_canfalling[client] = true;
}

bool IsNoHaveStateSurvivor(int client)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (i != client && IsSurvivor(i) && IsPlayerAlive(i) && IsPlayerState(i))
		{
			return false;
		}
	}

	return true;
}

bool IsNoSurvivorNear(int client, float cr_distance)
{
	float client_dis[3], other_dis[3], sub_distance;
	GetClientAbsOrigin(client, client_dis);
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (i != client && IsSurvivor(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, other_dis);
			sub_distance = GetVectorDistance(client_dis, other_dis);
			if (sub_distance <= cr_distance)
			{
				return false;
			}
		}
	}

	return true;
}

bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool IsPinned(int client)
{
	bool bIsPinned = false;
	if (IsSurvivor(client))
	{
		if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		{
			bIsPinned = true;
		}
		if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		{
			bIsPinned = true;
		}
		if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		{
			bIsPinned = true;
		}
		if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		{
			bIsPinned = true;
		}
		if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		{
			bIsPinned = true;
		}
	}		
	return bIsPinned;
}

bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}