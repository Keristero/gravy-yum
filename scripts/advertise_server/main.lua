local json = require('scripts/advertise_server/json')
local base64 = require('scripts/advertise_server/base64')
local folder_path = "scripts/advertise_server/"
local json_path = folder_path.."advertisement.json"
local config
local images = {}

--shorthands for async stuff.
function async(p)
    local co = coroutine.create(p)
    return Async.promisify(co)
end
function await(v) return Async.await(v) end
function load_image_data(path)
    print('[advertise_server] loading icon ',path)
    local f = io.open(path, "rb")
    local icon_data = f:read("*a")
    f:close()
    return icon_data
end
function save_image_data(path,data)
    local f = io.open(path, "wb")
    f:write(data)
    f:flush()
    f:close()
end

function advertise_all(include_icon)
    return async(function ()
        for i, url in ipairs(config.serverlists) do
            for i, advertisement in ipairs(config.advertisements) do
                local body = {}
                local headers = {}
                headers["Content-Type"] = "application/json"
                body.advertisement = advertisement
                if include_icon and images[i] ~= nil then
                    body.icon_data = base64.encode(images[i])
                end
                local res = await(Async.request(url, {
                    method = "POST",
                    headers = headers,
                    body = json.encode(body)
                }))
                local data = json.decode(res.body)
                print('[advertise_server] response',data)
            end
        end
    end)
end

--load configuration
async(function ()
    print('[advertise_server] loading...')
    local config_json = await(Async.read_file(json_path))
    config = json.decode(config_json)
    for i, advertisement in ipairs(config.advertisements) do
        local image_path = "./"..folder_path..advertisement.icon
        local image_data = load_image_data(image_path)
        images[i] = image_data
        print("Loaded image data")
    end
    advertise_all(true)
end)