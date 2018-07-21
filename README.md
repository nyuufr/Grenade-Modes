# SourceMod Plugin - Grenade Modes (Nademodes)

## Description

The grenades can be configured with different modes, providing the ability to use them for example as proximity mines.

[![Youtube](http://img.youtube.com/vi/v5sSuhIKtG0/0.jpg)](http://www.youtube.com/watch?v=v5sSuhIKtG0)

There're currently 4 grenade modes available:
* Normal (Classic)
* Impact (Explode after any contact)
* Proximity (Explode when a enemy is near)
* Tripwire (Explode when a enemy crosses the beam)

The mode can be configured per grenade type using the command "*+lookatweapon*" (F by default). 

The color of the effects (Beacon, beam..) depends of the relationship of the players with the grenade owner (Teammate or enemy).

For the moment, only the **hegrenade**, **flashbang** and **smokegrenade** are supported. 
The decoy, incendiary and tactical grenades will be supported in the future.

## Console variables

| Name                                    | Description                           |
| --------------------------------------- | ------------------------------------- |
| sm_grenade_modes_enable                 | Enable the plugin                     |
| sm_grenade_modes_self_color             | Set the color of the self effects     |
| sm_grenade_modes_teammate_color         | Set the color of the teammate effects |
| sm_grenade_modes_enemy_color            | Set the color of the enemy effects    |
| sm_grenade_modes_proximity_powerup_time | Set the proximity powerup time        |
| sm_grenade_modes_tripwire_powerup_time  | Set the tripwire powerup time         |

**Remark**: The colors must be in [hexadecimal format (0xRRGGBB)](https://www.google.fr/search?q=rgb+to+hex).
