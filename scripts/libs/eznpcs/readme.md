# eznpcs lib

Automatically creates NPC's for your server based on objects you add to the map in Tiled.

You can create branching dialogue trees for conversations with NPCs all from the map editor, and if you want you can add scripted events for more complicated interactions.

You can create paths using waypoints in the map editor which the NPCs will follow, with optional wait times and random path selection.

## Installation
currently all the files for eznpcs are scattered inside this gravy-yum repository, its inconvenient but you can find all the files you need here.

installation steps
1. copy eznpcs.lua to `yourserver/scripts/libs/eznpcs/eznpcs.lua`
2. copy main_entry.lua to `yourserver/scripts/main_entry.lua`
3. copy the eznpcs folder from the assets folder to `yourserver/assets/eznpcs`
optional:
    1. there are a bunch of events for this server in the entry script, use them as examples or remove them if you dont want them.

## Setup
add objects to your map with Type=`NPC` on an object layer above the tile layer where you want the NPC to spawn.

### NPC Type
- Custom properties:
    - Asset Name: string
        - name of npc tilesheet from `yourserver/assets/eznpcs/sheet`
        - for example `heel-navi-exe4_black` (no file extension)
    - Direction: string
        - see the section on [`Directions`](#Directions).
    - Dialogue Type: string
        - by including this property, this npc will become interactable
        - see the section on [`Dialogues`](#Dialogues).
    - Next Waypoint 1: string
        - by including this property, this npc will follow waypoints
        - Indicates the first waypoint that the npc should move to
        - see the section on [`Waypoints`](#Waypoints).



### Dialogues
any object can be a dialogue, you can use these custom properties to define what will happen next in the conversation when the dialogue is reached
- Custom properties:
    - Dialogue Type: string
        - `first`
            - this dialogue will make the NPC say the first `Text #` custom property, usually `Text 1`
            - after `Text 1` is finished, 
        - `random`
            - this dialogue will choose a random `Text #` custom property to say, it might be `Text 1`, `Text 2`, `Text 5`, etc.
            - If there is a `Next #` property with a matching number, that dialogue will be triggered next, otherwise it will default to `Next 1`
        - `question`
            - prompts the player to choose yes or no, with `Text 1` as the prompt text
            - afterwards the dialogues `Next 1` or `Next 2` will be triggered, matching the player's choice.
        - `none`
            - usually used with `Event Name`, no dialogue, but the event will still be triggered
            
    - Text 1: string
        - (numbered, you can also include, 2, 3, 4 etc. up to 10)
        - Text that will be spoken by NPCS who have this dialogue
    - Next 1: object
        - (numbered, you can also include, 2, 3, 4 etc. up to 10)
        - ID of the next dialogue to activate after the corresponding Text is spoken / chosen
    - Event Name: string
        - Name of event to activate when this dialogue starts, events can be added in your eznpcs entry script, see [`Dialogue Events`](#DialogueEvents) for details.

### Waypoints
any object can be a waypoint, you can use these custom properties to define what the NPC will do once it reaches said object.
- Custom properties:
    - Dialogue Type: string
    - Waypoint Type: string
        - `first`
            - after reaching this waypoint, the NPC will head to the waypoint referenced by the first `Next Waypoint #` custom property, usually `Next Waypoint 1`
        - `random`
            - after reaching this waypoint, the next one will be selected from a random `Next Waypoint #` custom property.
    - Wait Time: int
        - time in seconds to wait before moving to next waypoint
    - Direction: string
        - direction to face while waiting
        - see the section on [`Directions`](#Directions).
    - Waypoint Event: string
        - coming soon


### Interact Relay
- any object with the custom property `Interact Relay` (object) that is interacted with will start a conversation with the NPC that it is referencing
- useful for starting conversations with NPCS that are behind objects like counters

### DialogueEvents
- events added through the eznpcs entry script will be activated when a player reaches a dialogue during a conversation with a matching `Event Name` custom property
- the action of the event is a callback which allows for any and all custom interactions.
- callback parameters:
    - npc
        - (table) information about the NPC who the player is conversing with
    - player_id
        - (string) id of the player who engaged the npc in conversation
    - dialogue
        - (table) information about the dialogue object
    - relay_object
        - (table) information about the relay object which the player started their conversation with the NPC through (nil if the player did not start conversing using a relay object)
- expected return types
    - nil
        - will end the conversation
    - table
        - table with `wait_for_response` (bool) and `id` (string)
        - `wait_for_response` should be true if you sending any messages to the player in this event.
        - `id` should be the object id of the next dialogue you want to trigger after this one (if any)
```lua
local some_event = {
    name="Drink Gravy",
    action=function (npc,player_id,dialogue,relay_object)
        local player_mugshot = Net.get_player_mugshot(player_id)
        Net.play_sound_for_player(player_id,sfx.recover)
        Net.message_player(player_id,"\x01...\x01mmm gravy yum",player_mugshot.texture_path,player_mugshot.animation_path)
        local next_dialouge_options = {
            wait_for_response=true,
            id=dialogue.custom_properties["Next 1"]
        }
        return next_dialouge_options
    end
}
eznpcs.add_event(some_event)
```
### Waypoint Events
- coming soon

### Misc
#### Directions
- Left
- Right
- Up
- Down
- Up Left
- Up Right
- Down Left
- Down Right
