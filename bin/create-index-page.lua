#!/usr/bin/env lua


local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"
local cjson = require "cjson"
local rex = require "rex_pcre"


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config   = require "config"
local page     = require "page"
local utils    = require "utils"
local wxutils  = require "wxutils"



-- local express_loop = read_json_zone_file(config.get_value_for("lucas_county_zone_json"))
local function read_json_zone_file(url)
    local content = {}
    local num, status_code, headers, status_string = http.request {
        method = "GET",
        url = url,
        headers = {
            ["User-Agent"] = "Mozilla/5.0 (X11; CrOS armv7l 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.97 Safari/537.36",
            ["Accept"] = "*/*"
        },
        sink = ltn12.sink.table(content)   
    }
    content = table.concat(content)
    -- utils.table_print(lua_table)
    local lua_table = cjson.decode(content)
end




local function get_web_page(url)
    local content = {}
    local num, status_code, headers, status_string = http.request {
        method = "GET",
        url = url,
        headers = {
            ["User-Agent"] = "Mozilla/5.0 (X11; CrOS armv7l 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.97 Safari/537.36",
            ["Accept"] = "*/*"
        },
        sink = ltn12.sink.table(content)   
    }
    content = table.concat(content)
    -- utils.table_print(lua_table)
    return content 
end


--------------------------------------------





local discussion_url = config.get_value_for("forecast_discussion")
local discussion_text = get_web_page(discussion_url)
if discussion_text == nil  then
    error("Could not retrieve " .. discussion_url .. ".")
end
discussion_text = string.lower(discussion_text)
local discussion_time, afd_text = rex.match(discussion_text, "^(.*)est(.*)$", 1, "m")
if utils.is_empty(discussion_time) == false then
    discussion_time = wxutils.reformat_nws_text_time(discussion_time)
else
    discussion_time = " "
end



local marine_url = config.get_value_for("marine_forecast")
local marine_text = get_web_page(marine_url)
if marine_text == nil  then
    error("Could not retrieve " .. marine_url .. ".")
end
marine_text = string.lower(marine_text)
local marine_time, afd_text = rex.match(marine_text, "^(.*)est(.*)$", 1, "m")
if utils.is_empty(marine_time) == false then
    marine_time = wxutils.reformat_nws_text_time(marine_time)
else
    marine_time = " "
end



local haz_url = config.get_value_for("hazardous_outlook")
local haz_text = get_web_page(haz_url)
if haz_text == nil  then
    error("Could not retrieve " .. haz_url .. ".")
end
haz_text = string.lower(haz_text)
local haz_time, afd_text = rex.match(haz_text, "^(.*)est(.*)$", 1, "m")
if utils.is_empty(haz_time) == false then
    haz_time = wxutils.reformat_nws_text_time(haz_time)
else
    haz_time = " "
end


print(haz_time)
