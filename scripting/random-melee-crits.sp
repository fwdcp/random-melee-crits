#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <tf2attributes>
#include <tf2itemsinfo>
#undef REQUIRE_EXTENSIONS
#include <tf2items>

#define NO_WEAPONS_CRIT 0
#define MELEE_WEAPONS_CRIT 1
#define ALL_WEAPONS_CRIT 2

#define SLOT_MELEE 2

#define VERSION "1.3.1"

new Handle:hSelection = INVALID_HANDLE;
new Handle:hDebug = INVALID_HANDLE;
new Handle:hGameCrits = INVALID_HANDLE;

new bool:bEventHooked = false;

public Plugin:myinfo = 
{
	name = "Random Melee Crits",
	author = "thesupremecommander",
	description = "A plugin that can disable random crits on all weapons except for melee weapons.",
	version = VERSION,
	url = "http://steamcommunity.com/groups/fwdcp"
};

stock TagsCheck(const String:tag[], bool:add = true) // credits to DarthNinja
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (StrContains(tags, tag, false) == -1 && add)
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		ReplaceString(newTags, sizeof(newTags), ",,", ",", false);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	else if (StrContains(tags, tag, false) > -1 && !add)
	{
		ReplaceString(tags, sizeof(tags), tag, "", false);
		ReplaceString(tags, sizeof(tags), ",,", ",", false);
		SetConVarString(hTags, tags);
	}
	
	CloseHandle(hTags);
}

public OnPluginStart()
{
	CreateConVar("random_melee_crits_version", VERSION, "Melee Random Crits version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	hSelection = CreateConVar("random_melee_crits_selection", "1", "sets which weapons should be allowed to randomly crit (0: no weapons, 1: melee weapons, 2: all weapons)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hDebug = CreateConVar("random_melee_crits_debug", "0", "set whether the nocrit attribute is visible", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	hGameCrits = FindConVar("tf_weapon_criticals");
	
	HookConVarChange(hSelection, OnSelectionChange);
	HookConVarChange(hGameCrits, OnGameCritsChange);
	
	AutoExecConfig();
	
	UpdateCritSelection();
}
 
public OnAllPluginsLoaded()
{
	if (!LibraryExists("tf2items") && !bEventHooked)
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

public OnSelectionChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateCritSelection();
}

public OnGameCritsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (GetConVarInt(hSelection) == NO_WEAPONS_CRIT && GetConVarBool(hGameCrits))
	{
		SetConVarBool(hGameCrits, false, true);
	}
	else if (GetConVarInt(hSelection) != NO_WEAPONS_CRIT && !GetConVarBool(hGameCrits))
	{
		SetConVarBool(hGameCrits, true, true);
	}
	
	CreateTimer(0.1, Timer_SetTags);
}

public Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(hSelection) != MELEE_WEAPONS_CRIT)
	{
		return;
	}
	
	new iUserId = GetEventInt(event, "userid");
	new iClient = GetClientOfUserId(iUserId);
	
	for (new iSlot = 0; iSlot <= 5; iSlot++)
	{
		new iWeaponEntity = GetPlayerWeaponSlot(iClient, iSlot);
		
		if (Weapon_IsValid(iWeaponEntity == -1))
		{
			break;
		}
	
		if (iSlot != SLOT_MELEE)
		{
			if (GetConVarInt(hSelection) == MELEE_WEAPONS_CRIT)
			{
				AddNoRandomCrits(iWeaponEntity);
			}
			else if (CheckDefaultCritStatus(iWeaponEntity))
			{
				RemoveNoRandomCrits(iWeaponEntity);
			}
		}
	}
}

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (GetConVarInt(hSelection) != MELEE_WEAPONS_CRIT)
	{
		return;
	}
	
	CreateTimer(0.1, Timer_CheckWeapon, entityIndex);
}

public Action:Timer_CheckWeapon(Handle:timer, any:data)
{
	if (Weapon_IsValid(data) && GetPlayerWeaponSlot(Weapon_GetOwner(data), SLOT_MELEE) != data)
	{
		if (GetConVarInt(hSelection) == MELEE_WEAPONS_CRIT)
		{
			AddNoRandomCrits(data);
		}
		else if (CheckDefaultCritStatus(data))
		{
			RemoveNoRandomCrits(data);
		}
	}
	
	return Plugin_Handled;
}

public Action:Timer_SetTags(Handle:timer, any:data)
{
	if (GetConVarInt(hSelection) == ALL_WEAPONS_CRIT)
	{
		TagsCheck("nocrits", false);
	}
	else
	{
		TagsCheck("nocrits", true);
	}
}

UpdateCritSelection()
{
	new iSelection = GetConVarInt(hSelection);
	
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		{
			continue;
		}
		
		for (new iSlot = 0; iSlot <= 5; iSlot++)
		{
			new iWeaponEntity = GetPlayerWeaponSlot(iClient, iSlot);
			
			if (Weapon_IsValid(iWeaponEntity))
			{
				break;
			}
		
			if (iSlot != SLOT_MELEE)
			{
				if (iSelection == MELEE_WEAPONS_CRIT)
				{
					AddNoRandomCrits(iWeaponEntity);
				}
				else if (CheckDefaultCritStatus(iWeaponEntity))
				{
					RemoveNoRandomCrits(iWeaponEntity);
				}
			}
		}
	}
	
	if (iSelection == NO_WEAPONS_CRIT)
	{
		SetConVarBool(hGameCrits, false, true);
	}
	else
	{
		SetConVarBool(hGameCrits, true, true);
	}
	
	CreateTimer(0.1, Timer_SetTags);
}

AddNoRandomCrits(weapon)
{
	if (GetConVarBool(hDebug))
	{
		TF2Attrib_SetByName(weapon, "crit mod disabled", 0.0);
		TF2Attrib_ClearCache(weapon);
	}
	else
	{
		TF2Attrib_SetByName(weapon, "crit mod disabled hidden", 0.0);
		TF2Attrib_ClearCache(weapon);
	}
}

RemoveNoRandomCrits(weapon)
{
	TF2Attrib_RemoveByName(weapon, "crit mod disabled");
	TF2Attrib_RemoveByName(weapon, "crit mod disabled hidden");
}

CheckDefaultCritStatus(weapon)
{
	new iItemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	new iItemNumAttributes = TF2II_GetItemNumAttributes(iItemDefinitionIndex);
	
	for (new i = 0; i < iItemNumAttributes; i++)
	{
		new iItemAttributeID = TF2II_GetItemAttributeID(iItemDefinitionIndex, i);
		
		decl String:sAttributeName[32]; 
		TF2II_GetAttributeNameByID(iItemAttributeID, sAttributeName, sizeof(sAttributeName));
		
		if (StrContains(sAttributeName, "crit mod disabled", false) && TF2II_GetItemAttributeValue(iItemDefinitionIndex, i) == 0.0)
		{
			return false;
		}
	}
	
	return true;
}