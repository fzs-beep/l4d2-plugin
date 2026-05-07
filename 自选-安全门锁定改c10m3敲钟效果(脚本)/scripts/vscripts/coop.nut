Msg("启用自定义战役脚本\n");
IncludeScript("VSLib");
IncludeScript("SetMapName");

//=====================================参数===================================================
//是否开启门锁。像死亡丧钟教堂安全门
::DoorLock <- true;

function Notifications::OnModeStart::GameStart(gamemode)
{
	Dooor();
}

/*******************门锁***********************/
//防止跑图。如果坦克存在终点门不开。或者需要玩家守一段时间
//允许玩家在起始安全门进行防守坦克。当然如果门不破。
::ambient_generic <- null
//::ambient_table <- null

::Dooor <- function()
{
	doorindex <- null;
	while ((doorindex = Entities.FindByClassname(doorindex,"prop_door_rotating_checkpoint")) != null)
	{	
		DoorModel <- NetProps.GetPropString(doorindex, "m_ModelName")
		/*
		安全门锁 最终考虑还是屏蔽，部分尸潮图，难度比较大，
		if(DoorModel.find("checkpoint_door_-01") != null || DoorModel.find("checkpoint_door_01") != null )
		{
			doorindex.ConnectOutput( "OnFullyOpen", "lock_open");			
		}
		*/
		if(DoorModel.find("checkpoint_door_02") != null || DoorModel.find("checkpoint_door_-02") != null )
		{
			//末端安全门强制关闭。开启触发尸潮
			if(DoorLock)
			{
			//必要条件，如喜欢守两拨丧钟尸潮？？
				if(SessionState.MapName == "c10m3_ranchhouse") return;
				if(SessionState.MapName == "hotel04_scaling1") return;
				if(SessionState.MapName == "wfp2_horn") return;
				
				local pos = doorindex.GetOrigin();
				//pos.z += 72.0;
				//在安全門上放置一個喇叭
				local ambient_table = {health = "10", message = "npc.churchguy_RadioButton1Extended18", pitch = "100", pitchstart = "100", radius = "1250", spawnflags = "32"};
				ambient_generic = ::VSLib.Utils.CreateEntity("ambient_generic", pos, QAngle(0,0,0), ambient_table);
				if (!ambient_generic)
				{
					printl("警告:安全門警報產生失敗.");
					return;
				}	
				
				local doors = ::VSLib.Entity(doorindex);
				doors.SetKeyValue("spawnflags", 10240);
				doors.SetKeyValue("spawnpos", 0);
				doors.Input("Close");
				doors.Input("Lock");
				doorindex.ConnectOutput( "OnOpen", "door_open"); 
			}
		}
	}
}

::lock_open <- function()
{	
	local door_id = ::VSLib.Entity(self);
	door_id.Input("Lock");
}

::door_open <- function()
{
	local P_Distance = 0;
	local GetNearNum = 0;
	local GetNoNearNum = 0;
	local AllPlayer = 0;
	local SafeDoor = null;
	local SafeDoor01 = [];
	local SafeDoor02 = [];
	local door_id = ::VSLib.Entity(self);
	foreach (P in Players.All())
	{
		if(Player(P).GetTeam() == SURVIVORS && Player(P).IsAlive() && !Player(P).IsIncapacitated())
		{
			AllPlayer++;
			P_Distance = Utils.CalculateDistance(door_id.GetLocation(), Entity(P).GetLocation());
			if(P_Distance <= 300)
			{
				GetNearNum++;
			}
			else
			{
				GetNoNearNum++;
			}
		}
	}
	if(GetNearNum == AllPlayer)
	{
		SafeDoor01 = "安全门已解除锁定, 请做好防守准备";
		SafeDoor02 = "解锁条件: 远 = 0 | 当前: "+GetNearNum+"近 "+GetNoNearNum+"远";
		ambient_generic.Input("PlaySound");
		Timers.AddTimer ( 1.0, false, SayNext01,self);

		door_id.Input("Close");
		door_id.Input("Lock");
		door_id.SetKeyValue("spawnflags", 32768);
		door_id.SetKeyValue("spawnpos", 2);
	}
	else
	{
		door_id.Input("Close");
		SafeDoor01 = "安全门已强制锁定，需要所有队友在附近才可解锁";
		SafeDoor02 = "解锁条件: 远 = 0 | 当前: "+GetNearNum+"近 "+GetNoNearNum+"远";
	}
	SafeDoor = HUD.Item("{safedoor01}\n{safedoor02}");
	SafeDoor.SetValue("safedoor01", SafeDoor01);
	SafeDoor.SetValue("safedoor02", SafeDoor02);
	SafeDoor.AttachTo(HUD_MID_BOT); //HUD位置参数，可使用预设参数，如HUD_MID_BOT，也可使用数值(0-14)，如0, 0, 0, 0(x坐标, y坐标, 宽, 高)
	SafeDoor.ChangeHUDNative(0, 300, 1024, 50, 1366, 720); // HUD坐标(xy)和长宽，后面1024(长)和768(宽)是屏幕最大值
	SafeDoor.SetTextPosition(TextAlign.Center); //文本对齐参数，Left=左对齐，Center=中心对齐，Right=右对齐
	SafeDoor.AddFlag(g_ModeScript.HUD_FLAG_NOBG); //设置HUD界面参数
	Timers.AddTimer( 10.0, false, CloseHud, SafeDoor ); //添加计时器关闭HUD
}

::SayNext01 <-function(self)
{
	//::VSLib.Utils.PlaySoundToAll("npc.churchguy_RadioButton1Extended34");
	ambient_generic.SetKeyValue("message", "npc.churchguy_RadioButton1Extended34");
	ambient_generic.Input("PlaySound");	
	Timers.AddTimer ( 3.5, false, SayNext02,self);
}
::SayNext02 <-function(self)
{
	//::VSLib.Utils.PlaySoundToAll("npc.churchguy_RadioButton1Extended40");
	ambient_generic.SetKeyValue("message", "npc.churchguy_RadioButton1Extended40");
	ambient_generic.Input("PlaySound");		
	Timers.AddTimer ( 2.0, false, SayNext03,self);
}

::SayNext03 <-function(self)
{
	//::VSLib.Utils.PlaySoundToAll("npc.churchguy_RadioButton1Extended43");
	ambient_generic.SetKeyValue("message", "npc.churchguy_RadioButton1Extended43");
	ambient_generic.Input("PlaySound");			
	Timers.AddTimer ( 2.5, false, SayNext04,self);
}

::SayNext04 <-function(self)
{
	ambient_generic.SetKeyValue("message", "Churchbell.StartLoop");
	ambient_generic.Input("PlaySound");		
	Timers.AddTimer ( 9.0, false, spawn_mob,self);
	
	//::VSLib.Utils.PlaySoundToAll("Churchbell.StartLoop");
}

::Open_Door <- function(door)
{

	local door_id = ::VSLib.Entity(door);
	door_id.Input("Unlock");
	door_id.Input("Toggle");	
	door_id.SetKeyValue("spawnflags", 8192);
	door_id.SetKeyValue("spawnpos", 1);	
	ambient_generic.StopSound("Churchbell.StartLoop")
	// VSLib.Utils.StopSoundOnAll("Churchbell.StartLoop");
	//ambient_generic.Input("ToggleSound");
	//ambient_generic.Kill();
	//也许这个声音不用关闭。。过图自定清空。如果出现bug再加时间经行关闭
	//VSLib.Utils.PlaySoundToAll("Churchbell.End");
	ambient_generic.SetKeyValue("message", "Churchbell.End");
	ambient_generic.Input("PlaySound");		
	door.DisconnectOutput( "OnOpen", "door_open");
	door_id.Input("Close");
}

::spawn_mob <- function(self)
{
	//重置特感和尸潮时间。
	//DirectorScript.DirectorOptions.LockTempo <- true;
	//SessionState.CurrentTick++;
	//Director.ResetMobTimer();
	Director.ResetSpecialTimers();
	Director.PlayMegaMobWarningSounds();
	Utils.TriggerStage( STAGE_PANIC, 5 );
	
	Timers.AddTimer ( 90.0, false, Open_Door,self);
}