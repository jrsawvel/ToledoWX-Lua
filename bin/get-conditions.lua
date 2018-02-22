#!/usr/local/bin/lua


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


function read_json_zone_file(url)

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

    return parse_json_table(lua_table)
end



function parse_json_table (t) 

    local my_hash = {}
    local my_loop = {}

    if ( t == nil ) then
        my_hash["error"] = "yes"
        my_loop[0] = my_hash
        return my_loop
    end 
  
    my_hash.updatedate      = t.currentobservation.Date
    my_hash.pressure        = t.currentobservation.SLP
    my_hash.winddirection   = t.currentobservation.Windd
    my_hash.windspeedgust   = t.currentobservation.Gust
    my_hash.windspeed       = t.currentobservation.Winds
    my_hash.windspeedunits  = "mph"
    my_hash.weather         = t.currentobservation.Weather
    my_hash.visibility      = t.currentobservation.Visibility
    my_hash.dewpoint        = t.currentobservation.Dewp
    my_hash.temperature     = t.currentobservation.Temp

    -- print(t.creationDate)
    -- print(t.time.startValidTime[1])
  
    -- updatedate exists in the json file in the following format 
    --     13 Feb 15:52 pm EST 
    -- i at least want the year included.
    -- i may try to change the time from 24 hour to 12 hour since the am and pm qualifiers are included.
    -- seems odd for the nws json to contain military time with am or pm included too.
    local tmp_hash = wxutils.reformat_nws_date_time(t.time.startValidTime[1])
    local mon_day_year = utils.split(tmp_hash.date, ' ')
    -- print(mon_day_year[3]) -- year
    local update_date_array = utils.split(my_hash.updatedate, ' ')
    local tmp_time = utils.split(update_date_array[3], ':')
    local tmp_hr = tonumber(tmp_time[1])
    if ( tmp_hr > 12 ) then
        tmp_hr = tmp_hr - 12
    end


    my_hash.updatedate = string.format("%s %s, %s %d:%s %s %s", 
                     update_date_array[2],
                     update_date_array[1],
                     mon_day_year[3],
                     tmp_hr,
                     tmp_time[2],                     
                     update_date_array[4],
                     update_date_array[5])
    -- that should produce: Feb 13, 2018 3:52 pm EST

    my_hash.humidity = wxutils.calc_relative_humidity(my_hash.temperature, my_hash.dewpoint)

    my_hash.heatindex = wxutils.calc_heat_index(my_hash.temperature, my_hash.humidity)
    my_hash.heatindexexists = false
    if ( my_hash.heatindex > 0 ) then
        my_hash.heatindexexists = true
    end

    if ( utils.is_numeric(my_hash.winddirection) ) then
        my_hash.winddirection = wxutils.wind_direction_degrees_to_cardinal(my_hash.winddirection)
    end

    if ( my_hash.windspeed == 0 ) then
        my_hash.winddirection = "Calm"
        my_hash.windspeed = ""
    else
        my_hash.windchill = wxutils.calc_wind_chill(my_hash.temperature, my_hash.windspeed)
        if ( my_hash.windchill ~= 999 ) then
            my_hash.windchillexists = true
        end
    end

    my_hash.windspeedgustexists = false
    if ( utils.is_numeric(my_hash.windspeedgust) and tonumber(my_hash.windspeedgust) > 0 ) then
        my_hash.windspeedgustexists = true
        my_hash.windspeedgustunits = "mph"
    end

    my_loop[1] = my_hash
    return my_loop
end




--------------------------------



local express_loop = read_json_zone_file(config.get_value_for("lucas_county_zone_json"))
-- utils.table_print(express_loop)

local executive_loop = read_json_zone_file(config.get_value_for("toledo_executive_ap"))

local suburban_loop = read_json_zone_file(config.get_value_for("toledo_suburban_ap"))


page.set_template_name("conditions");
page.set_template_variable("express_loop" ,express_loop);
page.set_template_variable("executive_loop" ,executive_loop);
page.set_template_variable("suburban_loop" ,suburban_loop);
page.set_template_variable("basic_page", true);

local html_output = page.get_output("Airport Conditions")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_conditions_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()






--[[

[currentobservation] => table
    (
       [Altimeter] => 1040.6
       [longitude] => -83.81
       [Visibility] => 10.00
       [elev] => 673
       [Date] => 13 Feb 09:52 am EST
       [id] => KTOL
       [Relh] => 71
       [Temp] => 20
       [Gust] => 0
       [SLP] => 30.69
       [timezone] => EST
       [Winds] => 7
       [Weather] => Fair
       [Windd] => 999
       [state] => OH
       [WindChill] => 11
       [name] => Toledo - Toledo Express Airport
       [Dewp] => 12
       [Weatherimage] => sct.png
       [latitude] => 41.59
    )

]]

