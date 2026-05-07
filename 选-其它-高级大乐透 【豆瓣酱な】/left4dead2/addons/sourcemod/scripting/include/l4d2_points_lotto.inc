#if defined _EvilPointsDrawn
 #endinput
#endif
#define _EvilPointsDrawn

public SharedPlugin __pl_l4d2_points_fall = 
{
	name = "l4d2_points_fall",
	file = "l4d2_points_fall.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_points_fall_SetNTVOptional()
{
	MarkNativeAsOptional("IsOpenBigLottoMenu");
	MarkNativeAsOptional("IsBigLottoBuyStatus");
	MarkNativeAsOptional("IsLotteryTipsStatus");
	MarkNativeAsOptional("IsLotteryPlayStatus");
	MarkNativeAsOptional("IsLotteryMenuStatus");
	MarkNativeAsOptional("GetMenuDisplayTimer");
	MarkNativeAsOptional("SetMenuDisplayTimer");
	MarkNativeAsOptional("GetLotteryMinPoints");
	MarkNativeAsOptional("SetLotteryMinPoints");
	MarkNativeAsOptional("GetLotteryMenuTime");
	MarkNativeAsOptional("SetLotteryMenuTime");
	MarkNativeAsOptional("GetDrawIntervals");
	MarkNativeAsOptional("SetDrawIntervals");
	MarkNativeAsOptional("GetLotteryInterval");
	MarkNativeAsOptional("SetLotteryInterval");
	MarkNativeAsOptional("GetDrawDisplays");
	MarkNativeAsOptional("SetDrawDisplays");
	MarkNativeAsOptional("GetCountdownSound");
	MarkNativeAsOptional("SetCountdownSound");
	MarkNativeAsOptional("GetArrayLength");
	MarkNativeAsOptional("GetDrawnNumbers");
	MarkNativeAsOptional("GetClonesHandle");
}
#endif

/**
 * 打开大乐透菜单.
 *
 * @param client	        传入玩家的index索引.
 *
 * @noreturn
 */
native void IsOpenBigLottoMenu(int client);

/**
 * 获取大乐透购买状态.
 *
 * @param client	        传入玩家的index索引.
 *
 * @return                  已购买大乐透返回=true,反之=false.
 */
native bool IsBigLottoBuyStatus(int client);

/**
 * 获取开奖提示显示状态.
 *
 * @param client	        传入玩家的index索引.
 *
 * @return                  显示开奖提示=true,反之=false.
 */
native bool IsLotteryTipsStatus(int client);

/**
 * 获取开奖声音播放状态.
 *
 * @param client	        传入玩家的index索引.
 *
 * @return                  播放开奖声音=true,反之=false.
 */
native bool IsLotteryPlayStatus(int client);

/**
 * 获取开奖菜单显示状态.
 *
 * @param client	        传入玩家的index索引.
 *
 * @return                  显示开奖菜单=true,反之=false.
 */
native bool IsLotteryMenuStatus(int client);

/**
 * 获取显示菜单最大重试时间.
 *
 * @return                  返回显示菜单最大重试时间.
 */
native int GetMenuMaxRetryTime();

/**
 * 设置显示菜单最大重试时间.
 *
 * @param iValue	        传入显示菜单最大重试时间.
 *
 * @noreturn
 */
native void SetMenuMaxRetryTime(int iValue);

/**
 * 获取自动打开的菜单显示时间.
 *
 * @return                  返回自动打开的菜单显示时间.
 */
native int GetMenuDisplayTimer();

/**
 * 设置自动打开的菜单显示时间.
 *
 * @param iValue	        传入自动打开的菜单显示时间.
 *
 * @noreturn
 */
native void SetMenuDisplayTimer(int iValue);

/**
 * 获取购买大乐透所需的最小点数.
 *
 * @return                  返回购买大乐透所需的最小点数.
 */
native int GetLotteryMinPoints();

/**
 * 设置购买大乐透所需的最小点数.
 *
 * @param iValue	        传入购买大乐透所需的最小点数.
 *
 * @noreturn
 */
native void SetLotteryMinPoints(int iValue);

/**
 * 获取开奖和购买号码菜单的显示时间(单位:秒).
 *
 * @return                  返回开奖和购买号码菜单的显示时间.
 */
native int GetLotteryMenuTime();

/**
 * 设置开奖和购买号码菜单的显示时间(单位:秒).
 *
 * @param iValue	        传入开奖和购买号码菜单的显示时间.
 *
 * @noreturn
 */
native void SetLotteryMenuTime(int iValue);

/**
 * 获取开奖时间的间隔(单位:秒).
 *
 * @return                  返回开奖时间的间隔.
 */
native int GetDrawIntervals();

/**
 * 设置开奖时间的间隔(单位:秒).
 *
 * @param iDrawIntervals	传入开奖时间的间隔.
 *
 * @noreturn
 */
native void SetDrawIntervals(int iDrawIntervals);

/**
 * 获取开奖结果显示时间(单位:秒).
 *
 * @return                  返回开奖结果显示时间.
 */
native int GetLotteryInterval();

/**
 * 设置开奖结果显示时间(单位:秒).
 *
 * @param value	            传入开奖结果显示时间.
 *
 * @noreturn
 */
native void SetLotteryInterval(int value);

/**
 * 获取显示开奖倒计时的时间(单位:秒).
 *
 * @return                  返回显示开奖倒计时的时间.
 */
native int GetDrawDisplays();

/**
 * 设置显示开奖倒计时的时间(单位:秒).
 *
 * @param value         	传入开奖结果显示时间.
 *
 * @noreturn
 */
native void SetDrawDisplays(int value);

/**
 * 获取显示开奖倒计时的时间(单位:秒).
 *
 * @return                  返回显示开奖倒计时的时间.
 */
native int GetCountdownSound();

/**
 * 设置显示开奖倒计时的时间(单位:秒).
 *
 * @param value         	传入显示开奖倒计时的时间.
 *
 * @noreturn
 */
native void SetCountdownSound(int value);

/**
 * 获取开奖号码的动态数组大小.
 *
 * @return                  返回开奖号码的动态数组大小.
 */
native int GetArrayLength();

/**
 * 获取指定位置的开奖号码.
 *
 * @param index		        数组中的索引.
 * @param sNumber		    需要复制的字符串.
 * @param maxlength		    字符串的最大大小.
 *
 * @noreturn
 */
native void GetDrawnNumbers(int index, char[] sNumber, int maxlength);

/**
 * 获取开奖号码的动态数组句柄.
 *
 * @return                  返回开奖号码的动态数组句柄.
 */
native ArrayList GetClonesHandle();

/**
 * 开奖时的转发.
 *
 * @param iLength		    获取动态数组大小.
 * @param sNumber		    获取开奖时的号码.
 *
 * @noreturn
 */
forward void OnBigLottoStart(int iLength, char[] sNumber);

/**
 * 大乐透开奖插件加载时调用(forward void OnAllPluginsLoaded()).
 *
 * @param bLateLoad		    插件被延迟加载=true,反之=false.
 *
 * @noreturn
 */
forward void OnBigLottoLoad(bool bLateLoad);

/**
 * 大乐透开奖插件卸载时调用(forward void OnPluginEnd()).
 *
 * @noreturn
 */
forward void OnBigLottoEnd();