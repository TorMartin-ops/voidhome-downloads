# Included mods

The **client installer installs thirteen JAR files**. All Skyblock gameplay is in Voidhome; the companions improve performance and useful information.

| Mod | Why it is included |
|---|---|
| Voidhome | The world, progression, skills, quests, fishing and co-op systems |
| [Fabric API](https://modrinth.com/mod/fabric-api) | Required library for Voidhome |
| [Sodium](https://modrinth.com/mod/sodium) | Faster rendering |
| [Lithium](https://modrinth.com/mod/lithium) | Faster game logic, including the singleplayer server |
| [FerriteCore](https://modrinth.com/mod/ferrite-core) | Lower memory use |
| [ImmediatelyFast](https://modrinth.com/mod/immediatelyfast) | Optimized HUD, text, particles and entity rendering |
| [Entity Culling](https://modrinth.com/mod/entityculling) | Avoids drawing entities hidden behind blocks; server-side farms keep running |
| [AppleSkin](https://modrinth.com/mod/appleskin) | Food and saturation information |
| [Jade](https://modrinth.com/mod/jade) | Information about the block or creature you are looking at |
| [Shulker Box Tooltip](https://modrinth.com/mod/shulkerboxtooltip) | Preview stored items without placing the box |
| [JEI](https://modrinth.com/mod/jei) | Shows every recipe and use of an item: press R or U on any item. Recipes that Voidhome teaches through a boss or unlocks in the Hall show up there too, but cannot be crafted until the crew has earned them |
| [MezzConfig](https://modrinth.com/mod/mezzconfig) | The settings library that JEI needs; it does nothing on its own |
| [Mouse Tweaks](https://modrinth.com/mod/mouse-tweaks) | Faster inventory moves: drag items across slots, scroll to move stacks |

Only **Voidhome and Fabric API** are required for gameplay. The other eleven are the curated companions (MezzConfig is JEI's library, not a mod you use). Performance benefits depend on your hardware and base; no fixed FPS improvement is promised.

Minecraft **26.3**, Fabric Loader **0.19.5** and Java **25** are required. Loader is not another file in `mods`. Exact companion versions and download hashes are in [mods.lock.json](../modpack/mods.lock.json).

## Licences of the companions added in 4.1.1

The installer and the `.mrpack` only link to these mods' official downloads (pinned by hash); Voidhome does not redistribute them. Each keeps its own licence, read from its Modrinth page and from the licence field of its JAR:

| Mod | Licence |
|---|---|
| JEI 31.14.0.72 | MIT |
| MezzConfig 0.6.10 (JEI's library) | MIT |
| Mouse Tweaks 26.3-2.31 | BSD 3-Clause |
| Lithium 0.26.3 (moved up from 0.26.1) | LGPL-3.0-only |

MezzConfig has no full release for 26.3 yet; 0.6.10 is its newest beta, the one JEI 31.14.0.72 is built against (`>=0.6.3`).

## Why Minecraft shows more than thirteen mods

The pinned Fabric API JAR contains **44 internal modules**. Other mods and the loader also include libraries. Fabric counts these separately. A high displayed count does not mean the installer added that many separate gameplay mods. Do not remove individual modules from a JAR.

## Windows installation and updates

1. Download the latest `voidhome-<version>-client.zip` from [GitHub Releases](https://github.com/TorMartin-ops/voidhome-downloads/releases/latest).
2. Extract it, close Minecraft and the launcher, and double-click **Install.bat**.
3. Select the Voidhome installation named in the installer's completion message.

The installer uses a dedicated game directory, normally `%APPDATA%\.minecraft\profiles\ultimate-skyblock-26.3`. It installs the thirteen-file set without additional bundles. Standard generated launcher names are updated to show the installed version; custom names are preserved.

To preview changes without writing anything:

```powershell
powershell -ExecutionPolicy Bypass -File install-client.ps1 -DryRun
```

Re-running the installer upgrades the mod and removes unchanged companion JARs that it previously installed but which are no longer in this set. It keeps saves, settings, and user-added or modified JARs. It records ownership in `mods/.ultimateskyblock-managed.json`. If you added a second Voidhome JAR manually, keep only the current version.

Advanced options are `-GameDir <folder>`, `-ModJar <file>`, or `-ModJarUrl <https URL>` with `-ModJarSha1 <hash>`. Normally the installer finds the mod JAR beside itself.

## macOS and Linux

Import the release's `.mrpack` in a launcher with Modrinth pack support to install the curated set. It uses the same pinned versions as the Windows installer and contains no personal settings or worlds. See [portable instructions](../modpack/PORTABLE.md).

For manual installation, install Fabric Loader for Minecraft 26.3. Put the release's Voidhome JAR and the pinned Fabric API JAR in the profile's `mods` folder. Those two files are sufficient for gameplay. Add the companions from the table if wanted, using the versions and URLs in the lock. The supplied Windows installer does not run on macOS or Linux. Native macOS gameplay has not been fully verified.

## Playing with friends

The host and every player need the **same Voidhome version** and compatible Fabric API. The client performance and information mods are not mandatory server dependencies.

The dedicated server installer defaults to **four JARs**: Voidhome, Fabric API, Lithium and FerriteCore. Optional server support for the included information mods is available with `-Include appleskin,jade,shulkerboxtooltip,jei`. This provides additional server data for their clients (JEI wants to be on the server for its recipe sync; a player who hosts from their own client already covers this); it adds no new progression system. See [HOSTING.md](HOSTING.md).

Voidhome zips a Skyblock world when it opens and every 30 minutes while you play, into `.minecraft\ultimateskyblock\backups\`; to go back, quit to the title screen and extract a zip into `.minecraft\saves` (details in [HOSTING.md](HOSTING.md)).

No hosting service, tunnel, account or paid subscription is installed by the client installer. Use the project's GitHub Releases page for official downloads; no paid modpack subscription is required.
