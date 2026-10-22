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

The voices are made with an AI text-to-speech service from the game's own text and are processed with tools/voice/echo_fx.py. The rooms the voices are processed in (impulse responses, tools/voice/ir) are tool inputs and are not part of the game files; all of them are made with ElevenLabs sound effects (tools/voice/ir/SOURCES.md), so no third-party recording is used.

- Room of the bestiary group: ElevenLabs sound effects (ElevenLabs API, sound effects v2, pcm_44100), prompt "A single hand clap in a small hut of rough logs with furs on the walls, warm short decay, then silence, nothing else.", made 2026-10-15; take bestiary_take1_fitted (tools/voice/ir/choices.json).
- Room of the chorus group: ElevenLabs sound effects (ElevenLabs API, sound effects v2, pcm_44100), prompt "One deep soft knock in a vast hollow space of nothing, an enormous slow tail that goes on and on, no music, nothing else.", made 2026-10-15; take chorus_take3_raw (tools/voice/ir/choices.json).
- Room of the found group: ElevenLabs sound effects (ElevenLabs API, sound effects v2, pcm_44100), prompt "A single sharp knock of stone on stone inside a small empty stone hut, short hard reflections, then silence, nothing else.", made 2026-10-15; take found_take1_fitted (tools/voice/ir/choices.json).
- Room of the legend group: ElevenLabs sound effects (ElevenLabs API, sound effects v2, pcm_44100), prompt "A single wooden clap on an open jetty at night over still water, open air, faint distant reflections, then silence, nothing else.", made 2026-10-15; take legend_take1_fitted (tools/voice/ir/choices.json).
- Room of the memory group: ElevenLabs sound effects (ElevenLabs API, sound effects v2, pcm_44100), prompt "One deep hollow knock in an immense dark empty space, a long soft reverberant tail, no music, nothing else.", made 2026-10-15; take memory_take1_raw (tools/voice/ir/choices.json).
- Room of the present group: ElevenLabs sound effects (ElevenLabs API, sound effects v2, pcm_44100), prompt "A single sharp hand clap in a small empty wooden cabin with a plank floor, natural short room reverb, then silence, nothing else.", made 2026-10-15; take present_take1_raw (tools/voice/ir/choices.json).

All audio the game ships was made with ElevenLabs' AI services and levelled with this repository's own tools; every file is listed in a manifest with what made it:

- The Void Echo voices (sounds/echo/, the letters, Legends and Bestiary notes): ElevenLabs text-to-speech from the game's own text, processed with tools/voice/echo_fx.py.
- The ambience beds (sounds/echo/bed/) and the ambience loops (sounds/ambience/): ElevenLabs sound effects, levelled with tools/voice/beds.py and tools/sfx.py.
- The sound effects (sounds/sfx/) and the visitors' sounds (sounds/visitor/): ElevenLabs sound effects, made with tools/sfx.py and tools/voice/visitor_sfx.py.
- The music (sounds/music/<track>/<take>.ogg): instrumental pieces made with ElevenLabs Eleven Music on a paid plan, levelled with tools/music.py and listed with their prompts in tools/music/music_manifest.json.

No real person speaks or performs in the game's audio, and no other third-party audio is shipped.
