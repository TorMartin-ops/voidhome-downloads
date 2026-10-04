# Hosting Voidhome

**Recommended:** run a dedicated Fabric server on the host's PC, and let friends in through a [playit.gg](https://playit.gg) tunnel.

A dedicated server keeps the world available while the host closes their game. LAN hosting is also possible on the same network; the host must keep the world open.

## 1. Set up the server (host, once)

You need Windows, about 4 GB of free RAM for the server, and the mod jar from the release. The script uses the Java 25 that comes with the Minecraft Launcher. If it can't find Java 25, install it with `winget install EclipseAdoptium.Temurin.25.JRE`.

1. Download and extract the `-server.zip` from the release. From its extracted folder,
   run the setup script. Use a separate destination for the running server.

   ```powershell
   powershell -ExecutionPolicy Bypass -File server\setup-server.ps1 -Dir C:\mc\skyblock-server -ModJar voidhome-3.3.2.jar
   ```

   - `-Include appleskin,jade,shulkerboxtooltip` adds server data for the included client information mods. Choose any of those names, or `all`.
   - `-DryRun` only shows what the script would do.

   The script:
   - downloads the Fabric server launcher;
   - creates the default settings;
   - applies [`server.properties.template`](../server/server.properties.template): hardcore, the skyblock world type, the whitelist, `spawn-protection=0` and `server-ip=127.0.0.1`;
   - installs only Voidhome, Fabric API, Lithium and FerriteCore by default;
   - copies `start.bat` and `start.ps1` into the folder.
2. Read the [Minecraft EULA](https://aka.ms/MinecraftEULA). If you accept it, run the same command again with `-AcceptEula`.
3. Start the server by double-clicking `C:\mc\skyblock-server\start.bat`. The first start generates the skyblock world.
4. In the server console, type `op <your name>`. Then type `whitelist add <name>` for each friend. Operators can always join and can use `/skyblock restart`. Everyone else needs to be on the whitelist.
5. Join from the host PC: **Multiplayer > Add Server**, address `127.0.0.1`.

To stop the server, type `stop` in its console. Don't just close the window, or the last few minutes may not be saved.

## 2. Let friends in with playit.gg

1. Install the playit.gg agent for Windows from <https://playit.gg/download> and start it.
2. Follow the link the agent shows to sign in and claim it.
3. In the playit.gg dashboard, add a **Minecraft Java** tunnel to `127.0.0.1:25565`.
4. Share the tunnel's address with your friends. They add it under **Multiplayer > Add Server**.

The agent must be running whenever the server is. Anyone can reach the tunnel address, so the whitelist is what keeps strangers out.

Friends install the client mods with the same mod jar as the server. See [MODS.md](MODS.md). Since 2.1 a client without the mod cannot join: the mod adds blocks, a skills screen and ghost keys.

**Pacts on a server:** the crew can seal pacts in the game on day one (a dialog on joining). To fix them for every run instead, set `presetPacts` in `config\ultimateskyblock.json` (pact ids separated by commas, for example `"lean_veins,meagre_spoils"`, or `"none"` for Heat 0), or an operator types `/skyblock pacts seal <pacts>` before the first day ends.

## Backups and restarts

- **Backups:** `start.ps1` zips the world into `backups\` every time the server starts, and keeps the newest 10 of those zips. Copy one somewhere else now and then.
- **Restoring a backup:**
  1. Stop the server.
  2. Move the `world` folder away.
  3. Extract the zip into the server folder. It contains `world\`.
  4. Start the server.
- **Backups from the game:** an operator types `/skyblock backup`. The mod saves and zips the world into `ultimateskyblock\backups\` while everyone keeps playing, and keeps the newest 10 of those zips.
- **Starting a new run:** an operator types `/skyblock restart` in the game and confirms (or presses **Start run N+1** on the screen that appears when everyone is dead). The mod stops the server, and `start.ps1` starts it again. The mod then moves the old world into `world-archive\` and generates a fresh one. This only works when the server was started with `start.bat` or `start.ps1`. Add `sameseed` to replay the same world.
- **Run history:** `/skyblock runs` lists the past runs and your bests. They are kept in `ultimateskyblock\runs.json`, outside the worlds.
- **Crashes:** `start.bat -RestartOnCrash` also restarts the server after a crash. It gives up after 3 crashes in a row within 2 minutes of starting.
- **Updating:** stop the server and run the setup script again with the new mod jar. It only replaces jars that it installed itself. Friends update with the client installer. A release that changes the balance version (2.1 does) replaces `config\ultimateskyblock.json` with the new defaults, so note any values you changed and set them again. A run in progress carries on after the update: skills start at level 0, and a run that began before 2.1 goes without pacts (Heat 0); the next run can seal them.
