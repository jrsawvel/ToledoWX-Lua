

-- darksky.lua
-- March 2018
-- jr@sawv.org


local https = require "ssl.https"
local cjson = require "cjson"

local mt = {}

local API_ENDPOINT = "https://api.forecast.io/forecast/"

 
local new = function(api_key, latitude, longitude)
    local obj = {
        api_key   = api_key,
        latitude  = latitude,
        longitude = longitude, 
        api_url   = API_ENDPOINT .. api_key .. "/" .. latitude .. "," .. longitude
    }
    return setmetatable(obj, mt)
end
 

local get_or_set_api_url = function(self, new_url)
    self.api_url = new_url or self.api_url
    return self.api_url
end
mt.apiurl = get_or_set_api_url


-- download json and convert json into lua table
-- optional date time argument "dt" in format as:
--     2012-07-11T12:00:00-0400
-- Dark Sky permits retrieving old data for a location.
local fetch_dark_sky_data = function(self, dt)
    local tmp_url = self.api_url
    if dt ~= nil then
        tmp_url = tmp_url .. "," .. dt
    end 

    local body,code,headers,status = https.request(tmp_url)

    if code >= 300 then
        return false, status
    end

    self.data = cjson.decode(body)

    return true, self.data
end
mt.fetch_data = fetch_dark_sky_data


 
mt.__index = mt
 
mt.__metatable = {}

 
local ctor = function(cls, ...)
  return new(...)
end

 
return setmetatable({}, { __call = ctor })



