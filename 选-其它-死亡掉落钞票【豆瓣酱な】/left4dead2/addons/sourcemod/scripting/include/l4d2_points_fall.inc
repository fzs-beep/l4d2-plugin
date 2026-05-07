#if defined _EvilPointsFall
 #endinput
#endif
#define _EvilPointsFall

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
	MarkNativeAsOptional("OpenDropPoints");
	MarkNativeAsOptional("GetSurvivorFall");
	MarkNativeAsOptional("SetSurvivorFall");
	MarkNativeAsOptional("GetInfectedFall");
	MarkNativeAsOptional("SetInfectedFall");
	MarkNativeAsOptional("GetUseMoneyTime");
	MarkNativeAsOptional("SetUseMoneyTime");
	MarkNativeAsOptional("GetMaxEntityNumber");
	MarkNativeAsOptional("SetMaxEntityNumber");
	MarkNativeAsOptional("GetMaxBrightRange");
	MarkNativeAsOptional("SetMaxBrightRange");
	MarkNativeAsOptional("GetMaxMoneyNumber");
	MarkNativeAsOptional("SetMaxMoneyNumber");
	MarkNativeAsOptional("GetMinPointsValue");
	MarkNativeAsOptional("SetMinPointsValue");
	MarkNativeAsOptional("GetMaxPointsValue");
	MarkNativeAsOptional("SetMaxPointsValue");
	MarkNativeAsOptional("GetPlayerRemoveMoney");
	MarkNativeAsOptional("SetPlayerRemoveMoney");
	MarkNativeAsOptional("GetSurvivorRemoveMoney");
	MarkNativeAsOptional("SetSurvivorRemoveMoney");
	MarkNativeAsOptional("GetInfectedRemoveMoney");
	MarkNativeAsOptional("SetInfectedRemoveMoney");
}
#endif

/**
 * 打开丢弃点数菜单.
 *
 * @param client           传入玩家的索引.
 *
 * @noreturn
 */
native void OpenDropPoints(int client);

/**
 * 获取生还者掉落钞票的数组大小.
 *
 * @return                  返回数组的大小.
 */
native int GetSurvivorFall();

/**
 * 设置生还者掉落的点数.
 *
 * @param row               传入数组的行.
 * @param value             传入设置的值.
 *
 * @noreturn
 */
native void SetSurvivorFall(int row, int value);

/**
 * 获取感染者死亡掉落钞票的数组大小.
 *
* @param value	            数组的最大行和列数量.
 *
 * @noreturn
 */
native void GetInfectedFall(int value[2]);

/**
 * 设置击杀感染者掉落钞票的概率和掉落钞票的数量.
 *
 * @param row               传入数组的行.
 * @param column	        传入数组的列.
 * @param buffer	        传入设置的字符串.
 *
 * @noreturn
 */
native void SetInfectedFall(int row, int column, char[] buffer);

/**
 * 获取拾取钞票所需的时间/秒.
 *
 * @return                  返回拾取所需的时间.
 */
native int GetUseMoneyTime();

/**
 * 设置拾取钞票所需的时间/秒.
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetUseMoneyTime(float value);

/**
 * 获取限制创建钞票的最大实体总数量(最大实体数量:2048).
 *
 * @return                  返回最大实体数量.
 */
native int GetMaxEntityNumber();

/**
 * 设置限制创建钞票的最大实体总数量(最大实体数量:2048).
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetMaxEntityNumber(int value);

/**
 * 获取钞票的最大发光距离.
 *
 * @return                  返回最大发光距离.
 */
native int GetMaxBrightRange();

/**
 * 设置钞票的最大发光距离.
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetMaxBrightRange(int value);

/**
 * 获取同时存在的最大钞票总数量.
 *
 * @return                  返回最大钞票总数量.
 */
native int GetMaxMoneyNumber();

/**
 * 设置同时存在的最大钞票总数量.
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetMaxMoneyNumber(int value);

/**
 * 获取每个钞票获得的最小点数.
 *
 * @return                  返回每个钞票获得的最小点数.
 */
native int GetMinPointsValue();

/**
 * 设置每个钞票获得的最小点数.
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetMinPointsValue(int value);

/**
 * 获取每个钞票获得的最大点数.
 *
 * @return                  返回每个钞票获得的最大点数.
 */
native int GetMaxPointsValue();

/**
 * 设置每个钞票获得的最大点数.
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetMaxPointsValue(int value);

/**
 * 获取玩家丢弃的钞票的删除时间/秒.
 *
 * @return                  返回钞票的存在时间.
 */
native int GetPlayerRemoveMoney();

/**
 * 设置玩家丢弃的钞票的删除时间/秒.
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetPlayerRemoveMoney(float value);

/**
 * 获取生还者掉落钞票的删除时间/秒.
 *
 * @return                  返回钞票的存在时间.
 */
native int GetSurvivorRemoveMoney();

/**
 * 设置生还者掉落钞票的删除时间/秒.
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetSurvivorRemoveMoney(float value);

/**
 * 获取感染者掉落钞票的删除时间/秒.
 *
 * @return                  返回钞票的存在时间.
 */
native int GetInfectedRemoveMoney();

/**
 * 设置感染者掉落钞票的删除时间/秒.
 *
 * @param value               传入需要设置的值.
 *
 * @noreturn
 */
native void SetInfectedRemoveMoney(float value);

/**
 * 玩家死亡时调用.
 *
 * @param entity		    实体的索引.
 * @param total		        点数总数量.
 * @param number		    钞票总数量.
 * @param remaining		    剩余总数量(只限团队2的真实玩家).
 *
 * @noreturn
 */
forward void OnPlayerDeathFall(int entity, int total, int number, int remaining);

/**
 * 玩家成功拾取钞票时调用.
 *
 * @param client		    玩家的索引.
 * @param number		    获得的数量.
 * @param total		    	点数总数量.
 *
 * @noreturn
 */
forward void OnPlayerPickupMoney(int client, int number, int total);

/**
 * 玩家成功丢弃钞票时调用.
 *
 * @param client		    玩家的索引.
 * @param total		        点数总数量.
 * @param number		    钞票总数量.
 *
 * @noreturn
 */
forward void OnPlayerDropItMoney(int client, int total, int number);

/**
 * 掉落钞票插件加载时调用(forward void OnAllPluginsLoaded()).
 *
 * @param bLateLoad		    插件被延迟加载=true,反之=false.
 *
 * @noreturn
 */
forward void OnPointsFallLoad(bool bLateLoad);

/**
 * 掉落钞票插件卸载时调用(forward void OnPluginEnd()).
 *
 * @noreturn
 */
forward void OnPointsFallEnd();