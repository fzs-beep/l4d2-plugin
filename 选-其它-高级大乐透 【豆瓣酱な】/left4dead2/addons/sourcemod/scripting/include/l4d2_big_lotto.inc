#if defined _EvilBigLotto
 #endinput
#endif
#define _EvilBigLotto

public SharedPlugin __pl_l4d2_big_lotto = 
{
	name = "l4d2_big_lotto",
	file = "l4d2_big_lotto.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_big_lotto_SetNTVOptional()
{
	MarkNativeAsOptional("GetRandomRange");
	MarkNativeAsOptional("SetRandomRange");
	MarkNativeAsOptional("GetMaxIntNumber");
	MarkNativeAsOptional("SetMaxIntNumber");
	MarkNativeAsOptional("GetMinIntNumber");
	MarkNativeAsOptional("SetMinIntNumber");
	MarkNativeAsOptional("GetBaseValue");
	MarkNativeAsOptional("SetBaseValue");
	MarkNativeAsOptional("GetPointsTaxRates");
	MarkNativeAsOptional("SetPointsTaxRates");
	MarkNativeAsOptional("GetPointEarnings");
	MarkNativeAsOptional("GetRewardsNumber");
	MarkNativeAsOptional("GetRandomNumber");
	MarkNativeAsOptional("GetNumberQuantity");
	MarkNativeAsOptional("GetOrganizeNumber");
	MarkNativeAsOptional("GetWinningNumber");
}
#endif

/**
 * 获取随机值的最大范围.
 *
 * @return                  返回随机值的最大范围.
 */
native int GetRandomRange();

/**
 * 设置随机值的最大范围(从1开始的整数,必须是最大号码数量的两倍).
 *
 * @param iRange			传入随机值的最大范围.
 *
 * @noreturn
 */
native void SetRandomRange(int iRange);

/**
 * 获取随机的最大号码数量.
 *
 * @return                  返回随机的最大号码数量.
 */
native int GetMaxIntNumber();

/**
 * 设置随机的最大号码数量(必须大于中奖的最少号码数量).
 *
 * @param iQuantity			传入随机的最大号码数量.
 *
 * @noreturn
 */
native void SetMaxIntNumber(int iQuantity);

/**
 * 获取中奖的最少号码数量.
 *
 * @return                  返回中奖的最少号码数量.
 */
native int GetMinIntNumber();

/**
 * 设置中奖的最少号码数量(不能大于随机的最大号码数量).
 *
 * @param iQuantity			传入中奖的最少号码数量.
 *
 * @noreturn
 */
native void SetMinIntNumber(int iQuantity);

/**
 * 获取奖励的基础值.
 *
 * @return                  返回奖励的基础值.
 */
native int GetBaseValue();

/**
 * 设置计算奖励的基础值(这里的值越大中奖的号码越多结果越大).
 * 数量 = 中奖号码数量 - 最大号码数量.
 * 计算公式:收入 = 支出的积分 * (基础值 * (数量 * 数量 * 数量 + 5 * 数量) - 80).
 * 注意:数量 = 0 时是直接 * 实际收入比例.
 * 
 * @param iValue			传入奖励的基础值.
 *
 * @noreturn
 */
native void SetBaseValue(int iValue);

/**
 * 获取实际收入比例.
 *
 * @return                  返回实际收入比例.
 */
native float GetPointsTaxRates();

/**
 * 设置实际收入比例.
 *
 * @param fValue			传入实际收入比例.
 *
 * @noreturn
 */
native void SetPointsTaxRates(float fValue);

/**
 * 获取税收后的实际收入(这里的值越大中奖的号码越多结果越大).
 * 计算公式:点数收入*税收比例(使用RoundToFloor函数取整);
 *
 * @param iValue			传入支出点数数量.
 *
 * @return                  返回税收后的实际收入.
 */
native int GetPointEarnings(int iValue);

/**
 * 根据购买号码使用的积分和中奖的号码数量计算奖励.
 *
 * @param iPoints			传入消耗的积分数量.
 * @param iNumber			传入中奖的号码数量.
 *
 * @return					中奖号码数量大于或等于最少号码数量时返回奖励的数量,反之=0.
 */
native int GetRewardsNumber(int iPoints, int iNumber);

/**
 * 随机一组指定数量和数值范围的号码.
 *
 * @param sNumber			获取随机的号码.
 *
 * @return					成功时返回=true,反之=false.
 */
native bool GetRandomNumber(char[] sNumber);

/**
 * 获取号码组的号码数量.
 *
 * @param sNumber			传入号码字符串.
 *
 * @return					返回号码组里的号码数量.
 */
native int GetNumberQuantity(char[] sNumber);

/**
 * 号码组对齐(适用于显示).
 *
 * @param sNumber1		    传入需要用于对齐的号码字符串.
 * @param sNumber2		    传入需要用于对齐的号码字符串.
 * @param sNumber3		    传入需要用于对齐的号码字符串.
 *
 * @noreturn
 */
native void GetOrganizeNumber(char[] sNumber1, char[] sNumber2, char[] sNumber3 = "");

/**
 * 获取两组号码里重复的号码.
 *
 * @param sNumber1		    传入玩家的号码.
 * @param sNumber2		    传入开奖的号码.
 * @param sNumber3		    获取中奖的号码.
 *
 * @return                  返回中奖号码的数量.
 */
native int GetWinningNumber(char[] sNumber1, char[] sNumber2, char[] sNumber3);

/**
 * 大乐透依赖插件加载时调用(forward void OnAllPluginsLoaded()).
 *
 * @param bLateLoad		    插件被延迟加载=true,反之=false.
 *
 * @noreturn
 */
forward void OnBigLateLoad(bool bLateLoad);

/**
 * 大乐透依赖插件被卸载时调用(forward void OnPluginEnd()).
 *
 * @noreturn
 */
forward void OnLibrariesEnd();
