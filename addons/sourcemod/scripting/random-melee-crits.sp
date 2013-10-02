#include <sourcemod>
#include <sdktools>
#include <tf2attributes>
#undef REQUIRE_EXTENSIONS
#include <tf2items>

#define SLOT_MELEE 3

#define VERSION "0.0.0"

new Handle:hEnabled = INVALID_HANDLE;

new bool:bEventHooked = false;

public Plugin:myinfo = 
{
	name = "Random Melee Crits",
	author = "thesupremecommander",
	description = "A plugin that disables random crits on all weapons except for melee weapons.",
	version = VERSION,
	url = "http://steamcommunity.com/groups/fwdcp"
};

public OnPluginStart()
{
	CreateConVar("random_melee_crits_version", VERSION, "Melee Random Crits version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	hEnabled = CreateConVar("random_melee_crits_enabled", "1", "sets whether only melee weapons should be allowed to randomly crit", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig();
}
 
public OnAllPluginsLoaded()
{
	if (!LibraryExists("tf2items") && bEventHooked)
	{
		HookEvent("post_inventory_application", Event_Inventory);
		bEventHooked = true;
	}
}
 
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "tf2items") && !bEventHooked)
	{
		HookEvent("post_inventory_application", Event_Inventory);
		bEventHooked = true;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "tf2items") && bEventHooked)
	{
		UnhookEvent("post_inventory_application", Event_Inventory);
		bEventHooked = false;
	}
}

public Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(hEnabled))
	{
		return;
	}
	
	new iUserId = GetEventInt(event, "userid");
	new iClient = GetClientOfUserId(iUserId);
	
	for (new iSlot = 0; iSlot <= 5; iSlot++)
	{
		new iWeaponEntity = GetPlayerWeaponSlot(iClient, iSlot);
		
		if (iWeaponEntity == -1)
		{
			break;
		}
	
		if (iSlot != SLOT_MELEE)
		{
			AddNoRandomCrits(iWeaponEntity);
		}
	}
}

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (!GetConVarBool(hEnabled))
	{
		return;
	}
	
	if (GetPlayerWeaponSlot(client, SLOT_MELEE) != entityIndex)
	{
		AddNoRandomCrits(entityIndex);
	}
}

AddNoRandomCrits(iWeaponEntity)
{	
	TF2Attrib_SetByName(iWeaponEntity, "crit mod disabled hidden", 0.0);
	TF2Attrib_ClearCache(iWeaponEntity);
}