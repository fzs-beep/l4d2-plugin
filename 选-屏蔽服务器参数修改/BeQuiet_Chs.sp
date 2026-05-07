#pragma semicolon 1

#include <colors>
#pragma newdecls required
#include <sourcemod>

ConVar hCvarCvarChange, hCvarNameChange, hCvarServerChange, hCvarAdminSMTip, hCvarSpecNameChange, hCvarSpecSeeChat;
bool bCvarChange, bNameChange, bServerChange, bAdminSMTip, bSpecNameChange, bSpecSeeChat;

public Plugin myinfo = 
{
	name = "BeQuiet",
	author = "Sir && ヾ藤野深月ゞ",
	description = "屏蔽服务器修改参数提示",
	version = "1.33.7",
	url = "https://github.com/SirPlease/SirCoding"
}

public void OnPluginStart()
{
	AddCommandListener(Say_Callback, "say");
	AddCommandListener(TeamSay_Callback, "say_team");

	//Server CVar
	HookEvent("server_cvar", Event_ServerConVar, EventHookMode_Pre);
	HookEvent("player_changename", Event_NameChange, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook, true);
	
	//Cvars
	hCvarCvarChange = CreateConVar("bq_cvar_change_suppress", "1", "是否屏蔽 服务器参数 修改提示？[0=关闭 1=开启]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvarNameChange = CreateConVar("bq_name_change_suppress", "1", "是否屏蔽 玩家名称 修改提示？[0=关闭 1=开启]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvarServerChange = CreateConVar("bq_server_change_suppress", "1", "是否屏蔽 sm_cvar 参数修改提示？[0=关闭 1=开启]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvarAdminSMTip = CreateConVar("bq_admin_smtip_suppress", "1", "是否屏蔽 管理员[SM] 提示？[0=关闭 1=开启]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvarSpecNameChange = CreateConVar("bq_name_change_spec_suppress", "1", "是否屏蔽 闲置玩家名称 修改提示？[0=关闭 1=开启]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvarSpecSeeChat = CreateConVar("bq_show_player_team_chat_spec", "1", "闲置玩家是否能看见幸存者和感染者的对话？[0=关闭 1=开启]", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	bCvarChange = GetConVarBool(hCvarCvarChange);
	bNameChange = GetConVarBool(hCvarNameChange);
	bServerChange = GetConVarBool(hCvarServerChange);
	bAdminSMTip = GetConVarBool(hCvarAdminSMTip);
	bSpecNameChange = GetConVarBool(hCvarSpecNameChange);
	bSpecSeeChat = GetConVarBool(hCvarSpecSeeChat);

	hCvarCvarChange.AddChangeHook(cvarChanged);
	hCvarNameChange.AddChangeHook(cvarChanged);
	hCvarSpecNameChange.AddChangeHook(cvarChanged);
	hCvarSpecSeeChat.AddChangeHook(cvarChanged);

	AutoExecConfig(true, "BeQuiet_Chs");
}

public Action Say_Callback(int client, char[] command, int args)
{
	char sayWord[MAX_NAME_LENGTH];
	GetCmdArg(1, sayWord, sizeof(sayWord));
	if(sayWord[0] == '!' || sayWord[0] == '/') return Plugin_Handled;
	return Plugin_Continue; 
}

public Action TeamSay_Callback(int client, char[] command, int args)
{
	char sayWord[MAX_NAME_LENGTH];
	GetCmdArg(1, sayWord, sizeof(sayWord));
	if(sayWord[0] == '!' || sayWord[0] == '/') return Plugin_Handled;
	if (bSpecSeeChat && GetClientTeam(client) != 1)
	{
		char sChat[256];
		GetCmdArgString(sChat, 256);
		StripQuotes(sChat);
		for(int i = 0; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == 1)
			{
				if (GetClientTeam(client) == 2) CPrintToChat(i, "{default}(幸存者) {blue}%N {default}: %s", client, sChat);
				else CPrintToChat(i, "{default}(感染者) {red}%N {default}: %s", client, sChat);
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_ServerConVar(Event event, const char[] name, bool dontBroadcast)
{
	if (bCvarChange) return Plugin_Handled;
	return Plugin_Continue;
}

public Action UserMessageHook(UserMsg MsgId, Handle hBitBuffer, const char[] iPlayers, int iNumPlayers, bool bReliable, bool bInit) 
{
	char strMessage[256];
	BfReadByte(hBitBuffer);
	BfReadString(hBitBuffer, strMessage, sizeof(strMessage), true);
	if(StrContains(strMessage, "更改 cvar") != -1 && bServerChange) return Plugin_Handled;
	if(StrContains(strMessage, "[SM]") != -1 && bAdminSMTip) return Plugin_Handled;
	return Plugin_Continue; 
}

public Action Event_NameChange(Event event, const char[] name, bool dontBroadcast)
{
	int clientid = event.GetInt("userid");
	int client = GetClientOfUserId(clientid);
	if (IsValidClient(client))
	{
		if (GetClientTeam(client) == 1 && bSpecNameChange) return Plugin_Handled;
		else if (bNameChange) return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void cvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	bCvarChange = hCvarCvarChange.BoolValue;
	bNameChange = hCvarNameChange.BoolValue;
	bSpecNameChange = hCvarSpecNameChange.BoolValue;
	bSpecSeeChat = hCvarSpecSeeChat.BoolValue;
}

stock bool IsValidClient(int client)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false; 
	return true;
}
