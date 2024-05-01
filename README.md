# LENT-PackageDeliveries
*Done waiting for pakcages? Are they never on time? Well how about you step in their shoes! Filling out the jobs of either GoPostal or Post OP! Give it your best and deliver the packages around the City of Los Santos!*

## Dependencies
- [LENT-Library](https://github.com/Lanzaned-Enterprises/LENT-Library) ***(REQUIRED)***
- [Renewed-Banking](github.com/Renewed-Scripts/Renewed-Banking/releases) (optional)

## How To Install!
- Drag & Drop `LENT-PackageDeliveries` in your resources folder
    - Make any changes to the [Config](./shared/sh_config.lua)

### Server Start
- Open the `server.cfg`
- Type `ensure LENT-PackageDeliveries` somewhere in your resources part

### Ingame Start
- Type `/refresh`
    - Wait for the refresh to be done
- type `/start LENT-PackageDeliveries`

### Add the job 
```lua
gopostal = { label = "GoPostal", defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = 'Driver', payment = 5, } } },
postop = { label = "Post OP", defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = 'Driver', payment = 5, } } },
```

## Issues
|  Question |  Answer |
|----       |----     |
|           |         |

## Contributors
|  Rank       |  Member       | ID                 | Qualifications                       |
|----         |----           |----                |----                                  |
| Director    | [Lanzaned](https://discordapp.com/users/871877975346405388) | [871877975346405388](https://discordapp.com/users/871877975346405388) | Javascript, XML, HTML, CSS, lua, SQL |

## Useful Links
|  Platform |  Link   |
|----       |----     |
|  Discord         |     https://discord.lanzaned.com    |
|  Github         |    https://github.lanzaned.com     |
|  Documentation         |   https://docs.lanzaned.com/      |
