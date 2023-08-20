local json = require('scripts/advertise_server/json')
local base64 = require('scripts/advertise_server/base64')
local urlencode = require('scripts/advertise_server/urlencode')
local folder_path = "scripts/advertise_server/data/"
local advertisement_json_path = folder_path.."advertisement.json"
local secret_keys_json_path = folder_path.."secret_keys.json"
local online_players = 0
local minimum_sync_interval = 5
local maximum_sync_interval = 60*60
local public_info = {
    pending_fields={},
    time_since_last_sync={}
}
local listservers = {}
local secret_keys = {}
local server_ids = {}

--shorthands for async stuff.
local function async(p)
    local co = coroutine.create(p)
    return Async.promisify(co)
end
local function await(v) return Async.await(v) end
local function load_image_data(path)
    print('[advertise_server] loading icon ',path)
    local f = io.open(path, "rb")
    local icon_data = f:read("*a")
    f:close()
    return icon_data
end
local function save_image_data(path,data)
    local f = io.open(path, "wb")
    f:write(data)
    f:flush()
    f:close()
end

--Event handlers
Net:on("player_connect", function(event)
    online_players = online_players + 1
    set_pending_field_for_all_servers("online_players",online_players)
end)

Net:on("player_disconnect", function(event)
    online_players = online_players - 1
    set_pending_field_for_all_servers("online_players",online_players)
end)

function set_pending_field_for_all_servers(field_name,value)
    for server_id, _ in pairs(public_info.time_since_last_sync) do
        set_pending_field(server_id,field_name,value)
    end
end

function set_pending_field(server_id,field_name,value)
    if not public_info.pending_fields[server_id] then
        public_info.pending_fields[server_id] = {}
    end
    public_info.pending_fields[server_id][field_name] = value
    public_info.time_since_last_sync[server_id] = maximum_sync_interval+1
end

function clear_pending_fields(server_id)
    public_info.pending_fields[server_id] = {}
end

function build_payload(server_id)
    local payload = {
        server_id=server_id,
        fields={}
    }
    for field_name, value in pairs(public_info.pending_fields[server_id]) do
        payload.fields[field_name] = value
    end
    clear_pending_fields(server_id)
    return payload
end

function get_secret_key(server_id,listserver_name)
    if not secret_keys[listserver_name] then
        return nil
    end
    if not secret_keys[listserver_name][server_id] then
        return nil
    end
    return secret_keys[listserver_name][server_id]
end

function save_secret_key(file_path,server_id,listserver_name,secret_key)
    return async(function ()
        if not secret_keys[listserver_name] then
            secret_keys[listserver_name] = {}
        end
        if not secret_keys[listserver_name][server_id] then
            secret_keys[listserver_name][server_id] = {}
        end
        secret_keys[listserver_name][server_id] = secret_key
        await(Async.write_file(file_path,json.encode(secret_keys)))
    end)
end

function sync_to_servers(server_id)
    return async(function ()
        print('[advertise_server] syncing '..server_id..' to server lists...')
        local payload = build_payload(server_id)
        local headers = {}
        headers["Content-Type"] = "application/json"
        --for each serverlist server
        for listserver_name, url in pairs(listservers) do
            payload.secret_key = get_secret_key(server_id,listserver_name)
            local res = await(Async.request(url, {
                method = "POST",
                headers = headers,
                body = json.encode(payload)
            }))
            if res then
                local data = json.decode(res.body)
                if data and data.secret_key ~= nil then
                    await(save_secret_key(secret_keys_json_path,server_id,listserver_name,data.secret_key))
                end
            end
        end
        public_info.time_since_last_sync[server_id] = 0
    end)
end

local function read_json(file_path)
    return async(function ()
        local data = {}
        pcall(function()
            data = json.decode(await(Async.read_file(file_path)))
            if data == nil then
                data = {}
            end
        end)
        return data
    end)
end

local function load_all_images_for_advertisements(advertisements)
    return async(function ()
        for i, advertisement in ipairs(advertisements) do
            if advertisement.icon then
                local image_path = "./"..folder_path..advertisement.icon
                local image_data = load_image_data(image_path)
                set_pending_field(advertisement.unique_server_id,"b64_image",base64.encode(image_data))
            end
        end
    end)
end

local function initialize_pending_fields_from_advertisements(advertisements)
    set_pending_field_for_all_servers("online_players",0)
    for i, advertisement in ipairs(advertisements) do
        --Some ephemral fields need defaults
        local server_id = advertisement.unique_server_id
        for field_name, value in pairs(advertisement) do
            set_pending_field(server_id,field_name,value)
        end
    end
end

--load configuration
async(function()
    print('[advertise_server] loading...')
    --load secret keys
    secret_keys = await(read_json(secret_keys_json_path))
    --load advertisements
    local data = await(read_json(advertisement_json_path))
    local advertisements = data.advertisements
    listservers = data.listservers
    initialize_pending_fields_from_advertisements(advertisements)
    --load images
    await(load_all_images_for_advertisements(advertisements))
    while true do
        --every minimum_sync_interval, we send all the batched changes
        await(Async.sleep(minimum_sync_interval))
        for unique_server_id, time in pairs(public_info.time_since_last_sync) do
            if time > maximum_sync_interval then
                sync_to_servers(unique_server_id)
            else
                public_info.time_since_last_sync[unique_server_id] = time + 10
            end
        end
    end
end)