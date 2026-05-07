#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <l4d2_ems_hud>

#define PLUGIN_VERSION "1.5"

new Handle:DisplayAllHUD_Timer = null;
new KillNumber[MAXPLAYERS+1];
new KillInfected[MAXPLAYERS+1];
new FriendDamage[MAXPLAYERS+1];
new CauseDamage[MAXPLAYERS+1];
new Player[MAXPLAYERS+1];
//new KillMvp[MAXPLAYERS+1];
new bool:IsRoundEnd;
new String:frame[][] =
{
	"===================",
	"★"
};

public Plugin myinfo =
{
	name = "[L4D2] 击杀，友伤统计 HUD ",
	author = "ヾ藤野深月ゞ (原作者：萌新/幸运星)",
	description = "[优化重写版本]提供更加直观的友伤统计与击杀排名(最大支持 14 人)",
	version = PLUGIN_VERSION,
	url = "--"
}

public void OnPluginStart()
{
	HookEvent("round_start",		Event_RoundStartinfo);
	HookEvent("round_end",			Event_RoundEndinfo);
	HookEvent("map_transition", Event_RoundEndinfo);
	HookEvent("player_death",		Event_PlayerDeath);
	HookEvent("player_hurt",		Event_PlayerHurt);
	HookEvent("infected_death", Event_InfectedKill);
}

//回合开始
public void Event_RoundStartinfo(Event event, const char[] name, bool dontBroadcast)
{
	IsRoundEnd = false;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidPlayer(i)) continue;
		KillNumber[i] = 0;
		KillInfected[i] = 0;
		FriendDamage[i] = 0;
		CauseDamage[i] = 0;
		Player[i] = 0;
	}
	DisplayAllHUD_Timer = CreateTimer(0.1, DisplayPlayerInfo, INVALID_HANDLE, TIMER_REPEAT);
}

//回合结束
public void Event_RoundEndinfo(Event event, const char[] name, bool dontBroadcast)
{
	IsRoundEnd = true;
	RemoveAllHUD();
	PrintPlayerInfo();
	delete DisplayAllHUD_Timer;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(GetEventInt(event,"userid"));
	int attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	if(IsValidPlayer(Client) && GetClientTeam(Client) == 3)
	{
		if(IsValidPlayer(attacker) && !IsFakeClient(attacker))
			KillNumber[attacker] += 1;
	}
	return Plugin_Handled;
}

public Action:Event_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damageDone = GetEventInt(event, "dmg_health");
	if (IsValidPlayer(attacker) && IsValidPlayer(victim) && !IsFakeClient(attacker))
	{
		if (GetClientTeam(attacker) == GetClientTeam(victim))
			FriendDamage[attacker] += damageDone;
		if (GetClientTeam(attacker) != GetClientTeam(victim) && !IsPlayerIncapped(victim))
			CauseDamage[attacker] += damageDone;
	}
	return Plugin_Handled;
}

public Action:Event_InfectedKill(Handle:event, String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsValidPlayer(attacker) && GetClientTeam(attacker) == 2 && !IsFakeClient(attacker))
		KillInfected[attacker] += 1;
	return Plugin_Handled;
}

//玩家连接
public void OnClientConnected(int Client)
{   
	if(!IsFakeClient(Client))
	{
		KillNumber[Client] = 0;
		KillInfected[Client] = 0;
		FriendDamage[Client] = 0;
		CauseDamage[Client] = 0;
	}
}

//玩家离开.
public void OnClientDisconnect(int Client)
{   
	if(!IsFakeClient(Client))
	{
		KillNumber[Client] = 0;
		KillInfected[Client] = 0;
		FriendDamage[Client] = 0;
		CauseDamage[Client] = 0;
	}
}

public Action DisplayPlayerInfo(Handle timer)
{
	RemoveAllDisplayHUD();
	return Plugin_Continue;
}

void RemoveAllDisplayHUD()
{
	if(HUDSlotIsUsed(HUD_LEFT_TOP))			RemoveHUD(HUD_LEFT_TOP);
	if(HUDSlotIsUsed(HUD_LEFT_BOT))			RemoveHUD(HUD_LEFT_BOT);
	if(HUDSlotIsUsed(HUD_MID_BOT))			RemoveHUD(HUD_MID_BOT);
	if(HUDSlotIsUsed(HUD_RIGHT_TOP))		RemoveHUD(HUD_RIGHT_TOP);
	if(HUDSlotIsUsed(HUD_RIGHT_BOT))		RemoveHUD(HUD_RIGHT_BOT);
	if(HUDSlotIsUsed(HUD_TICKER))				RemoveHUD(HUD_TICKER);
	if(HUDSlotIsUsed(HUD_FAR_LEFT))			RemoveHUD(HUD_FAR_LEFT);
	if(HUDSlotIsUsed(HUD_FAR_RIGHT))		RemoveHUD(HUD_FAR_RIGHT);
	if(HUDSlotIsUsed(HUD_MID_BOX))			RemoveHUD(HUD_MID_BOX);
	if(HUDSlotIsUsed(HUD_SCORE_TITLE))	RemoveHUD(HUD_SCORE_TITLE);
	if(HUDSlotIsUsed(HUD_SCORE_4))			RemoveHUD(HUD_SCORE_4);
	if(HUDSlotIsUsed(HUD_SCORE_3))			RemoveHUD(HUD_SCORE_3);
	if(HUDSlotIsUsed(HUD_SCORE_2))			RemoveHUD(HUD_SCORE_2);
	if(HUDSlotIsUsed(HUD_SCORE_1))			RemoveHUD(HUD_SCORE_1);
	if(HUDSlotIsUsed(HUD_LEFT_TOP))			RemoveHUD(HUD_LEFT_TOP);
	if(!IsRoundEnd) DisplayAllHUD();
}

void DisplayAllHUD()
{
	new index = 0, String:title[128], String:playerinfo[256], Float:HUDPos;
	new AllPlayer = GetAllPlayer(), IsAlive = GetAlivePlayer();
	new GetMapMax = GetMapMaxFlowDistance();
	Format(title,sizeof(title),"%s\n%s 击杀 / 黑枪 [路程:%d％](%d/%d) %s\n%s",frame[0],frame[1],GetMapMax,IsAlive,AllPlayer,frame[1],frame[0]);
	HUDSetLayout(HUD_MID_TOP,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,title);
	HUDPlace(HUD_MID_TOP, 0.00, 0.00, 0.52, 0.06);
	for(int Client = 1; Client <= MaxClients; Client++)
	{
		if(IsValidPlayer(Client) && GetClientTeam(Client) == 2)
			Player[index++] = Client;
	}
	SortCustom1D(Player, sizeof(Player), SortKillInfo);
	for(int i = 0; i < index; i++)
	{
		if(!IsValidPlayer(Player[i]) || GetClientTeam(Player[i]) != 2) continue;
		HUDPos = (0.03 * i) + 0.06;
		Format(playerinfo,sizeof(playerinfo),"%s %d：%d / %d → %N", frame[1], i + 1, KillNumber[Player[i]], FriendDamage[Player[i]], Player[i]);
		SettingHUDSetLayout(Player[i], i, HUDPos, playerinfo)
	}
}
/*
void PrintPlayerInfo()
{
	new index = 0;
	for(int Client = 1; Client <= MaxClients; Client++)
	{
		if(IsValidPlayer(Client) && GetClientTeam(Client) == 2)
			KillMvp[index++] = Client;
	}
	SortCustom1D(Player, sizeof(Player), SortDamageInfo);
	// 显示MVP排名 //
	PrintToChatAll("\x04[MVP]\x03 本回合其他数据排名：");
	for(int i = 0; i < index; i ++)
	{
		if(!IsValidPlayer(KillMvp[i]) || GetClientTeam(KillMvp[i]) != 2) continue;
		PrintToChatAll("\x04%s %d \x03对特感伤害[\x04%d\x03] 击杀小僵尸[\x04%d\x03]\x04 → %N"
		, frame[1], i + 1, CauseDamage[KillMvp[i]], KillInfected[KillMvp[i]], KillMvp[i]);
	}
}
*/
void PrintPlayerInfo()
{
	new client, players = -1, playersNum, players_clients[128];
	decl Damage, Infected;
	for (client = 1; client <= MaxClients; client++)
	{
		if (IsValidPlayer(client) && GetClientTeam(client) == 2)
		{
			players++;
			playersNum++;
			players_clients[players] = client;
			Damage = CauseDamage[client];
			Infected = KillInfected[client];
		}
	}
	// 显示MVP排名 
	PrintToChatAll("\x04[MVP]\x03 本回合其他数据排名：");
	SortCustom1D(players_clients, sizeof(players_clients), SortDamageInfo);
	for(int i = 0; i < playersNum; i ++)
	{
		client = players_clients[i];
		Damage = CauseDamage[client];
		Infected = KillInfected[client];
		PrintToChatAll("\x04%s %d \x03对特感伤害[\x04%d\x03] 击杀小僵尸[\x04%d\x03]\x04 → %N", frame[1], i + 1, Damage, Infected, client);
	}
}

/* 获取最大路径 */
int GetMapMaxFlowDistance()
{
	if(L4D_HasAnySurvivorLeftSafeArea())
	{
		int OneSurvivor;
		float GetMapMaxFlow = L4D2Direct_GetMapMaxFlowDistance();
		float fHighestFlow = IsValidSurvivor((OneSurvivor = L4D_GetHighestFlowSurvivor())) ? L4D2Direct_GetFlowDistance(OneSurvivor) : L4D2_GetFurthestSurvivorFlow();
		if(fHighestFlow) fHighestFlow = fHighestFlow / GetMapMaxFlow * 100;
		return RoundToNearest(fHighestFlow);
	} else return 0;
}

stock bool IsValidSurvivor(int client)
{
	return IsValidPlayer(client) && GetClientTeam(client) == 2;
}

/*对击杀信息进行排序*/
public SortDamageInfo(elem1, elem2, const array[], Handle:hndl)
{
	if (CauseDamage[elem1] > CauseDamage[elem2]) return -1;
	else if (CauseDamage[elem2] > CauseDamage[elem1]) return 1;
	else if (elem1 > elem2) return -1;
	else if (elem2 > elem1) return 1;
	return 0;
}

/*对击杀信息进行排序*/
public SortKillInfo(elem1, elem2, const array[], Handle:hndl)
{
	if (KillNumber[elem1] > KillNumber[elem2]) return -1;
	else if (KillNumber[elem2] > KillNumber[elem1]) return 1;
	else if (elem1 > elem2) return -1;
	else if (elem2 > elem1) return 1;
	return 0;
}

public GetAllPlayer()
{
	new index;
	for(new Client = 1; Client <= MaxClients; Client++)
	{
		if(IsValidPlayer(Client) && GetClientTeam(Client) == 2)
			index += 1;
	}
	return index;
}

public GetAlivePlayer()
{
	new index;
	for(new Client = 1; Client <= MaxClients; Client++)
	{
		if(IsValidPlayer(Client) && GetClientTeam(Client) == 2 && IsPlayerAlive(Client))
			index += 1;
	}
	return index;
}

stock bool:IsValidPlayer(Client, bool:AllowBot = true, bool:AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients) return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client)) return false;
	return true;
}

//HUDPlace(int slot, float x, float y, float width, float height)
public SettingHUDSetLayout(Client, Type, Float:HUDPos, String:TextInfo[])
{
	switch(Type)
	{
		case 0: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_LEFT_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_LEFT_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_LEFT_BOT, 0.00, HUDPos, 1.00, 0.04);
		}
		case 1: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_MID_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_MID_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_MID_BOT, 0.00, HUDPos, 1.00, 0.04);
		}
		case 2: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_RIGHT_TOP,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_RIGHT_TOP,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_RIGHT_TOP, 0.00, HUDPos, 1.00, 0.04);
		}
		case 3: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_RIGHT_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_RIGHT_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_RIGHT_BOT, 0.00, HUDPos, 1.00, 0.04);
		}
		case 4: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_TICKER,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_TICKER,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_TICKER, 0.00, HUDPos, 1.00, 0.04);
		}
		case 5: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_FAR_LEFT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_FAR_LEFT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_FAR_LEFT, 0.00, HUDPos, 1.00, 0.04);
		}
		case 6: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_FAR_RIGHT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_FAR_RIGHT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_FAR_RIGHT, 0.00, HUDPos, 1.00, 0.04);
		}
		case 7: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_MID_BOX,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_MID_BOX,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_MID_BOX, 0.00, HUDPos, 1.00, 0.04);
		}
		case 8: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_SCORE_TITLE,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_SCORE_TITLE,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_SCORE_TITLE, 0.00, HUDPos, 1.00, 0.04);
		}
		case 9: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_SCORE_1,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_SCORE_1,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_SCORE_1, 0.00, HUDPos, 1.00, 0.04);
		}
		case 10: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_SCORE_2,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_SCORE_2,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_SCORE_2, 0.00, HUDPos, 1.00, 0.04);
		}
		case 11: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_SCORE_3,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_SCORE_3,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_SCORE_3, 0.00, HUDPos, 1.00, 0.04);
		}
		case 12: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_SCORE_4,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_SCORE_4,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_SCORE_4, 0.00, HUDPos, 1.00, 0.04);
		}
		case 13: 
		{
			if(IsPlayerAlive(Client)) HUDSetLayout(HUD_LEFT_TOP,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT,TextInfo);
			else HUDSetLayout(HUD_LEFT_TOP,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK|HUD_FLAG_COUNTDOWN_WARN|HUD_FLAG_TEXT,TextInfo);
			HUDPlace(HUD_LEFT_TOP, 0.00, HUDPos, 1.00, 0.04);
		}
	}
}

stock bool:IsCommonInfected(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "infected");
	}
	return false;
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

stock bool:IsPlayerIncapped(Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated") == 1) return true;
	else return false;
}