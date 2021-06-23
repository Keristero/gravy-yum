Automatically adds landings locations for server warps to your server, also handles arrival / leaving animations

Requirements:
- Delay lib https://github.com/Keristero/gravy-yum/blob/main/scripts/libs/delay.lua
- assets/landings https://github.com/Keristero/gravy-yum/tree/main/assets/landings

Supported warp types:
- Server Warp
    - supports arrival animations
- Custom Warp
    - supports arrival animations
- Interact Warp
    - (a warp activated by interaction)
    - supports arrival animations
    - supports landing animations
- Radius Warp
    - (a warp activated by entering its radius)
    - supports arrival animations
    - supports landing animations

Supported warp custom properties:
- "Incoming Data" (string) secret to share with the server that is linking to you; for their "Data"
- "Data" (string) secret to share with the server you are linking to, for their "IncomingData"
- "Direction" (string) direction the warp will make the player walk on arrival; defaults to "Down"
- "Warp In" (boolean) should the warp in animation be shown (laser from sky)
- "Arrival Animation" (string) name of special animation which should play on warp in, not compatible with "Warp In" (I think)
- "Leave Animation" (string) name of special animation to play on warp out

Special Animations (for arrival / leave animation):
- fall_in
- lev_beast_in
- lev_beast_out

More special animations can be added by requiring them in main.lua -> special_animations