/*
 * v1.1.0
 *	
 *	1:当前钞票总数量或实体总数量超过设定值时不会刷出钞票.
 *
 * v1.2.0
 *	
 *	1:随机钞票颜色.
 *
 * v1.3.0
 *	
 *	1:新增Native和Forwards用于设置插件配置.
 *
 * v1.4.0
 *	
 *	1:新增拾取钞票时随机获得点数.
 *
 * v1.5.0
 *	
 *	1:新增丢失点数功能.
 *	2:此版本必须跟开奖插件一起使用.
 *
 * v1.6.0
 *	
 *	1:新增丢弃钞票的Forward转发.
 *	2:删除设置最低点数的设置函数(好像有兼容性问题).
 *	3:生还者死亡掉落和丢弃的钞票生还者拾取时会显示谁丢弃或掉落的.
 *
 * v1.7.0
 *	
 *	1:恢复设置最低点数的设置函数.
 *	2:取消设置份数,改成自动计算并随机.
 *	3:增加最低点数会直接*总点数,自动计算.
 *
 * v1.7.1
 *	
 *	1:丢弃点数和份数添加对齐显示.
 *
 * v1.7.2
 *	
 *	1:想方设法把最大份数减少了一些.
 *
 * v1.7.3
 *	
 *	1:重新更换了计算份数的方法.
 *
 * v1.7.4
 *	
 *	1:想不到吧,我又调整了下计算份数的方法.
 *	2:丢弃点数删除了自定义份数,改为随机份数.
 *
 * v1.7.5
 *	
 *	1:修复闲置玩家对应的生还者电脑死亡掉落的钞票拾取时名字显示不对的问题.
 *
 * v1.7.6
 *	
 *	1:修复每个钞票获得的最低点数小于最小值的问题.
 *
 * v1.7.7
 *	
 *	1:修复点数不足的情况下还能继续丢钱的BUG.
 *
 * v1.8.7
 *	
 *	1:新增玩家死亡的转发.
 *
 * v1.8.8
 *	
 *	1:更改玩家死亡的转发函数名(因为发现跟其它插件重复了).
 *
 * v1.9.8
 *	
 *	1:新增玩家成功拾取钞票的转发(forward void OnPlayerPickupMoney).
 *	2:成功拾取钞票的提示改到转发里设置.
 *	3:丢弃钞票的转发名称更改为(forward void OnPlayerDropItMoney)
 *
 */
#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <l4d2_points_fall>

#define MAX_LENGTH		128		//字符串最大值.

#define PLUGIN_VERSION	"1.9.8"
#define CVAR_FLAGS		FCVAR_NOTIFY

//掉落钞票插件的配置.
#define MAX_ENTITY_NUMBER		1900	//最大实体数量(最多:2048).
#define USE_MONEY_TIME			1.5		//设置拾取所需的时间/秒.
#define PLAYER_REMOVE_MONEY		60.0	//设置玩家丢弃的钞票的删除时间/秒.
#define SURVIVOR_REMOVE_MONEY	45.0	//设置生还者掉落钞票的删除时间/秒.
#define INFECTED_REMOVE_MONEY	30.0	//设置感染者掉落钞票的删除时间/秒.
#define MAX_MONEY_NUMBER		300		//设置钞票存在的最大数量.
#define MAX_BRIGHT_RANGE		800		//设置钞票的最大发光距离.
#define MIN_POINTS_VALUE		2		//设置每个钞票获得的最小点数(该值相当于总点数倍数).
#define MAX_POINTS_VALUE		7		//设置每个钞票获得的最大点数(钞票能获得的最大点数).

//生还者死亡掉落钞票(总点数:最小和最大).
int g_iSurvivorName[] = {15, 45};
//感染者死亡掉落钞票的概率().
char g_sZombieName[][][] = 
{
	//(概率:击杀和爆头)(总点数:最小和最大)
	{"舌头", "15", "25", "1", "2"},
	{"胖子", "10", "20", "1", "1"},
	{"猎人", "15", "35", "1", "2"},
	{"口水", "15", "20", "1", "1"},
	{"猴子", "15", "30", "1", "2"},
	{"牛牛", "25", "45", "3", "5"},
	{"女巫", "35", "65", "15", "35"},
	{"坦克", "100", "100", "35", "55"}
};

public Plugin myinfo =  
{
	name = "l4d2_points_info",
	author = "豆瓣酱な",
	description = "设置掉落钞票插件的配置",
	version = PLUGIN_VERSION,
	url = "N/A"
};
//所有插件加载完成后执行一次(延迟加载插件也会执行一次).
public void OnAllPluginsLoaded()   
{
	IsBanknotesFall();//设置掉落钞票插件配置.
}
//玩家成功拾取钞票时.
public void OnPlayerPickupMoney(int client, int number, int total)
{
	PrintToChat(client, "\x04[提示]\x05获得了\x03%d\x05点数\x04,\x05总共\x03%d\x05点数\x04.", number, total);
}
//玩家死亡时.
public void OnPlayerDeath(int entity, int total, int number, int remaining)
{
	/*
	if (IsValidEdict(entity))
	{
		char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (strcmp(classname, "witch") == 0)
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
					PrintToChat(i, "\x04[提示]\x05感染者\x03%s\x05已死亡,掉落\x03%d\x05点数\x04,\x05共\x03%d\x05份\x04.", g_sZombieName[6][0], total, number);
		}
	}
	*/
	if(IsValidClient(entity))
	{
		switch(GetClientTeam(entity))
		{
			case 2:
			{
				for (int i = 1; i <= MaxClients; i++)
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
					if(i != entity)
						PrintToChat(i, "\x04[提示]\x05生还者\x03%N\x05已死亡,掉落\x03%d\x05点数\x04,\x05共\x03%d\x05份\x04.", entity, total, number);
					else
						PrintToChat(entity, "\x04[提示]\x05你已死亡,掉落\x03%d\x05点数\x04,\x05共\x03%d\x05份\x04,\x05剩余\x03%d\x05点数\x04.", total, number, remaining);
						
			}
			/*
			case 3:
			{
				int iClass = GetEntProp(entity, Prop_Send, "m_zombieClass") - 1;

				for (int i = 1; i <= MaxClients; i++)
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
						PrintToChat(i, "\x04[提示]\x05感染者\x03%s\x05已死亡,掉落\x03%d\x05点数\x04,\x05共\x03%d\x05份\x04.", g_sZombieName[iClass][0], total, number);
			}
			*/
		}
	}
}
//玩家丢弃钞票时调用.
public void OnPointsDiscard(int client, int total, int number)
{
	for (int i = 1; i <= MaxClients; i++)
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
			PrintToChat(i, "\x04[提示]\x03%N\x05丢弃了\x03%d\x05点数\x04,\x05共\x03%d\x05份\x04.", client, total, number);
}
//掉落钞票插件加载时.
public void OnPointsFallLoad(bool bLateLoad)
{
	IsBanknotesFall();//掉落钞票插件加载时.
}
void IsBanknotesFall()
{
	//设置生还者死亡掉落的钞票数量(不设置则使用默认值).
	for (int i = 0; i < GetSurvivorFall(); i++)
		SetSurvivorFall(i, g_iSurvivorName[i]);

	int value[2];
	GetInfectedFall(value);
	//设置感染者死亡掉落钞票的概率和数量.
	for (int i = 0; i < value[0]; i++)
		for (int y = 0; y < value[1]; y++)
			SetInfectedFall(i, y, g_sZombieName[i][y]);

	SetUseMoneyTime(USE_MONEY_TIME);//设置拾取时间.
	SetMaxEntityNumber(MAX_ENTITY_NUMBER);//最大实体数量(最多:2048).
	SetMaxBrightRange(MAX_BRIGHT_RANGE);//设置钞票的最大发光距离.
	SetMaxMoneyNumber(MAX_MONEY_NUMBER);//设置钞票存在的最大数量.
	SetPlayerRemoveMoney(PLAYER_REMOVE_MONEY);//设置玩家丢弃的钞票的删除时间/秒.
	SetSurvivorRemoveMoney(SURVIVOR_REMOVE_MONEY);//设置生还者掉落钞票的删除时间/秒.
	SetInfectedRemoveMoney(INFECTED_REMOVE_MONEY);//设置感染者掉落钞票的删除时间/秒.
	SetMinPointsValue(MIN_POINTS_VALUE);//设置每个钞票获得的最小点数.
	SetMaxPointsValue(MAX_POINTS_VALUE);//设置每个钞票获得的最大点数.
}
//判断玩家有效.
stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}