#!/usr/local/bin/lua


local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"
local cjson = require "cjson"
local rex         = require "rex_pcre"
local feedparser  = require "feedparser"


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config   = require "config"
local page     = require "page"
local utils    = require "utils"
local wxutils  = require "wxutils"



local function output_briefing_json_multiple(statements, conditions, afd, forecast)
    local update_date = os.date("%Y-%m-%dT%X.0Z")

    local a = {}

    local h = {}

    h.uid = os.time() .. "-1"
    h.updateDate = update_date
    h.titleText = "Important Statement"
    h.mainText = statements
    h.redirectionUrl = "http://toledoweather.info/hazardous-weather-outlook.html"
    a[1] = h


    h = {}
    h.uid = os.time() .. "-2"
    h.updateDate = update_date
    h.titleText = "Current Conditions"
    h.mainText = conditions
    h.redirectionUrl = "http://toledoweather.info/current-conditions.html"
    a[2] = h


    h = {}
    h.uid = os.time() .. "-3"
    h.updateDate = update_date
    h.titleText = "Synopsis"
    h.mainText = afd 
    h.redirectionUrl = "http://toledoweather.info/area-forecast-discussions.html"
    a[3] = h


    h = {}
    h.uid = os.time() .. "-4"
    h.updateDate = update_date
    h.titleText = "Forecast"
    h.mainText = forecast
    h.redirectionUrl = "http://toledoweather.info/forecast.html"
    a[4] = h

    local json_str = cjson.encode(a)

    local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("alexa_flash_briefing_json")
    local o = assert(io.open(output_filename, "w"))
    o:write(json_str)
    o:close()
end


local function output_briefing_html(statements, conditions, afd, forecast)
    page.set_template_name("alexa-flash-briefing")

    page.set_template_variable("statements", statements)
    page.set_template_variable("conditions", conditions)
    page.set_template_variable("afdsynopsis", afd)
    page.set_template_variable("forecast", forecast)
    page.set_template_variable("basic_page", true);

    local html_output = page.get_output("Alexa Flash Briefing")
    local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("alexa_flash_briefing_html")
    local o = assert(io.open(output_filename, "w"))
    o:write(html_output)
    o:close()
end



local function get_web_page(url)
    local content = {}

    local ua_str = "Mozilla/5.0 (X11; CrOS armv7l 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) "
    ua_str = ua_str .. "Chrome/62.0.3202.97 Safari/537.36"

    local num, status_code, headers, status_string = http.request {
        method = "GET",
        url = url,
        headers = {
            ["User-Agent"] = ua_str,
            ["Accept"] = "*/*"
        },
        sink = ltn12.sink.table(content)
    }
    content = table.concat(content)
    return content
end


-- attn...wfo...
-- if (  $mddesc =~ m/CLE/s   or  $mddesc =~ m/DTX/s  or  $mddesc =~ m/IWX/s  ) {
local function regional_md(str)
    local return_val = false
    local one, two = rex.match(str, "attn(.*)wfo(.*)", 1, "si")
    if utils.is_empty(one) == false then
        if rex.match(two, "CLE",1,"s") or rex.match(two, "DTX",1,"s") or  rex.match(two, "IWX",1,"s") then
            return_val = true
        end
    end
    return return_val
end



local function get_mds()
    local url = config.get_value_for("spc_md_xml")
--    url = "http://testcode.soupmode.com/spcmdrss.xml"
--    url = "http://www.spc.noaa.gov/products/spcmdrss.xml"

    local md_xml = get_web_page(url)

    local parsed = feedparser.parse(md_xml)


    local a_entries = parsed.entries -- rss items

    local a_mds = {}

    for i=1,#a_entries do

        if regional_md(a_entries[i].summary) then
            a_mds[i] = a_entries[i].title
            local a_text = utils.split(a_mds[i], ' ')
            if #a_text == 3 then
                a_mds[i] = "Mesoscale Discussion Number " .. a_text[3]
            end
        end
    end

    return a_mds
end



-- Check for any additional alerts, such as flood warnings, that were missed elsewhere, but 
--    might be listed in this Atom XML file.

local function get_alerts()
    local https = require("ssl.https") 

    local url = 'https://alerts.weather.gov/cap/wwaatmget.php?x=OHC095&y=0'
--    url = "http://testcode.soupmode.com/alerts1.xml"

    local body,c,l,h = https.request(url)

    local parsed = feedparser.parse(body)

    local a_entries = parsed.entries -- atom items

    local a_alerts = {}

    if a_entries[1].title == "There are no active watches, warnings or advisories" then
        return a_alerts
    end

    for i=1,#a_entries do

        body,c,l,h = https.request(a_entries[i].link)
    
        if body == nil then
            error("Could not retrieve " .. a_entries[i].link .. ".")
        end

        a_alerts[i] = rex.match(body, "<event>(.*)</event>", 1, "s") 

    end

    return a_alerts
end



function get_hazards()

    local zone_json  = get_web_page(config.get_value_for("lucas_county_zone_json"))
    if zone_json == nil  then
        error("Could not retrieve JSON for Lucas County Zone.")
    end

    local zone_table = cjson.decode(zone_json)

    return zone_table.data.hazard
        
end


function get_forecast()

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

    content = table.concat(content)

    local lua_table = cjson.decode(content)

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

--    for i=1,#forecast_array do
-- short-term forecast. display only first five 12-hour segments
    for i=1,5 do
        local hash = {}
        hash["period"] = time_period_array[i]
        hash["forecast"] = forecast_array[i]
        hash["forecast"] = string.gsub(hash["forecast"], "mph", "miles per hour")
        loop[i] = hash
    end


    local tmp_hash = wxutils.reformat_nws_date_time(creation_date)

    creation_date = tmp_hash["date"] .. " "  .. tmp_hash["time"] .. " " .. tmp_hash["period"]

    page.set_template_name("alexa-forecast-min")

    page.set_template_variable("forecast_loop", loop)

    page.set_template_variable("lastupdate", creation_date)

    local html_output = page.get_output_min()

    local text = utils.remove_html(html_output)
    text = utils.remove_newline(text)

    return text, html_output

end




function get_afd() 

    local url = config.get_value_for("forecast_discussion")

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

    local dummy, synopsis = rex.match(content, "SYNOPSIS([.]*)([^&]*)", nil, "s")
    if utils.is_empty(synopsis) then
        error("Could not parse synopsis from area forecast discussion for the Alexa Flash Briefing skill.")
    end

    synopsis = rex.gsub(synopsis, "[\r\n]", " ", nil, "s") 
    synopsis = utils.trim_spaces(synopsis)

    page.set_template_name("alexa-afd-min")
    page.set_template_variable("afdsynopsis", synopsis)
    local html_output = page.get_output_min()

    return utils.remove_html(html_output), html_output
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
    my_hash.windspeedunits  = "miles per hour"
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
        my_hash.winddirection = wxutils.wind_direction_degrees_to_cardinal_full_name(my_hash.winddirection)
    end

    my_hash.iscalmwind = false
    my_hash.iswindspeed = true

    if ( my_hash.windspeed == "0" ) then
        my_hash.winddirection = "Calm"
        my_hash.windspeed = ""
        my_hash.iscalmwind = true
        my_hash.iswindspeed = false
    else
        my_hash.windchill = wxutils.calc_wind_chill(my_hash.temperature, my_hash.windspeed)
        if ( my_hash.windchill ~= 999 ) then
            my_hash.windchillexists = true
        end
    end

    my_hash.windspeedgustexists = false
    if ( utils.is_numeric(my_hash.windspeedgust) and tonumber(my_hash.windspeedgust) > 0 ) then
        my_hash.windspeedgustexists = true
        my_hash.windspeedgustunits = "miles per hour"
    end

    my_loop[1] = my_hash
    return my_loop
end



-- For Toledo Express Airport
function get_conditions()

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

    content = table.concat(content)

    -- utils.table_print(lua_table)

    local lua_table = cjson.decode(content)

    local h_conditions = parse_json_table(lua_table)

    page.set_template_name("alexa-conditions-min")
    page.set_template_variable("express_loop", h_conditions)
    local html_output = page.get_output_min()

    local text = utils.remove_html(html_output)
    text = utils.remove_newline(text)

    return text, html_output
end

--------------------------------

local afd_text, afd_html = get_afd()

local conditions_text, conditions_html = get_conditions()

local forecast_text, forecast_html = get_forecast()

local a_hazards = get_hazards()
local a_alerts  = get_alerts()
local a_mds     = get_mds()

local important_statements = ""

local important_statements_exist = false

for i=1, #a_hazards do
    important_statements = important_statements .. "A " .. a_hazards[i] .. ". "
    important_statements_exist = true
end

for i=1, #a_alerts do
    important_statements = important_statements .. "A " .. a_alerts[i] .. ". "
    important_statements_exist = true
end

for i=1, #a_mds do
    important_statements = important_statements .. a_mds[i] .. ". "
    important_statements_exist = true
end

if important_statements_exist then
    important_statements = "The following important weather statements exist: " .. important_statements 
    important_statements = important_statements .. "Visit toledoweather.info for details." 
else 
    important_statements = "No important weather statements exist at this time."
end


output_briefing_html(important_statements, conditions_html, afd_html, forecast_html)

output_briefing_json_multiple(important_statements, conditions_text, afd_text, forecast_text)

