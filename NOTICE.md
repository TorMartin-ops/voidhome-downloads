# Rights and third-party notices

Free Java downloads are provided under [the Free Play License](LICENSE).
The source repository remains private. Version 2.8.5 is the first public
distribution, and no Ultimate Skyblock material has ever been released under
CC0 or another public license.

The CC0 text in [licenses/CC0-1.0.txt](licenses/CC0-1.0.txt) belongs to the
Fabric example mod template the project was started from. It covers only that
template's own unmodified build scaffolding, not Ultimate Skyblock's code,
assets, text, data or design.

Minecraft belongs to Mojang/Microsoft. This project is unofficial and is not
approved by or associated with Mojang or Microsoft. Minecraft game JARs and
decompiled sources are not distributed. Minecraft data and references do not
transfer ownership of Minecraft content.

The spoken voices of the Void Echoes (the letters, Legends and Bestiary notes that can be listened to) are generated with an AI text-to-speech service from the game's own text, under a plan that permits distribution. No real person speaks these lines in the game. The recordings are regenerated only when a text changes (`tools/voice.py`); the service's key is never kept in this repository.

Companion mods, the Gradle wrapper and third-party libraries retain their own
licenses. See [the mod list](docs/MODS.md). Installers use pinned official CDN
downloads; the pack license does not replace the companions' licenses.

## Third-party audio

The voices are made with an AI text-to-speech service from the game's own text and are processed with tools/voice/echo_fx.py. These recordings are used as impulse responses (a room's sound, convolved with the voice while it is processed); they are tool inputs kept in tools/voice/ir and are not part of the game files.

- Tiny Bedroom 2 by KenMix, https://freesound.org/s/645097/, licence CC0 1.0; original FLAC, 44.1 kHz stereo; used as the small wooden room of the present group (tools/voice/ir/small_wood_room.wav).
- Tiny Bedroom 2 by KenMix, https://freesound.org/s/645097/, licence CC0 1.0; original FLAC, 44.1 kHz stereo; used as the small wooden room of the bestiary group (tools/voice/ir/wooden_hut.wav).
- IR Bathroom (stereo) by Nox_Sound, https://freesound.org/s/585741/, licence CC0 1.0; original WAV, 48 kHz 24-bit stereo; used as the small hard room of the found group (tools/voice/ir/hard_small_room.wav).
- IR Forest 5m (stereo) by Nox_Sound, https://freesound.org/s/558822/, licence CC0 1.0; original WAV, 96 kHz 24-bit stereo; used as the open air of the legend group (tools/voice/ir/open_jetty.wav).
- IR Cathedral 5m (stereo) by Nox_Sound, https://freesound.org/s/648945/, licence CC0 1.0; original WAV, 96 kHz 24-bit stereo; used as the large space of the memory group (tools/voice/ir/large_space.wav).

All audio the game ships was made with ElevenLabs' AI services and levelled with this repository's own tools; every file is listed in a manifest with what made it:

- The Void Echo voices (sounds/echo/, the letters, Legends and Bestiary notes): ElevenLabs text-to-speech from the game's own text, processed with tools/voice/echo_fx.py.
- The ambience beds (sounds/echo/bed/) and the ambience loops (sounds/ambience/): ElevenLabs sound effects, levelled with tools/voice/beds.py and tools/sfx.py.
- The sound effects (sounds/sfx/) and the visitors' sounds (sounds/visitor/): ElevenLabs sound effects, made with tools/sfx.py and tools/voice/visitor_sfx.py.
- The music (sounds/music/<track>/<take>.ogg): instrumental pieces made with ElevenLabs Eleven Music on a paid plan, levelled with tools/music.py and listed with their prompts in tools/music/music_manifest.json.

No real person speaks or performs in the game's audio, and no other third-party audio is shipped.
