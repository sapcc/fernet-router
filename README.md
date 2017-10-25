# Fernet-Request-Router

The Fernet Request Router is a reverse proxy, which routes requests to various backends according to either user- or project-id stored in a keystone fernet token.

The administrator can define a number of ids and their associated backends, if no id matches, it falls back to the configured default backend.

It is maybe around 100 lines of lua script on top of openresty and luajit-msgpack-pure, and at this point more intended for development purposes than production use-cases.

## Building

Run `docker build .` and you'll have an image

## Configuration

The configuration is expected under `/etc/fernet-router/local_init.lua`, but can be placed in any directory, which is in the lua search path.
The file is required on startup, and allows you to override most lookup functionality.
By default the fernet keys are expeced under `/fernet-keys/{0..N}`, and are only loaded on startup.

Let's say, you want to get your own requests routed to your development hosts:
```
-- local_init.lua

function default_upstream() return 'http://the-real-service.example.com' end

user_overrides["my-user-id-and-not-my-user-name"] = "http://my-development-host.example.com:8080"

```

Restart nginx, and it could already work. If you see resolver errors, you probably have to change the resolver in the nginx.conf.

Most functions can be replaced in your local config, so you can do something more dynamically.
Say, you want to get the configuration out of a redis-db:
```
-- local_init.lua
function default_upstream() return 'http://the-real-service.example.com' end

local resty_redis = require "resty.redis"

local function get(id)
    local db = resty_redis:new()
    local ok, err = db:connect("redis-db.example.com", 6379)
    if not ok then
        ngx.log(ngx.WARN, "Could not connect to redis due to ", err)
        return
    end
    local res, err = db:get(id)
    db:set_keepalive(60000, 5)
    if not res then
        ngx.log(ngx.WARN, "Could not get value for ", id, " due to ", err)
    end
    if res == ngx.null then
        return
    end
    return res
end

function user_override(user) return get("fr:user:" .. user) end
function project_override(project) return get("fr:project:" .. project) end
```

That's all for now. Hope, it works for you.
