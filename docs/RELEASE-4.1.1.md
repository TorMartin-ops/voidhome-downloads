# Voidhome 4.1.1

Voidhome 4.1.1: a patch for 4.1.0 with JEI and Mouse Tweaks in the pack, automatic world backups, fixes, five new fish marks and the Ledger's missing sounds.

## New
- **JEI and Mouse Tweaks** join the pack, which is now thirteen files. JEI shows every recipe and use of an item (R or U), including the recipes Voidhome teaches through a boss or unlocks in the Hall. Mouse Tweaks drags items across slots and scrolls stacks
- **Automatic world backups.** A Skyblock world is zipped when it opens and every 30 minutes while you play, into `ultimateskyblock/backups`. The newest eight are kept, within 2 GB, and your own `/skyblock backup` zips are never deleted. A damaged saved-data file is set aside and restored from a checked copy instead of being overwritten
- **Five new fish marks**, and **five Ledger sounds** that never played: taking a reward, opening a parcel, filing a letter, paying levels for a path change, and something new waiting
- **Fixes:** the light and first-log hints on the real starter island, the Rally and Giantslayer perks counting every named boss, a warning when a bed gives up a held repair night, item sources that read whole, the feast days gift and mob heads filling their trophy slots

## Install
You need Minecraft 26.3, Fabric Loader 0.19.5, Java 25 and Fabric API.

- Windows: extract `voidhome-4.1.1-client.zip` and run `Install.bat`. It updates an older install and keeps your worlds
- Modrinth App or Prism: import `voidhome-4.1.1.mrpack`
- Or put `voidhome-4.1.1.jar` and Fabric API in your mods folder, and remove the old `voidhome-4.1.0.jar`
- Hosting a server: `voidhome-4.1.1-server.zip`, see docs/HOSTING.md

Then make a new world with World Type **Skyblock** (Hardcore if you want it the way it is meant to be played), or join a server that runs the mod.

**Everyone who plays together must update together:** 4.1.0 and 4.1.1 do not mix. Worlds from 4.1.0 carry on and the config stays at version 19. To go back, put `voidhome-4.1.0.jar` back; the first time 4.1.1 opens a world it zips it first, so that zip is your way back. Checksums are in `SHA256SUMS.txt`.
