# ezlibs

### contents

## ezmemory
provides easyish saving and loading of things.

```lua
local new_item_id = ezmemory.create_or_update_item(item_name,item_description,is_key)
```
- if an item with is_key is given to a player it will show in keyitems
- if an item with the same name already exists; the details will be updated, this wont update in the players key items until the player reconnects

```lua
local new_item_count = ezmemory.give_player_item(player_id, name, amount)
```
- gives the player an item