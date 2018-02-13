#!/usr/bin/env lua


local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"
local cjson = require "cjson"


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config   = require "config"
local page     = require "page"
local utils    = require "utils"
local wxutils  = require "wxutils"


---------------------------


local url = config.get_value_for("lucas_county_zone_json")

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

-- get body as string by concatenating table filled by sink

content = table.concat(content)

local lua_table = cjson.decode(content)

-- utils.table_print(lua_table)


-- from the json file
-- "creationDate":"2018-02-09T15:31:00-05:00",
-- "creationDateLocal":"9 Feb 15:52 pm EST",

-- local creation_date = lua_table.creationDateLocal

local creation_date = lua_table.creationDate

local forecast_array = {}

for i=1,#lua_table.data.text do
    forecast_array[i] = lua_table.data.text[i]
end


local time_period_array = {}

for i=1,#lua_table.time.startPeriodName do
    time_period_array[i] = lua_table.time.startPeriodName[i]
end


local loop = {}

for i=1,#forecast_array do
    local hash = {}
    hash["period"] = time_period_array[i]
    hash["forecast"] = forecast_array[i]
    loop[i] = hash
end

-- utils.table_print(loop)

local tmp_hash = wxutils.reformat_nws_date_time(creation_date)

creation_date = tmp_hash["date"] .. " "  .. tmp_hash["time"] .. " " .. tmp_hash["period"]

page.set_template_name("forecast");

page.set_template_variable("forecast", loop)

page.set_template_variable("lastupdate", creation_date)

page.set_template_variable("basic_page", true);

local html_output = page.get_output("Forecast")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_forecast_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()
