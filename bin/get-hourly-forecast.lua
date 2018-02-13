#!/usr/bin/env lua


local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"
local cjson = require "cjson"


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"



local url = config.get_value_for("lucas_county_hourly_forecast_json")
url = "http://testcode.soupmode.com/hourly.json"

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

local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}


local first_12_hours  = lua_table.PeriodNameList["0"]
local second_12_hours = lua_table.PeriodNameList["1"]
local third_12_hours  = lua_table.PeriodNameList["2"]



local first_12_hours_temperature           = lua_table[first_12_hours].temperature
local first_12_hours_weather               = lua_table[first_12_hours].weather
local first_12_hours_winddirectioncardinal = lua_table[first_12_hours].windDirectionCardinal
local first_12_hours_pop                   = lua_table[first_12_hours].pop
local first_12_hours_unixtime              = lua_table[first_12_hours].unixtime
local first_12_hours_cloudamount           = lua_table[first_12_hours].cloudAmount
local first_12_hours_windchill             = lua_table[first_12_hours].windChill
local first_12_hours_windspeed             = lua_table[first_12_hours].windSpeed
local first_12_hours_time                  = lua_table[first_12_hours].time


local loop = {}

for i=1,#first_12_hours_temperature do

    local dt = os.date("*t", first_12_hours_unixtime[i])
    local secs = 5 * 3600
    if ( dt.isdst ) then
        secs = 4 * 3600
    end
    dt = os.date("*t", first_12_hours_unixtime[i] - secs)

    local hash = {}

    hash.time            = first_12_hours_time[i] 
    hash.date            = months[dt.month] .. " " .. dt.day - 1 
    hash.temp            =  first_12_hours_temperature[i] 
    hash.windirection    = first_12_hours_winddirectioncardinal[i] 
    hash.windspeed       = first_12_hours_windspeed[i] 
    hash.windchill       = first_12_hours_windchill[i]
    hash.precipchance    = first_12_hours_pop[i]
    hash.cloudamount     = first_12_hours_cloudamount[i]

    hash.windchillexists = false
    if ( hash.windchill ~= nil and utils.is_numeric(hash.windchill) ) then
        hash.windchillexists = true
    end

    loop[i] = hash
end


utils.table_print(loop)


