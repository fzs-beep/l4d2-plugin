/*  设置地图中文名称
*	如需添加新地图名称
*	请依照以下格式写入：
*	else if(Map == "建图代码")
	{
		GetMapName = "地图名称";
	}
*/


::Set_MapName<-function(Map)
{
	local GetMapName = [];
	
	if(Map == "c1m1_hotel")
	{
		GetMapName = "死亡中心-①旅馆";
	}
	else if(Map == "c1m2_streets")
	{
		GetMapName = "死亡中心-②街道";
	}
	else if(Map == "c1m3_mall")
	{
		GetMapName = "死亡中心-③购物中心";
	}
	else if(Map == "c1m4_atrium")
	{
		GetMapName = "死亡中心-④中厅";
	}
	else if(Map == "c2m1_highway")
	{
		GetMapName = "黑色嘉年华-①高速公路";
	}
	else if(Map == "c2m2_fairgrounds")
	{
		GetMapName = "黑色嘉年华-②游乐场";
	}
	else if(Map == "c2m3_coaster")
	{
		GetMapName = "黑色嘉年华-③过山车";
	}
	else if(Map == "c2m4_barns")
	{
		GetMapName = "黑色嘉年华-④谷仓";
	}
	else if(Map == "c2m5_concert")
	{
		GetMapName = "黑色嘉年华-⑤音乐会";
	}
	else if(Map == "c3m1_plankcountry")
	{
		GetMapName = "沼泽激战-①乡村";
	}
	else if(Map == "c3m2_swamp")
	{
		GetMapName = "沼泽激战-②沼泽";
	}
	else if(Map == "c3m3_shantytown")
	{
		GetMapName = "沼泽激战-③贫民窟";
	}
	else if(Map == "c3m4_plantation")
	{
		GetMapName = "沼泽激战-④种植园";
	}
	else if(Map == "c4m1_milltown_a")
	{
		GetMapName = "暴风骤雨-①密尔城";
	}
	else if(Map == "c4m2_sugarmill_a")
	{
		GetMapName = "暴风骤雨-②糖厂";
	}
	else if(Map == "c4m3_sugarmill_b")
	{
		GetMapName = "暴风骤雨-③逃离工厂";
	}
	else if(Map == "c4m4_milltown_b")
	{
		GetMapName = "暴风骤雨-④重返小镇";
	}
	else if(Map == "c4m5_milltown_escape")
	{
		GetMapName = "暴风骤雨-⑤逃离小镇";
	}
	else if(Map == "c5m1_waterfront")
	{
		GetMapName = "教区-①码头";
	}
	else if(Map == "c5m2_park")
	{
		GetMapName = "教区-②公园";
	}
	else if(Map == "c5m3_cemetery")
	{
		GetMapName = "教区-③墓地";
	}
	else if(Map == "c5m4_quarter")
	{
		GetMapName = "教区-④特区";
	}
	else if(Map == "c5m5_bridge")
	{
		GetMapName = "教区-⑤桥";
	}
	else if(Map == "c6m1_riverbank")
	{
		GetMapName = "短暂时刻-①河畔";
	}
	else if(Map == "c6m2_bedlam")
	{
		GetMapName = "短暂时刻-②地下";
	}
	else if(Map == "c6m3_port")
	{
		GetMapName = "短暂时刻-③港口";
	}
	else if(Map == "c7m1_docks")
	{
		GetMapName = "牺牲-①码头";
	}
	else if(Map == "c7m2_barge")
	{
		GetMapName = "牺牲-②驳船";
	}
	else if(Map == "c7m3_port")
	{
		GetMapName = "牺牲-③港口";
	}
	else if(Map == "c8m1_apartment")
	{
		GetMapName = "毫不留情-①公寓";
	}
	else if(Map == "c8m2_subway")
	{
		GetMapName = "毫不留情-②地下铁";
	}
	else if(Map == "c8m3_sewers")
	{
		GetMapName = "毫不留情-③下水道";
	}
	else if(Map == "c8m4_interior")
	{
		GetMapName = "毫不留情-④医院";
	}
	else if(Map == "c8m5_rooftop")
	{
		GetMapName = "毫不留情-⑤楼顶";
	}
	else if(Map == "c9m1_alleys")
	{
		GetMapName = "坠机险途-①小巷";
	}
	else if(Map == "c9m2_lots")
	{
		GetMapName = "坠机险途-②卡车停车场";
	}
	else if(Map == "c10m1_caves")
	{
		GetMapName = "死亡丧钟-①收费公路";
	}
	else if(Map == "c10m2_drainage")
	{
		GetMapName = "死亡丧钟-②水沟";
	}
	else if(Map == "c10m3_ranchhouse")
	{
		GetMapName = "死亡丧钟-③教堂";
	}
	else if(Map == "c10m4_mainstreet")
	{
		GetMapName = "死亡丧钟-④小镇";
	}
	else if(Map == "c10m5_houseboat")
	{
		GetMapName = "死亡丧钟-⑤码头";
	}
	else if(Map == "c11m1_greenhouse")
	{
		GetMapName = "寂静时分-①花房";
	}
	else if(Map == "c11m2_offices")
	{
		GetMapName = "寂静时分-②起重机";
	}
	else if(Map == "c11m3_garage")
	{
		GetMapName = "寂静时分-③建筑工地";
	}
	else if(Map == "c11m4_terminal")
	{
		GetMapName = "寂静时分-④航空机场";
	}
	else if(Map == "c11m5_runway")
	{
		GetMapName = "寂静时分-⑤飞机跑道";
	}
	else if(Map == "c12m1_hilltop")
	{
		GetMapName = "血腥收获-①森林";
	}
	else if(Map == "c12m2_traintunnel")
	{
		GetMapName = "血腥收获-②隧道";
	}
	else if(Map == "c12m3_bridge")
	{
		GetMapName = "血腥收获-③桥";
	}
	else if(Map == "c12m4_barn")
	{
		GetMapName = "血腥收获-④火车站";
	}
	else if(Map == "c12m5_cornfield")
	{
		GetMapName = "血腥收获-⑤农舍";
	}
	else if(Map == "c13m1_alpinecreek")
	{
		GetMapName = "刺骨寒溪-①山川";
	}
	else if(Map == "c13m2_southpinestream")
	{
		GetMapName = "刺骨寒溪-②南松河";
	}
	else if(Map == "c13m3_memorialbridge")
	{
		GetMapName = "刺骨寒溪-③断桥";
	}
	else if(Map == "c13m4_cutthroatcreek")
	{
		GetMapName = "刺骨寒溪-④险溪";
	}
	else if(Map == "C1_mario1_1")
	{
		GetMapName = "马里奥探险-第①关";
	}
	else if(Map == "C1_mario1_2")
	{
		GetMapName = "马里奥探险-第②关";
	}
	else if(Map == "C1_mario1_3")
	{
		GetMapName = "马里奥探险-第③关";
	}
	else if(Map == "C1_mario1_4")
	{
		GetMapName = "马里奥探险-救援关";
	}
	else if(Map == "l4d2_tanksplayground")
	{
		GetMapName = "坦克竞技场";
	}
	else if(Map == "simple_map_1")
	{
		GetMapName = "漫画世界-第①关";
	}
	else if(Map == "simple_map_2")
	{
		GetMapName = "漫画世界-第②关";
	}
	else if(Map == "simple_map_3")
	{
		GetMapName = "漫画世界-第③关";
	}
	else if(Map == "simple_map_4")
	{
		GetMapName = "漫画世界-第④关";
	}
	else if(Map == "simple_map_5")
	{
		GetMapName = "漫画世界-救援关";
	}
	else if(Map == "msd1_town")
	{
		GetMapName = "再见了晨茗-第①关";
	}
	else if(Map == "msd2_gasstation")
	{
		GetMapName = "再见了晨茗-第②关";
	}
	else if(Map == "msdnew_tccity_newway")
	{
		GetMapName = "再见了晨茗-第③关";
	}
	else if(Map == "msd3_square")
	{
		GetMapName = "再见了晨茗-救援关";
	}
	else if(Map == "l4d_yama_1")
	{
		GetMapName = "摩耶山危机-第①关";
	}
	else if(Map == "l4d_yama_2")
	{
		GetMapName = "摩耶山危机-第②关";
	}
	else if(Map == "l4d_yama_3")
	{
		GetMapName = "摩耶山危机-第③关";
	}
	else if(Map == "l4d_yama_4")
	{
		GetMapName = "摩耶山危机-第④关";
	}
	else if(Map == "l4d_yama_5")
	{
		GetMapName = "摩耶山危机-救援关";
	}
	else if(Map == "l4d2_fallindeath01")
	{
		GetMapName = "坠入死亡-第①关";
	}
	else if(Map == "l4d2_fallindeath02")
	{
		GetMapName = "坠入死亡-第②关";
	}
	else if(Map == "l4d2_fallindeath03")
	{
		GetMapName = "坠入死亡-第③关";
	}
	else if(Map == "l4d2_fallindeath04")
	{
		GetMapName = "坠入死亡-救援关";
	}
	else if(Map == "wfp1_track")
	{
		GetMapName = "白森林-第①关";
	}
	else if(Map == "wfp2_horn")
	{
		GetMapName = "白森林-第②关";
	}
	else if(Map == "wfp3_mill")
	{
		GetMapName = "白森林-第③关";
	}
	else if(Map == "wfp4_commstation")
	{
		GetMapName = "白森林-救援关";
	}
	else if(Map == "deadbeat01_forest")
	{
		GetMapName = "无缝逃离-第①关";
	}
	else if(Map == "deadbeat02_alley")
	{
		GetMapName = "无缝逃离-第②关";
	}
	else if(Map == "deadbeat03_street")
	{
		GetMapName = "无缝逃离-第③关";
	}
	else if(Map == "deadbeat04_park")
	{
		GetMapName = "无缝逃离-救援关";
	}
	else if(Map == "uf1_boulevard")
	{
		GetMapName = "城市航班-第①关";
	}
	else if(Map == "uf2_rooftops")
	{
		GetMapName = "城市航班-第②关";
	}
	else if(Map == "uf3_harbor")
	{
		GetMapName = "城市航班-第③关";
	}
	else if(Map == "uf4_airfield")
	{
		GetMapName = "城市航班-救援关";
	}
	else if(Map == "l4d_ihm01_forest")
	{
		GetMapName = "我恨山2-第①关";
	}
	else if(Map == "l4d_ihm02_manor")
	{
		GetMapName = "我恨山2-第②关";
	}
	else if(Map == "l4d_ihm03_underground")
	{
		GetMapName = "我恨山2-第③关";
	}
	else if(Map == "l4d_ihm04_lumberyard")
	{
		GetMapName = "我恨山2-第④关";
	}
	else if(Map == "l4d_ihm05_lakeside")
	{
		GetMapName = "我恨山2-救援关";
	}
	else if(Map == "gridlockfinal2")
	{
		GetMapName = "交通堵塞";
	}
	else if(Map == "l4d2_daybreak01_hotel")
	{
		GetMapName = "黎明-第①关";
	}
	else if(Map == "l4d2_daybreak02_coastline")
	{
		GetMapName = "黎明-第②关";
	}
	else if(Map == "l4d2_daybreak03_bridge")
	{
		GetMapName = "黎明-第③关";
	}
	else if(Map == "l4d2_daybreak04_cruise")
	{
		GetMapName = "黎明-第④关";
	}
	else if(Map == "l4d2_daybreak05_rescue")
	{
		GetMapName = "黎明-救援关";
	}
	else if(Map == "crashbandicootmap1")
	{
		GetMapName = "崩溃的博士1-第①关";
	}
	else if(Map == "crashbandicootmap2")
	{
		GetMapName = "崩溃的博士1-第②关";
	}
	else if(Map == "crashbandicootmap3")
	{
		GetMapName = "崩溃的博士1-第③关";
	}
	else if(Map == "crashbandicootmap4")
	{
		GetMapName = "崩溃的博士1-第④关";
	}
	else if(Map == "crashbandicootmap5")
	{
		GetMapName = "崩溃的博士1-第⑤关";
	}
	else if(Map == "crashbandicootmap6")
	{
		GetMapName = "崩溃的博士1-救援关";
	}
	else if(Map == "l4d2_CrashBandicootvs1")
	{
		GetMapName = "崩溃的博士2-第①关";
	}
	else if(Map == "l4d2_CrashBandicootvs2")
	{
		GetMapName = "崩溃的博士2-第②关";
	}
	else if(Map == "l4d2_CrashBandicootvs3")
	{
		GetMapName = "崩溃的博士2-第③关";
	}
	else if(Map == "l4d2_CrashBandicootvs4")
	{
		GetMapName = "崩溃的博士2-救援关";
	}
	else if(Map == "l4d2_wanli01")
	{
		GetMapName = "万里-第①关";
	}
	else if(Map == "l4d2_wanli02")
	{
		GetMapName = "万里-第②关";
	}
	else if(Map == "l4d2_wanli03")
	{
		GetMapName = "万里-救援关";
	}
	else if(Map == "ch_map1_city")
	{
		GetMapName = "方氏-第①关";
	}
	else if(Map == "ch_map2_temple")
	{
		GetMapName = "方氏-第②关";
	}
	else if(Map == "ch_map3_greatwall")
	{
		GetMapName = "方氏-救援关";
	}
	else if(Map == "l4d2_ff01_woods")
	{
		GetMapName = "致命货运站-第①关";
	}
	else if(Map == "l4d2_ff02_factory")
	{
		GetMapName = "致命货运站-第②关";
	}
	else if(Map == "l4d2_ff03_highway")
	{
		GetMapName = "致命货运站-第③关";
	}
	else if(Map == "l4d2_ff04_plant")
	{
		GetMapName = "致命货运站-第④关";
	}
	else if(Map == "l4d2_ff05_station")
	{
		GetMapName = "致命货运站-救援关";
	}
	else if(Map == "saltwell_1_d")
	{
		GetMapName = "盐井地狱公园-第①关";
	}
	else if(Map == "saltwell_2_d")
	{
		GetMapName = "盐井地狱公园-第②关";
	}
	else if(Map == "saltwell_3_d")
	{
		GetMapName = "盐井地狱公园-第③关";
	}
	else if(Map == "saltwell_4_d")
	{
		GetMapName = "盐井地狱公园-第④关";
	}
	else if(Map == "saltwell_5_d")
	{
		GetMapName = "盐井地狱公园-救援关";
	}
	else if(Map == "l4d2_cc_stranded")
	{
		GetMapName = "复杂过程-第①关";
	}
	else if(Map == "l4d2_cc_sampling")
	{
		GetMapName = "复杂过程-第②关";
	}
	else if(Map == "l4d2_cc_gauntlet")
	{
		GetMapName = "复杂过程-第③关";
	}
	else if(Map == "l4d2_cc_tower")
	{
		GetMapName = "复杂过程-第④关";
	}
	else if(Map == "l4d2_cc_ai")
	{
		GetMapName = "复杂过程-第⑤关";
	}
	else if(Map == "l4d2_cc_escape")
	{
		GetMapName = "复杂过程-救援关";
	}
	else if(Map == "l4d_eft1_subsystem")
	{
		GetMapName = "逃离多伦多-第①关";
	}
	else if(Map == "l4d_eft2_tower")
	{
		GetMapName = "逃离多伦多-第②关";
	}
	else if(Map == "l4d_eft3_queensquay")
	{
		GetMapName = "逃离多伦多-第③关";
	}
	else if(Map == "l4d_eft4_drybay")
	{
		GetMapName = "逃离多伦多-第④关";
	}
	else if(Map == "l4d_eft5_niagaracity")
	{
		GetMapName = "逃离多伦多-第⑤关";
	}
	else if(Map == "l4d_eft6_bordercrossing1")
	{
		GetMapName = "逃离多伦多-救援关";
	}
	else if(Map == "hotel01_market1")
	{
		GetMapName = "死亡度假2-第①关";
	}
	else if(Map == "hotel02_sewer1")
	{
		GetMapName = "死亡度假2-第②关";
	}
	else if(Map == "hotel03_ramsey1")
	{
		GetMapName = "死亡度假2-第③关";
	}
	else if(Map == "hotel04_scaling1")
	{
		GetMapName = "死亡度假2-第④关";
	}
	else if(Map == "hotel05_rooftop1")
	{
		GetMapName = "死亡度假2-救援关";
	}
	else if(Map == "l4d2_ravenholmwar_1")
	{
		GetMapName = "我们不去莱温霍姆-第①关";
	}
	else if(Map == "l4d2_ravenholmwar_2")
	{
		GetMapName = "我们不去莱温霍姆-第②关";
	}
	else if(Map == "l4d2_ravenholmwar_3")
	{
		GetMapName = "我们不去莱温霍姆-第③关";
	}
	else if(Map == "l4d2_ravenholmwar_4")
	{
		GetMapName = "我们不去莱温霍姆-救援关";
	}
	else if(Map == "l4d_deathaboard01_prison")
	{
		GetMapName = "幽灵船2-第①关";
	}
	else if(Map == "l4d_deathaboard02_yard")
	{
		GetMapName = "幽灵船2-第②关";
	}
	else if(Map == "l4d_deathaboard03_docks")
	{
		GetMapName = "幽灵船2-第③关";
	}
	else if(Map == "l4d_deathaboard04_ship")
	{
		GetMapName = "幽灵船2-第④关";
	}
	else if(Map == "l4d_deathaboard05_light")
	{
		GetMapName = "幽灵船2-救援关";
	}
	else if(Map == "beldurra2_1")
	{
		GetMapName = "恐惧2-第①关";
	}
	else if(Map == "beldurra2_2")
	{
		GetMapName = "恐惧2-第②关";
	}
	else if(Map == "beldurra2_3")
	{
		GetMapName = "恐惧2-第③关";
	}
	else if(Map == "beldurra2_4")
	{
		GetMapName = "恐惧2-第④关";
	}
	else if(Map == "beldurra2_5")
	{
		GetMapName = "恐惧2-救援关";
	}
	else if(Map == "qe_1_cliche")
	{
		GetMapName = "伦理问题1-第①关";
	}
	else if(Map == "qe_2_remember_me")
	{
		GetMapName = "伦理问题1-第②关";
	}
	else if(Map == "qe_3_unorthodox_paradox")
	{
		GetMapName = "伦理问题1-第③关";
	}
	else if(Map == "qe_4_ultimate_test")
	{
		GetMapName = "伦理问题1-救援关";
	}
	else if(Map == "qe2_ep1")
	{
		GetMapName = "伦理问题2-第①关";
	}
	else if(Map == "qe2_ep2")
	{
		GetMapName = "伦理问题2-第②关";
	}
	else if(Map == "qe2_ep3")
	{
		GetMapName = "伦理问题2-第③关";
	}
	else if(Map == "qe2_ep4")
	{
		GetMapName = "伦理问题2-第④关";
	}
	else if(Map == "qe2_ep5")
	{
		GetMapName = "伦理问题2-救援关";
	}
	else if(Map == "hf01_theforest")
	{
		GetMapName = "颤栗森林-第①关";
	}
	else if(Map == "hf02_thesteeple")
	{
		GetMapName = "颤栗森林-第②关";
	}
	else if(Map == "hf03_themansion")
	{
		GetMapName = "颤栗森林-第③关";
	}
	else if(Map == "hf04_escape")
	{
		GetMapName = "颤栗森林-救援关";
	}
	else if(Map == "nt01_mansion")
	{
		GetMapName = "夜惊-第①关";
	}
	else if(Map == "nt02_haunts")
	{
		GetMapName = "夜惊-第②关";
	}
	else if(Map == "nt03_moria")
	{
		GetMapName = "夜惊-第③关";
	}
	else if(Map == "nt04_jungleruins")
	{
		GetMapName = "夜惊-第④关";
	}
	else if(Map == "nt05_wake")
	{
		GetMapName = "夜惊-救援关";
	}
	else if(Map == "l4d_fallen01_approach")
	{
		GetMapName = "坠落-第①关";
	}
	else if(Map == "l4d_fallen02_trenches")
	{
		GetMapName = "坠落-第②关";
	}
	else if(Map == "l4d_fallen03_tower")
	{
		GetMapName = "坠落-第③关";
	}
	else if(Map == "l4d_fallen04_cliff")
	{
		GetMapName = "坠落-第④关";
	}
	else if(Map == "l4d_fallen05_shaft")
	{
		GetMapName = "坠落-救援关";
	}
	else if(Map == "bot1")
	{
		GetMapName = "玩具世界大乱斗-第①关";
	}
	else if(Map == "bot2")
	{
		GetMapName = "玩具世界大乱斗-第②关";
	}
	else if(Map == "bot3")
	{
		GetMapName = "玩具世界大乱斗-救援关";
	}
	else if(Map == "l4d2_tank_challenge")
	{
		GetMapName = "坦克挑战-10波";
	}
	else if(Map == "l4d2_tank_challenge_15_rounds")
	{
		GetMapName = "坦克挑战-15波";
	}
	else if(Map == "l4d2_tank_challenge_20_rounds")
	{
		GetMapName = "坦克挑战-20波";
	}
	else if(Map == "l4d2_tank_challenge_30_rounds")
	{
		GetMapName = "坦克挑战-30波";
	}
	else if(Map == "ddntr1_01urban")
	{
		GetMapName = "死亡陷阱-第①关";
	}
	else if(Map == "ddntr1_02normal")
	{
		GetMapName = "死亡陷阱-第②关";
	}
	else if(Map == "ddntr1_02reverse")
	{
		GetMapName = "死亡陷阱-第③关";
	}
	else if(Map == "ddntr1_03day")
	{
		GetMapName = "死亡陷阱-第④关";
	}
	else if(Map == "ddntr1_03night")
	{
		GetMapName = "死亡陷阱-第⑤关";
	}
	else if(Map == "ddntr1_04finale")
	{
		GetMapName = "死亡陷阱-救援关";
	}
	else if(Map == "gr-mapone-7")
	{
		GetMapName = "赶尽杀绝-第①关";
	}
	else if(Map == "gasrunpart2")
	{
		GetMapName = "赶尽杀绝-第②关";
	}
	else if(Map == "evac2")
	{
		GetMapName = "赶尽杀绝-第③关";
	}
	else if(Map == "gasrun")
	{
		GetMapName = "赶尽杀绝-救援关";
	}
	else if(Map == "ec01_outlets")
	{
		GetMapName = "能源危机-第①关";
	}
	else if(Map == "ec02_dam")
	{
		GetMapName = "能源危机-第②关";
	}
	else if(Map == "ec03_village")
	{
		GetMapName = "能源危机-第③关";
	}
	else if(Map == "ec04_powerstation")
	{
		GetMapName = "能源危机-第④关";
	}
	else if(Map == "ec05_quarry")
	{
		GetMapName = "能源危机-救援关";
	}
	else if(Map == "ddg1_tower_v2_1")
	{
		GetMapName = "暴毙峡谷-第①关";
	}
	else if(Map == "ddg2_gristmill_v2")
	{
		GetMapName = "暴毙峡谷-第②关-";
	}
	else if(Map == "ddg3_bluff_v2_1")
	{
		GetMapName = "暴毙峡谷-救援关";
	}
	else if(Map == "x1m1_cliffs")
	{
		GetMapName = "绝命公路-第①关";
	}
	else if(Map == "x1m2_path")
	{
		GetMapName = "绝命公路-第②关";
	}
	else if(Map == "x1m3_city")
	{
		GetMapName = "绝命公路-第③关";
	}
	else if(Map == "x1m4_forest")
	{
		GetMapName = "绝命公路-第④关";
	}
	else if(Map == "x1m5_salvation")
	{
		GetMapName = "绝命公路-救援关";
	}
	else if(Map == "esc_jailbreak")
	{
		GetMapName = "阿森松岛-第①关";
	}
	else if(Map == "esc_sunken_park")
	{
		GetMapName = "阿森松岛-第②关";
	}
	else if(Map == "esc_bypass")
	{
		GetMapName = "阿森松岛-第③关";
	}
	else if(Map == "esc_fly_me_to_the_moon")
	{
		GetMapName = "阿森松岛-救援关";
	}
	else if(Map == "AirCrash")
	{
		GetMapName = "天堂可待II-第①关";
	}
	else if(Map == "RiverMotel")
	{
		GetMapName = "天堂可待II-第②关";
	}
	else if(Map == "OutSkirts")
	{
		GetMapName = "天堂可待II-第③关";
	}
	else if(Map == "CityHall")
	{
		GetMapName = "天堂可待II-第④关";
	}
	else if(Map == "BombShelter")
	{
		GetMapName = "天堂可待II-救援关";
	}
	else if(Map == "l4d2_deathwoods01_stranded")
	{
		GetMapName = "死亡森林-第①关";
	}
	else if(Map == "l4d2_deathwoods02_tunnel")
	{
		GetMapName = "死亡森林-第②关";
	}
	else if(Map == "l4d2_deathwoods03_bridge")
	{
		GetMapName = "死亡森林-第③关";
	}
	else if(Map == "l4d2_deathwoods04_power")
	{
		GetMapName = "死亡森林-第④关";
	}
	else if(Map == "l4d2_deathwoods05_airfield")
	{
		GetMapName = "死亡森林-救援关";
	}
	else if(Map == "l4d2_coast_01")
	{
		GetMapName = "半条命2:17号公路-第①关";
	}
	else if(Map == "l4d2_coast_02")
	{
		GetMapName = "半条命2:17号公路-第②关";
	}
	else if(Map == "l4d2_coast_03")
	{
		GetMapName = "半条命2:17号公路-第③关";
	}
	else if(Map == "l4d2_coast_04")
	{
		GetMapName = "半条命2:17号公路-第④关";
	}
	else if(Map == "l4d2_coast_05")
	{
		GetMapName = "半条命2:17号公路-救援关";
	}
	else if(Map == "l4d2_pasiri1")
	{
		GetMapName = "可乐之塔-第①关";
	}
	else if(Map == "l4d2_pasiri2")
	{
		GetMapName = "可乐之塔-第②关";
	}
	else if(Map == "l4d2_pasiri3")
	{
		GetMapName = "可乐之塔-第③关";
	}
	else if(Map == "l4d2_pasiri4")
	{
		GetMapName = "可乐之塔-救援关";
	}
	else if(Map == "l4d_viennacalling_city")
	{
		GetMapName = "维也纳的呼唤1-第①关";
	}
	else if(Map == "l4d_viennacalling_kaiserfranz")
	{
		GetMapName = "维也纳的呼唤1-第②关";
	}
	else if(Map == "l4d_viennacalling_gloomy")
	{
		GetMapName = "维也纳的呼唤1-第③关";
	}
	else if(Map == "l4d_viennacalling_donauinsel")
	{
		GetMapName = "维也纳的呼唤1-第④关";
	}
	else if(Map == "l4d_viennacalling_donauturm")
	{
		GetMapName = "维也纳的呼唤1-救援关";
	}
	else if(Map == "l4d_viennacalling2_1")
	{
		GetMapName = "维也纳的呼唤2-第①关";
	}
	else if(Map == "l4d_viennacalling2_2")
	{
		GetMapName = "维也纳的呼唤2-第②关";
	}
	else if(Map == "l4d_viennacalling2_3")
	{
		GetMapName = "维也纳的呼唤2-第③关";
	}
	else if(Map == "l4d_viennacalling2_4")
	{
		GetMapName = "维也纳的呼唤2-第④关";
	}
	else if(Map == "l4d_viennacalling2_5")
	{
		GetMapName = "维也纳的呼唤2-第⑤关";
	}
	else if(Map == "l4d_viennacalling2_finale")
	{
		GetMapName = "维也纳的呼唤2-救援关";
	}
	else if(Map == "l4d_sh01_oldsh")
	{
		GetMapName = "寂静岭2-第①关";
	}
	else if(Map == "l4d_sh02_school")
	{
		GetMapName = "寂静岭2-第②关";
	}
	else if(Map == "l4d_sh03_schoolalt")
	{
		GetMapName = "寂静岭2-第③关";
	}
	else if(Map == "l4d_sh04_church")
	{
		GetMapName = "寂静岭2-第④关";
	}
	else if(Map == "l4d_sh05_hospital")
	{
		GetMapName = "寂静岭2-第⑤关";
	}
	else if(Map == "l4d_sh07_otherchurch")
	{
		GetMapName = "寂静岭2-第⑥关";
	}
	else if(Map == "l4d_sh08_sewres")
	{
		GetMapName = "寂静岭2-第⑦关";
	}
	else if(Map == "l4d_sh09_resort")
	{
		GetMapName = "寂静岭2-第⑧关";
	}
	else if(Map == "l4d_sh10_amusementpark")
	{
		GetMapName = "寂静岭2-第⑨关";
	}
	else if(Map == "l4d_sh11_nowhere")
	{
		GetMapName = "寂静岭2-第⑩关";
	}
	else if(Map == "l4d_sh12_theend")
	{
		GetMapName = "寂静岭2-救援关";
	}
	else if(Map == "l4d_sh_theend2")
	{
		GetMapName = "寂静岭2-救援关";
	}
	else if(Map == "l4d_sh_theend3")
	{
		GetMapName = "寂静岭2-救援关";
	}
	else if(Map == "l4d_sh_theend4")
	{
		GetMapName = "寂静岭2-救援关";
	}
	else if(Map == "l4d_sh_credits")
	{
		GetMapName = "寂静岭2-救援关";
	}
	else if(Map == "l4d_farm05_cornfield_revdm")
	{
		GetMapName = "魔鬼山目的地-第①关";
	}
	else if(Map == "l4d_farm04_barn_revdm")
	{
		GetMapName = "魔鬼山目的地-第②关";
	}
	else if(Map == "l4d_farm03_bridge_revdm")
	{
		GetMapName = "魔鬼山目的地-第③关";
	}
	else if(Map == "l4d_farm02_traintunnel_revdm")
	{
		GetMapName = "魔鬼山目的地-第④关";
	}
	else if(Map == "l4d_crstreetdm")
	{
		GetMapName = "魔鬼山目的地-第⑤关";
	}
	else if(Map == "l4d_crgrapedm")
	{
		GetMapName = "魔鬼山目的地-第⑥关";
	}
	else if(Map == "l4d_crrivercitydm")
	{
		GetMapName = "魔鬼山目的地-第⑦关";
	}
	else if(Map == "l4d_crmurphydm")
	{
		GetMapName = "魔鬼山目的地-第⑧关";
	}
	else if(Map == "farmdm")
	{
		GetMapName = "魔鬼山目的地-第⑨关";
	}
	else if(Map == "slaughterdm")
	{
		GetMapName = "魔鬼山目的地-第⑩关";
	}
	else if(Map == "dm1_suburbsdm")
	{
		GetMapName = "魔鬼山目的地-第11关";
	}
	else if(Map == "dm5_summitdm")
	{
		GetMapName = "魔鬼山目的地-救援关";
	}
	else if(Map == "l4d_brain4dead01_suburbs_b2")
	{
		GetMapName = "太平间-第①关";
	}
	else if(Map == "l4d_brain4dead02_pool_b1")
	{
		GetMapName = "太平间-第②关";
	}
	else if(Map == "l4d_mortuary01")
	{
		GetMapName = "太平间-第③关";
	}
	else if(Map == "l4d_mortuary02")
	{
		GetMapName = "太平间-第④关";
	}
	else if(Map == "l4d_mortuary03")
	{
		GetMapName = "太平间-救援关";
	}
	else if(Map == "srocchurch")
	{
		GetMapName = "巴塞罗那-第①关";
	}
	else if(Map == "plaza_espana")
	{
		GetMapName = "巴塞罗那-第②关";
	}
	else if(Map == "maria_cristina")
	{
		GetMapName = "巴塞罗那-第③关";
	}
	else if(Map == "mnac")
	{
		GetMapName = "巴塞罗那-救援关";
	}
	else if(Map == "l4d2_deathcraft_01_town")
	{
		GetMapName = "我的世界-第①关";
	}
	else if(Map == "l4d2_deathcraft_02_ravine")
	{
		GetMapName = "我的世界-第②关";
	}
	else if(Map == "l4d2_deathcraft_03_stronghold")
	{
		GetMapName = "我的世界-第③关";
	}
	else if(Map == "l4d2_deathcraft_04_nether")
	{
		GetMapName = "我的世界-第④关";
	}
	else if(Map == "l4d2_deathcraft_05_lighthouse")
	{
		GetMapName = "我的世界-第⑤关";
	}
	else if(Map == "l4d2_minecraft_evolution")
	{
		GetMapName = "我的世界-救援关";
	}
	else if(Map == "l4d_damit01_orchard")
	{
		GetMapName = "大坝-第①关";
	}
	else if(Map == "l4d_damit02_campground")
	{
		GetMapName = "大坝-第②关";
	}
	else if(Map == "l4d_damit03_dam")
	{
		GetMapName = "大坝-救援关";
	}
	else if(Map == "re3m1")
	{
		GetMapName = "生化危机3-第①关";
	}
	else if(Map == "re3m2")
	{
		GetMapName = "生化危机3-第②关";
	}
	else if(Map == "re3m3")
	{
		GetMapName = "生化危机3-第③关";
	}
	else if(Map == "re3m4")
	{
		GetMapName = "生化危机3-第④关";
	}
	else if(Map == "re3m5")
	{
		GetMapName = "生化危机3-第⑤关";
	}
	else if(Map == "re3m6")
	{
		GetMapName = "生化危机3-第⑥关";
	}
	else if(Map == "re3m7")
	{
		GetMapName = "生化危机3-第⑦关";
	}
	else if(Map == "re3m8")
	{
		GetMapName = "生化危机3-救援关";
	}
	else
	{
		GetMapName = "地图："+Map;
	}
	
	return GetMapName;
}