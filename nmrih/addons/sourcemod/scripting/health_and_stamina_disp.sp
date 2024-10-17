//	2018/08/20	v1.0.0	Dayonn_dayonn	気まぐれで新規作成。検証用に使う予定。たぶん公開しない。
//	2018/10/23	v1.0.1	Dayonn_dayonn	色変更、表示位置変更、常時表示からしゃがみ時表示へ変更。
//	2018/10/23	v1.0.2	Dayonn_dayonn	しゃがみながら移動したり攻撃しても表示されるように変更。
//	2019/05/25	v1.0.2	Dayonn_dayonn	体力の減少に合わせ表示色が変わるように変更。
//	2019/09/23	v1.0.4	Dayonn_dayonn	公開を前提としたソースコード見直し。機能自体に変更は無し。
//	2019/09/24	v1.0.5	Dayonn_dayonn	表示のちらつき防止のため、表示時間を 0.55 -> 0.65 に変更。
//	2020/07/31	v1.1.0	Dayonn_dayonn	機能を大幅に追加。かなり変わりすぎて、コード行数が10倍近いw
//										・体力表示の色変化をNMRiH本体と全く一緒になるよう、CVARからの読み取り and 色変化のスムーズ化。
//										・状態異常・チャージ攻撃力・攻撃時のダメージ表示を追加。
//										・Gray83 さん [NMRiH] Health & Armor Vampirism との同時利用を想定し、1行目を非表示にできるよう機能追加。
//											(https://forums.alliedmods.net/showthread.php?t=300674)
//										・表示位置変更機能を追加。
//	2020/08/02	v1.1.1	Dayonn_dayonn	2行表示を3行表示に変更。翻訳機能を追加。チャージ投げでもチャージ攻撃量を表示していたので非表示に修正。
//	2020/08/07	v1.1.2	Dayonn_dayonn	色の変化の計算式が間違えていたので修正。
//	2020/08/26	v1.1.3	Dayonn_dayonn	それぞれの文字位置をcfgで設定できるよう変更。(cfgを変更することで、2行表示ができる。)
//										Lord Stranker さんの要望により、キーバインド設定できるよう機能追加。
//	2020/09/01	v1.1.4	Dayonn_dayonn	一度しゃがむと永遠に体力を表示し続ける現象を修正。
//										他プラグインによりアイテム除去を行うと、このプラグインがエラーを大量に出力する現象を修正。
//										クライアントが攻撃を行った直後に切断すると、このプラグインがエラーを大量に出力する現象を修正。
//										その他、取得した値が異常なためにエラーが発生する現象を全体的に検証、修正。
//										(検証に協力してくれた Lord Stranker さん、 yomox9 さん、 misosiruGT さん、 overmase さんに感謝します。)
//	2020/09/03	v1.1.4a	Dayonn_dayonn	overmase さんからバグ報告、6桁もの異常なダメージが脳幹ショット時に出るとのこと。原因の特定はできていないが、お試しで修正。
//	2020/10/08	v1.1.5	Dayonn_dayonn	GEEEX221 さんからバグ報告。キーバインド設定時、一部のプレイヤーのキー設定が処理されていなかった現象を修正。
//										(clientの範囲指定で"<="とすべき所が"<"になっていた)。
//	2020/12/30	v1.1.6	Dayonn_dayonn	2行目と3行目をそれぞれ非表示にできるよう機能追加。
//										脳幹ショット時、ヘッドショットの50倍のダメージが出るのは仕様のようなので、いったんv1.1.4aにて行った仮修正を元に戻す。
//										(リアリズムモードのヘッドショットの時と同様に、ゾンビの最大体力+1のダメージ表示 に表示を補正しても構わないとも思ったが、
//										実際にそのダメージがでているので、そのまま表示させる。)
//	2022/04/18	v1.1.7	Dayonn_dayonn	他の表示を上書き表示しないように修正。表示の優先順位をcfgに追加。
//										常時表示に対応。
//										テスト用に限定公開。
//	2022/04/24	v1.1.8	Dayonn_dayonn	ダメージ量が4未満の時にはダメージ表記をしないよう修正(炎上ダメージによってそれまでのダメージ表示が消えてしまうのを防止)。
//										ゾンビ・プレイヤー以外へのダメージを表示しないよう変更。(処理の軽量化。)
//										Listen Serverにて、感染時にエラーでサーバが落ちる不具合を修正。
//										ダメージ量の表示時間をcfgにて設定するよう修正。
//										(表示量も設定できるようにしたかったが、グローバルで動的配列を設定するにはCreateArray関数が必要で、これを使うと処理が遅くので諦めた。)
//	2022/04/27	v1.1.9	Dayonn_dayonn	adjust_damage との機能連携。
//	2022/06/08	v1.1.10	Dayonn_dayonn	MonsterXD さんからバグ報告により発覚。Valveはサーバがクライアント上で一部のコマンド実行をすることを許可しない。
//										キーバインド機能も該当する。この為、キーバインド機能を削除。
//
//---------------------------------------------------------------------------------------------------------------------------



#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.1.10"



public Plugin myinfo = {
	name = "health_and_stamina_disp",
	author = "Dayonn_dayonn",
	description = "Display health, stamina, debuff, charge value and damage value",
	version = PLUGIN_VERSION
};



const float fPrint_Time = 0.3;							// 1回ごとに表示する時間。表示は同じチャンネルで上書きするので、表示が重複することはない。
														// 0.15ではちらつく場合があるので0.3に変更。
const float fPrint_Repeat_time = 0.1;					// 表示する処理を何秒ごとに繰り返すか。
const float fShowHudText_From_Me = 876.5;				// このプラグインからのShowHudTextであることを示すため、fxTimeに書き込むkey値。この数字自体に意味はない。
const float fCharge_Show_Time = 4.5;					// チャージ量表示をリセットする秒数。
const int iDamage_Count_Max = 5;						// ダメージの最大表示数。
KeyValues hConfig;										// Config の KeyValue 。
int iCfg_Print_Health;									// 体力とスタミナ表示をするかどうか(cfgによる設定)。
int iCfg_Print_Charge;									// チャージ量を表示するかどうか(cfgによる設定)。
int iCfg_Print_Damage;									// ダメージを表示するかどうか(cfgによる設定)。
float fCfg_Damage_Reset_Time = 4.5;						// ダメージ表示をリセットする秒数。
float fCfg_Health_Pos_x = 0.02;							// 体力を表示する位置 x
float fCfg_Health_Pos_y = 0.86;							// 体力を表示する位置 y
float fCfg_Charge_Pos_x = 0.02;							// チャージ量を表示する位置 x
float fCfg_Charge_Pos_y = 0.90;							// チャージ量を表示する位置 y
float fCfg_Damage_Pos_x = 0.02;							// ダメージを表示する位置 x
float fCfg_Damage_Pos_y = 0.94;							// ダメージを表示する位置 y

bool bIs_Print_Health_Swich[MAXPLAYERS + 1];			// 体力とスタミナ表示をするかどうか(フラグ)。

float fMAX_Charge;										// CVAR "sv_max_charge_length"  default: 3.5
float fCharge_Per_Sec;									// CVAR "sv_melee_dmg_per_sec"  default: 0.571
float fMaglite_Factor;									// CVAR "sv_maglite_melee_factor"  default: 0.35
float fEtool_pick_Factor;								// CVAR "sv_etool_pick_damage_modifier"  default: 1.5
int iZombie_Health;										// CVAR "sv_zombie_health"
int iRunner_Health;										// = CVAR "sv_runner_health_fraction" * "sv_zombie_health"
int iKid_Health;										// = CVAR "sv_kid_health_fraction" * "sv_zombie_health"

int iWeapon[MAXPLAYERS + 1];							// 装備中武器のエンティティのID
bool bWeapon_Can_Charge[MAXPLAYERS + 1];				// 装備中武器がチャージ攻撃可能かどうか。
char sWeapon[MAXPLAYERS + 1][32];						// 装備中武器の名前
int iShortest_Charging_Damage[MAXPLAYERS + 1];			// 武器変更時、.cfgファイルから読み込む。.cfgファイルの値は.ctxファイルの"HeadshotDamage"と同じ値にする。
														// 本来ならば.ctxファイルから読み込んだ方がいいけれど、呼び出し方法が分からない..。
int iCharge_Attack[MAXPLAYERS + 1];						// 画面に表示するチャージ攻撃のチャージ量。チャージ量を表示するかどうかのフラグにも使用。リセット必要。
bool bIs_Freeze;										// ゲーム自体がフリーズ状態(脱出時のカメラ演出の間・ラウンド開始時の1秒以下の動けない時間)かどうか
bool bIs_Charge_Attack[MAXPLAYERS + 1];					// 現在チャージ攻撃をしているかどうかを格納する。リセット必要。
int iDamage_Count[MAXPLAYERS + 1];						// 一定時間内に何回ダメージを与えたか。ダメージ表示をするかどうかのフラグにも使用。リセット必要。
char sDamage[MAXPLAYERS + 1][iDamage_Count_Max + 1][16];		// 与えたダメージ量の配列				BrainStem		//すうじをちょうせいちゅう
char sDamage_Print[MAXPLAYERS + 1][20 + (3 + 16) * iDamage_Count_Max + 2 + 5]; // 与えたダメージを画面表示できるよう処理した文字列。翻訳対応のため大目にとってある。
Handle hDamage_Print_Timer[MAXPLAYERS + 1];				// ダメージ表示タイマーのハンドル。
Handle hCharge_Print_Timer[MAXPLAYERS + 1];				// チャージ量表示タイマーのハンドル。

int iPrint_Channel[MAXPLAYERS + 1][3];					// 体力・チャージ量・ダメージ量をどのチャンネルに表示するか。
enum
{ 
	iContents_Health = 0,								// iPrint_Channelの配列数が3だから、0-2を ヘルス / チャージ / ダメージ にしている。
	iContents_Charge = 1,
	iContents_Damage = 2,
	iContents_NoData = 3,
	iContents_Other = 4
};
int iChannel_Contents[MAXPLAYERS + 1][6];					// チャンネルごとの利用状況。値はemunの値を利用する。
Handle hOther_Print_Timer[MAXPLAYERS + 1][6];			// チャンネル利用状況のリセットタイマー。

int iCfg_Show_Priority[3];								// 表示優先度(cfgによる設定)。値はemunの値を利用する。
float fDamage_Factor[MAXPLAYERS + 1];					// ダメージ倍率。adjust_damage との連携で使用する。



//ロード直後、OnPluginStartの前に実行。Native関数が他のプラグインから実行できるよう宣言する。
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("Send_fDamage_Factor", Native_Get_fDamage_Factor);
    return APLRes_Success;
}



public void OnPluginStart()
{
	LoadTranslations("health_and_stamina_disp.phrases");
	Load_Config();
	Load_CVAR();
	Hook_Change_CVAR();
	Hook_Events();
	CreateTimer(fPrint_Repeat_time, Repeat_Print, _, TIMER_REPEAT);
}



void Load_Config()
{
	hConfig = new KeyValues("health_and_stamina_disp.cfg");
	char sConfig_Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig_Path, sizeof(sConfig_Path), "configs/health_and_stamina_disp.cfg");
	if (!hConfig.ImportFromFile(sConfig_Path)) {
		SetFailState("[health_and_stamina_disp]: Couldn't load 'health_and_stamina_disp.cfg' from ...addons/sourcemod/configs/");
	}

	// Display Config のロード
	hConfig.JumpToKey("Display_Config",false);
	iCfg_Print_Health = hConfig.GetNum("Show_Health_and_stamina", 1);
	iCfg_Print_Charge = hConfig.GetNum("Show_Charge", 1);
	iCfg_Print_Damage = hConfig.GetNum("Show_Damage", 1);
	fCfg_Damage_Reset_Time = hConfig.GetFloat("Damage_Reset_Time", 4.5);
	iCfg_Show_Priority[hConfig.GetNum("Show_priority_of_Health_and_stamina", 1) - 1] = iContents_Health;
	iCfg_Show_Priority[hConfig.GetNum("Show_priority_of_Charge", 2) - 1] = iContents_Charge;
	iCfg_Show_Priority[hConfig.GetNum("Show_priority_of_Damage", 3) - 1] = iContents_Damage;
	fCfg_Health_Pos_x = hConfig.GetFloat("Health_Display_Position_x", 0.020);
	fCfg_Health_Pos_y = hConfig.GetFloat("Health_Display_Position_y", 0.860);
	fCfg_Charge_Pos_x = hConfig.GetFloat("Charge_Display_Position_x", 0.020);
	fCfg_Charge_Pos_y = hConfig.GetFloat("Charge_Display_Position_y", 0.900);
	fCfg_Damage_Pos_x = hConfig.GetFloat("Damage_Display_Position_x", 0.020);
	fCfg_Damage_Pos_y = hConfig.GetFloat("Damage_Display_Position_y", 0.940);

	hConfig.GoBack();
	hConfig.JumpToKey("Headshot_Damage_with_Shortest_Charging",false);		//頻繁に使用するから、先にジャンプしておく。
}



void Load_CVAR()
{
	fMAX_Charge = FindConVar("sv_max_charge_length").FloatValue;
	fCharge_Per_Sec = FindConVar("sv_melee_dmg_per_sec").FloatValue;
	fMaglite_Factor = FindConVar("sv_maglite_melee_factor").FloatValue;
	fEtool_pick_Factor = FindConVar("sv_etool_pick_damage_modifier").FloatValue;
	iZombie_Health = FindConVar("sv_zombie_health").IntValue;
	iRunner_Health = RoundToZero(float(iZombie_Health) * FindConVar("sv_runner_health_fraction").FloatValue);
	iKid_Health = RoundToZero(float(iZombie_Health) * FindConVar("sv_kid_health_fraction").FloatValue);
}



void Hook_Change_CVAR()
{
	FindConVar("sv_max_charge_length").AddChangeHook(OnCVAR_Change);
	FindConVar("sv_melee_dmg_per_sec").AddChangeHook(OnCVAR_Change);
	FindConVar("sv_maglite_melee_factor").AddChangeHook(OnCVAR_Change);
	FindConVar("sv_etool_pick_damage_modifier").AddChangeHook(OnCVAR_Change);
	FindConVar("sv_zombie_health").AddChangeHook(OnCVAR_Change);
	FindConVar("sv_runner_health_fraction").AddChangeHook(OnCVAR_Change);
	FindConVar("sv_kid_health_fraction").AddChangeHook(OnCVAR_Change);
}



public void OnCVAR_Change(ConVar hCVAR, char[] sOld_Value, char[] sNew_Value)
{
	char sCVAR_Name[64];
	if (hCVAR == INVALID_HANDLE) return;
	hCVAR.GetName(sCVAR_Name, sizeof(sCVAR_Name));

	if (StrEqual(sCVAR_Name, "sv_max_charge_length"))
	{
		fMAX_Charge = StringToFloat(sNew_Value);
	}
	else if (StrEqual(sCVAR_Name, "sv_melee_dmg_per_sec"))
	{
		fCharge_Per_Sec = StringToFloat(sNew_Value);
	}
	else if (StrEqual(sCVAR_Name, "sv_maglite_melee_factor"))
	{
		fMaglite_Factor = StringToFloat(sNew_Value);
	}
	else if (StrEqual(sCVAR_Name, "sv_etool_pick_damage_modifier"))
	{
		fEtool_pick_Factor = StringToFloat(sNew_Value);
	}
	else if (StrEqual(sCVAR_Name, "sv_zombie_health"))
	{
		iZombie_Health = StringToInt(sNew_Value);
		iRunner_Health = RoundToZero(float(iZombie_Health) * FindConVar("sv_runner_health_fraction").FloatValue);
		iKid_Health = RoundToZero(float(iZombie_Health) * FindConVar("sv_kid_health_fraction").FloatValue);
	}
	else if (StrEqual(sCVAR_Name, "sv_runner_health_fraction"))
	{
		iRunner_Health = RoundToZero(float(iZombie_Health) * StringToFloat(sNew_Value));
	}
	else if (StrEqual(sCVAR_Name, "sv_kid_health_fraction"))
	{
		iKid_Health = RoundToZero(float(iZombie_Health) * StringToFloat(sNew_Value));
	}
}



void Hook_Events()
{
	HookEvent("player_spawn", OnPlayer_spawn_Post, EventHookMode_Post);
	HookEvent("nmrih_reset_map", OnReset_Map_Pre, EventHookMode_Pre);	// PreのNoCopyはない。
	HookEvent("nmrih_round_begin", OnRound_Begin_Post, EventHookMode_PostNoCopy);
	HookEvent("freeze_all_the_things", OnFreeze_Post, EventHookMode_Post);
	HookUserMessage(GetUserMessageId("HudMsg"), OnDisp_HudMsg_Pre, false);
}



// プレイヤーのスポーン直後、初期化をする。
public void OnPlayer_spawn_Post(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (hEvent == INVALID_HANDLE) return;
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	// チャージ量リセット、フラグとフラグのタイマーもリセット
	if(iCfg_Print_Charge != 0)
	{	
		iCharge_Attack[client] = 0;
		bIs_Charge_Attack[client] = false;
		if (iCfg_Print_Charge == 1)delete hCharge_Print_Timer[client];
	}

	// ダメージリセット、タイマーもリセット
	if(iCfg_Print_Damage != 0)
	{	
		iDamage_Count[client] = 0;
		if (iCfg_Print_Damage == 1)delete hDamage_Print_Timer[client];
	}
}



// マップ開始 and リスタートの瞬間で、ラウンドがリセットされる直前(ただし、練習時間のスタートは除く)、
// プレイヤーが操作できないことを変数に取得する。
public void OnReset_Map_Pre(Event hEvent, const char[] name, bool dontBroadcast)
{
	bIs_Freeze = true;
}



// マップ開始 or リスタート にて、動けるようになった直後、プレイヤーが操作できることを変数に取得する。
public void OnRound_Begin_Post(Event hEvent, const char[] name, bool dontBroadcast)
{
	bIs_Freeze = false;
}



// 脱出時のカメラ演出へ切り替わった後と戻った後、プレイヤーが操作できるかどうかを変数で取得する。
public void OnFreeze_Post(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (hEvent == INVALID_HANDLE) return;
	bIs_Freeze = hEvent.GetBool("frozen");
	if(bIs_Freeze)
	{
		// チャージ表示の初期化。ダメージ表示の初期化はしない。
		if(iCfg_Print_Charge != 0)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				// チャージ量リセット、フラグとフラグのタイマーもリセット
				iCharge_Attack[client] = 0;
				bIs_Charge_Attack[client] = false;
				if (iCfg_Print_Charge == 1)delete hCharge_Print_Timer[client];
			}
		}
	}
}



// クライアントログイン後に、キーバインドを追加・チャンネルのリセット
public void OnClientPostAdminCheck(int client)
{
	if (!(1 <= client && client <= MaxClients)) return; 	//なぜか client = 15648 とエラーが出た事があった。その対策。
	if(IsFakeClient(client)) return;					//外部からの情報取得後は、エラー回避のため全て検証する必要がある。

	// 1行目、体力とスタミナを表示するか初期設定
	switch(iCfg_Print_Health)
	{
		case 0:
		{
			bIs_Print_Health_Swich[client] = false;
		}
		case 2:
		{
			bIs_Print_Health_Swich[client] = true;
		}
	}

	//表示チャンネルのリセット
	iPrint_Channel[client][iContents_Health] = 3;
	iPrint_Channel[client][iContents_Charge] = 4;
	iPrint_Channel[client][iContents_Damage] = 5;
	
	//使用中チャンネルのリセット
	for (int iChannel = 0; iChannel <= 5; iChannel++)
	{
		iChannel_Contents[client][iChannel] = iContents_NoData;
	}

	// ダメージ乗数のリセット
	fDamage_Factor[client] = 1.0;
}



// 	クライアント切断前に、タイマーリセット(をしないとハンドル変数が残り続ける)。
public void OnClientDisconnect(int client)
{
	if (iCfg_Print_Charge == 1)delete hCharge_Print_Timer[client];
	if (iCfg_Print_Damage == 1)delete hDamage_Print_Timer[client];
	for (int iChannel = 0; iChannel <= 5; iChannel++)
	{
		if (iChannel_Contents[client][iChannel] != iContents_NoData)delete hOther_Print_Timer[client][iChannel];
	}
}



// 画面表示を行う。画面表示の更新時間・描画時間は定数で調整する。
public Action Repeat_Print(Handle hTimer)
{
	if (MaxClients == 0)return Plugin_Continue;		// クライアントが参加できない状態(マップ変更中等)なら、終了。
	if (bIs_Freeze)return Plugin_Continue;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (!IsClientTimingOut(client) && IsPlayerAlive(client))
			{
				//キーバインドされていないとき、しゃがんでいるかどうかで表示判定
				if (iCfg_Print_Health == 1)
				{
					if (GetEntProp(client, Prop_Send, "m_bDucked") == 1)
					{
						bIs_Print_Health_Swich[client] = true;
					}
					else
					{
						bIs_Print_Health_Swich[client] = false;
					}
				}

				// １行目、体力とスタミナ表示
				float fFX_time;
				if ((bIs_Print_Health_Swich[client]) && (iPrint_Channel[client][iContents_Health] != 10))
				{
					// 体力・スタミナの文字列を生成
					int iHealth = GetClientHealth(client);
					int iStamina = RoundToZero(GetEntPropFloat(client, Prop_Send, "m_flStamina", 0));
					char sHealth_Text[256];
					FormatEx(sHealth_Text, sizeof(sHealth_Text), "%T", "Health", client, iHealth, iStamina);

					// 出血・感染・ワクチン接種の文字列を生成
					if(GetEntProp(client, Prop_Send, "_bleedingOut") == 1)
					{
						Format(sHealth_Text, sizeof(sHealth_Text), "%T", "bleeding", client, sHealth_Text);		//文字列の再編集なので、安全のためFormatを使う。
					}

					if(GetEntProp(client, Prop_Send, "_vaccinated") == 1)
					{
						Format(sHealth_Text, sizeof(sHealth_Text), "%T", "vaccinated", client, sHealth_Text);
					}
					else
					{
						float fInfection_Death_Time = GetEntPropFloat(client, Prop_Send, "m_flInfectionDeathTime");
						if(fInfection_Death_Time != -1.0)
						{
							int iInfection_Death_Time = RoundToNearest(fInfection_Death_Time - GetGameTime());
							Format(sHealth_Text, sizeof(sHealth_Text), "%T", "infected", client, sHealth_Text, iInfection_Death_Time);
						}
					}				

					/*--------------
					//デバッグ検証用。1行目をチャンネル利用状況の文字列に置き換える。
					//注；処理の軽量化のため、Health/Charge/Damageの場合は書き込みをせずにスキップするように変更した。再検証の時には注意。2022/04/24
					for (int i = 0; i <= 5; i++)
					{
						if (i == 0)
						{
							FormatEx(sHealth_Text, sizeof(sHealth_Text), "%i..", i);
						}
						else
						{
							Format(sHealth_Text, sizeof(sHealth_Text), "%s / %i..", sHealth_Text, i);
						}

						switch(iChannel_Contents[client][i])
						{
							case iContents_Health:
							{
								Format(sHealth_Text, sizeof(sHealth_Text), "%sHealth", sHealth_Text);
							}
							case iContents_Charge:
							{
								Format(sHealth_Text, sizeof(sHealth_Text), "%sCharge", sHealth_Text);
							}
							case iContents_Damage:
							{
								Format(sHealth_Text, sizeof(sHealth_Text), "%sDamage", sHealth_Text);
							}
							case iContents_NoData:
							{
								Format(sHealth_Text, sizeof(sHealth_Text), "%sNoData", sHealth_Text);
							}
							case iContents_Other:
							{
								Format(sHealth_Text, sizeof(sHealth_Text), "%sOther", sHealth_Text);
							}
						}
					}
					--------------*/

					// 体力・スタミナの文字列を表示
					int iText_Color_r, iText_Color_g, iText_Color_b;
					iText_Color_b = 0;
					if (iHealth > 99)		// 100
					{
						iText_Color_r = 0;
						iText_Color_g = 255;
					}
					else if (iHealth > 66)		// 99 - 67
					{
						iText_Color_r = RoundToNearest(((100.0 - float(iHealth)) / 34.0) * 255.0);
						iText_Color_g = 255;
					}
					else if (iHealth > 33)		// 66 - 34
					{
						iText_Color_r = 255;
						iText_Color_g = RoundToNearest((float(iHealth) - 33.0) / 33.0 * 255.0);
					}
					else		// 33 - 0
					{
						iText_Color_r = 255;
						iText_Color_g = 0;
					}

					fFX_time = fShowHudText_From_Me + float(iContents_Health);
					SetHudTextParams(fCfg_Health_Pos_x, fCfg_Health_Pos_y, fPrint_Time, iText_Color_r, iText_Color_g, iText_Color_b, 255, 0, fFX_time, 0.0, 0.0);
					ShowHudText(client, iPrint_Channel[client][iContents_Health], sHealth_Text);
				}

				// 2行目、チャージ量表示
				if((iCfg_Print_Charge >= 1) && (iPrint_Channel[client][iContents_Charge] != 10))
				{

					// 武器を変更したかどうかを確認する。
					// SDKHook(client, SDKHook_WeaponSwitchPost, On_Weapon_Switch_Post) で武器変更をフックする処理の方法だと、
					// 例えば!shopの売却直後の1秒間だとか、nmrih_item_deleter の代替品のない装備アイテムの削除だとかで、フックされずに何も装備していない(素手でもない)状態になる。
					// SDKHook_WeaponSwitchPost は何か別の武器に変更することをフックするので、何も装備していない状況はフックできない。サーバには負担になってしまうが、0.1秒ごとに装備のチェックを行う。
					int iWeapon_New;
					iWeapon_New = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if(iWeapon[client] != iWeapon_New)
					{
						bWeapon_Can_Charge[client] = false;	//エラー回避のため、念のため、if{}else{} の中に記述するのではなく、ここで初期化をする。
															//たとえば iWeapon_New がエンティティでない(何も装備していない、素手でもない)場合でも、チャージ攻撃が非表示になるだけでエラーを出さない。
						if (IsValidEntity(iWeapon_New))
						{
							iWeapon[client] = iWeapon_New;	//エラー回避のため、確認が取れてから取得する。
							if (HasEntProp(iWeapon[client], Prop_Send, "m_bIsCharging"))
							{
								bWeapon_Can_Charge[client] = true;
								GetEntityClassname(iWeapon[client], sWeapon[client], sizeof(sWeapon[]));
								iShortest_Charging_Damage[client] = hConfig.GetNum(sWeapon[client], -10);
									//検証のため、初期値を -10 にしている。.cfgファイルのリストに武器名が見つからない場合は、チャージ量がマイナス表示される。
							}
						}
					}	

					// チャージ攻撃時のチャージ量を取得する。
					if (bWeapon_Can_Charge[client])
					{
						if (GetEntProp(iWeapon[client], Prop_Send, "m_bIsCharging") == 1)
						{
							if (GetEntPropFloat(client, Prop_Send, "m_flThrowDropTimer") == -1.0)	// 投げチャージならGameTimeが入る。攻撃チャージなら-1.0
							{

								// チャージ攻撃のチャージ量を計算
								float fCharge_Time = GetGameTime() - GetEntPropFloat(iWeapon[client], Prop_Send, "m_flLastBeginCharge");
								Calculate_Charge_Attack(client, fCharge_Time);

								// フラグOn、タイマーをリセット
								bIs_Charge_Attack[client] = true;
								if (iCfg_Print_Charge == 1)delete hCharge_Print_Timer[client];
							}
						}
						else
						{
							// チャージ攻撃を放った直後だった場合、最終チャージ量を取得する。
							if(bIs_Charge_Attack[client])
							{
								// チャージ攻撃の最終チャージ量を計算
								float fCharge_Time = GetEntPropFloat(iWeapon[client], Prop_Send, "m_flLastChargeLength");
								Calculate_Charge_Attack(client, fCharge_Time);

								// フラグOff、タイマーをセット
								bIs_Charge_Attack[client] = false;
								if (iCfg_Print_Charge == 1)
								{
									hCharge_Print_Timer[client] = CreateTimer(fCharge_Show_Time, Timer_of_Reset_Charge, GetClientUserId(client));
								}
							}
						}
					}

					// チャージ量の文字列を生成・表示する。
					if((iCfg_Print_Charge == 2) || (iCharge_Attack[client] != 0))
					{
						char sCharge_Text[32];		//翻訳対応のため文字数を大目にとってある。

						// チャージ量の文字列を生成
						FormatEx(sCharge_Text, sizeof(sCharge_Text), "%T", "Charge", client, iCharge_Attack[client]);

						// チャージ量の文字列を表示
						int iText_Color_r, iText_Color_g, iText_Color_b;
						iText_Color_b = 0;
						if (iCharge_Attack[client] < iKid_Health)		// だれも一撃で倒せない .. 緑
						{
							iText_Color_r = 0;
							iText_Color_g = 255;
						}
						else if (iCharge_Attack[client] < iRunner_Health)		// kid以下を一撃で倒せる .. 黄色
						{
							iText_Color_r = 255;
							iText_Color_g = 255;
						}
						else if (iCharge_Attack[client] < iZombie_Health)		// runner以下を一撃で倒せる .. オレンジ
						{
							iText_Color_r = 255;
							iText_Color_g = 127;
						}
						else		// 通常ゾンビを一撃で倒せる .. 赤
						{
							iText_Color_r = 255;
							iText_Color_g = 0;
						}
						fFX_time = fShowHudText_From_Me + float(iContents_Charge);
						SetHudTextParams(fCfg_Charge_Pos_x, fCfg_Charge_Pos_y, fPrint_Time, iText_Color_r, iText_Color_g, iText_Color_b, 255, 0, fFX_time, 0.0, 0.0);
						ShowHudText(client, iPrint_Channel[client][iContents_Charge], sCharge_Text);
					}
				}

				// 3行目、ダメージ量表示
				if((iCfg_Print_Damage >= 1) && (iPrint_Channel[client][iContents_Damage] != 10))
				{
					// ダメージ量の文字列を表示する。
					if(iDamage_Count[client] > 0)
					{
						// ダメージ量の文字列を表示
						fFX_time = fShowHudText_From_Me + float(iContents_Damage);
						SetHudTextParams(fCfg_Damage_Pos_x, fCfg_Damage_Pos_y, fPrint_Time, 0, 255, 0, 255, 0, fFX_time, 0.0, 0.0);
						ShowHudText(client, iPrint_Channel[client][iContents_Damage], sDamage_Print[client]);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}



// チャージ攻撃のチャージ量を計算する。
void Calculate_Charge_Attack(int client, float fCharge_Time)
{
	if (fCharge_Time < 0.0)
	{
		fCharge_Time = 0.0;		// 構え動作中はマイナスになるから0に直す。
	}
	else if (fCharge_Time > fMAX_Charge)
	{
		fCharge_Time = fMAX_Charge;
	}

	// 計算
	float fAttack = float(iShortest_Charging_Damage[client]) * (1.0 + fCharge_Per_Sec * fCharge_Time) / fDamage_Factor[client];
	if (StrEqual(sWeapon[client], "item_maglite"))
	{
		fAttack = fAttack * fMaglite_Factor;
	} 
	else if (StrEqual(sWeapon[client], "me_etool"))
	{
		if (GetEntProp(iWeapon[client], Prop_Send, "_pickActive") == 1)
		{
			fAttack = fAttack * fEtool_pick_Factor;
		}
	}
	iCharge_Attack[client] = RoundToNearest(fAttack);
}



// チャージ攻撃を放ってから一定時間後にチャージ量をリセットする。クライアントの切断・接続により変数clientが再利用される可能性があるため、UseIDを引数にする。
public Action Timer_of_Reset_Charge(Handle timer, int iUser_Id)
{
	int client = GetClientOfUserId(iUser_Id);
	if(client != 0)	// クライアントが切断するなどして見つからないとき、0が返される。そのため、本来のclient = x のタイマハンドルの変数をここでは初期化できない。
	{	
		iCharge_Attack[client] = 0;
		hCharge_Print_Timer[client] = INVALID_HANDLE;
	}
	return Plugin_Continue;
}



// 新しいエンティティが出来た時、ゾンビであればフックをつける。
public void OnEntityCreated(int entity, const char[] classname)
{
	if(iCfg_Print_Damage >= 1)
	{
		if (!IsValidEntity(entity)) return;
		
		if(StrEqual(classname, "player")||
		   StrEqual(classname, "npc_nmrih_shamblerzombie")||
		   StrEqual(classname, "npc_nmrih_turnedzombie")||
		   StrEqual(classname, "npc_nmrih_runnerzombie")||
		   StrEqual(classname, "npc_nmrih_kidzombie"))
		{
			SDKHookEx(entity, SDKHook_OnTakeDamagePost, OnTake_Damage_Post);
				// エンティティが削除されるかプラグインがアンロードされれば、自動的にUnHookされる。
				// なので、KeyValueでHookしたエンティティのリストを保持しておいて、あとでSDKUnhookで丁寧に消していくといったようなことはしなくていい。
		}
	}	
}



// 何かがダメージを受けた時、プレイヤーからの攻撃かを確認し、ダメージ表示の文字列を生成する。
public void OnTake_Damage_Post(int victim, int iAttacker, int inflictor, float fDamage, int damagetype)
{
	if (!IsValidEntity(inflictor)) return;		//ダメージを与えた手段がエンティティではない場合(イベントやプラグインやコマンドの場合)、処理しない。
	if (iAttacker < 1 || iAttacker > MaxClients) return;
	if (victim == iAttacker) return;		// 自殺・出血・炎上ダメージ等、攻撃者が自分であるダメージは表示しない。
	if (fDamage < 4.0) return;		// 炎上等、小さいダメージの場合には表示しない。

	// ダメージ文字列の格納位置の調整
	if (iDamage_Count[iAttacker] == iDamage_Count_Max)
	{
		// 表示位置をずらす
		for (int i = 1; i <= iDamage_Count_Max - 1; i++)
		{
			Format(sDamage[iAttacker][i], sizeof(sDamage[][]), "%s", sDamage[iAttacker][i + 1]);
		}
	}
	else
	{
		iDamage_Count[iAttacker]++;
	}
	IntToString(RoundToNearest(fDamage), sDamage[iAttacker][iDamage_Count[iAttacker]], sizeof(sDamage[][]));

	// 表示用文字列生成
	switch(iDamage_Count[iAttacker])
	{
		case 1:
		{
			FormatEx(sDamage_Print[iAttacker], sizeof(sDamage_Print[]), "%T%s", "Damage", iAttacker, sDamage[iAttacker][iDamage_Count[iAttacker]]);
		}

		case iDamage_Count_Max:
		{
			FormatEx(sDamage_Print[iAttacker], sizeof(sDamage_Print[]), "%T...", "Damage", iAttacker);
			for (int i = 1; i <= iDamage_Count[iAttacker]; i++)
			{			
				Format(sDamage_Print[iAttacker], sizeof(sDamage_Print[]), "%s + %s", sDamage_Print[iAttacker], sDamage[iAttacker][i]);
			}
		}

		default:
		{
			Format(sDamage_Print[iAttacker], sizeof(sDamage_Print[]), "%s + %s", sDamage_Print[iAttacker], sDamage[iAttacker][iDamage_Count[iAttacker]]);
		}
	}

	// ダメージ表示タイマーをリセット、再セット。
	if(iCfg_Print_Damage == 1)
	{
		if(fCfg_Damage_Reset_Time >= 0.0)
		{
			delete hDamage_Print_Timer[iAttacker];
			hDamage_Print_Timer[iAttacker] = CreateTimer(fCfg_Damage_Reset_Time, Timer_of_Reset_Damage, GetClientUserId(iAttacker));
		}
	}	
}



// 最後にダメージを与えてから一定時間後にダメージ表示をリセットする。クライアントの切断・接続により変数clientが再利用される可能性があるため、UseIDを引数にする。
public Action Timer_of_Reset_Damage(Handle timer, int iUser_Id)
{
	int client = GetClientOfUserId(iUser_Id);
	if(client != 0)	// クライアントが切断するなどして見つからないとき、0が返される。そのため、本来のclient = x のタイマハンドルの変数をここでは初期化できない。
	{	
		iDamage_Count[client] = 0;
		hDamage_Print_Timer[client] = INVALID_HANDLE;
	}
	return Plugin_Continue;
}



// チャンネル表示をフックし、表示状況を変数に格納する。
public Action OnDisp_HudMsg_Pre(UserMsg msg_id, Handle hBf, const int[] players, int playersNum, bool reliable, bool init)
{
	// フックしたバッファから情報読み込み
	int iUse_Channel = BfReadByte(hBf);
	BfReadFloat(hBf);	//pos_x
	BfReadFloat(hBf);	//pos_y
	BfReadByte(hBf);	//color r1
	BfReadByte(hBf);	//color b1
	BfReadByte(hBf);	//color g1
	BfReadByte(hBf);	//color a1
	BfReadByte(hBf);	//color r2
	BfReadByte(hBf);	//color g2
	BfReadByte(hBf);	//color b2
	BfReadByte(hBf);	//color a2
	int iMsg_EffectType = BfReadByte(hBf);	// EffectType  0か1..fadeInTime時間をかけて徐々に濃くなって表示 / 2..fadeInTime時間ごとに1文字ずつ表示
	float fMsg_fadeInTime = BfReadFloat(hBf);	//fadeinTime  effectが2の時は、実際のFadeInTimeは、この値*文字数、になる。
	float fMsg_fadeOutTime = BfReadFloat(hBf);	// fadeoutTime  この時間だけ徐々に薄くなって消えていく。
	float fMsg_Hold_Time = BfReadFloat(hBf);	//holdTime  固定表示時間
	float fMsg_fxTime = BfReadFloat(hBf);	//fxTime  EffectTypeが0か1の場合、最初からcolor1にて表示され、この値は無視される。
											//        EffectTypeが2の場合、color2にて初期表示され、fxTimeの時間をかけてcolor1へ変化してゆく。
	char sMsg_Text[128];
	BfReadString(hBf, sMsg_Text, sizeof(sMsg_Text));	//text

	// 情報検証、エラー回避
	if ((playersNum < 0) || (playersNum > MaxClients))return Plugin_Continue;
	for (int i = 0; i <= playersNum - 1; i++)
	{
		if ((players[i] < 0) || (players[i] > MaxClients))return Plugin_Continue;
	}
	if ((iUse_Channel < 0) || (iUse_Channel > 5))return Plugin_Continue;
	if ((iMsg_EffectType < 0) || (iMsg_EffectType > 2))return Plugin_Continue;

	// 表示内容の確認
	int iContents;
	if (iMsg_EffectType == 0) //このプラグインからのShoWHudTextは、EffectType = 0 / FxTime = (fShowHudText_From_Me) + (enumのどれか) にしている。
	{
		iContents = RoundToNearest(fMsg_fxTime - fShowHudText_From_Me);
		if ((iContents < iContents_Health) || (iContents > iContents_Damage))iContents = iContents_Other;
	}
	else
	{
		iContents = iContents_Other;
	}

	// 表示終了予定時刻の計算
	float fShow_Time;
	if (iMsg_EffectType == 2)
	{
		fShow_Time = (fMsg_fadeInTime * StrLenMB(sMsg_Text)) + fMsg_Hold_Time + fMsg_fadeOutTime;
	}
	else
	{
		fShow_Time = fMsg_fadeInTime + fMsg_Hold_Time + fMsg_fadeOutTime;
	}

	//このプラグインによる表示ではない場合、チャンネル利用状況の書き込みと割り当ての再設定を行う。
	//ここではhealthとChargeとDamageの利用状況書き込みをスキップしている。再検証の為に必要であれば、※部分の処理をif文の処理の枠から外すようにコードを修正する事。2022/4/29
	if (iContents == iContents_Other)
	{
		for (int i = 0; i <= playersNum - 1; i++)
		{
			if (iChannel_Contents[players[i]][iUse_Channel] == iContents_Other)
				// 利用状況を書きこむ前に、現状の利用状況を確認し、使用中であればタイマーをリセットする。
			{
				delete hOther_Print_Timer[players[i]][iUse_Channel];
			}
			DataPack pack;		// ※ここから
			hOther_Print_Timer[players[i]][iUse_Channel] = CreateDataTimer(fShow_Time, Timer_of_Reset_Cannel, pack);
			pack.WriteCell(players[i]);
			pack.WriteCell(iUse_Channel);

			//チャンネルごとの利用状況を書き込む
			iChannel_Contents[players[i]][iUse_Channel] = iContents;		// ※ここまで スキップ解除

			Channel_Assignment(players[i]);
		}
	}
	return Plugin_Continue;
}



// マルチバイト文字列の文字数を数える
// Created by Impact123
// https://forums.alliedmods.net/showthread.php?t=216841
stock int StrLenMB(const char[] str)
{
	int len = strlen(str);
	int count;

	for(int i; i < len; i++)
	{
		count += ((str[i] & 0xc0) != 0x80) ? 1 : 0;
	}

	return count;
} 



// チャンネルの利用が終了したときに利用状況をリセットする。
public Action Timer_of_Reset_Cannel(Handle timer, DataPack pack)
{
	int client;
	int iChannel;

	pack.Reset();
	client = pack.ReadCell();
	iChannel = pack.ReadCell();

	if (iChannel_Contents[client][iChannel] == iContents_Other)
		//全体的にはOtherしかこないのでif文は不要だが、チャンネル利用状況の再検証でスキップする処理を戻す可能性もあるので、そのままにする。2022/4/24
	{
		iChannel_Contents[client][iChannel] = iContents_NoData;
		//他からのチャンネル利用だった場合、チャンネルが空くので、割り当ての再設定を行う。
		Channel_Assignment(client);
	}
	else
	{
		iChannel_Contents[client][iChannel] = iContents_NoData;
	}	
	
	hOther_Print_Timer[client][iChannel] = INVALID_HANDLE;
	return Plugin_Continue;
}



// チャンネルの再割り当てをする
void Channel_Assignment(int client)
{
	int i = 0;
	
	// 表示チャンネルの初期化。チャンネルは0-5なので、わざと10を入れて使用不可にする。
	for (int iContents = 0; iContents <= 2; iContents++)
	{	
		iPrint_Channel[client][iContents] = 10;
	}	

	for (int iChannel = 0; iChannel <= 5; iChannel++)
	{
		if(	iChannel_Contents[client][iChannel] == iContents_NoData)
		{
			iPrint_Channel[client][iCfg_Show_Priority[i]] = iChannel;
			i++;
			if (i == 3)return;
		}
	}
}



// adjust_damage との連携。ダメージ乗数を受信する。
public any Native_Get_fDamage_Factor(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}

	fDamage_Factor[client] = view_as<float>(GetNativeCell(2));
	return true;
}


