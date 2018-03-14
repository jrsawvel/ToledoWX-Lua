#!/usr/local/bin/lua


local io          = require "io"


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my Toledo WX modules
local config   = require "config"
local page     = require "page"
local utils    = require "utils"
local wxutils  = require "wxutils"

-- my Dark Sky API wrapper and related utilities
local darksky = require "darksky"
local dsutils = require "dsutils"


local api_key          = config.get_value_for("darksky_api_key")

-- Central Toledo, Ohio location
local latitude  = config.get_value_for("toledo_latitude")
local longitude = config.get_value_for("toledo_longitude")

local ds = darksky(api_key, latitude, longitude)

-- boston, ma
-- ds:apiurl("https://api.darksky.net/forecast/cd50a948f24600c7cc2986548ee741f1/42.3605,-71.0596")

local rc, wx = ds:fetch_data()

if rc == false then
    print(wx)
    error(os.date() .. ": Unable to retrieve Dark Sky JSON data for Toledo.")
end

local toledo_minutely_loop = {}
local minutely = wx.minutely.data

for i=1, #minutely do

    local m = minutely[i]

    local hash = {}

    hash.time = os.date("%I:%M %p", m.time + (wx.offset * 3600))

    hash.precipChance = false
    hash.noPrecipChance = false

    if m.precipIntensity > 0.0 then
        hash.precipProbability = dsutils.round(m.precipProbability * 100)
        hash.precipIntensity, hash.precipColor = dsutils.calc_precip_intensity_and_color(m.precipIntensity)
        hash.precipType = m.precipType
        hash.precipChance = true
    else
        hash.precipProbability = 0
        hash.noPrecipChance = true
    end

    toledo_minutely_loop[i] = hash

end




local currently = wx.currently

local currently_winds_str
local wind_direction, wind_gust, wind_direction_fullname

local wind_speed = dsutils.round(currently.windSpeed)

if wind_speed == 0 or currently.windBearing == nil then
    currently_winds_str = "Calm wind"
else 
    wind_direction =  dsutils.degrees_to_cardinal(currently.windBearing)
    wind_direction_fullname =  dsutils.degrees_to_cardinal_fullname(currently.windBearing)
    wind_gust = dsutils.round(currently.windGust)
    currently_winds_str = wind_direction .. " at " .. wind_speed .. " mph. Gust " .. wind_gust .. " mph."
end


page.set_template_name("darksky")
page.set_template_variable("basic_page", false)
page.set_template_variable("back_and_refresh", true)
page.set_template_variable("toledo_latitude", latitude)
page.set_template_variable("toledo_longitude", longitude)

page.set_template_variable("toledo_minutely_summary", wx.minutely.summary)
page.set_template_variable("toledo_minutely_loop", toledo_minutely_loop)

page.set_template_variable("currently_summary", wx.currently.summary)
page.set_template_variable("currently_temperature", dsutils.round(currently.temperature))

if dsutils.round(currently.apparentTemperature) ~=  dsutils.round(currently.temperature) then
    page.set_template_variable("use_apparent_temperature", true)
    page.set_template_variable("currently_apparent_temperature", dsutils.round(currently.apparentTemperature))
end

page.set_template_variable("currently_winds", currently_winds_str)
page.set_template_variable("hourly_summary", wx.hourly.summary)
page.set_template_variable("daily_summary", wx.daily.summary)
page.set_template_variable("currently_date_time", os.date("%I:%M %p, %a, %b %d, %Y ", currently.time + (wx.offset * 3600)))

page.set_template_variable("currently_dewpoint", dsutils.round(currently.dewPoint))
page.set_template_variable("currently_humidity", dsutils.round(currently.humidity * 100))
page.set_template_variable("currently_wind_direction_fullname", wind_direction_fullname)
page.set_template_variable("currently_wind_speed", wind_speed)
page.set_template_variable("currently_wind_gust", wind_gust)
page.set_template_variable("currently_pressure", dsutils.millibars_to_inches(currently.pressure))
page.set_template_variable("currently_uvindex", currently.uvIndex)
local uvindex_rating, uvindex_color = dsutils.get_uvindex_info(currently.uvIndex)
page.set_template_variable("currently_uvindex_color", uvindex_color)
page.set_template_variable("currently_uvindex_rating", uvindex_rating)
page.set_template_variable("currently_cloud_cover", dsutils.round(currently.cloudCover * 100)) 
page.set_template_variable("currently_cloud_cover_description", dsutils.cloud_cover_description(currently.cloudCover))
page.set_template_variable("currently_precip_probability", dsutils.round(currently.precipProbability * 100))
page.set_template_variable("currently_precip_intensity", currently.precipIntensity)
local precip_desc, precip_color = dsutils.calc_precip_intensity_and_color(currently.precipIntensity)
page.set_template_variable("currently_precip_color", precip_color)
page.set_template_variable("currently_precip_description", precip_desc)
if currently.precipIntensity > 0.0 then
    page.set_template_variable("currently_precip_type", currently.precipType)
end
page.set_template_variable("currently_visibility", currently.visibility) 
if currently.nearestStormDistance < 1.0 then
    page.set_template_variable("currently_nearest_precip_distance", "Precip is occurring over or near this location.")
else 
    page.set_template_variable("currently_nearest_precip_distance", dsutils.round(currently.nearestStormDistance) .. " miles")
    page.set_template_variable("currently_nearest_precip_bearing", dsutils.degrees_to_cardinal_fullname(currently.nearestStormBearing)) 
end



-- Sylvania location

latitude  = config.get_value_for("sylvania_darksky_latitude")
longitude = config.get_value_for("sylvania_darksky_longitude")

local sylvania = darksky(api_key, latitude, longitude)
local src, swx = sylvania:fetch_data()

if src == false then
    print(swx)
    error(os.date() .. ": Unable to retrieve Dark Sky JSON data for Sylvania.")
end

local sylvania_minutely_loop = {}
local s_minutely = swx.minutely.data

for i=1, #s_minutely do

    local m = s_minutely[i]

    local hash = {}

    hash.time = os.date("%I:%M %p", m.time + (swx.offset * 3600))

    hash.precipChance = false
    hash.noPrecipChance = false

    if m.precipIntensity > 0.0 then
        hash.precipProbability = dsutils.round(m.precipProbability * 100)
        hash.precipIntensity, hash.precipColor = dsutils.calc_precip_intensity_and_color(m.precipIntensity)
        hash.precipType = m.precipType
        hash.precipChance = true
    else
        hash.precipProbability = 0
        hash.noPrecipChance = true
    end

    sylvania_minutely_loop[i] = hash

end


page.set_template_variable("sylvania_minutely_summary", swx.minutely.summary)
page.set_template_variable("sylvania_minutely_loop", sylvania_minutely_loop)


local alerts_loop = {}
local alerts = wx.alerts
if alerts == nil then 
    page.set_template_variable("no_alerts", true)
else
    page.set_template_variable("have_alerts", true)
    for i=1, #alerts do
        local hash = {}
        hash.title         =  alerts[i].title
        hash.description   =  alerts[i].description
        hash.startTime     =  os.date("%I:%M %p, %a, %b %d, %Y ", alerts[i].time + (wx.offset * 3600))
        hash.endTime       =  os.date("%I:%M %p, %a, %b %d, %Y ", alerts[i].expires + (wx.offset * 3600))
        -- hash.severity      =  alerts[i].severity
        hash.url           =  alerts[i].uri
        --[[
        if alerts[i].regions ~= nil then
            local regions = alerts[i].regions
            print(" Alert includes the following areas: ")
            for r=1, #regions do
                print("    " .. regions[r])
            end
        end
        ]]
        alerts_loop[i] = hash
    end
    page.set_template_variable("alerts_loop", alerts_loop)
end





local daily = wx.daily.data
local daily_loop = {}

for i=1, #daily do
    local hash = {}
    local d = daily[i]

    local wdf, ws
    ws = dsutils.round(d.windSpeed)
    if ws == 0 or d.windBearing == nil then
        wdf  = "Calm" 
    else 
        wdf  = dsutils.degrees_to_cardinal_fullname(d.windBearing)
    end

    hash.date                =   os.date("%a, %b %d, %Y", d.time)
    hash.summary             =   d.summary
    hash.sunriseTime         =   os.date("%I:%M %p", d.sunriseTime + (wx.offset * 3600))
    hash.sunsetTime          =   os.date("%I:%M %p", d.sunsetTime + (wx.offset * 3600))
    hash.cloudCoverDesc      =   dsutils.cloud_cover_description(d.cloudCover)
    hash.precipType          =   d.precipType
    hash.precipProbability   =   dsutils.round(d.precipProbability * 100) 
    local snow_accumulation  = 0.0
    if  d.precipType == "snow" then
        snow_accumulation    =   d.precipAccumulation 
    end
    hash.snowAccumulation    =   snow_accumulation
    hash.lowTemp             =   dsutils.round(d.temperatureLow)
    hash.lowTempTime         =   os.date("%I:%M %p", d.temperatureLowTime + (wx.offset * 3600))
    hash.highTemp            =   dsutils.round(d.temperatureHigh)
    hash.highTempTime        =   os.date("%I:%M %p", d.temperatureHighTime + (wx.offset * 3600))
    hash.windSpeed           =   ws
    hash.windDirection       =   wdf

    daily_loop[i] = hash
end

page.set_template_variable("daily_loop", daily_loop)


local html_output = page.get_output("Dark Sky Data")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_darksky_output_file")
local o = assert(io.open(output_filename, "w"))
o:write(html_output)
o:close()


