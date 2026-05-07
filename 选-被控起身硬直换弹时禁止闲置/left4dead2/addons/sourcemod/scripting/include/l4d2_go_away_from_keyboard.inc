/*
 * @Author:             Pure_*
 * @Last Modified by: Pure_*
 * @Create Date:        2025-03-18 16:10:30
 * @Last Modified time: 2025-03-18 16:10:30
 * @Github:             https://github.com/PureZhao
 */


#if defined _pure_l4d2_go_away_from_keyboard_included
    #endinput
#endif
#define _pure_l4d2_go_away_from_keyboard_included

#define Afk_Blind (1 << 0)
#define Afk_IsTank (1 << 1)

public SharedPlugin __pl_l4d2goawayfromkeyboard = {
    name = "l4d2_go_away_from_keyboard",
    file = "l4d2_go_away_from_keyboard.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

public void __pl_l4d2goawayfromkeyboard_SetNTVOptional()
{
    MarkNativeAsOptional("L4D2_Afk_PreventClient");
    MarkNativeAsOptional("L4D2_Afk_AllowClient");
}

/* Natives */

/**
 * Set client who can not use afk.
 *
 * @param client    Client index
 * @param condition    id which disallow client to afk.(Value must be The Power of 2)
 * @noreturn
 */
native void L4D2_Afk_PreventClient(int client, int condition);

/**
 * Set client who can use afk.
 *
 * @param client    Client index
 * @param condition    id which allow client to afk.(Value must be The Power of 2)
 * @noreturn
 */
native void L4D2_Afk_AllowClient(int client, int condition);