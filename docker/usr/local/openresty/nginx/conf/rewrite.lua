local headers = ngx.req.get_headers()
local auth_token = headers.x_auth_token

local function decode_fernet(data)
    if data and data ~= "" then
        data = data:gsub("-", "+"):gsub("_", "/")
        data = ngx.decode_base64(data .. string.rep('=', 4 - #data % 4))
        if data and data:byte() == 0x80 then
            local ciphertext = data:sub(26, -33)
            local iv = data:sub(10,25)
            return fernet_keys(function (key)
                local dec = aes:new(key, nil, aes.cipher(128,"cbc"), {iv=iv})
                local decrypted = dec:decrypt(ciphertext)
                if decrypted then
                    local offset, decoded = msgpack.unpack(decrypted)
                    if offset == #decrypted then
                        local project_id = decoded[4][1] and resty_string.to_hex(decoded[4][2]) or decoded[4][2]
                        local user_id = decoded[2][1] and resty_string.to_hex(decoded[2][2]) or decoded[2][2]
                        return user_id, project_id
                    end
                end
            end)
        end
    end
end

local user, project = decode_fernet(auth_token)
local override = user_override(user) or project_override(project)

ngx.log(ngx.DEBUG, "Got ", user, " " , project, " -> " , override)
if not override then
    ngx.var.upstream = default_upstream()
else
    ngx.log(ngx.NOTICE, "Redirecting to ", override)
    ngx.var.upstream = override
end

