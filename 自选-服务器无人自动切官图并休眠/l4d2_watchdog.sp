// Force strict semicolon mode
#pragma semicolon 1
#include <sourcemod>
#include <halflife>
#include <string>
#include <sdktools_functions>

#define PLUGIN_VERSION	"1.0"

int thirdparty_count = 0;
Handle g_hTimer_CheckEmpty;

static const String:FinishedMap[][] = 	
{ 
	"c1m1_hotel" ,
	"c2m1_highway" ,
	"c3m1_plankcountry" ,
	"c4m1_milltown_a" ,
	"c5m1_waterfront" ,
	"c6m1_riverbank" ,
	"c7m1_docks" ,
	"c8m1_apartment" ,
	"c9m1_alleys" ,
	"c10m1_caves" ,
	"c11m1_greenhouse" ,
	"c12m1_hilltop" ,
	"c13m1_alpinecreek"
};

bool:IsFinishedMap(const String:CurrenMap[])
{
	for(new i=0;i<sizeof(FinishedMap);i++)
	{
		if(StrEqual(CurrenMap,FinishedMap[i]))
		{
			return true;
		}
	}
	return false;
}

public Plugin myinfo =
{
	name = "[L4D2] Server Watchdog",
	author = "Rikka0w0",
	description = "Switch the map to offical maps when the server has no active player but running 3rd party map",
	version = PLUGIN_VERSION,
	url = "..."
}

Timer_CheckEmpty_Kill() {
	if (g_hTimer_CheckEmpty != INVALID_HANDLE) {
		KillTimer(g_hTimer_CheckEmpty);
		g_hTimer_CheckEmpty = INVALID_HANDLE;
	}
}

public OnMapStart() {
	bool hasHumanPlayers = false;
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i))
			continue;

		if (!IsFakeClient(i))
			hasHumanPlayers = true;
	}
	char mapNames[256];
	GetCurrentMap(mapNames, 256);
	if (!IsFinishedMap(mapNames) && !hasHumanPlayers)
	//if (!hasHumanPlayers)
	{
		SetConVarInt(FindConVar("sv_hibernate_when_empty"), 0);
	}
	Timer_CheckEmpty_Kill();
	g_hTimer_CheckEmpty = CreateTimer(5.0, Timer_OnFeedDog, INVALID_HANDLE, TIMER_REPEAT);
}

public OnMapEnd() {
	SetConVarInt(FindConVar("sv_hibernate_when_empty"), 1);
	Timer_CheckEmpty_Kill();
}

public Action Timer_OnFeedDog(Handle timer, any param) 
{
	bool isOfficialMap = true;
	char mapName[256];
	GetCurrentMap(mapName, 256);
	if (!IsFinishedMap(mapName))
		isOfficialMap = false;

	bool hasHumanPlayer = false;
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i))
			continue;

		if (!IsFakeClient(i))
			hasHumanPlayer = true;
	}

	if ((!hasHumanPlayer) && !isOfficialMap) {
		thirdparty_count++;
		if (thirdparty_count > 12) {
			thirdparty_count = 0;

			Timer_CheckEmpty_Kill();
			switch(GetRandomInt(0,12))
			{
				case 0:		ForceChangeLevel("c2m1_highway",		"服务器空闲且是三方图时，更换为官图");
				case 1:		ForceChangeLevel("c3m1_plankcountry",	"服务器空闲且是三方图时，更换为官图");
				case 2:		ForceChangeLevel("c4m1_milltown_a",		"服务器空闲且是三方图时，更换为官图");
				case 3:		ForceChangeLevel("c5m1_waterfront",		"服务器空闲且是三方图时，更换为官图");
				case 4:		ForceChangeLevel("c6m1_riverbank",		"服务器空闲且是三方图时，更换为官图");
				case 5:		ForceChangeLevel("c7m1_docks",			"服务器空闲且是三方图时，更换为官图");
				case 6:		ForceChangeLevel("c8m1_apartment",		"服务器空闲且是三方图时，更换为官图");
				case 7:		ForceChangeLevel("c9m1_alleys",			"服务器空闲且是三方图时，更换为官图");
				case 8:		ForceChangeLevel("c10m1_caves",			"服务器空闲且是三方图时，更换为官图");
				case 9:		ForceChangeLevel("c11m1_greenhouse",	"服务器空闲且是三方图时，更换为官图");
				case 10:	ForceChangeLevel("c12m1_hilltop",		"服务器空闲且是三方图时，更换为官图");
				case 11:	ForceChangeLevel("c13m1_alpinecreek",	"服务器空闲且是三方图时，更换为官图");
				case 12:	ForceChangeLevel("c1m1_hotel",			"服务器空闲且是三方图时，更换为官图");
			}
			LogMessage("服务器空闲且检测到当前是三方图，正在更换为官图并休眠");
			SetConVarInt(FindConVar("sv_hibernate_when_empty"), 1);
			return Plugin_Stop;
		}
	} else {
		thirdparty_count = 0;
	}
	
	return Plugin_Handled;
}