/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This file is part of the SourceMod/SourcePawn SDK.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#if defined _entity_prop_stocks_included
	#endinput
#endif
#define _entity_prop_stocks_included

enum MoveType
{
	MOVETYPE_NONE = 0,	 /**< 从不移动 */
	MOVETYPE_ISOMETRIC,	 /**< 用于玩家 */
	MOVETYPE_WALK,		 /**< 仅玩家 - 在地面上移动 */
	MOVETYPE_STEP,		 /**< 受重力影响，特殊边缘处理——怪物使用此类型 */
	MOVETYPE_FLY,		 /**< 无重力，但仍与物体碰撞 */
	MOVETYPE_FLYGRAVITY, /**< 在空中飞行并受重力影响 */
	MOVETYPE_VPHYSICS,	 /**< 使用 VPHYSICS 进行模拟 */
	MOVETYPE_PUSH,		 /**< 不与世界发生碰撞，但能推动和碾压 */
	MOVETYPE_NOCLIP,	 /**< 无重力，无碰撞，仍保持速度和角速度 */
	MOVETYPE_LADDER,	 /**< 仅玩家在梯子上时使用 */
	MOVETYPE_OBSERVER,	 /**< 观察者移动，取决于玩家的观察者模式 */
	MOVETYPE_CUSTOM		 /**< 允许实体定义自己的物理行为 */
};

enum RenderMode
{
	RENDER_NORMAL,			   /**< 源颜色 */
	RENDER_TRANSCOLOR,		   /**< 源颜色 * 透明度 + 目标颜色 * (1-透明度) */
	RENDER_TRANSTEXTURE,	   /**< 源纹理 * 透明度 + 目标颜色 * (1-透明度) */
	RENDER_GLOW,			   /**< 源颜色 * 透明度 + 目标颜色 —— 无 Z 缓冲检查 —— 屏幕空间固定大小 */
	RENDER_TRANSALPHA,		   /**< 源颜色 * 源透明度 + 目标颜色 * (1-源透明度) */
	RENDER_TRANSADD,		   /**< 源颜色 * 透明度 + 目标颜色 */
	RENDER_ENVIRONMENTAL,	   /**< 不被绘制，用于环境效果 */
	RENDER_TRANSADDFRAMEBLEND, /**< 使用分数帧值在动画帧之间混合 */
	RENDER_TRANSALPHAADD,	   /**< 源颜色 + 目标颜色 * (1-透明度) */
	RENDER_WORLDGLOW,		   /**< 与 kRenderGlow 相同，但屏幕空间大小不固定 */
	RENDER_NONE				   /**< 不渲染。 */
};

enum RenderFx
{
	RENDERFX_NONE = 0,
	RENDERFX_PULSE_SLOW,
	RENDERFX_PULSE_FAST,
	RENDERFX_PULSE_SLOW_WIDE,
	RENDERFX_PULSE_FAST_WIDE,
	RENDERFX_FADE_SLOW,
	RENDERFX_FADE_FAST,
	RENDERFX_SOLID_SLOW,
	RENDERFX_SOLID_FAST,
	RENDERFX_STROBE_SLOW,
	RENDERFX_STROBE_FAST,
	RENDERFX_STROBE_FASTER,
	RENDERFX_FLICKER_SLOW,
	RENDERFX_FLICKER_FAST,
	RENDERFX_NO_DISSIPATION,
	RENDERFX_DISTORT,		  /**< 扭曲/缩放/平移闪烁 */
	RENDERFX_HOLOGRAM,		  /**< kRenderFxDistort + 距离淡出 */
	RENDERFX_EXPLODE,		  /**< 放大到非常大！ */
	RENDERFX_GLOWSHELL,		  /**< 发光外壳 */
	RENDERFX_CLAMP_MIN_SCALE, /**< 防止此精灵变得非常小（仅限 SPRITES！） */
	RENDERFX_ENV_RAIN,		  /**< 用于环境渲染模式，制造雨 */
	RENDERFX_ENV_SNOW,		  /**< 用于环境渲染模式，制造雪 */
	RENDERFX_SPOTLIGHT,		  /**< 实验性聚光灯的测试代码 */
	RENDERFX_RAGDOLL,		  /**< HACKHACK：用于标记布娃娃角色死亡的测试代码 */
	RENDERFX_PULSE_FAST_WIDER,
	RENDERFX_MAX
};

// 以下定义用于客户端按键，每个宏代表一个二进制位，组合后表示玩家当前按下的所有按键。
#define IN_ATTACK				 (1 << 0)  /**<值: 1		主要攻击（通常为鼠标左键） */
#define IN_JUMP					 (1 << 1)  /**<值: 2		跳跃（通常为空格键） */
#define IN_DUCK					 (1 << 2)  /**<值: 4		下蹲/蹲下（通常为 Ctrl 键） */
#define IN_FORWARD				 (1 << 3)  /**<值: 8		向前移动（通常为 W 键） */
#define IN_BACK					 (1 << 4)  /**<值: 16		向后移动（通常为 S 键） */
#define IN_USE					 (1 << 5)  /**<值: 32		使用/互动（通常为 E 键，如开门、拆弹、救人） */
#define IN_CANCEL				 (1 << 6)  /**<值: 64		取消（极少使用，可能用于某些 UI 取消动作） */
#define IN_LEFT					 (1 << 7)  /**<值: 128		视角向左转（通常为鼠标向左移动，或键盘方向键左） */
#define IN_RIGHT				 (1 << 8)  /**<值: 256		视角向右转（通常为鼠标向右移动，或键盘方向键右） */
#define IN_MOVELEFT				 (1 << 9)  /**<值: 512		向左平移（通常为 A 键，即左移） */
#define IN_MOVERIGHT			 (1 << 10) /**<值: 1024		向右平移（通常为 D 键，即右移） */
#define IN_ATTACK2				 (1 << 11) /**<值: 2048		次要攻击/特殊功能（通常为鼠标右键，如开镜、投掷等） */
#define IN_RUN					 (1 << 12) /**<值: 4096		奔跑/加速（通常为 Shift 键，按住时加快移动速度） */
#define IN_RELOAD				 (1 << 13) /**<值: 8192		重新装弹（通常为 R 键） */
#define IN_ALT1					 (1 << 14) /**<值: 16384	备用动作1（游戏特定，如 L4D 中的呼喊） */
#define IN_ALT2					 (1 << 15) /**<值: 32768	备用动作2（游戏特定，如 L4D 中的特殊指令） */
#define IN_SCORE				 (1 << 16) /**<值: 65536	显示计分板（通常为 Tab 键，由 client.dll 处理） */
#define IN_SPEED				 (1 << 17) /**<值: 131072	速度键（通常为 Shift 键，与 IN_RUN 类似，但可能用于步行/奔跑切换） */
#define IN_WALK					 (1 << 18) /**<值: 262144	行走/慢走（通常为 Alt 键，按住时切换为静步或慢走） */
#define IN_ZOOM					 (1 << 19) /**<值: 524288	缩放/瞄准镜（通常为鼠标中键或右键长按，用于狙击镜或望远镜） */
#define IN_WEAPON1				 (1 << 20) /**<值: 1048576	武器选择1（通常为数字键 1，用于切换到主武器） */
#define IN_WEAPON2				 (1 << 21) /**<值: 2097152	武器选择2（通常为数字键 2，用于切换到副武器） */
#define IN_BULLRUSH				 (1 << 22) /**<值: 4194304	冲锋/冲刺（常见于 L4D，按住时快速奔跑并推开队友/丧尸） */
#define IN_GRENADE1				 (1 << 23) /**<值: 8388608	投掷物1（通常为数字键 4 或 G 键，用于切换或投掷第一种手雷） */
#define IN_GRENADE2				 (1 << 24) /**<值: 16777216	投掷物2（通常为数字键 5，用于切换或投掷第二种手雷） */
#define IN_ATTACK3				 (1 << 25) /**<值: 33554432	第三次攻击/特殊攻击（游戏特定，如某些模组的额外攻击方式） */

// 注意：这些仅用于 GetEntityFlags 和 SetEntityFlags，
//       可能与游戏实际的内部 m_fFlags 值不匹配。
// 首先定义玩家特定标志，因为我们只使用网络精度的少数位。
#define FL_ONGROUND				 (1 << 0) /**< 静止/在地面上 */
#define FL_DUCKING				 (1 << 1) /**< 玩家标志 —— 玩家完全蹲下 */
#define FL_WATERJUMP			 (1 << 2) /**< 玩家跳出水面 */
#define FL_ONTRAIN				 (1 << 3) /**< 玩家正在控制火车，因此在预测期间应忽略移动命令。 */
#define FL_INRAIN				 (1 << 4) /**< 表示实体站在雨中 */
#define FL_FROZEN				 (1 << 5) /**< 玩家因第三人称相机而冻结 */
#define FL_ATCONTROLS			 (1 << 6) /**< 玩家无法移动，但保留按键输入以控制另一个实体 */
#define FL_CLIENT				 (1 << 7) /**< 是玩家 */
#define FL_FAKECLIENT			 (1 << 8) /**< 假客户端，服务器端模拟；不向它们发送网络消息 */
// 注意：如果向上移动内容，请务必更改此值
#define PLAYER_FLAG_BITS		 9
// 非玩家特定（即不被 GameMovement 或 client.dll 使用）——但仍可应用于玩家
#define FL_INWATER				 (1 << 9)  /**< 在水中 */
#define FL_FLY					 (1 << 10) /**< 更改 SV_Movestep() 行为，无需在地面上 */
#define FL_SWIM					 (1 << 11) /**< 更改 SV_Movestep() 行为，无需在地面上（但停留在水中） */
#define FL_CONVEYOR				 (1 << 12)
#define FL_NPC					 (1 << 13)
#define FL_GODMODE				 (1 << 14)
#define FL_NOTARGET				 (1 << 15)
#define FL_AIMTARGET			 (1 << 16) /**< 设置如果准星需要瞄准该实体 */
#define FL_PARTIALGROUND		 (1 << 17) /**< 并非所有角落都有效 */
#define FL_STATICPROP			 (1 << 18) /**< 这是个静态道具！ */
#define FL_GRAPHED				 (1 << 19) /**< 世界图将此实体列为阻挡连接的东西 */
#define FL_GRENADE				 (1 << 20)
#define FL_STEPMOVEMENT			 (1 << 21) /**< 更改 SV_Movestep() 行为，不进行任何处理 */
#define FL_DONTTOUCH			 (1 << 22) /**< 不产生触碰函数，为任何在此标志设置时正在触碰的对象生成 Untouch() */
#define FL_BASEVELOCITY			 (1 << 23) /**< 基础速度已在此帧应用（用于将基础速度转换为动量） */
#define FL_WORLDBRUSH			 (1 << 24) /**< 不可移动/移除的刷子实体（实际上是世界的一部分，但为了透明度或其他原因而表示为实体） */
#define FL_OBJECT				 (1 << 25) /**< 名称糟糕。这是 NPC 应该看到的物体。例如导弹。 */
#define FL_KILLME				 (1 << 26) /**< 此实体标记为死亡 —— 将由游戏 DLL 释放 */
#define FL_ONFIRE				 (1 << 27) /**< 你知道... */
#define FL_DISSOLVING			 (1 << 28) /**< 我们正在溶解！ */
#define FL_TRANSRAGDOLL			 (1 << 29) /**< 正在转变为客户端布娃娃的过程中。 */
#define FL_UNBLOCKABLE_BY_PLAYER (1 << 30) /**< 不能被玩家阻挡的推动者 */
#define FL_FREEZING				 (1 << 31) /**< 我们正在冻结！ */
#define FL_EP2V_UNKNOWN1		 (1 << 31) /**< 未知 */
// END entity flag #defines

/**
 * Get an entity's flags.
 *
 * @note The game's actual flags are internally translated by SM
 *       to match the entity flags defined above as the actual values
 *       can differ per engine.
 *
 * @param entity        Entity index.
 * @return              Entity's flags, see entity flag defines above.
 * @error               Invalid entity index, or lack of mod compliance.
 */
native int	   GetEntityFlags(int entity);

/**
 * Sets an entity's flags.
 *
 * @note The entity flags as defined above are internally translated by SM
 *       to match the current game's expected value for the flags as
 *       the actual values can differ per engine.
 *
 * @param entity        Entity index.
 * @param flags         Entity flags, see entity flag defines above.
 * @error               Invalid entity index, or lack of mod compliance.
 */
native void	   SetEntityFlags(int entity, int flags);

/**
 * Gets an entity's movetype.
 *
 * @param entity        Entity index.
 * @return              Movetype, see enum above.
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock MoveType GetEntityMoveType(int entity)
{
	static bool gotconfig = false;
	static char datamap[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_MoveType", datamap, sizeof(datamap));
		delete gc;

		if (!exists)
		{
			strcopy(datamap, sizeof(datamap), "m_MoveType");
		}

		gotconfig = true;
	}

	return view_as<MoveType>(GetEntProp(entity, Prop_Data, datamap));
}

/**
 * Sets an entity's movetype.
 *
 * @param entity        Entity index.
 * @param mt            Movetype, see enum above.
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock void SetEntityMoveType(int entity, MoveType mt)
{
	static bool gotconfig = false;
	static char datamap[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_MoveType", datamap, sizeof(datamap));
		delete gc;

		if (!exists)
		{
			strcopy(datamap, sizeof(datamap), "m_MoveType");
		}

		gotconfig = true;
	}

	SetEntProp(entity, Prop_Data, datamap, mt);
}

/**
 * Gets an entity's render mode.
 *
 * @param entity        Entity index.
 * @return              RenderMode value.
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock RenderMode GetEntityRenderMode(int entity)
{
	static bool gotconfig = false;
	static char prop[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_nRenderMode", prop, sizeof(prop));
		delete gc;

		if (!exists)
		{
			strcopy(prop, sizeof(prop), "m_nRenderMode");
		}

		gotconfig = true;
	}

	return view_as<RenderMode>(GetEntProp(entity, Prop_Send, prop, 1));
}

/**
 * Sets an entity's render mode.
 *
 * @param entity        Entity index.
 * @param mode          RenderMode value.
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock void SetEntityRenderMode(int entity, RenderMode mode)
{
	static bool gotconfig = false;
	static char prop[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_nRenderMode", prop, sizeof(prop));
		delete gc;

		if (!exists)
		{
			strcopy(prop, sizeof(prop), "m_nRenderMode");
		}

		gotconfig = true;
	}

	SetEntProp(entity, Prop_Send, prop, mode, 1);
}

/**
 * Gets an entity's render Fx.
 *
 * @param entity        Entity index.
 * @return              RenderFx value.
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock RenderFx GetEntityRenderFx(int entity)
{
	static bool gotconfig = false;
	static char prop[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_nRenderFX", prop, sizeof(prop));
		delete gc;

		if (!exists)
		{
			strcopy(prop, sizeof(prop), "m_nRenderFX");
		}

		gotconfig = true;
	}

	return view_as<RenderFx>(GetEntProp(entity, Prop_Send, prop, 1));
}

/**
 * Sets an entity's render Fx.
 *
 * @param entity        Entity index.
 * @param fx            RenderFx value.
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock void SetEntityRenderFx(int entity, RenderFx fx)
{
	static bool gotconfig = false;
	static char prop[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_nRenderFX", prop, sizeof(prop));
		delete gc;

		if (!exists)
		{
			strcopy(prop, sizeof(prop), "m_nRenderFX");
		}

		gotconfig = true;
	}

	SetEntProp(entity, Prop_Send, prop, fx, 1);
}

/**
 * Gets an entity's color.
 *
 * @param entity        Entity index.
 * @param r             Amount of red (0-255)
 * @param g             Amount of green (0-255)
 * @param b             Amount of blue (0-255)
 * @param a             Amount of alpha (0-255)
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock void GetEntityRenderColor(int entity, int &r, int &g, int &b, int &a)
{
	static bool gotconfig = false;
	static char prop[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_clrRender", prop, sizeof(prop));
		delete gc;

		if (!exists)
		{
			strcopy(prop, sizeof(prop), "m_clrRender");
		}

		gotconfig = true;
	}

	int offset = GetEntSendPropOffs(entity, prop);

	if (offset <= 0)
	{
		ThrowError("GetEntityRenderColor not supported by this mod");
	}

	r = GetEntData(entity, offset, 1);
	g = GetEntData(entity, offset + 1, 1);
	b = GetEntData(entity, offset + 2, 1);
	a = GetEntData(entity, offset + 3, 1);
}

/**
 * Sets an entity's color.
 *
 * @param entity        Entity index
 * @param r             Amount of red (0-255)
 * @param g             Amount of green (0-255)
 * @param b             Amount of blue (0-255)
 * @param a             Amount of alpha (0-255)
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock void SetEntityRenderColor(int entity, int r = 255, int g = 255, int b = 255, int a = 255)
{
	static bool gotconfig = false;
	static char prop[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_clrRender", prop, sizeof(prop));
		delete gc;

		if (!exists)
		{
			strcopy(prop, sizeof(prop), "m_clrRender");
		}

		gotconfig = true;
	}

	int offset = GetEntSendPropOffs(entity, prop);

	if (offset <= 0)
	{
		ThrowError("SetEntityRenderColor not supported by this mod");
	}

	SetEntData(entity, offset, r, 1, true);
	SetEntData(entity, offset + 1, g, 1, true);
	SetEntData(entity, offset + 2, b, 1, true);
	SetEntData(entity, offset + 3, a, 1, true);
}

/**
 * Gets an entity's gravity.
 *
 * @param entity 	Entity index.
 * @return              Entity's m_flGravity value.
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock float GetEntityGravity(int entity)
{
	static bool gotconfig = false;
	static char datamap[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_flGravity", datamap, sizeof(datamap));
		delete gc;

		if (!exists)
		{
			strcopy(datamap, sizeof(datamap), "m_flGravity");
		}

		gotconfig = true;
	}

	return GetEntPropFloat(entity, Prop_Data, datamap);
}

/**
 * Sets an entity's gravity.
 *
 * @param entity        Entity index.
 * @param amount        Gravity to set (default = 1.0, half = 0.5, double = 2.0).
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock void SetEntityGravity(int entity, float amount)
{
	static bool gotconfig = false;
	static char datamap[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_flGravity", datamap, sizeof(datamap));
		delete gc;

		if (!exists)
		{
			strcopy(datamap, sizeof(datamap), "m_flGravity");
		}

		gotconfig = true;
	}

	SetEntPropFloat(entity, Prop_Data, datamap, amount);
}

/**
 * Sets an entity's health
 *
 * @param entity        Entity index.
 * @param amount        Health amount.
 * @error               Invalid entity index, or lack of mod compliance.
 */
stock void SetEntityHealth(int entity, int amount)
{
	static bool gotconfig = false;
	static char prop[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_iHealth", prop, sizeof(prop));
		delete gc;

		if (!exists)
		{
			strcopy(prop, sizeof(prop), "m_iHealth");
		}

		gotconfig = true;
	}

	PropFieldType type;
	int			  offset;

	if ((offset = FindDataMapInfo(entity, prop, type)) == -1)
	{
		ThrowError("SetEntityHealth not supported by this mod");
		return;
	}

	/* Dark Messiah uses a float for the health instead an integer */
	if (type == PropField_Float)
	{
		SetEntDataFloat(entity, offset, float(amount));
	}
	else
	{
		SetEntData(entity, offset, amount);
	}

	if (IsValidEdict(entity))
	{
		ChangeEdictState(entity);
	}
}

/**
 * Get's a users current pressed buttons
 *
 * @param client        Client index
 * @return              Bitsum of buttons
 * @error               Invalid client index, client not in game,
 *                      or lack of mod compliance.
 */
stock int GetClientButtons(int client)
{
	static bool gotconfig = false;
	static char datamap[32];

	if (!gotconfig)
	{
		GameData gc		= new GameData("core.games");
		bool	 exists = gc.GetKeyValue("m_nButtons", datamap, sizeof(datamap));
		delete gc;

		if (!exists)
		{
			strcopy(datamap, sizeof(datamap), "m_nButtons");
		}

		gotconfig = true;
	}

	return GetEntProp(client, Prop_Data, datamap);
}
