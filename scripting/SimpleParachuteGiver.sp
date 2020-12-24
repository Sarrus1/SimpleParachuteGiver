#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define Survival_ParachuteEquipped	"survival/parachute_pickup_success_01.wav"
#define Survival_ItemPickup			"~survival/money_collect_04.wav"

#define ENABLE_BUTTON_JUMP		(1<<0)		/**< Jump Key */
#define ENABLE_BUTTON_LAW		(1<<1)		/**< LookAtWeapon Key */
#define ENABLE_BUTTON_USE		(1<<2)		/**< Use Key */

Handle g_hEquipParachute;
Handle g_hRemoveParachute;

int g_iClientParachuteEntity[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

public Plugin myinfo = {
	name = "[CS:GO] Parachute Manager",
	author = "SHUFEN from POSSESSION.tokyo fixed by Sarrus",
	description = "Allows player to use CS:GO internal parachute",
	version = "2.0",
	url = ""
};

//----------------------------------------------------------------------------------------------------
// Purpose: General
//----------------------------------------------------------------------------------------------------
public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("SimpleParachuteGiver.games");
	if (hGameConf == INVALID_HANDLE) {
		SetFailState("Couldn't load SimpleParachuteGiver.games game config!");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "EquipParachute")) {
		delete hGameConf;
		SetFailState("PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, \"EquipParachute\" failed!");
		return;
	}
	g_hEquipParachute = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RemoveParachute")) {
		delete hGameConf;
		SetFailState("PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, \"RemoveParachute\" failed!");
		return;
	}
	g_hRemoveParachute = EndPrepSDKCall();

	delete hGameConf;

	HookEvent("player_spawn", Event_PlayerSpawnPost, EventHookMode_Post);
}


public void OnMapStart() {
	PrecacheModel("models/props_survival/upgrades/parachutepack.mdl");
	PrecacheModel("models/weapons/v_parachute.mdl");
	PrecacheModel("models/props_survival/parachute/chute.mdl");

	// When Start Press E
	PrecacheSound("survival/parachute_pickup_start_01.wav", true);		// ENT: Parachute, CHA:6, VOL: 1.0, LVL: 75, PIT: 100, FLAG: 0

	// When Equipped
	PrecacheSound(Survival_ParachuteEquipped, true);					// ENT: Parachute, CHA: 6, VOL: 1.0, LVL: 75, PIT: 100, FLAG: 0
	PrecacheSound(Survival_ItemPickup, true);							// ENT: Parachute, CHA: 6, VOL: 1.0, LVL: 70, PIT: 100, FLAG: 1024

	// When Deployed
	PrecacheSound("survival/dropzone_parachute_deploy.wav", true);		// ENT: Client, CHA: 6, VOL: 0.5, LVL: 80, PIT: 100, FLAG: 0
	PrecacheSound("survival/dropzone_parachute_success_02.wav", true);	// ENT: Client, CHA: 6, VOL: 0.5, LVL: 80, PIT: 100, FLAG: 0 --> VOL: 0.0, LVL: 0, PIT: 100, FLAG: 4 (Stop Sound)
}


//----------------------------------------------------------------------------------------------------
// Purpose: Entities
//----------------------------------------------------------------------------------------------------
public void OnEntityCreated(int entity, const char[] classname) {
	if (StrEqual(classname, "dynamic_prop", false) || StrEqual(classname, "predicted_viewmodel", false))
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawn);
}

public void OnEntitySpawn(int entity) {
	RequestFrame(Frame_EntitySpawn_Post, entity);
}

void Frame_EntitySpawn_Post(int entity) {
	if (IsValidEntity(entity)) {
		char sModelPath[PLATFORM_MAX_PATH];//, sClassName[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
		if (StrContains(sModelPath, "chute.mdl", false) > -1) {
			int iOwner = GetEntPropEnt(entity, Prop_Data, "m_pParent");
			if (iOwner > 0 && iOwner <= MaxClients) {
				g_iClientParachuteEntity[iOwner] = entity;
			}
		}
	}
}

public void OnEntityDestroyed(int entity) {
	for (int i = 1; i < MaxClients; i++) {
		if (entity == g_iClientParachuteEntity[i])
			RequestFrame(Frame_CheckParachute, i);
	}
}

void Frame_CheckParachute(int client) {
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		EquipParachute(client);
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose: Events
//----------------------------------------------------------------------------------------------------
public void Event_PlayerSpawnPost(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	EquipParachute(client, true);
}


//----------------------------------------------------------------------------------------------------
// Purpose: SDKCalls
//----------------------------------------------------------------------------------------------------
stock void EquipParachute(int client, bool sounds = false) {
		SDKCall(g_hEquipParachute, client);
		if (sounds) {
			//EmitSoundToAll(Survival_ParachuteEquipped, client, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
			//EmitSoundToAll(Survival_ItemPickup, client, SNDCHAN_STATIC, SNDLEVEL_CAR, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
		}
		Event event = CreateEvent("parachute_pickup");
		if (event != null) {
			event.SetInt("userid", GetClientUserId(client));
			event.Fire();
		}
}

stock void RemoveParachute(int client) {
	SDKCall(g_hRemoveParachute, client);
}