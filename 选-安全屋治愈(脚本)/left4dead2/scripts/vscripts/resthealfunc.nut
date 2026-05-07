Convars.SetValue("sv_consistency", 0);Convars.SetValue("sv_pure_kick_clients", 0);

if (!("MANACAT" in getroottable())){
	::MANACAT <- {}
}

if(!("chkpheal" in ::MANACAT)){
	::MANACAT.chkpheal <- {
		check = false
		ver = 20230304
	}
	::MANACAT.slot6 <- function(ent){
		local msg = Convars.GetClientConvarValue("cl_language", ent.GetEntityIndex());
		switch(msg){
			case "korean":case "koreana":	msg = "체크포인트 힐";	break;
			case "japanese":				msg = "チェックポイントヒル";	break;
			case "spanish":					msg = "Checkpoint Heal";	break;
			case "schinese":				msg = "安全屋治愈";	break;
			case "tchinese":				msg = "安全屋治癒";	break;
			default:						msg = "Checkpoint Heal";	break;
		}
		ClientPrint( ent, 5, "\x02 - "+msg+" \x01 v"+::MANACAT.chkpheal.ver);
	};
}

printl( "<MANACAT> CheckPoint Heal Loaded. v"+::MANACAT.chkpheal.ver);

IncludeScript("manacat_chkpheal/info");
if (!("manacatInfo" in getroottable())){
	IncludeScript("manacat/info");
}
IncludeScript("manacat_chkpheal/rngitem");
if (!("manacat_rng_item" in getroottable())){
	IncludeScript("manacat/rngitem");
}

IncludeScript("manacat_chkpheal/manacatTimer");
if (!("manacatTimers" in getroottable())){
	IncludeScript("manacat/manacatTimer");
}

::restHealVars<-{
	finaleChk = false
	loadChk = false
	healCharList = [null,null,null,null,null,null,null,null]
	
	roundEnd = false
	healed = false
	healStop = []
	healinfo = {}
	idleList = []//유휴로 들어갈 때 어느 봇이 누구의 대타로 들어갔는지
}
::restHealFunc<-{	
	function healPlayer(finale){
		::restHealVars.roundEnd = true;
		local ent = null;
		local _NetProps = NetProps;

		while (ent = Entities.FindByClassname(ent, "player")){
			if(ent != null && ent.IsValid()){
				if(ent.GetZombieType() == 9 && _NetProps.GetPropInt(ent,"m_lifeState") == 0){//살아있을때만
					if(ent.IsIncapacitated()){	ent.ReviveFromIncap();	ent.SetHealthBuffer(0);	}
					ent.SetReviveCount(0);
					local getHealth = ent.GetHealth();
					ent.GiveItem("health");
					ent.SetHealth(getHealth);
					local tgHealth = getHealth;
					local getHealthBuffer = ent.GetHealthBuffer();

					if(getHealth < 2)	tgHealth = 2;

					getHealth = ent.GetHealth();

					if(getHealth < 65)	tgHealth = ::restHealFunc.healCount(getHealth);
					
					local len = ::restHealVars.idleList.len();
					for(local i = 0; i < len; i++){
						if(::restHealVars.idleList[i][1] == ent){
							::manacatAddTimer(0.1, false, ::restHealFunc.heal, { player = ::restHealVars.idleList[i][0], currentHP = getHealth, currentHPB = getHealthBuffer, tgHP = (tgHealth+2) });
						}
					}
					::manacatAddTimer(0.1, false, ::restHealFunc.heal, { player = ent, currentHP = getHealth, currentHPB = getHealthBuffer, tgHP = (tgHealth+2) });

					local model = ent.GetModelName();
					switch(model){
						case "models/survivors/survivor_gambler.mdl":		model = "hp0";	break;
						case "models/survivors/survivor_producer.mdl":		model = "hp1";	break;
						case "models/survivors/survivor_coach.mdl":			model = "hp2";	break;
						case "models/survivors/survivor_mechanic.mdl":		model = "hp3";	break;
						case "models/survivors/survivor_namvet.mdl":		model = "hp4";	break;
						case "models/survivors/survivor_teenangst.mdl":		model = "hp5";	break;
						case "models/survivors/survivor_manager.mdl":		model = "hp6";	break;
						case "models/survivors/survivor_biker.mdl":			model = "hp7";	break;
						default:											continue;
					}
					::restHealVars.healinfo[model] <- tgHealth;
				}
			}
		}
		
		SaveTable("chkpheal", ::restHealVars.healinfo);
	}

	function healCount(hp){
			local point = 50; //잔여 포인트
			local arr = [50,60,65,68,70]; //체력을 구간별로 나눠줌
			
			local f = 1.0; //보너스 배율
			local len = arr.len();

			for(local i = 0; i < len; i++){
				local nextHealth = arr[i];

				if(hp <= nextHealth){//현재 체력이 구간별 체력보다 작을때만 실행함
					local p = (nextHealth-hp)*f;//까주는 포인트

					if(point >= p){//포인트가 넉넉하면 체력을 다 줌
						point -= p;
						hp += nextHealth-hp;
					}else{//포인트가 적으면 포인트 만큼 체력을 주고 멈춰줌
						hp += floor(point/f+0.5);
						break;
					}
				}
				
				f *= 2; //포인트 까주는거 2배씩 증가
			}

			return hp;
		}

	function healBuffCount(ohp, nhp, buff){
		local ret = buff-(nhp-ohp);

		return (ret > 0) ? ret : 0;
	}

	function heal(params){
		if(params.player == null || !params.player.IsValid())return;
		local len = ::restHealVars.healStop.len();
		for(local i = 0; i < len; i++){
			if(::restHealVars.healStop[i] == params.player)return;
		}
		local healHP = (params.currentHP +(0.35 * (params.tgHP - params.currentHP))).tointeger();
		if((params.tgHP - healHP) < 1)healHP = params.tgHP;
		params.currentHPB = ::restHealFunc.healBuffCount(params.currentHP,healHP,params.currentHPB);
		params.currentHP = healHP;
		::manacatAddTimer(0.05, false, ::restHealFunc.heal, params);
		params.player.SetHealth(healHP);
		params.player.SetHealthBuffer(params.currentHPB);
	}

	function OnGameEvent_heal_success(params){
		if(::restHealVars.roundEnd){
			RestoreTable("chkpheal", ::restHealVars.healinfo);
			local player = GetPlayerFromUserID(params.subject);
			::restHealVars.healStop.append(player);
			local model = player.GetModelName()
			switch(model){
				case "models/survivors/survivor_gambler.mdl":		model = "hp0";	break;
				case "models/survivors/survivor_producer.mdl":		model = "hp1";	break;
				case "models/survivors/survivor_coach.mdl":			model = "hp2";	break;
				case "models/survivors/survivor_mechanic.mdl":		model = "hp3";	break;
				case "models/survivors/survivor_namvet.mdl":		model = "hp4";	break;
				case "models/survivors/survivor_teenangst.mdl":		model = "hp5";	break;
				case "models/survivors/survivor_manager.mdl":		model = "hp6";	break;
				case "models/survivors/survivor_biker.mdl":			model = "hp7";	break;
			}

			local tgHealth = ::restHealFunc.healCount(::restHealVars.healinfo[model]);

			player.SetHealth(tgHealth+(100-tgHealth)*Convars.GetFloat("first_aid_heal_percent"));
			::restHealVars.healinfo[model] <- player.GetHealth();
			SaveTable("chkpheal", ::restHealVars.healinfo);
		}
	}

	/* //피날레 100 HP
	function hpChk(){//피날레 챕터에서 100회복 시작이 됐는지 안됐는지 체크, 회복이 안됐으면 false
		local ent = null;
		local player = 0;
		
		while (ent = Entities.FindByClassname(ent, "player"))
		{
			if(ent.IsValid())
			{
				if(ent.GetZombieType() == 9)
				{
					local isInStartArea = (ResponseCriteria.GetValue(ent,"instartarea").tointeger() > 0) ? true : false;
					if(isInStartArea != true)return true;
					player = 1;
					if(ent.GetHealth() != 100)return false;
				}
			}
		}
		if(player == 0)return false;
		return true;
	}
	*/

	function OnGameEvent_map_transition(params){
		::restHealVars.healinfo <- {};
		healPlayer(false);
	}

	//피날레 100 HP
	function OnGameEvent_round_start_post_nav(params){
		RestoreTable("chkpheal", ::restHealVars.healinfo);
		SaveTable("chkpheal", ::restHealVars.healinfo);
		if(::restHealVars.healinfo.len() == 0 || (Director.IsSessionStartMap() && Time() < 10)){
			::restHealVars.healinfo <- {};
		}
	}

	function OnGameEvent_player_transitioned(params){
		::manacatAddTimer(0.01, false, ::restHealFunc.healRe, {player = GetPlayerFromUserID(params.userid)});
	}

	function OnGameEvent_bot_player_replace(params){	//printl("플레이어가 봇의 대타로 들어감")
		local player = GetPlayerFromUserID(params.player);
		local bot = GetPlayerFromUserID(params.bot);
		local len = ::restHealVars.idleList.len()-1;
		for(local i = len; i >= 0; i--){
			if(::restHealVars.idleList[i][0] == player)::restHealVars.idleList.remove(i);
		}
	}

	function OnGameEvent_player_bot_replace(params){	//printl("봇이 플레이어의 대타로 들어감")
		local player = GetPlayerFromUserID(params.player);
		local bot = GetPlayerFromUserID(params.bot);
		::restHealVars.idleList.append([player, bot]);
	}

	function OnGameEvent_player_disconnect(params){		//printl("연결 끊김");
		local player = GetPlayerFromUserID(params.userid);
		local len = ::restHealVars.idleList.len();
		for(local i = 0; i < len; i++){
			if(::restHealVars.idleList[i][0] == player){
				::restHealVars.idleList.remove(i);
			}
		}
	}

	function healRe(params){
		if(::restHealVars.healed){
			::restHealVars.healed = true;
			local ent = null;
			while (ent = Entities.FindByClassname(ent, "player")){
				local model = ent.GetModelName()
				switch(model){
					case "models/survivors/survivor_gambler.mdl":		model = "hp0";	break;
					case "models/survivors/survivor_producer.mdl":		model = "hp1";	break;
					case "models/survivors/survivor_coach.mdl":			model = "hp2";	break;
					case "models/survivors/survivor_mechanic.mdl":		model = "hp3";	break;
					case "models/survivors/survivor_namvet.mdl":		model = "hp4";	break;
					case "models/survivors/survivor_teenangst.mdl":		model = "hp5";	break;
					case "models/survivors/survivor_manager.mdl":		model = "hp6";	break;
					case "models/survivors/survivor_biker.mdl":			model = "hp7";	break;
					default:											return;
				}
				if(!(model in ::restHealVars.healinfo))continue;
				local currentHP = ent.GetHealth();
				local healHP = ::restHealVars.healinfo[model];
				ent.SetHealth(healHP);
				ent.SetHealthBuffer(::restHealFunc.healBuffCount(currentHP,healHP,ent.GetHealthBuffer()));
			}
		}else{
			local model = params.player.GetModelName()
			switch(model){
				case "models/survivors/survivor_gambler.mdl":		model = "hp0";	break;
				case "models/survivors/survivor_producer.mdl":		model = "hp1";	break;
				case "models/survivors/survivor_coach.mdl":			model = "hp2";	break;
				case "models/survivors/survivor_mechanic.mdl":		model = "hp3";	break;
				case "models/survivors/survivor_namvet.mdl":		model = "hp4";	break;
				case "models/survivors/survivor_teenangst.mdl":		model = "hp5";	break;
				case "models/survivors/survivor_manager.mdl":		model = "hp6";	break;
				case "models/survivors/survivor_biker.mdl":			model = "hp7";	break;
				default:											return;
			}
			if(!(model in ::restHealVars.healinfo))return;
			local currentHP = params.player.GetHealth();
			local healHP = ::restHealVars.healinfo[model];
			params.player.SetHealth(healHP);
			params.player.SetHealthBuffer(::restHealFunc.healBuffCount(currentHP,healHP,params.player.GetHealthBuffer()));
		}
	}
}

__CollectEventCallbacks(::restHealFunc, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);