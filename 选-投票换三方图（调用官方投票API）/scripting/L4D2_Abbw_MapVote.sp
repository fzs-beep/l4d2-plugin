#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nativevotes>

#define PLUGIN_VERSION "7.0"

new Handle:abbw_map_limit;
new Handle:abbw_map_timer;
new Handle:abbw_map_server;
new Handle:abbw_map_change;
new Handle:abbw_change_map;

#define MaxMap 5000
#define MaxMapNumber GetConVarInt(abbw_map_limit)

/*官方UI的投票全局参数*/
new String:Vote_MapUpdate_Temp[128];
new String:EN_name[MaxMap][MAX_NAME_LENGTH];
new String:CHI_name[MaxMap][MAX_NAME_LENGTH];
new String:ChangeMap[MAX_NAME_LENGTH];

public Plugin:myinfo =
{
	name = "投票换第三方图",
	description = "投票换第三方图，三方图从data/l4d2_abbw_map.txt加载",
	author = "笨蛋海绵 & 藤野深月(反编译修改版)",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_mapvote", check, "投票换非官图");
	RegConsoleCmd("sm_v", check, "投票换非官图");
	
	CreateConVar("L4D2_MapVote_Version", PLUGIN_VERSION, "L4D2 投票换图 插件版本");
	abbw_map_limit			= CreateConVar("abbw_map_limit", 			"50",						"设置 菜单读取地图数量(可以多设置)\n \n显示数量取决于data数据文件参数(自动过滤空白)\n \n最终显示取决于 数据文本 和 读取地图数量");
	abbw_map_timer			= CreateConVar("abbw_map_timer", 			"5.0",					"设置 投票换图延迟时间[投票成功后的延时]");
	abbw_map_server			= CreateConVar("abbw_map_server", 		"1",						"设置 服务器在进行三方图时 \n是否启用无人时自动换图功能？(0=禁用)");
	abbw_map_change			= CreateConVar("abbw_map_change",			"c2m1_highway",	"设置 服务器在进行三方图时 \n启用无人自动换图功能的换图代码");
	abbw_change_map			= CreateConVar("abbw_change_map",			"90.0",					"设置 服务器在进行三方图时 \n玩家离开多久后检测无人自动换图(秒)");
	/* 设置Config */
	AutoExecConfig(true, "L4D2_Abbw_MapVote");
	//载入数据
	LoadMapInfoData();
}

/* 玩家离开游戏 */
public OnClientDisconnect(Client)
{
	if(GetConVarInt(abbw_map_server) != 0)
	{
		/* 获取换图代码 */
		GetConVarString(abbw_map_change, ChangeMap, sizeof(ChangeMap));
		CreateTimer(GetConVarFloat(abbw_change_map), CheckReChangeMap, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:CheckReChangeMap(Handle:timer)
{
	decl String:MapName[128];
	GetCurrentMap(MapName,sizeof(MapName));
	//检测是否为三方图
	new bool:IsAdditional = false;
	for (new x = 1; x < MaxMapNumber ; x++)
	{
		if(StrEqual(MapName, EN_name[x]))
			IsAdditional = true;
	}
	//检测人数设置
	new count = GetValidPlayerNumber();
	if( count < 1 && IsAdditional )
	{
		if(StrEqual(ChangeMap, ""))
			ServerCommand("changelevel c2m1_highway");
		else
			ServerCommand("changelevel %s", ChangeMap);
	}
}
	

stock LoadMapInfoData()
{
	decl String:sTemp[128];
	new Handle:hFile = OpenConfig();
	for (new x = 1; x < MaxMapNumber ; x++)
	{
		IntToString(x, sTemp, sizeof(sTemp));
		if (KvJumpToKey(hFile, sTemp, false))
		{
			KvGetString(hFile, "中文名", CHI_name[x], sizeof(sTemp), "");
			KvGetString(hFile, "建图代码", EN_name[x], sizeof(sTemp), "");
			KvRewind(hFile);
		}
	}
}

Handle:OpenConfig()
{
	decl String:sPath[256];
	BuildPath(Path_SM, sPath, 255, "data/l4d2_abbw_map.txt");
	
	if (!FileExists(sPath))
		SetFailState("[提示] 找不到文件 data/l4d2_abbw_map.txt");
	else
		PrintToServer("[提示] 文件数据 data/l4d2_abbw_map.txt 加载成功");
	
	new Handle:hFile = CreateKeyValues("第三方图数据");
	if (!FileToKeyValues(hFile, sPath))
	{
		CloseHandle(hFile);
		SetFailState("无法载入 data/l4d2_abbw_map.txt'");
	}
	return hFile;
}

public Action:check(client, args)
{
	if (IsValidPlayer(client))
	{
		PrintToChat(client, "\x04[提示] \x03该功能仅限有效玩家使用！");
		return Plugin_Stop;
	}
	map_vote(client, args);
	return Plugin_Stop;
}

public Action:map_vote(client, args)
{
	new Handle:menu = CreateMenu(ModeMenuHandler);
	SetMenuTitle(menu, "地图切换");
	AddMenuItem(menu, "option1", "帮助说明");
	for (new i = 1; i < MaxMapNumber ; i++)
	{
		if (!StrEqual("", CHI_name[i], true))
		{
			AddMenuItem(menu, EN_name[i], CHI_name[i]);
		}
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public ModeMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select)
	{
		if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_YesNo))
		{
			ReplyToCommand(client, "[提示]游戏不支持当前投票类型.");
			return;
		}
		if (!NativeVotes_IsNewVoteAllowed())
		{
			ReplyToCommand(client, "[提示]目前无法还无法发起投票.");
			return;
		}
		switch (itemNum)
		{
			case 0:
			{
				PrintToChat(client, "\x04[提示] \x03如果发现无法按下5,6,7,8,9,0键,请在控制台输入 \n\x05bind 5 slot5; bind 6 slot6; bind 7 slot7; bind 8 slot8; bind 9 slot9; bind 0 slot10");
				PrintToChat(client, "\x04如果某玩家没有该第三方图，将会断开游戏");
			}
			default:
			{
				new String:info[128], String:name[128], style;
				GetMenuItem(menu, itemNum, info, sizeof(info), style, name, sizeof(name));
				
				Format(Vote_MapUpdate_Temp,sizeof(Vote_MapUpdate_Temp),"%s",info);
				NativeVote vote = new NativeVote(MapToUpdate_YesNoHandler, NativeVotesType_Custom_YesNo);
				
				vote.Initiator = client;
				vote.SetDetails("更换地图为 %s ", name);
				vote.DisplayVoteToAll(15);
			}
		}
	}
}

public int MapToUpdate_YesNoHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
			}
			else
			{
				vote.DisplayFail(NativeVotesFail_Generic);
			}
		}
		case MenuAction_VoteEnd:
		{
			if (param1 == NATIVEVOTES_VOTE_NO)
			{
				vote.DisplayFail(NativeVotesFail_Loses);
			}
			else
			{
				vote.DisplayPass("更改地图投票通过! 即将更改...");
				CreateTimer(GetConVarFloat(abbw_map_timer), MapToUpdate_YesNoHandler_MapUpadteDelayTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:MapToUpdate_YesNoHandler_MapUpadteDelayTimer(Handle:timer)
{
	ForceChangeLevel(Vote_MapUpdate_Temp, "vote");
	return Plugin_Stop;
}

stock bool:IsValidPlayer(Client, bool:AllowBot = true, bool:AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients)
		return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return false;
	if (!AllowBot)
	{
		if (IsFakeClient(Client))
			return false;
	}
	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
			return false;
	}	
	return true;
}

/* 获取有效生还者人数 */
public GetValidPlayerNumber()
{
	int count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(i) && !IsFakeClient(i))
			count += 1;
	}
	return count;
}