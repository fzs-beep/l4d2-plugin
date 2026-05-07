/*
 *	注意:该插件需要点数商店插件才能运行.
 *
 *	v1.5.4
 *
 *	1:开奖记录和购买记录增加对齐显示(强迫症的福音).
 *	2:合并开奖插件和购买插件(更改了插件名称和inc名称)
 *
 *	v1.5.5
 *
 *	1:购买记录忘记+1了,导致从0开始算显示了.
 *
 * v1.5.6
 *
 *	1:中奖记录忘记+1了,导致从0开始算显示了.
 *	
 *	v1.5.7
 *	
 *	1:中奖记录还有一个地方忘记+1了,导致从0开始算显示了.
 *	2:中奖记录详细列表开奖号码和你的号码使用对齐显示.
 *	
 *	v1.6.7
 *	
 *	1:倒计时新增多少秒内才显示开奖倒计时.
 *	2:新增快速开关手电筒打开购买大乐透菜单.
 *	
 *	v1.7.7
 *	
 *	1:新增丢钱点数功能,此版本开始需要掉落钞票插件配合使用.
 *
 *	v1.7.8
 *	1:增加指令提示和快捷键功能开关.
 *
 *	v1.8.8
 *
 *	1:新增倒计时播放声音(可设置剩余多少时间才播放,玩家可关闭).
 *	2:新增下期开奖时间预告开关(玩家可关闭).
 *
 *	v1.8.9
 *
 *	1:购买记录菜单前面的期号忘记对齐显示.
 *
 *	v1.8.10
 *
 *	1:玩家离开时重新bool值为:true.
 *	2:删除多余的代码.
 *
 *	v1.9.10
 *
 *	1:新增点数回收计划,可购买射击或换弹加速.
 *
 *	v1.9.11
 *
 *	1:禁用大乐透菜单更改为开局自动打开大乐透菜单.
 *
 *	v1.9.12
 *
 *	1:新增设置自动打开菜单是显示时间.
 *
 *	v1.9.13
 *
 *	1:修复开奖倒计时结束后下一期开奖数字显示不正确的问题.
 *
 *	v1.10.13
 *
 *	1:更换开奖显示菜单的执行方式,改成读取数据成功就显示菜单.
 *	2:可设置最大重试时间,异步查询可能导致一些延迟,默认超时时间8秒.
 *	
 */
#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <l4d2_big_lotto>
#include <l4d2_points_lotto>

#define MAX_LENGTH		128		//字符串最大值.

#define PLUGIN_VERSION	"1.10.13"
#define CVAR_FLAGS		FCVAR_NOTIFY

//这里的变量更改后最好重开游戏,否则可能导致某些地方显示错误.
#define MAX_NUMBER		35		//设置随机值的最大范围(1-?).
#define MAX_WINNING		7		//设置随机的最大号码数量(必须大于中奖的最少号码数量).
#define MIN_WINNING		2		//设置获得奖励的最少数量(不能大于随机的最大号码数量).

#define BASE_VALUE		15		//设置奖励的基础值(值越大中奖的号码数量越多奖励越多).
#define TAX_RATES		0.7		//设置实际收入比例(平衡中奖的收入,其它可以理解为税收).

#define MIN_POINTS		5		//购买大乐透所需的最少点数.
#define MENU_TIME		20		//设置开奖和购买号码菜单的显示时间(单位:秒).
#define DRAE_TIME		450		//设置开奖时间的间隔(单位:秒).

#define MAX_RETRY_TIME	8		//设置显示菜单最大重试时间(单位:秒).
#define AUTO_MENU_TIME	30		//设置自动打开菜单显示时间(单位:秒).
#define COUNTDOWN_TIME	5		//设置播放开奖倒计时的时间(单位:秒).
#define DISPLAY_TIME	30		//设置显示开奖倒计时的时间(单位:秒).
#define DRAW_NOTICE		5		//设置下次开奖时间显示时间(单位:秒).

public Plugin myinfo =  
{
	name = "l4d2_points_data",
	author = "豆瓣酱な",
	description = "设置大乐透依赖插件和开奖插件购买插件的配置",
	version = PLUGIN_VERSION,
	url = "N/A"
};
//所有插件加载完成后执行一次(延迟加载插件也会执行一次).
public void OnAllPluginsLoaded()   
{
	IsBigLateLoad();//设置乐透依赖插件配置.
	IsBigLottoLoad();//设置乐透购买插件配置.
}
//乐透依赖插件加载时.
public void OnBigLateLoad(bool bLateLoad)
{
	IsBigLateLoad();//乐透依赖插件加载时.
}
void IsBigLateLoad()
{
	//设置基础配置(不设置则使用默认值).
	SetRandomRange(MAX_NUMBER);//设置随机值的最大范围.
	SetMaxIntNumber(MAX_WINNING);//设置随机的最大号码数量.
	SetMinIntNumber(MIN_WINNING);//设置随机的最小号码数量.
	SetBaseValue(BASE_VALUE);//设置奖励的基础值.
	SetPointsTaxRates(TAX_RATES);//设置收入税收比例.
}
//乐透购买插件加载时.
public void OnBigLottoLoad()   
{
	IsBigLottoLoad();//乐透购买插件加载时.
}
void IsBigLottoLoad()
{
	//设置基础配置(不设置则使用默认值).
	SetMenuMaxRetryTime(MAX_RETRY_TIME);	//设置显示菜单最大重试时间(单位:秒).
	SetDrawDisplays(DISPLAY_TIME);			//设置显示开奖倒计时的时间(单位:秒).
	SetCountdownSound(COUNTDOWN_TIME);		//设置播放开奖倒计时的时间(单位:秒).
	SetDrawIntervals(DRAE_TIME);			//设置开奖时间的间隔(单位:秒).
	SetLotteryInterval(DRAW_NOTICE);		//设置下次开奖时间显示时间(单位:秒).
	SetLotteryMenuTime(MENU_TIME);			//设置开奖和购买号码菜单的显示时间(单位:秒).
	SetLotteryMinPoints(MIN_POINTS);		//设置购买大乐透所需的最小点数.
	SetMenuDisplayTimer(AUTO_MENU_TIME);	//设置自动打开的菜单显示时间.
}
