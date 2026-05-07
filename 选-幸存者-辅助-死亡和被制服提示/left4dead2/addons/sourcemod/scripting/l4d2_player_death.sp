//每行代码结束需填写“;”
#pragma semicolon 1
//强制新语法
#pragma newdecls required
#include <sourcemod>

char clientName[32];

bool l4d2_playerdeathbool;

ConVar l4d2_player_ledge_grab, l4d2_player_death, l4d2_incapacitated;

public void OnPluginStart()
{
	l4d2_player_ledge_grab	= CreateConVar("l4d2_enabled_player_survivor_player_ledge_grab", "1", "启用幸存者挂边提示? 0=禁用, 1=启用.", FCVAR_NOTIFY);
	l4d2_player_death		= CreateConVar("l4d2_enabled_player_survivors_death", "1", "启用幸存者死亡提示和击杀者提示? 0=禁用, 1=启用.", FCVAR_NOTIFY);
	l4d2_incapacitated	= CreateConVar("l4d2_enabled_player_survivors_incapacitated", "1", "启用幸存者被制服提示? 0=禁用, 1=启用.", FCVAR_NOTIFY);
	
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeavingplayer, EventHookMode_Pre);//救援离开
	HookEvent("player_ledge_grab", Event_player_ledge_grab);//幸存者挂边.
	HookEvent("player_death", Event_PlayerDeath);//玩家死亡.
	HookEvent("player_incapacitated", Event_Incapacitate);//玩家倒下.
	
	AutoExecConfig(true, "l4d2_player_death");//生成指定文件名的CFG.
}

//地图开始.
public void OnMapStart()
{
	l4d2_playerdeathbool = false;
}

//救援离开.
public Action Event_FinaleVehicleLeavingplayer(Event event, const char[] name, bool dontBroadcast)
{
	if (!l4d2_playerdeathbool)
		l4d2_playerdeathbool = true;
}

//幸存者挂边.
public void Event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (l4d2_player_ledge_grab.IntValue == 0)
		return;
		
	if (l4d2_playerdeathbool)
		return;
	
	if(IsValidClient(client))
	{
		GetTrueName(client, clientName);
		PrintToChatAll("\x04[提示]\x03%s\x05挂边了.", clientName);//聊天窗提示.
	}
}

//玩家死亡.
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (l4d2_player_death.IntValue == 0)
		return;
		
	if (l4d2_playerdeathbool)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	char classname[32];
	int entity = GetEventInt(event, "attackerentid");
	int damagetype = GetEventInt(event, "type");
	GetEdictClassname(entity, classname, sizeof(classname));

	if(IsValidClient(client))
	{
		GetTrueName(client, clientName);
		
		char slName1[12];
		FormatEx(slName1, sizeof(slName1), "%N", attacker);
		SplitString(slName1, "Smoker", slName1, sizeof(slName1));
		
		char slName2[12];
		FormatEx(slName2, sizeof(slName2), "%N", attacker);
		SplitString(slName2, "Boomer", slName2, sizeof(slName2));
		
		char slName3[12];
		FormatEx(slName3, sizeof(slName3), "%N", attacker);
		SplitString(slName3, "Hunter", slName3, sizeof(slName3));
		
		char slName4[12];
		FormatEx(slName4, sizeof(slName4), "%N", attacker);
		SplitString(slName4, "Spitter", slName4, sizeof(slName4));
		
		char slName5[12];
		FormatEx(slName5, sizeof(slName5), "%N", attacker);
		SplitString(slName5, "Jockey", slName5, sizeof(slName5));
		
		char slName6[12];
		FormatEx(slName6, sizeof(slName6), "%N", attacker);
		SplitString(slName6, "Charger", slName6, sizeof(slName6));
		
		char slName8[12];
		FormatEx(slName8, sizeof(slName8), "%N", attacker);
		SplitString(slName8, "Tank", slName8, sizeof(slName8));

		if (attacker)
		{
			if (GetClientTeam(attacker) == 2)
			{
				char attackername[32];
				GetTrueName(attacker, attackername);
				if (attacker != client)
					PrintToChatAll("\x04[提示]\x03%s\x05黑死了\x03%s", attackername, clientName);//聊天窗提示.
				else
				{
					if(damagetype == 8  || damagetype == 2056 || damagetype == 268435464)
						PrintToChatAll("\x04[提示]\x03%s\x05玩火自焚.", clientName);//聊天窗提示.
					else if(damagetype == 6144)
					{
						//PrintToChatAll("\x04[提示]\x03%s\x05自杀身亡.", clientName);//聊天窗提示.
					}
					else
						PrintToChatAll("\x04[提示]\x03%s\x05已死亡.", clientName);//聊天窗提示.
				}
			}
			else if (GetClientTeam(attacker) == 3)
			{
				int iClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
				
				switch (iClass)
				{
					case 1: //smoker
						PrintToChatAll("\x04[提示]\x03舌头%s\x5杀死了\x03%s", slName1, clientName);//聊天窗提示.
					case 2: //boomer
						PrintToChatAll("\x04[提示]\x03胖子%s\x5杀死了\x03%s", slName2, clientName);//聊天窗提示.
					case 3: //hunter
						PrintToChatAll("\x04[提示]\x03猎人%s\x5杀死了\x03%s", slName3, clientName);//聊天窗提示.
					case 4: //spitter
						PrintToChatAll("\x04[提示]\x03口水%s\x5杀死了\x03%s", slName4, clientName);//聊天窗提示.
					case 5: //jockey
						PrintToChatAll("\x04[提示]\x03猴子%s\x5杀死了\x03%s", slName5, clientName);//聊天窗提示.
					case 6: //charger
						PrintToChatAll("\x04[提示]\x03牛牛%s\x5杀死了\x03%s", slName6, clientName);//聊天窗提示.
					case 8: //tank
						PrintToChatAll("\x04[提示]\x03坦克%s\x5杀死了\x03%s", slName8, clientName);//聊天窗提示.
				}
			}
		}
		else
		{
			if (IsValidEdict(entity))
			{
				if(strcmp(classname, "worldspawn") == 0)
				{
					switch(damagetype)
					{
						case 32:
							PrintToChatAll("\x04[提示]\x03%s\x05摔死了,亲亲也起不来了.", clientName);//聊天窗提示.
						case 131072:
							PrintToChatAll("\x04[提示]\x03%s\x05流血过多而死.", clientName);//聊天窗提示.
						case 524288:
							PrintToChatAll("\x04[提示]\x03%s\x05水疗.", clientName);//聊天窗提示.
					}
				}
				else if (StrEqual(classname, "witch", false))
					PrintToChatAll("\x04[提示]\x03女巫\x05杀死了\x03%s", clientName);//聊天窗提示.
				else if(strcmp(classname, "infected") == 0)
					PrintToChatAll("\x04[提示]\x03小丧尸\x05杀死了\x03%s", clientName);//聊天窗提示.
				else if(strcmp(classname, "trigger_hurt") == 0 && damagetype == 16384)
					PrintToChatAll("\x04[提示]\x03%s\x05淹死了.", clientName);//聊天窗提示.
				else if(strcmp(classname, "insect_swarm") == 0)
					PrintToChatAll("\x04[提示]\x05踩痰达人\x03%s\x05已死亡.", clientName);//聊天窗提示.
				else if(strcmp(classname, "func_movelinear") == 0)
					PrintToChatAll("\x04[提示]\x03%s\x05被压死了.", clientName);//聊天窗提示.
				else
					PrintToChatAll("\x04[提示]\x03%s\x05已死亡.", clientName);//聊天窗提示.
				//PrintToChatAll("\x04[提示]\x03%d\x05类型%s.", damagetype, classname);//聊天窗提示.
			}
		}
	}
}

//玩家倒下.
public void Event_Incapacitate(Event event, const char[] name, bool dontBroadcast)
{
	if (l4d2_incapacitated.IntValue == 0)
		return;
		
	if (l4d2_playerdeathbool)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	char classname[32];
	int entity = GetEventInt(event, "attackerentid");
	int damagetype = GetEventInt(event, "type");
	GetEdictClassname(entity, classname, sizeof(classname));

	if(IsValidClient(client))
	{
		GetTrueName(client, clientName);
		
		char slName1[12];
		FormatEx(slName1, sizeof(slName1), "%N", attacker);
		SplitString(slName1, "Smoker", slName1, sizeof(slName1));
		
		char slName2[12];
		FormatEx(slName2, sizeof(slName2), "%N", attacker);
		SplitString(slName2, "Boomer", slName2, sizeof(slName2));
		
		char slName3[12];
		FormatEx(slName3, sizeof(slName3), "%N", attacker);
		SplitString(slName3, "Hunter", slName3, sizeof(slName3));
		
		char slName4[12];
		FormatEx(slName4, sizeof(slName4), "%N", attacker);
		SplitString(slName4, "Spitter", slName4, sizeof(slName4));
		
		char slName5[12];
		FormatEx(slName5, sizeof(slName5), "%N", attacker);
		SplitString(slName5, "Jockey", slName5, sizeof(slName5));
		
		char slName6[12];
		FormatEx(slName6, sizeof(slName6), "%N", attacker);
		SplitString(slName6, "Charger", slName6, sizeof(slName6));
		
		char slName8[12];
		FormatEx(slName8, sizeof(slName8), "%N", attacker);
		SplitString(slName8, "Tank", slName8, sizeof(slName8));
		
		if (attacker)
		{
			if (GetClientTeam(attacker) == 2)
			{
				char attackername[32];
				GetTrueName(attacker, attackername);
				if (attacker != client)
					PrintToChatAll("\x04[提示]\x03%s\x05制服了\x03%s", attackername, clientName);//聊天窗提示.
				else
					PrintToChatAll("\x04[提示]\x03%s\x05制服了自己.", clientName);//聊天窗提示.
			}
			else if (GetClientTeam(attacker) == 3)
			{
				int iClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
				
				switch (iClass)
				{
					case 1: //smoker
						PrintToChatAll("\x04[提示]\x03舌头%s\x05制服了\x03%s", slName1, clientName);//聊天窗提示.
					case 2: //boomer
						PrintToChatAll("\x04[提示]\x03胖子%s\x05制服了\x03%s", slName2, clientName);//聊天窗提示.
					case 3: //hunter
						PrintToChatAll("\x04[提示]\x03猎人%s\x05制服了\x03%s", slName3, clientName);//聊天窗提示.
					case 4: //spitter
						PrintToChatAll("\x04[提示]\x03口水%s\x05制服了\x03%s", slName4, clientName);//聊天窗提示.
					case 5: //jockey
						PrintToChatAll("\x04[提示]\x03猴子%s\x05制服了\x03%s", slName5, clientName);//聊天窗提示.
					case 6: //charger
						PrintToChatAll("\x04[提示]\x03牛牛%s\x05制服了\x03%s", slName6, clientName);//聊天窗提示.
					case 8: //tank
						PrintToChatAll("\x04[提示]\x03坦克%s\x05制服了\x03%s", slName8, clientName);//聊天窗提示.
				}
			}
		}
		else
		{
			if (IsValidEdict(entity))
			{
				if(strcmp(classname, "worldspawn") == 0 && damagetype == 32)
					PrintToChatAll("\x04[提示]\x03%s\x05摔倒了,需要亲亲才能起来.", clientName);//聊天窗提示.
				else if (StrEqual(classname, "witch", false))
					PrintToChatAll("\x04[提示]\x03女巫\x05制服了\x03%s", clientName);//聊天窗提示.
				else if(strcmp(classname, "infected") == 0)
					PrintToChatAll("\x04[提示]\x03小丧尸\x05制服了\x03%s", clientName);//聊天窗提示.
				else if(strcmp(classname, "trigger_hurt") == 0 && damagetype == 16384)
					PrintToChatAll("\x04[提示]\x03%s\x05在水里倒下.", clientName);//聊天窗提示.
				else if(strcmp(classname, "insect_swarm") == 0)
					PrintToChatAll("\x04[提示]\x05踩痰达人\x03%s\x05倒下了.", clientName);//聊天窗提示.
				else if(strcmp(classname, "func_movelinear") == 0)
					PrintToChatAll("\x04[提示]\x03%s\x05被重物碰倒了.", clientName);//聊天窗提示.
				else
					PrintToChatAll("\x04[提示]\x03%s\x05倒下了.", clientName);//聊天窗提示.
				//PrintToChatAll("\x04[提示]\x03%d\x05类型%s.", damagetype, classname);//聊天窗提示.
			}
		}
	}
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

void GetTrueName(int bot, char[] savename)
{
	int tbot = IsClientIdle(bot);
	
	if(tbot != 0)
	{
		Format(savename, 32, "★闲置:%N★", tbot);
	}
	else
	{
		GetClientName(bot, savename, 32);
	}
}

int IsClientIdle(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == 2 && IsFakeClient(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client))
			{
				return client;
			}
		}
	}
	return 0;
}