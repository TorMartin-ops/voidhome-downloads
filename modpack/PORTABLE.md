# Voidhome portable pack

Import the `.mrpack` in a launcher that supports Modrinth packs, such as the Modrinth App or Prism Launcher.
Use Java 25. The pack pins Minecraft 26.3, Fabric Loader 0.19.5 and the same thirteen mod files as the Windows installer.

Create a world with World Type **Skyblock**, structures enabled and Hardcore for the intended experience.
For multiplayer, use the same Voidhome version on every client and on the host/server.

Press **K** for skills. Tap **B** for the selected tool's regular perk action; hold **B** for at least 0.6 seconds
for a charged level-10 capstone. Timber! grows saplings; Feller chops a tree. Use `/skyblock guide` for the guide,
`/skyblock notes` for perk details, and `/skyblock rewards` for unclaimed team rewards.

## Updating

A new `.mrpack` makes a new instance. Do not import it over the old one.
1. Close the game. Download the new `.mrpack` from the Releases page.
2. Import it in your launcher. You now have two instances: the old one and the new one.
3. Your worlds stay in the **old** instance. To bring them across, open the old instance's folder
   (Modrinth App: the instance, then **Open folder**. Prism Launcher: right-click the instance, then **Folder**).
   Copy the world folders you want from its `saves` folder into the new instance's `saves` folder.
   A world is a folder: copy the whole folder.
4. Start the new instance and open the world. The first time, Voidhome keeps a copy of the world's old data
   in a `pre-` folder named after the new version (for example `pre-4.1`) under `data/ultimateskyblock` in the world, so you can go back (see the release notes).
5. When the world opens fine, you can delete the old instance. Keep it until then.

Settings stay in the old instance too. The new instance starts with Voidhome's defaults. To keep a setting you changed,
copy it by hand from the old `config/ultimateskyblock.json` into the new one.

## What is in the pack

Only release files are packaged. There are no accounts, worlds, server addresses or personal options in this pack.
Companions download from their pinned official Modrinth CDN URLs with SHA1 and SHA512 hashes.
Minecraft ownership and authentication are handled by your launcher.

Project, bug reports and hosting instructions: https://github.com/TorMartin-ops/voidhome-downloads
