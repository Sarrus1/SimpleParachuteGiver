#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1


public Plugin myinfo =
{
	name = "SimpleParachuteGiver",
	author = "Sarrus",
	description = "A simple plugin that gives parachute to player when they spawn.",
	version = "1.0",
	url = "https://github.com/Sarrus1/"
};

public void OnPluginStart()
{
	PrecacheModel("models/props_survival/upgrades/parachutepack.mdl");
	PrecacheModel("models/weapons/v_parachute.mdl");
	PrecacheModel("models/props_survival/parachute/chute.mdl");
	new flags = GetCommandFlags("parachute");
	if (!(SetCommandFlags("parachute", flags & ~FCVAR_CHEAT)))
		PrintToChatAll("Failed to load");
	else
		PrintToChatAll("Ye to load");
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}


public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int parachute_entity = CreateEntityByName("prop_weapon_upgrade_chute");
	float vecPosition[3];
	GetClientAbsOrigin(client, vecPosition);
	if (parachute_entity != -1)
	{
		DispatchSpawn(parachute_entity);
		TeleportEntity(parachute_entity, vecPosition, NULL_VECTOR , NULL_VECTOR);
	}
	return Plugin_Continue;
}