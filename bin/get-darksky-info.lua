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

--ds:apiurl("https://soupmode.com/images/darksky05mar2018.json")
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


local currently_winds_str

local wind_speed = dsutils.round(wx.currently.windSpeed)

if wind_speed == 0 or wx.currently.windBearing == nil then
    currently_winds_str = "Calm wind"
else 
    wind_direction =  dsutils.degrees_to_cardinal(wx.currently.windBearing)
    wind_gust = dsutils.round(wx.currently.windGust)
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
page.set_template_variable("currently_temperature", dsutils.round(wx.currently.temperature))
page.set_template_variable("currently_apparent_temperature", dsutils.round(wx.currently.apparentTemperature))
page.set_template_variable("currently_winds", currently_winds_str)
page.set_template_variable("hourly_summary", wx.hourly.summary)
page.set_template_variable("daily_summary", wx.daily.summary)



-- Sylvania location

latitude  = config.get_value_for("sylvania_forecastio_latitude")
longitude = config.get_value_for("sylvania_forecastio_longitude")

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


local html_output = page.get_output("Dark Sky Data")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_forecastio_output_file")
local o = assert(io.open(output_filename, "w"))
o:write(html_output)
o:close()


