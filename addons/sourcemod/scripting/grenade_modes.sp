
/* ========================================================================= */
/* INCLUDES                                                                  */
/* ========================================================================= */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls  required

/* ========================================================================= */
/* DEFINES                                                                   */
/* ========================================================================= */

/* Plugin version                                                            */
#define C_PLUGIN_VERSION                    "2.0.0"

/* ------------------------------------------------------------------------- */

/* High explosive grenade type                                               */
#define C_GRENADE_TYPE_HE                   (0)
/* Flashbang grenade type                                                    */
#define C_GRENADE_TYPE_FLASHBANG            (1)
/* Smoke grenade type                                                        */
#define C_GRENADE_TYPE_SMOKE                (2)
/* Decoy grenade type                                                        */
#define C_GRENADE_TYPE_DECOY                (3)
/* Tactical awareness grenade type                                           */
#define C_GRENADE_TYPE_TA                   (4)
/* Incendiary (+ molotov) grenade type                                       */
#define C_GRENADE_TYPE_INCENDIARY           (5)
/* Maximum grenade type                                                      */
#define C_GRENADE_TYPE_MAXIMUM              (6)

/* Normal grenade mode                                                       */
#define C_GRENADE_MODE_NORMAL               (0)
/* Impact grenade mode                                                       */
#define C_GRENADE_MODE_IMPACT               (1)
/* Proximity grenade mode                                                    */
#define C_GRENADE_MODE_PROXIMITY            (2)
/* Tripwire grenade mode                                                     */
#define C_GRENADE_MODE_TRIPWIRE             (3)
/* Maximum grenade mode                                                      */
#define C_GRENADE_MODE_MAXIMUM              (4)

/* ========================================================================= */
/* GLOBAL CONSTANTS                                                          */
/* ========================================================================= */

/* Plugin information                                                        */
public Plugin myinfo =
{
    name        = "Grenade Modes",
    author      = "Nyuu",
    description = "Add new custom modes for the grenades",
    version     = C_PLUGIN_VERSION,
    url         = "https://forums.alliedmods.net/showthread.php?t=309154"
}

/* ------------------------------------------------------------------------- */

/* Grenade type names (Translation)                                          */
char gl_szGrenadeTypeNameTr[C_GRENADE_TYPE_MAXIMUM][] =
{
    "TExplosive", // HE
    "TFlashbang", // FLASHBANG
    "TSmoke",     // SMOKE
    "TDecoy",     // DECOY
    "TTactical",  // TA
    "TIncendiary" // INCENDIARY (+ MOLOTOV)
};

/* Grenade mode names (Translation)                                          */
char gl_szGrenadeModeNameTr[C_GRENADE_MODE_MAXIMUM][] =
{
    "TNormal",    // NORMAL
    "TImpact",    // IMPACT
    "TProximity", // PROXIMITY
    "TTripwire"   // TRIPWIRE
};

/* Grenade mode limits                                                       */
int gl_iGrenadeModeLimits[C_GRENADE_TYPE_MAXIMUM] = 
{
    C_GRENADE_MODE_MAXIMUM, // HE
    C_GRENADE_MODE_MAXIMUM, // FLASHBANG
    C_GRENADE_MODE_MAXIMUM, // SMOKE
    C_GRENADE_MODE_MAXIMUM, // DECOY
    C_GRENADE_MODE_IMPACT,  // TA
    C_GRENADE_MODE_MAXIMUM  // INCENDIARY (+ MOLOTOV)
};

/* ========================================================================= */
/* GLOBAL VARIABLES                                                          */
/* ========================================================================= */

/* Plugin late loading                                                       */
bool      gl_bPluginLateLoading;

/* Players mode for each grenade type                                        */
int       gl_iPlayerGrenadeMode[MAXPLAYERS + 1][C_GRENADE_TYPE_MAXIMUM];

/* Beacon sprite                                                             */
int       gl_nSpriteBeacon;
/* Beam sprite                                                               */
int       gl_nSpriteBeam;
/* Halo sprite                                                               */
int       gl_nSpriteHalo;

/* Grenade weapon name stringmap                                             */
StringMap gl_hMapGrenadeWeaponName;
/* Grenade projectile name stringmap                                         */
StringMap gl_hMapGrenadeProjectileName;

/* ------------------------------------------------------------------------- */

/* Plugin enable cvar                                                        */
ConVar    gl_hCvarPluginEnable;
/* Color of the self effects cvar                                            */
ConVar    gl_hCvarEffectsSelfColor;
/* Color of the teammate effects cvar                                        */
ConVar    gl_hCvarEffectsTeammateColor;
/* Color of the enemy effects cvar                                           */
ConVar    gl_hCvarEffectsEnemyColor;
/* Powerup time for the proximity mode cvar                                  */
ConVar    gl_hCvarProximityPowerupTime;
/* Powerup time for the tripwire mode cvar                                   */
ConVar    gl_hCvarTripwirePowerupTime;

/* Plugin enable cvar value                                                  */
bool      gl_bCvarPluginEnable;
/* Color of the self effects cvar value                                      */
int       gl_iCvarEffectsSelfColor;
/* Color of the teammate effects cvar value                                  */
int       gl_iCvarEffectsTeammateColor;
/* Color of the enemy effects cvar value                                     */
int       gl_iCvarEffectsEnemyColor;
/* Powerup time for the proximity mode cvar value                            */
float     gl_flCvarProximityPowerupTime;
/* Powerup time for the tripwire mode cvar value                             */
float     gl_flCvarTripwirePowerupTime;

/* ========================================================================= */
/* FUNCTIONS                                                                 */
/* ========================================================================= */

/* ------------------------------------------------------------------------- */
/* Plugin                                                                    */
/* ------------------------------------------------------------------------- */

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrorMaxLen)
{
    // Cache plugin late loading status
    gl_bPluginLateLoading = bLate;
    
    return APLRes_Success;
}

public void OnPluginStart()
{
    // Initialize the cvars
    CvarInitialize();
    
    // Load the translations
    LoadTranslations("grenade_modes.phrases");
    
    // Prepare the grenade weapon name stringmap
    gl_hMapGrenadeWeaponName = new StringMap();
    gl_hMapGrenadeWeaponName.SetValue("weapon_hegrenade",    C_GRENADE_TYPE_HE);
    gl_hMapGrenadeWeaponName.SetValue("weapon_flashbang",    C_GRENADE_TYPE_FLASHBANG);
    gl_hMapGrenadeWeaponName.SetValue("weapon_smokegrenade", C_GRENADE_TYPE_SMOKE);
    gl_hMapGrenadeWeaponName.SetValue("weapon_decoy",        C_GRENADE_TYPE_DECOY);
    gl_hMapGrenadeWeaponName.SetValue("weapon_tagrenade",    C_GRENADE_TYPE_TA);
    gl_hMapGrenadeWeaponName.SetValue("weapon_incgrenade",   C_GRENADE_TYPE_INCENDIARY);
    gl_hMapGrenadeWeaponName.SetValue("weapon_molotov",      C_GRENADE_TYPE_INCENDIARY);
    
    // Prepare the grenade projectile name stringmap
    gl_hMapGrenadeProjectileName = new StringMap();
    gl_hMapGrenadeProjectileName.SetValue("hegrenade_projectile",    C_GRENADE_TYPE_HE);
    gl_hMapGrenadeProjectileName.SetValue("flashbang_projectile",    C_GRENADE_TYPE_FLASHBANG);
    gl_hMapGrenadeProjectileName.SetValue("smokegrenade_projectile", C_GRENADE_TYPE_SMOKE);
    gl_hMapGrenadeProjectileName.SetValue("decoy_projectile",        C_GRENADE_TYPE_DECOY);
    gl_hMapGrenadeProjectileName.SetValue("tagrenade_projectile",    C_GRENADE_TYPE_TA);
    gl_hMapGrenadeProjectileName.SetValue("molotov_projectile",      C_GRENADE_TYPE_INCENDIARY);
    
    // Hook the player command +lookatweapon
    AddCommandListener(OnPlayerLookAtWeapon, "+lookatweapon");
    
    // Manage late loading
    PluginStartLate();
}

void PluginStartLate()
{
    // Check if the plugin has been loaded late
    if (gl_bPluginLateLoading)
    {
        // Process the players already on the server
        for (int iPlayer = 1 ; iPlayer <= MaxClients ; iPlayer++)
        {
            // Check if the player is connected
            if (IsClientConnected(iPlayer))
            {
                // Call the client connected forward
                OnClientConnected(iPlayer);
            }
        }
    }
}

/* ------------------------------------------------------------------------- */
/* Map                                                                       */
/* ------------------------------------------------------------------------- */

public void OnMapStart()
{
    // Precache the sprites
    gl_nSpriteBeacon = PrecacheModel("materials/sprites/physbeam.vmt");
    gl_nSpriteBeam   = PrecacheModel("materials/sprites/purplelaser1.vmt");
    gl_nSpriteHalo   = PrecacheModel("materials/sprites/purpleglow1.vmt");
    
    // Precache the sounds
    PrecacheSound("buttons/blip1.wav");
    PrecacheSound("buttons/blip2.wav");
}

/* ------------------------------------------------------------------------- */
/* Cvar                                                                      */
/* ------------------------------------------------------------------------- */

void CvarInitialize()
{
    // Create the version cvar
    CreateConVar("sm_grenade_modes_version", C_PLUGIN_VERSION, "Display the plugin version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY);
    
    // Create the custom cvars
    gl_hCvarPluginEnable         = CreateConVar("sm_grenade_modes_enable",                 "1",        "Enable the plugin",                     _, true, 0.0, true, 1.0);
    gl_hCvarEffectsSelfColor     = CreateConVar("sm_grenade_modes_self_color",             "0x0000FF", "Set the color of the self effects",     _, true, 0.0);
    gl_hCvarEffectsTeammateColor = CreateConVar("sm_grenade_modes_teammate_color",         "0x0000FF", "Set the color of the teammate effects", _, true, 0.0);
    gl_hCvarEffectsEnemyColor    = CreateConVar("sm_grenade_modes_enemy_color",            "0xFF0000", "Set the color of the enemy effects",    _, true, 0.0);
    gl_hCvarProximityPowerupTime = CreateConVar("sm_grenade_modes_proximity_powerup_time", "2.0",      "Set the proximity powerup time",        _, true, 0.0);
    gl_hCvarTripwirePowerupTime  = CreateConVar("sm_grenade_modes_tripwire_powerup_time",  "2.0",      "Set the tripwire powerup time",         _, true, 0.0);
    
    // Cache the custom cvars values
    gl_bCvarPluginEnable          = gl_hCvarPluginEnable.BoolValue;
    gl_iCvarEffectsSelfColor      = gl_hCvarEffectsSelfColor.IntValue;
    gl_iCvarEffectsTeammateColor  = gl_hCvarEffectsTeammateColor.IntValue;
    gl_iCvarEffectsEnemyColor     = gl_hCvarEffectsEnemyColor.IntValue;
    gl_flCvarProximityPowerupTime = gl_hCvarProximityPowerupTime.FloatValue;
    gl_flCvarTripwirePowerupTime  = gl_hCvarTripwirePowerupTime.FloatValue;
    
    // Hook the custom cvars change
    gl_hCvarPluginEnable.AddChangeHook(OnCvarChanged);
    gl_hCvarEffectsSelfColor.AddChangeHook(OnCvarChanged);
    gl_hCvarEffectsTeammateColor.AddChangeHook(OnCvarChanged);
    gl_hCvarEffectsEnemyColor.AddChangeHook(OnCvarChanged);
    gl_hCvarProximityPowerupTime.AddChangeHook(OnCvarChanged);
    gl_hCvarTripwirePowerupTime.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
    // Cache the custom cvars values
    if      (gl_hCvarPluginEnable         == hCvar) gl_bCvarPluginEnable          = gl_hCvarPluginEnable.BoolValue;
    else if (gl_hCvarEffectsSelfColor     == hCvar) gl_iCvarEffectsSelfColor      = gl_hCvarEffectsSelfColor.IntValue;
    else if (gl_hCvarEffectsTeammateColor == hCvar) gl_iCvarEffectsTeammateColor  = gl_hCvarEffectsTeammateColor.IntValue;
    else if (gl_hCvarEffectsEnemyColor    == hCvar) gl_iCvarEffectsEnemyColor     = gl_hCvarEffectsEnemyColor.IntValue;
    else if (gl_hCvarProximityPowerupTime == hCvar) gl_flCvarProximityPowerupTime = gl_hCvarProximityPowerupTime.FloatValue;
    else if (gl_hCvarTripwirePowerupTime  == hCvar) gl_flCvarTripwirePowerupTime  = gl_hCvarTripwirePowerupTime.FloatValue;
}

/* ------------------------------------------------------------------------- */
/* Client                                                                    */
/* ------------------------------------------------------------------------- */

public void OnClientConnected(int iClient)
{
    // Reset the mode of all the grenade types
    for (int iGrenadeType = 0 ; iGrenadeType < C_GRENADE_TYPE_MAXIMUM ; iGrenadeType++)
    {
        gl_iPlayerGrenadeMode[iClient][iGrenadeType] = C_GRENADE_MODE_NORMAL;
    }
}

/* ------------------------------------------------------------------------- */
/* Player                                                                    */
/* ------------------------------------------------------------------------- */

public Action OnPlayerLookAtWeapon(int iPlayer, const char[] szCommand, int iArgc)
{
    // Check if the plugin is enabled
    if (gl_bCvarPluginEnable)
    {
        // Check if the player is alive
        if (IsClientInGame(iPlayer) && IsPlayerAlive(iPlayer))
        {
            char szClassname[32];
            int  iGrenadeType;
            
            // Get the player weapon
            GetClientWeapon(iPlayer, szClassname, sizeof(szClassname));
            
            // Check if the player weapon is a grenade
            if (gl_hMapGrenadeWeaponName.GetValue(szClassname, iGrenadeType))
            {
                // Cache the grenade mode
                int iGrenadeMode = gl_iPlayerGrenadeMode[iPlayer][iGrenadeType];
                
                // @TODO: Search the next grenade mode available using cvars
                iGrenadeMode = (iGrenadeMode + 1) % gl_iGrenadeModeLimits[iGrenadeType];
                
                // Set the grenade mode
                gl_iPlayerGrenadeMode[iPlayer][iGrenadeType] = iGrenadeMode;
                
                // Display the grenade mode
                PrintHintText(iPlayer, "<b> %t <font color='#CE7FFF'>%t</font></b>\n\
                                        <b> >> %t : <font color='#4FE44A'>%t</font></b>",
                                        "TGrenade", gl_szGrenadeTypeNameTr[iGrenadeType], 
                                        "TMode",    gl_szGrenadeModeNameTr[iGrenadeMode]);
            }
        }
    }
    
    return Plugin_Continue;
}

int PlayerGetEffectColor(int iPlayer, int iOther, int iOtherTeam)
{
    // Check if the player sees his own effect
    if (iPlayer == iOther)
    {
        return gl_iCvarEffectsSelfColor;
    }
    // Check if the player sees the effect of a teammate
    else if (GetClientTeam(iPlayer) == iOtherTeam)
    {
        return gl_iCvarEffectsTeammateColor;
    }
    
    // The player sees the effect of an enemy
    return gl_iCvarEffectsEnemyColor;
}

/* ------------------------------------------------------------------------- */
/* Entity                                                                    */
/* ------------------------------------------------------------------------- */

public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    static int iGrenadeType;
    
    // Check if the plugin is enabled
    if (gl_bCvarPluginEnable)
    {
        // Check if the entity created is a grenade projectile
        if (gl_hMapGrenadeProjectileName.GetValue(szClassname, iGrenadeType))
        {
            // Hook the grenade spawn function
            SDKHook(iEntity, SDKHook_SpawnPost, OnGrenadeSpawnPost);
        }
    }
}

/* ------------------------------------------------------------------------- */
/* Grenade                                                                   */
/* ------------------------------------------------------------------------- */

public void OnGrenadeSpawnPost(int iGrenade)
{
    // Request the next frame
    RequestFrame(OnGrenadeSpawnPostNextFrame, EntIndexToEntRef(iGrenade));
}

public void OnGrenadeSpawnPostNextFrame(int iGrenadeReference)
{
    // Get the grenade index
    int iGrenade = EntRefToEntIndex(iGrenadeReference);
    
    // Check if the grenade is still valid
    if (iGrenade != INVALID_ENT_REFERENCE)
    {
        char szClassname[32];
        int  iGrenadeType;
        
        // Get the grenade classname
        GetEdictClassname(iGrenade, szClassname, sizeof(szClassname));
        
        // Get the grenade type
        if (gl_hMapGrenadeProjectileName.GetValue(szClassname, iGrenadeType))
        {
            // Get the grenade owner
            int iGrenadeOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
            
            // Check if the owner is in game
            if ((1 <= iGrenadeOwner <= MaxClients) && IsClientInGame(iGrenadeOwner))
            {
                // Switch on the player grenade mode
                switch (gl_iPlayerGrenadeMode[iGrenadeOwner][iGrenadeType])
                {
                    case C_GRENADE_MODE_NORMAL:
                    {
                        // Nothing to do
                    }
                    case C_GRENADE_MODE_IMPACT:
                    {
                        // Set the grenade as infinite
                        SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", -1);
                        
                        // Hook the grenade touch function
                        SDKHook(iGrenade, SDKHook_Touch, OnGrenadeImpactTouch);
                    }
                    case C_GRENADE_MODE_PROXIMITY:
                    {
                        DataPack hGrenadePack;
                        
                        // Set the grenade as infinite
                        SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", -1);
                        
                        // Hook the grenade touch function
                        SDKHook(iGrenade, SDKHook_Touch, OnGrenadeTouchBlock);
                        
                        // Start the grenade think function
                        CreateDataTimer(0.1, OnGrenadeThink, hGrenadePack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                        
                        // Prepare the datapack
                        // ------------------------------
                        // int iGrenadeReference
                        // int hGrenadeThinkFunction
                        // ------------------------------
                        // int iGrenadeCounter
                        // ------------------------------
                        hGrenadePack.WriteCell(EntIndexToEntRef(iGrenade));
                        hGrenadePack.WriteFunction(OnGrenadeProximityThink__WaitIdle);
                        hGrenadePack.WriteCell(0);
                    }
                    case C_GRENADE_MODE_TRIPWIRE:
                    {
                        // Set the grenade as infinite
                        SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", -1);
                        
                        // Hook the grenade touch function
                        SDKHook(iGrenade, SDKHook_Touch, OnGrenadeTouchBlock);
                        
                        // Hook the grenade touch function
                        SDKHook(iGrenade, SDKHook_Touch, OnGrenadeTripwireTouch);
                    }
                }
            }
        }
    }
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Common                                                         */
/* ------------------------------------------------------------------------- */

void GrenadeSetBreakable(int iGrenade, int iHealth)
{
    // Set the grenade as breakable
    SetEntProp(iGrenade, Prop_Data, "m_takedamage", 2);
    SetEntProp(iGrenade, Prop_Data, "m_iHealth", iHealth);
}

bool GrenadeCheckTouch(int iGrenade, int iOther, bool bCheckPlayers)
{
    // Check if the grenade touches the world / sky
    if (iOther <= 0)
    {
        return true;
    }
    // Check if the grenade touches a player 
    else if (1 <= iOther <= MaxClients)
    {
        // Check if the players must be checked
        if (bCheckPlayers)
        {
            // Check if the touched player isn't the grenade owner
            if (GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity") != iOther)
            {
                return true;
            }
        }
    }
    // Check if the grenade touches a solid entity
    else if (GetEntProp(iOther, Prop_Send, "m_nSolidType", 1) && !(GetEntProp(iOther, Prop_Send, "m_usSolidFlags", 2) & 0x0004))
    {
        return true;
    }
    
    return false;
}

void GrenadeDetonate(int iGrenade)
{
    char szClassname[32];
    int  iGrenadeType;
    
    // Get the grenade classname
    GetEdictClassname(iGrenade, szClassname, sizeof(szClassname));
    
    // Get the grenade type
    if (gl_hMapGrenadeProjectileName.GetValue(szClassname, iGrenadeType))
    {
        // Switch on the grenade type
        switch (iGrenadeType)
        {
            case C_GRENADE_TYPE_HE, C_GRENADE_TYPE_FLASHBANG, C_GRENADE_TYPE_INCENDIARY:
            {
                // Set the grenade as breakable
                GrenadeSetBreakable(iGrenade, 1);
                
                // Detonate the grenade
                SDKHooks_TakeDamage(iGrenade, iGrenade, iGrenade, 100.0);
            }
            case C_GRENADE_TYPE_SMOKE, C_GRENADE_TYPE_DECOY:
            {
                float vGrenadeVelocity[3] = {0.0, 0.0, 0.0};
                
                // Stop the grenade velocity
                TeleportEntity(iGrenade, NULL_VECTOR, NULL_VECTOR, vGrenadeVelocity);
                
                // Detonate the grenade in the next tick
                SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", 1);
            }
            case C_GRENADE_TYPE_TA:
            {
                // @TODO - Call SDKTouch ?
            }
        }
    }
}

/* ------------------------------------------------------------------------- */

public Action OnGrenadeTouchBlock(int iGrenade, int iOther)
{
    // Don't continue touch
    return Plugin_Handled;
}

// @TODO: It shouldn't work with an enemy smokegrenade / decoy
public Action OnGrenadeTakeDamageBlock(int iGrenade, int &iAttacker, int &iInflictor, float &flDamage, int &iDamagetype)
{
    // Check if the attacker is a player
    if (1 <= iAttacker <= MaxClients)
    {
        // Get the grenade owner
        int iGrenadeOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
        
        // Check if the owner is still connected and in the same team than the attacker
        if ((1 <= iGrenadeOwner <= MaxClients) && (GetClientTeam(iAttacker) == GetClientTeam(iGrenadeOwner)))
        {
            // Don't do damage
            return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

public bool OnGrenadeTraceFilter(int iEntity, int iContentsMask, any iData)
{
    return (iEntity == view_as<int>(iData)) ? false : true;
}

public bool OnGrenadeTraceFilterNoPlayer(int iEntity, int iContentsMask, any iData)
{
    return ((iEntity == view_as<int>(iData)) || (1 <= iEntity <= MaxClients)) ? false : true;
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Impact                                                         */
/* ------------------------------------------------------------------------- */

public Action OnGrenadeImpactTouch(int iGrenade, int iOther)
{
    // Check if the grenade touches something
    if (GrenadeCheckTouch(iGrenade, iOther, true))
    {
        // Detonate the grenade
        GrenadeDetonate(iGrenade);
        
        // Don't continue touch
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Proximity                                                      */
/* ------------------------------------------------------------------------- */

public Action OnGrenadeProximityThink__WaitIdle(int iGrenade, DataPack hGrenadePack)
{
    static int      iGrenadeReference;
    static Function hGrenadeThinkFunction;
    static int      iGrenadeCounter;
    static float    vGrenadeVelocity[3];
    
    // Read the datapack
    ResetPack(hGrenadePack);
    iGrenadeReference     = hGrenadePack.ReadCell();
    hGrenadeThinkFunction = hGrenadePack.ReadFunction();
    iGrenadeCounter       = hGrenadePack.ReadCell();
    
    // Get the grenade velocity
    GetEntPropVector(iGrenade, Prop_Data, "m_vecVelocity", vGrenadeVelocity);
    
    // Check if the grenade is stationary
    if (GetVectorLength(vGrenadeVelocity) <= 0.0)
    {
        // Set the grenade as breakable
        GrenadeSetBreakable(iGrenade, 10);
        
        // Hook the grenade takedamage function
        SDKHook(iGrenade, SDKHook_OnTakeDamage, OnGrenadeTakeDamageBlock);
        
        // Set the grenade think function
        hGrenadeThinkFunction = OnGrenadeProximityThink__Powerup;
        
        // Set the grenade counter
        iGrenadeCounter = RoundFloat(gl_flCvarProximityPowerupTime * 10.0);
    }
    
    // Write the datapack
    ResetPack(hGrenadePack);
    hGrenadePack.WriteCell(iGrenadeReference);
    hGrenadePack.WriteFunction(hGrenadeThinkFunction);
    hGrenadePack.WriteCell(iGrenadeCounter);
    
    // Continue the timer
    return Plugin_Continue;
}

public Action OnGrenadeProximityThink__Powerup(int iGrenade, DataPack hGrenadePack)
{
    static int      iGrenadeReference;
    static Function hGrenadeThinkFunction;
    static int      iGrenadeCounter;
    
    // Read the datapack
    ResetPack(hGrenadePack);
    iGrenadeReference     = hGrenadePack.ReadCell();
    hGrenadeThinkFunction = hGrenadePack.ReadFunction();
    iGrenadeCounter       = hGrenadePack.ReadCell();
    
    // Decrement the grenade counter
    iGrenadeCounter--;
    
    // Check if the grenade is operational
    if (iGrenadeCounter <= 0)
    {
        // Play a sound
        EmitSoundToAll("buttons/blip2.wav", iGrenade, _, SNDLEVEL_CONVO, _, 0.9);
        
        // Set the grenade think function
        hGrenadeThinkFunction = OnGrenadeProximityThink__Operational;
    }
    else if ((iGrenadeCounter % 2) == 0)
    {
        // Play a sound
        EmitSoundToAll("buttons/blip1.wav", iGrenade, _, SNDLEVEL_CONVO, _, 0.9);
    }
    
    // Write the datapack
    ResetPack(hGrenadePack);
    hGrenadePack.WriteCell(iGrenadeReference);
    hGrenadePack.WriteFunction(hGrenadeThinkFunction);
    hGrenadePack.WriteCell(iGrenadeCounter);
    
    // Continue the timer
    return Plugin_Continue;
}

public Action OnGrenadeProximityThink__Operational(int iGrenade, DataPack hGrenadePack)
{
    static int      iGrenadeReference;
    static Function hGrenadeThinkFunction;
    static int      iGrenadeCounter;
    static int      iGrenadeOwner;
    
    // Read the datapack
    ResetPack(hGrenadePack);
    iGrenadeReference     = hGrenadePack.ReadCell();
    hGrenadeThinkFunction = hGrenadePack.ReadFunction();
    iGrenadeCounter       = hGrenadePack.ReadCell();
    
    // Get the grenade owner
    iGrenadeOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
    
    // Check if the owner is in game
    if ((1 <= iGrenadeOwner <= MaxClients) && IsClientInGame(iGrenadeOwner))
    {
        static int   iGrenadeTeam;
        static float vGrenadeOrigin[3];
        static float vPlayerOrigin[3];
        static int   iPlayer;
        
        // Get the grenade team
        iGrenadeTeam = GetClientTeam(iGrenadeOwner);
        
        // Get the grenade origin
        GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", vGrenadeOrigin);
        
        // Prepare the player index
        iPlayer = -1;
        
        // Check if there's a valid player near the grenade
        while ((iPlayer = FindEntityByClassname(iPlayer, "player")) != -1)
        {
            if ((1 <= iPlayer <= MaxClients) && (IsPlayerAlive(iPlayer)) && (GetClientTeam(iPlayer) != iGrenadeTeam))
            {
                GetEntPropVector(iPlayer, Prop_Send, "m_vecOrigin", vPlayerOrigin);
                
                if (GetVectorDistance(vGrenadeOrigin, vPlayerOrigin) <= 100.0)
                {
                    // Detonate the grenade
                    GrenadeDetonate(iGrenade);
                    
                    // Stop the timer
                    return Plugin_Stop;
                }
            }
        }
        
        // Decrement the grenade counter
        iGrenadeCounter--;
        
        // Check if the players must be warned
        if (iGrenadeCounter <= 0)
        {
            static int iPlayers[MAXPLAYERS + 1];
            static int iNbPlayers;
            static int iNumPlayer;
            static int iColor;
            
            // Move the grenade origin above the ground
            vGrenadeOrigin[2] += 2;
            
            // Get all the players in range
            iNbPlayers = GetClientsInRange(vGrenadeOrigin, RangeType_Audibility, iPlayers, MaxClients);
            
            // Send the beacon effect to all the close players
            for (iNumPlayer = 0 ; iNumPlayer < iNbPlayers ; iNumPlayer++)
            {
                // Cache the player index
                iPlayer = iPlayers[iNumPlayer];
                
                // Get the effect color
                iColor = PlayerGetEffectColor(iPlayer, iGrenadeOwner, iGrenadeTeam);
                
                // Prepare the beacon effect
                TE_Start      ("BeamRingPoint");
                TE_WriteVector("m_vecCenter",     vGrenadeOrigin);
                TE_WriteFloat ("m_flStartRadius", 0.0);
                TE_WriteFloat ("m_flEndRadius",   200.0);
                TE_WriteNum   ("m_nModelIndex",   gl_nSpriteBeacon);
                TE_WriteNum   ("m_nHaloIndex",    gl_nSpriteHalo);
                TE_WriteNum   ("m_nStartFrame",   0);
                TE_WriteNum   ("m_nFrameRate",    0);
                TE_WriteFloat ("m_fLife",         0.5);
                TE_WriteFloat ("m_fWidth",        4.0);
                TE_WriteFloat ("m_fEndWidth",     4.0);
                TE_WriteNum   ("r",               (iColor >> 16) & 0xFF);
                TE_WriteNum   ("g",               (iColor >>  8) & 0xFF);
                TE_WriteNum   ("b",               (iColor      ) & 0xFF);
                TE_WriteNum   ("a",               255);
                TE_WriteNum   ("m_nFadeLength",   0);
                
                // Send the beacon effect to the player
                TE_SendToClient(iPlayer);
            }
            
            // Set the grenade counter
            iGrenadeCounter = 10;
        }
    }
    else
    {
        // Kill the grenade
        AcceptEntityInput(iGrenade, "kill");
        
        // Stop the timer
        return Plugin_Stop;
    }
    
    // Write the datapack
    ResetPack(hGrenadePack);
    hGrenadePack.WriteCell(iGrenadeReference);
    hGrenadePack.WriteFunction(hGrenadeThinkFunction);
    hGrenadePack.WriteCell(iGrenadeCounter);
    
    // Continue the timer
    return Plugin_Continue;
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Tripwire                                                       */
/* ------------------------------------------------------------------------- */

public Action OnGrenadeTripwireTouch(int iGrenade, int iOther)
{
    // Check if the grenade touches something
    if (GrenadeCheckTouch(iGrenade, iOther, false))
    {
        float vTracker[6][3] = {{ 0.0,  0.0,  8.0},
                                { 0.0,  8.0,  0.0},
                                { 8.0,  0.0,  0.0},
                                { 0.0,  0.0, -8.0},
                                { 0.0, -8.0,  0.0},
                                {-8.0,  0.0,  0.0}};
        
        Handle hTrace;
        float  vGrenadeOrigin[3];
        float  vGrenadeEndPoint[3];
        float  vGrenadeNormal[3];
        
        int    i;
        float  flFraction;
        float  flBestFraction;
        
        // Get the grenade origin
        GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", vGrenadeOrigin);
        
        // Search the best fraction
        flBestFraction = 1.0;
        
        for (i = 0 ; i < 6 ; i++)
        {
            vGrenadeEndPoint[0] = vTracker[i][0] + vGrenadeOrigin[0];
            vGrenadeEndPoint[1] = vTracker[i][1] + vGrenadeOrigin[1];
            vGrenadeEndPoint[2] = vTracker[i][2] + vGrenadeOrigin[2];
            
            hTrace     = TR_TraceRayFilterEx(vGrenadeOrigin, vGrenadeEndPoint, MASK_SOLID, RayType_EndPoint, OnGrenadeTraceFilterNoPlayer, iGrenade);
            flFraction = TR_GetFraction(hTrace);
            
            if (flBestFraction > flFraction)
            {
                flBestFraction = flFraction;
                TR_GetPlaneNormal(hTrace, vGrenadeNormal);
            }
            
            CloseHandle(hTrace);
        }
        
        // Check if the fraction is good
        if (flBestFraction < 1.0)
        {
            DataPack hGrenadePack;
            
            // Start the grenade think function
            CreateDataTimer(0.1, OnGrenadeThink, hGrenadePack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            
            // Prepare the datapack
            // ------------------------------
            // int iGrenadeReference
            // int hGrenadeThinkFunction
            // ------------------------------
            // int iGrenadeCounter
            // float vGrenadeNormal[3]
            // ------------------------------
            hGrenadePack.WriteCell(EntIndexToEntRef(iGrenade));
            hGrenadePack.WriteFunction(OnGrenadeTripwireThink__Powerup);
            hGrenadePack.WriteCell(RoundFloat(gl_flCvarTripwirePowerupTime * 10.0));
            hGrenadePack.WriteFloat(vGrenadeNormal[0]);
            hGrenadePack.WriteFloat(vGrenadeNormal[1]);
            hGrenadePack.WriteFloat(vGrenadeNormal[2]);
            
            // Unhook the grenade touch function
            SDKUnhook(iGrenade, SDKHook_TouchPost, OnGrenadeTripwireTouch);
            
            // Block the grenade
            SetEntityMoveType(iGrenade, MOVETYPE_NONE);
            
            // Set the grenade breakable
            GrenadeSetBreakable(iGrenade, 10);
            
            // Hook the grenade takedamage function
            SDKHook(iGrenade, SDKHook_OnTakeDamage, OnGrenadeTakeDamageBlock);
        }
    }
    
    return Plugin_Continue;
}

public Action OnGrenadeTripwireThink__Powerup(int iGrenade, DataPack hGrenadePack)
{
    static int      iGrenadeReference;
    static Function hGrenadeThinkFunction;
    static int      iGrenadeCounter;
    
    // Read the datapack
    ResetPack(hGrenadePack);
    iGrenadeReference     = hGrenadePack.ReadCell();
    hGrenadeThinkFunction = hGrenadePack.ReadFunction();
    iGrenadeCounter       = hGrenadePack.ReadCell();
    
    // Decrement the grenade counter
    iGrenadeCounter--;
    
    // Check if the grenade is operational
    if (iGrenadeCounter <= 0)
    {
        // Play a sound
        EmitSoundToAll("buttons/blip2.wav", iGrenade, _, SNDLEVEL_CONVO, _, 0.9);
        
        // Set the grenade think function
        hGrenadeThinkFunction = OnGrenadeTripwireThink__Operational;
    }
    else if ((iGrenadeCounter % 2) == 0)
    {
        // Play a sound
        EmitSoundToAll("buttons/blip1.wav", iGrenade, _, SNDLEVEL_CONVO, _, 0.9);
    }
    
    // Write the datapack
    ResetPack(hGrenadePack);
    hGrenadePack.WriteCell(iGrenadeReference);
    hGrenadePack.WriteFunction(hGrenadeThinkFunction);
    hGrenadePack.WriteCell(iGrenadeCounter);
    
    // Continue the timer
    return Plugin_Continue;
}

public Action OnGrenadeTripwireThink__Operational(int iGrenade, DataPack hGrenadePack)
{
    static int      iGrenadeReference;
    static Function hGrenadeThinkFunction;
    static int      iGrenadeCounter;
    static float    vGrenadeNormal[3];
    static int      iGrenadeOwner;
    
    // Read the datapack
    ResetPack(hGrenadePack);
    iGrenadeReference     = hGrenadePack.ReadCell();
    hGrenadeThinkFunction = hGrenadePack.ReadFunction();
    iGrenadeCounter       = hGrenadePack.ReadCell();
    vGrenadeNormal[0]     = hGrenadePack.ReadFloat();
    vGrenadeNormal[1]     = hGrenadePack.ReadFloat();
    vGrenadeNormal[2]     = hGrenadePack.ReadFloat();
    
    // Get the grenade owner
    iGrenadeOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
    
    // Check if the owner is still connected
    if (1 <= iGrenadeOwner <= MaxClients)
    {
        static int    iGrenadeTeam;
        static Handle hTrace;
        static float  vGrenadeOrigin[3];
        static float  vGrenadeEndPoint[3];
        static int    iEntityHit;

        // Get the grenade team
        iGrenadeTeam = GetClientTeam(iGrenadeOwner);
        
        // Get the grenade origin
        GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", vGrenadeOrigin);
        
        // Check if there's a valid player in the grenade tripwire
        vGrenadeEndPoint[0] = vGrenadeNormal[0] * 8192.0 + vGrenadeOrigin[0];
        vGrenadeEndPoint[1] = vGrenadeNormal[1] * 8192.0 + vGrenadeOrigin[1];
        vGrenadeEndPoint[2] = vGrenadeNormal[2] * 8192.0 + vGrenadeOrigin[2];
        
        hTrace = TR_TraceRayFilterEx(vGrenadeOrigin, vGrenadeEndPoint, MASK_SOLID, RayType_EndPoint, OnGrenadeTraceFilter, iGrenade);
        
        if (TR_GetFraction(hTrace) < 1.0)
        {
            TR_GetEndPosition(vGrenadeEndPoint, hTrace);
            iEntityHit = TR_GetEntityIndex(hTrace);
            
            if ((1 <= iEntityHit <= MaxClients) && (IsPlayerAlive(iEntityHit)) && (GetClientTeam(iEntityHit) != iGrenadeTeam))
            {
                // Detonate the grenade
                GrenadeDetonate(iGrenade);
                    
                // Stop the timer
                return Plugin_Stop;
            }
        }
        
        CloseHandle(hTrace);
        
        // Decrement the grenade counter
        iGrenadeCounter--;
        
        // Check if the players must be warned
        if (iGrenadeCounter <= 0)
        {
            static int iPlayers[MAXPLAYERS + 1];
            static int iNbPlayers;
            static int iNumPlayer;
            static int iPlayer;
            static int iColor;
            
            // Get all the players in range
            iNbPlayers = GetClientsInRange(vGrenadeOrigin, RangeType_Audibility, iPlayers, MaxClients);
            
            // Send the beam effect to all the close players
            for (iNumPlayer = 0 ; iNumPlayer < iNbPlayers ; iNumPlayer++)
            {
                // Cache the player index
                iPlayer = iPlayers[iNumPlayer];
                
                // Get the color effect
                iColor = PlayerGetEffectColor(iPlayer, iGrenadeOwner, iGrenadeTeam);
                
                // Create the beam effect
                TE_Start      ("BeamEntPoint");
                TE_WriteNum   ("m_nStartEntity", iGrenade);
                TE_WriteVector("m_vecEndPoint",  vGrenadeEndPoint);
                TE_WriteNum   ("m_nModelIndex",  gl_nSpriteBeam);
                TE_WriteNum   ("m_nHaloIndex",   gl_nSpriteHalo);
                TE_WriteNum   ("m_nStartFrame",  0);
                TE_WriteNum   ("m_nFrameRate",   0);
                TE_WriteFloat ("m_fLife",        0.1);
                TE_WriteFloat ("m_fWidth",       8.0);
                TE_WriteFloat ("m_fEndWidth",    8.0);
                TE_WriteNum   ("r",              (iColor >> 16) & 0xFF);
                TE_WriteNum   ("g",              (iColor >>  8) & 0xFF);
                TE_WriteNum   ("b",              (iColor      ) & 0xFF);
                TE_WriteNum   ("a",              255);
                TE_WriteNum   ("m_nFlags",       FBEAM_STARTENTITY);
                TE_WriteNum   ("m_nFadeLength",  0);
                
                // Send the beam effect to the player
                TE_SendToClient(iPlayer);
            }
            
            // Set the grenade counter
            iGrenadeCounter = 1;
        }
    }
    else
    {
        // Kill the grenade
        AcceptEntityInput(iGrenade, "kill");
        
        // Stop the timer
        return Plugin_Stop;
    }
    
    // Write the datapack
    ResetPack(hGrenadePack);
    hGrenadePack.WriteCell(iGrenadeReference);
    hGrenadePack.WriteFunction(hGrenadeThinkFunction);
    hGrenadePack.WriteCell(iGrenadeCounter);
    hGrenadePack.WriteFloat(vGrenadeNormal[0]);
    hGrenadePack.WriteFloat(vGrenadeNormal[1]);
    hGrenadePack.WriteFloat(vGrenadeNormal[2]);
    
    // Continue the timer
    return Plugin_Continue;
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Thinker                                                        */
/* ------------------------------------------------------------------------- */

public Action OnGrenadeThink(Handle hTimer, DataPack hGrenadePack)
{
    static Action   iTimerAction;
    static int      iGrenade;
    static Function hGrenadeThinkFunction;
    
    // Read the datapack
    ResetPack(hGrenadePack);
    iGrenade              = EntRefToEntIndex(hGrenadePack.ReadCell());
    hGrenadeThinkFunction = hGrenadePack.ReadFunction();
    
    // Check if the grenade is still valid
    if (iGrenade != INVALID_ENT_REFERENCE)
    {
        // Call the grenade think function
        Call_StartFunction(INVALID_HANDLE, hGrenadeThinkFunction);
        Call_PushCell(iGrenade);
        Call_PushCell(hGrenadePack);
        Call_Finish(iTimerAction);
    }
    else
    {
        // Stop the timer
        iTimerAction = Plugin_Stop;
    }
    
    return iTimerAction;
}

/* ========================================================================= */
