#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar enabled_kill, enabled_PutIn, enabled_Switch, Client_PutIn, Client_PutIn_time, Client_kill;

bool l4d2_client_kill;//开局提示幸存者自杀指令可用.
bool l4d2_client_kill_Switch = true;

public void OnPluginStart()
{
	RegConsoleCmd("sm_zs", Client_kill_Me, "幸存者自杀指令.");
	RegConsoleCmd("sm_kill", Client_kill_Me, "幸存者自杀指令.");
	
	RegAdminCmd("sm_since", l4d2_server_client_kill, ADMFLAG_ROOT, "管理员开启或关闭幸存者自杀插件和开局提示.");
	
	enabled_kill		= CreateConVar("l4d2_abbw_msgrs_enabled_Kill", "2", "启用幸存者自杀指令? 0=禁用, 1=启用(只限倒地的), 2=启用(无条件使用).");
	enabled_PutIn		= CreateConVar("l4d2_abbw_msgrs_enabled_PutIn_Switch", "1", "启用开局时提示幸存者自杀指令 !zs 和 !kill 可用? 0=禁用, 1=启用.");
	Client_PutIn		= CreateConVar("l4d2_abbw_msgrs_enabled_PutIn_client", "1", "设置开局提示的显示类型. 1=聊天窗, 2=屏幕中下+聊天窗, 3=屏幕中下.");
	Client_PutIn_time	= CreateConVar("l4d2_abbw_msgrs_enabled_PutIn_client_time", "10", "设置开局提示自杀指令的延迟显示时间/秒.");
	enabled_Switch		= CreateConVar("l4d2_abbw_msgrs_enabled_Switch", "1", "设置默认开启或关闭幸存者自杀指令. (输入指令 !since 开启或关闭,指令更改后这里的值失效) 0=关闭, 1=开启.");
	Client_kill			= CreateConVar("l4d2_abbw_msgrs_enabled_client_kill", "1", "设置幸存者自杀提示的显示类型. 0=禁用, 1=聊天窗, 2=屏幕中下+聊天窗, 3=屏幕中下.");
	
	//AutoExecConfig(true, "l4d2_abbw_msgrs");
}

public void OnConfigsExecuted()
{
	int l4d2_enabled_Switch = GetConVarInt(enabled_Switch);
	
	if(l4d2_client_kill_Switch)
	{
		if(l4d2_enabled_Switch == 0)
		{
			l4d2_client_kill = false;
		}
		else if(l4d2_enabled_Switch == 1)
		{
			l4d2_client_kill = true;
		}
	}
}

public Action l4d2_server_client_kill(int client, int args)
{
	if (l4d2_client_kill)
	{
		if (GetConVarInt(enabled_kill) <= 2)
		{
			l4d2_client_kill = false;
			l4d2_client_kill_Switch = false;
			
			if (GetConVarInt(enabled_PutIn) == 1)
			{
				PrintToChatAll("\x04★ \x03已关闭\x05幸存者自杀指令和开局提示.");
			}
			else if (GetConVarInt(enabled_PutIn) == 0)
			{
				PrintToChatAll("\x04★ \x03已关闭\x05幸存者自杀指令.");
			}
		}
		else
		{
			if (GetConVarInt(enabled_PutIn) == 1)
			{
				PrintToChat(client, "\x04★ \x05幸存者自杀指令和开局提示已禁用,请在CFG中设为1启用.");
			}
			else if (GetConVarInt(enabled_PutIn) == 0)
			{
				PrintToChat(client, "\x04★ \x05幸存者自杀指令已禁用,请在CFG中设为1启用.");
			}
		}
	}
	else
	{
		if (GetConVarInt(enabled_kill) <= 2)
		{
			l4d2_client_kill = true;
			l4d2_client_kill_Switch = false;
			
			if (GetConVarInt(enabled_PutIn) == 1)
			{
				PrintToChatAll("\x04★ \x03已开启\x05幸存者自杀指令和开局提示.");
			}
			else if (GetConVarInt(enabled_PutIn) == 0)
			{
				PrintToChatAll("\x04★ \x03已开启\x05幸存者自杀指令.");
			}
		}
		else
		{
			if (GetConVarInt(enabled_PutIn) == 1)
			{
				PrintToChat(client, "\x04★ \x05幸存者自杀指令和开局提示已禁用,请在CFG中设为1启用.");
			}
			else if (GetConVarInt(enabled_PutIn) == 0)
			{
				PrintToChat(client, "\x04★ \x05幸存者自杀指令已禁用,请在CFG中设为1启用.");
			}
		}
	}
	return Plugin_Handled;
}

//幸存者自杀代码.
public Action Client_kill_Me(int client, int args)
{
	if(client && GetConVarInt(enabled_kill) != 0 && l4d2_client_kill)
	{
		if(IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		{
			if (IsPlayerAlive(client) && GetClientTeam(client) == 2)
			{
				if (GetConVarInt(enabled_kill) == 1)
				{
					if(GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0)
					{
						l4d2_abbw_msgrs_start(client);
					}
					else
					{
						PrintToChat(client,"\x04★ \x05只限倒地的幸存者使用.");
					}
				}
				else if (GetConVarInt(enabled_kill) == 2)
				{
					l4d2_abbw_msgrs_start(client);
				}
			}
			else if(GetClientTeam(client) == 1)
			{
				PrintToChat(client,"\x04★ \x05旁观者无权使用自杀指令.");
			}
			else if(!IsPlayerAlive(client))
			{
				PrintToChat(client,"\x04★ \x05你当前是死亡状态,无需自杀.");
			}
			else
			{
				PrintToChat(client,"\x04★ \x05此指令只限幸存者使用.");	
			}
		}
	}
	else
	{
		PrintToChat(client,"\x04★ \x05幸存者自杀指令未启用.");	
	}
	return Plugin_Handled;
}

void l4d2_abbw_msgrs_start(int client)
{
	ForcePlayerSuicide(client);//幸存者自杀代码.
	
	if (GetConVarInt(Client_kill) == 1 || GetConVarInt(Client_kill) == 2)
	{
		if (GetConVarInt(Client_kill) == 1 || GetConVarInt(Client_kill) == 2)
		{
			PrintToChatAll("\x04★ \x05%N \x01突然失去了梦想,自杀身亡.", client);//聊天窗提示.
		}
		if (GetConVarInt(Client_kill) == 2 || GetConVarInt(Client_kill) == 3)
		{
			PrintHintTextToAll("[提示] %N 突然失去了梦想,自杀身亡.", client);//屏幕中下提示.
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		if (GetConVarInt(enabled_kill) != 0 && GetConVarInt(enabled_kill) <= 2)
		{
			CreateTimer(GetConVarFloat(Client_PutIn_time), TimerAnnounce, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action TimerAnnounce(Handle timer, int client)
{
	if (IsClientInGame(client) && GetClientTeam(client) != 3 && l4d2_client_kill)
	{
		if(GetConVarInt(enabled_PutIn) != 0)
		{
			if (GetConVarInt(enabled_kill) == 1)
			{
				if (GetConVarInt(Client_PutIn) == 1 || GetConVarInt(Client_PutIn) == 2)
				{
					PrintToChat(client, "\x04★ \x05倒地时输入指令 \x04!zs \x05或 \x04!kill \x05可以自杀.");//聊天窗提示.
				}
				if (GetConVarInt(Client_PutIn) == 2 || GetConVarInt(Client_PutIn) == 3)
				{
					PrintHintText(client, "[提示] 倒地后输入指令 !zs 可以自杀.");//屏幕中下提示.
				}
			}
			else if (GetConVarInt(enabled_kill) == 2)
			{
				if (GetConVarInt(Client_PutIn) == 1 || GetConVarInt(Client_PutIn) == 2)
				{
					PrintToChat(client, "\x04★ \x05聊天窗输入指令 \x04!zs \x05或 \x04!kill \x05可以自杀.");//聊天窗提示.
				}
				if (GetConVarInt(Client_PutIn) == 2 || GetConVarInt(Client_PutIn) == 3)
				{
					PrintHintText(client, "[提示] 幸存者输入指令 !zs 可以自杀.");//屏幕中下提示.
				}
			}
		}
	}
}