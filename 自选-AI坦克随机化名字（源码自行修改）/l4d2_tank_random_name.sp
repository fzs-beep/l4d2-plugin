#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public OnPluginStart()
{
	HookEvent("tank_spawn", Tank_Spawn, EventHookMode_Post);
}

public Action:Tank_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client =  GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client))
		CreateTimer(0.1, TankSpawnTimer, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TankSpawnTimer(Handle:timer, any:client)
{
	
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && 
	IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
	{
		new num = GetRandomInt(0, 150);
		switch(num)
		{
			case 0:
			{
				SetClientInfo(client, "name", "黑暗之女");
			}
			case 1:
			{
				SetClientInfo(client, "name", "狂战士");
			}
			case 2:
			{
				SetClientInfo(client, "name", "正义巨像");
			}
			case 3:
			{
				SetClientInfo(client, "name", "卡牌大师");
			}
			case 4:
			{
				SetClientInfo(client, "name", "德邦总管");
			}
			case 5:
			{
				SetClientInfo(client, "name", "无畏战车");
			}
			case 6:
			{
				SetClientInfo(client, "name", "诡术妖姬");
			}
			case 7:
			{
				SetClientInfo(client, "name", "猩红收割者");
			}
			case 8:
			{
				SetClientInfo(client, "name", "远古恐惧");
			}
			case 9:
			{
				SetClientInfo(client, "name", "正义天使");
			}
			case 10:
			{
				SetClientInfo(client, "name", "无极剑圣");
			}
			case 11:
			{
				SetClientInfo(client, "name", "牛头酋长");
			}
			case 12:
			{
				SetClientInfo(client, "name", "符文法师");
			}
			case 13:
			{
				SetClientInfo(client, "name", "亡灵战神");
			}
			case 14:
			{
				SetClientInfo(client, "name", "战争女神");
			}
			case 15:
			{
				SetClientInfo(client, "name", "众星之子");
			}
			case 16:
			{
				SetClientInfo(client, "name", "迅捷斥候");
			}
			case 17:
			{
				SetClientInfo(client, "name", "麦林炮手");
			}
			case 18:
			{
				SetClientInfo(client, "name", "祖安怒兽");
			}
			case 19:
			{
				SetClientInfo(client, "name", "雪原双子");
			}
			case 20:
			{
				SetClientInfo(client, "name", "赏金猎人");
			}
			case 21:
			{
				SetClientInfo(client, "name", "寒冰射手");
			}
			case 22:
			{
				SetClientInfo(client, "name", "蛮族之王");
			}
			case 23:
			{
				SetClientInfo(client, "name", "武器大师");
			}
			case 24:
			{
				SetClientInfo(client, "name", "堕落天使");
			}
			case 25:
			{
				SetClientInfo(client, "name", "时光守护者");
			}
			case 26:
			{
				SetClientInfo(client, "name", "炼金术士");
			}
			case 27:
			{
				SetClientInfo(client, "name", "痛苦之拥");
			}
			case 28:
			{
				SetClientInfo(client, "name", "瘟疫之源");
			}
			case 29:
			{
				SetClientInfo(client, "name", "死亡颂唱者");
			}
			case 30:
			{
				SetClientInfo(client, "name", "虚空恐惧");
			}
			case 31:
			{
				SetClientInfo(client, "name", "殇之木乃伊");
			}
			case 32:
			{
				SetClientInfo(client, "name", "披甲龙龟");
			}
			case 33:
			{
				SetClientInfo(client, "name", "冰晶凤凰");
			}
			case 34:
			{
				SetClientInfo(client, "name", "恶魔小丑");
			}
			case 35:
			{
				SetClientInfo(client, "name", "祖安狂人");
			}
			case 36:
			{
				SetClientInfo(client, "name", "琴瑟仙女");
			}
			case 37:
			{
				SetClientInfo(client, "name", "虚空行者");
			}
			case 38:
			{
				SetClientInfo(client, "name", "刀锋舞者");
			}
			case 39:
			{
				SetClientInfo(client, "name", "风暴之怒");
			}
			case 40:
			{
				SetClientInfo(client, "name", "海洋之灾");
			}
			case 41:
			{
				SetClientInfo(client, "name", "英勇投弹手");
			}
			case 42:
			{
				SetClientInfo(client, "name", "天启者");
			}
			case 43:
			{
				SetClientInfo(client, "name", "瓦洛兰之盾");
			}
			case 44:
			{
				SetClientInfo(client, "name", "邪恶小法师");
			}
			case 45:
			{
				SetClientInfo(client, "name", "巨魔之王");
			}
			case 46:
			{
				SetClientInfo(client, "name", "诺克萨斯统领");
			}
			case 47:
			{
				SetClientInfo(client, "name", "皮城女警");
			}
			case 48:
			{
				SetClientInfo(client, "name", "蒸汽机器人");
			}
			case 49:
			{
				SetClientInfo(client, "name", "熔岩巨兽");
			}
			case 50:
			{
				SetClientInfo(client, "name", "不祥之刃");
			}
			case 51:
			{
				SetClientInfo(client, "name", "永恒梦魇");
			}
			case 52:
			{
				SetClientInfo(client, "name", "扭曲树精");
			}
			case 53:
			{
				SetClientInfo(client, "name", "荒漠屠夫");
			}
			case 54:
			{
				SetClientInfo(client, "name", "德玛西亚皇子");
			}
			case 55:
			{
				SetClientInfo(client, "name", "蜘蛛女皇");
			}
			case 56:
			{
				SetClientInfo(client, "name", "发条魔灵");
			}
			case 57:
			{
				SetClientInfo(client, "name", "齐天大圣");
			}
			case 58:
			{
				SetClientInfo(client, "name", "复仇焰魂");
			}
			case 59:
			{
				SetClientInfo(client, "name", "盲僧");
			}
			case 60:
			{
				SetClientInfo(client, "name", "暗夜猎手");
			}
			case 61:
			{
				SetClientInfo(client, "name", "机械公敌");
			}
			case 62:
			{
				SetClientInfo(client, "name", "魔蛇之拥");
			}
			case 63:
			{
				SetClientInfo(client, "name", "水晶先锋");
			}
			case 64:
			{
				SetClientInfo(client, "name", "大发明家");
			}
			case 65:
			{
				SetClientInfo(client, "name", "沙漠死神");
			}
			case 66:
			{
				SetClientInfo(client, "name", "狂野女猎手");
			}
			case 67:
			{
				SetClientInfo(client, "name", "兽灵行者");
			}
			case 68:
			{
				SetClientInfo(client, "name", "圣锤之毅");
			}
			case 69:
			{
				SetClientInfo(client, "name", "酒桶");
			}
			case 70:
			{
				SetClientInfo(client, "name", "不屈之枪");
			}
			case 71:
			{
				SetClientInfo(client, "name", "探险家");
			}
			case 72:
			{
				SetClientInfo(client, "name", "铁铠冥魂");
			}
			case 73:
			{
				SetClientInfo(client, "name", "牧魂人");
			}
			case 74:
			{
				SetClientInfo(client, "name", "离群之刺");
			}
			case 75:
			{
				SetClientInfo(client, "name", "狂暴之心");
			}
			case 76:
			{
				SetClientInfo(client, "name", "德玛西亚之力");
			}
			case 77:
			{
				SetClientInfo(client, "name", "曙光女神");
			}
			case 78:
			{
				SetClientInfo(client, "name", "虚空先知");
			}
			case 79:
			{
				SetClientInfo(client, "name", "刀锋之影");
			}
			case 80:
			{
				SetClientInfo(client, "name", "放逐之刃");
			}
			case 81:
			{
				SetClientInfo(client, "name", "深渊巨口");
			}
			case 82:
			{
				SetClientInfo(client, "name", "暮光之眼");
			}
			case 83:
			{
				SetClientInfo(client, "name", "光辉女郎");
			}
			case 84:
			{
				SetClientInfo(client, "name", "远古巫灵");
			}
			case 85:
			{
				SetClientInfo(client, "name", "龙血武姬");
			}
			case 86:
			{
				SetClientInfo(client, "name", "九尾妖狐");
			}
			case 87:
			{
				SetClientInfo(client, "name", "法外狂徒");
			}
			case 88:
			{
				SetClientInfo(client, "name", "潮汐海灵");
			}
			case 89:
			{
				SetClientInfo(client, "name", "不灭狂雷");
			}
			case 90:
			{
				SetClientInfo(client, "name", "傲之追猎者");
			}
			case 91:
			{
				SetClientInfo(client, "name", "惩戒之箭");
			}
			case 92:
			{
				SetClientInfo(client, "name", "深海泰坦");
			}
			case 93:
			{
				SetClientInfo(client, "name", "机械先驱");
			}
			case 94:
			{
				SetClientInfo(client, "name", "北地之怒");
			}
			case 95:
			{
				SetClientInfo(client, "name", "无双剑姬");
			}
			case 96:
			{
				SetClientInfo(client, "name", "爆破鬼才");
			}
			case 97:
			{
				SetClientInfo(client, "name", "仙灵女巫");
			}
			case 98:
			{
				SetClientInfo(client, "name", "荣耀行刑官");
			}
			case 99:
			{
				SetClientInfo(client, "name", "战争之影");
			}
			case 100:
			{
				SetClientInfo(client, "name", "虚空掠夺者");
			}
			case 101:
			{
				SetClientInfo(client, "name", "诺克萨斯之手");
			}
			case 102:
			{
				SetClientInfo(client, "name", "未来守护者");
			}
			case 103:
			{
				SetClientInfo(client, "name", "冰霜女巫");
			}
			case 104:
			{
				SetClientInfo(client, "name", "皎月女神");
			}
			case 105:
			{
				SetClientInfo(client, "name", "德玛西亚之翼");
			}
			case 106:
			{
				SetClientInfo(client, "name", "暗黑元首");
			}
			case 107:
			{
				SetClientInfo(client, "name", "铸星龙王");
			}
			case 108:
			{
				SetClientInfo(client, "name", "影流之镰");
			}
			case 109:
			{
				SetClientInfo(client, "name", "暮光星灵");
			}
			case 110:
			{
				SetClientInfo(client, "name", "荆棘之兴");
			}
			case 111:
			{
				SetClientInfo(client, "name", "虚空之女");
			}
			case 112:
			{
				SetClientInfo(client, "name", "迷失之牙");
			}
			case 113:
			{
				SetClientInfo(client, "name", "生化魔人");
			}
			case 114:
			{
				SetClientInfo(client, "name", "疾风剑豪");
			}
			case 115:
			{
				SetClientInfo(client, "name", "虚空之眼");
			}
			case 116:
			{
				SetClientInfo(client, "name", "岩雀");
			}
			case 117:
			{
				SetClientInfo(client, "name", "青钢影");
			}
			case 118:
			{
				SetClientInfo(client, "name", "弗雷尔卓德之心");
			}
			case 119:
			{
				SetClientInfo(client, "name", "戏命师");
			}
			case 120:
			{
				SetClientInfo(client, "name", "永猎双子");
			}
			case 121:
			{
				SetClientInfo(client, "name", "暴走萝莉");
			}
			case 122:
			{
				SetClientInfo(client, "name", "河流之王");
			}
			case 123:
			{
				SetClientInfo(client, "name", "涤魂圣枪");
			}
			case 124:
			{
				SetClientInfo(client, "name", "圣枪游侠");
			}
			case 125:
			{
				SetClientInfo(client, "name", "引流之主");
			}
			case 126:
			{
				SetClientInfo(client, "name", "暴怒骑士");
			}
			case 127:
			{
				SetClientInfo(client, "name", "时间刺客");
			}
			case 128:
			{
				SetClientInfo(client, "name", "元素女皇");
			}
			case 129:
			{
				SetClientInfo(client, "name", "皮城执法官");
			}
			case 130:
			{
				SetClientInfo(client, "name", "暗裔剑魔");
			}
			case 131:
			{
				SetClientInfo(client, "name", "唤潮鲛姬");
			}
			case 132:
			{
				SetClientInfo(client, "name", "沙漠皇帝");
			}
			case 133:
			{
				SetClientInfo(client, "name", "魔法猫咪");
			}
			case 134:
			{
				SetClientInfo(client, "name", "沙漠玫瑰");
			}
			case 135:
			{
				SetClientInfo(client, "name", "魂锁典狱长");
			}
			case 136:
			{
				SetClientInfo(client, "name", "海兽祭祀");
			}
			case 137:
			{
				SetClientInfo(client, "name", "虚空遁地兽");
			}
			case 138:
			{
				SetClientInfo(client, "name", "翠神");
			}
			case 139:
			{
				SetClientInfo(client, "name", "复仇之矛");
			}
			case 140:
			{
				SetClientInfo(client, "name", "星界游神");
			}
			case 141:
			{
				SetClientInfo(client, "name", "幻翎");
			}
			case 142:
			{
				SetClientInfo(client, "name", "逆羽");
			}
			case 143:
			{
				SetClientInfo(client, "name", "山隐之焰");
			}
			case 144:
			{
				SetClientInfo(client, "name", "解脱者");
			}
			case 145:
			{
				SetClientInfo(client, "name", "万花通灵");
			}
			case 146:
			{
				SetClientInfo(client, "name", "残月之肃");
			}
			case 147:
			{
				SetClientInfo(client, "name", "血港鬼影");
			}
			case 148:
			{
				SetClientInfo(client, "name", "封魔剑魂");
			}
			case 149:
			{
				SetClientInfo(client, "name", "腕豪");
			}
			case 150:
			{
				SetClientInfo(client, "name", "含羞蓓蕾");
			}
		}
	}
}