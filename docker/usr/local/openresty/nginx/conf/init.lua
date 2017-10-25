require "resty.core"
aes = require "resty.aes"
resty_string = require "resty.string"
msgpack = require "luajit-msgpack-pure"

-- Global variables statically configured on start
static_fernet_keys= {}
user_overrides    = {}
project_overrides = {}
fernet_key_path   = "/fernet-keys/"

-- Functions, so they can be replaced with something more dynamically in "local_init", if needed
function default_upstream() return 'http://localhost' end
function user_override(user) return user_overrides[user] end
function project_override(project) return project_overrides[project] end
function fernet_keys(op)
    for i, key in ipairs(static_fernet_keys) do
        local result = {op(key)} -- Capture _all_ return values in a table
        if next(result) ~= nil then -- Any values returned?
            return unpack(result)
        end
    end
end

-- Override values here
package.path = package.path .. ";/etc/fernet-router/?.lua"
local a, b = pcall(require, "local_init")
if not a then
    ngx.log(ngx.WARN, b)
else
    ngx.log(ngx.DEBUG, "Loaded overrides")
end

for i = 0,99 do
    local f = io.open(fernet_key_path .. i, "r")
    if not f then break end
    local data = f:read()
    static_fernet_keys[#static_fernet_keys+1] = ngx.decode_base64(data:gsub("-", "+"):gsub("_", "/")):sub(17)
    f:close()
end
