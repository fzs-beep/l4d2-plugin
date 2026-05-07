#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define Version "1.1"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;
new player_num = 0;
new bool:playerbindkey[MAXPLAYERS+1] = false;
new bool:inserver[MAXPLAYERS+1] = false;

new Handle:sm_msg_system_connect = INVALID_HANDLE;
new Handle:sm_msg_system_playernum = INVALID_HANDLE;


public Plugin:myinfo =
{
	name="信息系统[message system]",
	author="鸭蛋",
	description="显示各种类型的的游戏信息.",
	version=Version,
	url="www.l4d.cn"
};

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("该插件只能用于l4d和l4d2.");
	}
	
	sm_msg_system_connect = CreateConVar("sm_msg_system_connect","1","显示玩家连接和离开的信息(0:关闭 1:开启)", CVAR_FLAGS)
	sm_msg_system_playernum = CreateConVar("sm_msg_system_playernum","1","玩家连接和断开时显示剩余玩家数(0:关闭 1:开启)", CVAR_FLAGS)
	
	//AutoExecConfig(true, "sm_msg_system");
}

//玩家连接
public OnClientConnected(Client)
{
	if (!GetConVarInt(sm_msg_system_connect)){ return; }
	if (IsFakeClient(Client)){ return; }
	
	player_num+=1;
	new String:playername[32];
	GetClientName(Client,playername,sizeof(playername));
	if (GetConVarInt(sm_msg_system_playernum))
	{
		CPrintToChatAll("{green}★★★ {blue}%N {olive}正在连接,当前玩家总人数 {green}%i {olive}人.", Client, player_num);
	}
	else 
	{
		CPrintToChatAll("{green}★★★ {blue}%N {olive}正在连接.", Client);
	}
	
	inserver[Client] = true;
}

//玩家断开连接
public OnClientDisconnect(Client)
{
	if (!GetConVarInt(sm_msg_system_connect)){ return; }
	if (IsFakeClient(Client)){ return; }
	
	player_num-=1;
	new String:playername[32];
	GetClientName(Client,playername,sizeof(playername));
	if (GetConVarInt(sm_msg_system_playernum))
	{
		CPrintToChatAll("{green}★★★ {blue}%N {olive}离开游戏,当前玩家总人数 {green}%i {olive}人.", Client, player_num);
	}
	else
	{
		CPrintToChatAll("{green}★★★ {blue}%N {olive}离开游戏.", Client);
	}
	inserver[Client] = false;
	playerbindkey[Client] = false;
}


public OnMapEnd()
{
	player_num = 0;
}
