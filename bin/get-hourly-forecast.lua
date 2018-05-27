#!/usr/local/bin/lua


local io    = require "io"
local cjson = require "cjson"


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"


local url = config.get_value_for("lucas_county_hourly_forecast_json")

local content, code, headers, status = utils.get_web_page(url)

local lua_table = cjson.decode(content)

local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

-- each period is 12 hours
local periods = {"0", "1", "2"}

local p

local data_array = {}

for p=1, #periods do
    local prd = lua_table.PeriodNameList[periods[p]]

    -- tables. each table contains 12 hours of data for the variable.

    local t_temperature           = lua_table[prd].temperature
    local t_weather               = lua_table[prd].weather
    local t_winddirectioncardinal = lua_table[prd].windDirectionCardinal
    local t_pop                   = lua_table[prd].pop
    local t_unixtime              = lua_table[prd].unixtime
    local t_cloudamount           = lua_table[prd].cloudAmount
    local t_windchill             = lua_table[prd].windChill
    local t_windspeed             = lua_table[prd].windSpeed
    local t_time                  = lua_table[prd].time

    local loop = {}

    local i

    for i=1,#t_temperature do

        local dt = os.date("*t", t_unixtime[i])
        local secs = 5 * 3600
        if ( dt.isdst ) then
            secs = 4 * 3600
        end
        dt = os.date("*t", t_unixtime[i] - secs)

        local hash = {}

        hash.time            = t_time[i] 
        hash.date            = months[dt.month] .. " " .. dt.day .. ", " .. dt.year
        hash.temperature     = t_temperature[i] 
        hash.winddirection   = t_winddirectioncardinal[i] 
        hash.windspeed       = t_windspeed[i] 
--        hash.windchill       = t_windchill[i]
        hash.precipchance    = t_pop[i]
        hash.cloudamount     = t_cloudamount[i]

        hash.windchillexists = false
--        if ( hash.windchill ~= nil and utils.is_numeric(hash.windchill) ) then
        if t_windchill ~= nil then
            if t_windchill[i] ~= nil and utils.is_numeric(t_windchill[i]) then
                hash.windchill = t_windchill[i]
                hash.windchillexists = true
            end
        end

        loop[i] = hash
    end

    if ( p == 1 ) then
        data_array = loop
    else 
        for k,v in ipairs(loop) do
            table.insert(data_array, v)
        end
    end
end

-- utils.table_print(data_array)

page.set_template_name("hourlyforecast");

page.set_template_variable("hourly_loop" ,data_array);

page.set_template_variable("basic_page", true);

local html_output = page.get_output("Hourly Forecast")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_hourly_forecast_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()
