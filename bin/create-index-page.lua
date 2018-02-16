#!/usr/bin/env lua


local http        = require "socket.http"
local ltn12       = require "ltn12"
local io          = require "io"
local cjson       = require "cjson"
local rex         = require "rex_pcre"
local entities    = require "htmlEntities"
local feedparser  = require "feedparser"


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config   = require "config"
local page     = require "page"
local utils    = require "utils"
local wxutils  = require "wxutils"



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
    -- utils.table_print(lua_table)
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



local function download_gif(gif_file)
    local imagedir = config.get_value_for("imagedir")
    local spc_gif_url = config.get_value_for("spcmesoscalegifhome") .. "/" .. gif_file
    local dayfilename = imagedir .. gif_file

    if ( string.match(dayfilename, '^[a-zA-Z0-9/.%-_]+$') == nil ) then
        error("Bad filename " .. dayfilename ".")
    end

    local bincontent = {}

    local num, status_code, headers, status_string = http.request {
        method = "GET",
        url = spc_gif_url,
        headers = {
            ["User-Agent"] = "Mozilla/5.0 (X11; CrOS armv7l 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.97 Safari/537.36",
            ["Accept"] = "*/*"
        },
        sink = ltn12.sink.table(bincontent)   
    }

    if ( status_code == 200 ) then
        bincontent = table.concat(bincontent)
        local o = assert(io.open(dayfilename, "wb"))
        o:write(bincontent)
        o:close()
    else 
        error("Failed to download gif file " .. dayfilename .. ".")
    end
end



local function create_mesoscale_file(h)
    local gif_file = "mcd" .. h.mdnum .. ".gif"
    download_gif(gif_file)

    local img = '<img src="' ..  config.get_value_for("imagehome") .. '/' .. gif_file .. '">'

    h.mdcontent = img .. '<br />' .. h.mdcontent

    page.set_template_name("mesoscale")
    page.set_template_variable("content", h.mdcontent)
    page.set_template_variable("basic_page", true)

    local html_output = page.get_output("Mesoscale Discussion")

    local output_filename =  h.mdfilename
    local o = assert(io.open(output_filename, "w"))
    o:write(html_output)
    o:close()
end


local function process_md_item(h_item)

    local wxhome = config.get_value_for("wxhome")

    local hash = {}
    local mdhash = {}
    local content
    local link
    local mdnum
    local mdtime

    local mdlink = h_item.links[1].href
    local mddesc = h_item.summary

    if regional_md(mddesc) then
        link = mdlink
        content = mddesc
        content = utils.remove_html(content)
        content = utils.trim_spaces(content)
        content = string.lower(content)

        local one, two = rex.match(content, "^([0-9]* [a-z]*) est(.*)$", 1, "m")
        if utils.is_empty(one) == false then
            mdtime = one
            mdtime = wxutils.reformat_nws_text_time(mdtime)
        else
            one, two = rex.match(content,   "^([0-9]* [a-z]*) cst(.*)$", 1, "m")
            if utils.is_empty(one) == false then
                mdtime = one
                mdtime = wxutils.reformat_nws_text_time(mdtime, "cst")
            end
        end

        content = utils.newline_to_br(content)

        local htmldir = config.get_value_for("htmldir")

        mdnum = rex.match(link, "/md/md(.*).html")
        if utils.is_empty(mdnum) then
            mdnum = 0
        end

        mdhash.mdcontent = content
        mdhash.mdfilename = htmldir .. "mesoscale" .. mdnum .. ".html"
        mdhash.mdnum = mdnum
        mdhash.mdtim = mdtime

        hash.mdnum = mdnum
        hash.mdtime = mdtime
        hash.wxhome = wxhome

        create_mesoscale_file(mdhash)

    end

    return hash

end


local function get_mesoscale_info()
    local md_xml = get_web_page(config.get_value_for("spc_md_xml"))
--    local md_xml = get_web_page("http://testcode.soupmode.com/spcmdrss.xml")
    local parsed = feedparser.parse(md_xml)
--    utils.table_print(parsed)

    local a_entries = parsed.entries -- rss items
    local a_list = {}
    local counter = 1

    for i=1,#a_entries do
        local hash = process_md_item(a_entries[i])
        if next(hash) ~= nil then
            a_list[counter] = hash
            counter = counter + 1
        end
    end

    return a_list
end




--------------------------------------------





local discussion_url = config.get_value_for("forecast_discussion")
local discussion_text = get_web_page(discussion_url)
if discussion_text == nil  then
    error("Could not retrieve " .. discussion_url .. ".")
end
discussion_text = string.lower(discussion_text)
local discussion_time, tmp_discussion_text = rex.match(discussion_text, "^(.*)est(.*)$", 1, "m")
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
local marine_time, tmp_marine_text = rex.match(marine_text, "^(.*)est(.*)$", 1, "m")
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
local haz_time, tmp_haz_text = rex.match(haz_text, "^(.*)est(.*)$", 1, "m")
if utils.is_empty(haz_time) == false then
    haz_time = wxutils.reformat_nws_text_time(haz_time)
else
    haz_time = " "
end



--  local zone_json  = get_web_page("http://testcode.soupmode.com/zone.json")
-- local zone_json  = get_web_page("http://testcode.soupmode.com/zone2.json")
-- local zone_json  = get_web_page("http://testcode.soupmode.com/zone3.json")

local zone_json  = get_web_page(config.get_value_for("lucas_county_zone_json"))
if zone_json == nil  then
    error("Could not retrieve JSON for Lucas County Zone.")
end
local zone_table = cjson.decode(zone_json)

local h_conditions = {}

h_conditions.updatedate      = zone_table.currentobservation.Date
h_conditions.weather         = zone_table.currentobservation.Weather
h_conditions.temperature     = zone_table.currentobservation.Temp

local a_dt = utils.split(h_conditions.updatedate, ' ')
local tmp_time = utils.split(a_dt[3], ':')
local tmp_hr = tonumber(tmp_time[1])
if ( tmp_hr > 12 ) then
    tmp_hr = tmp_hr - 12
end
h_conditions.updatedate = string.format("%d:%s%s", tmp_hr, tmp_time[2], a_dt[4])


local forecast_creation_date = zone_table.creationDate -- in format of: 2018-02-15T05:40:29-05:00
local h_forecast_dt = wxutils.reformat_nws_date_time(forecast_creation_date)
forecast_creation_date = h_forecast_dt.time .. h_forecast_dt.period




-- grabbing alert messages

local no_important_hazardous_outlook_exists = true

local a_hazard_text = zone_table.data.hazard
local a_hazard_url  = zone_table.data.hazardUrl

local h_alerts = {}

for i=1, #a_hazard_text do
    local hazard     = string.lower(a_hazard_text[i])
    local hazard_url = a_hazard_url[i]
    if hazard == "hazardous weather outlook" then
        no_important_hazardous_outlook_exists = false
    end
    h_alerts[hazard] = hazard_url
end


local a_alert_button_loop = {}
local alert_counter = 1
-- local alert_buttons_exist = false


for k,v in pairs(h_alerts) do

    local x_text_url = entities.decode(v)

    local x_text = get_web_page(x_text_url)
    if x_text == nil  then
        error("Could not retrieve " .. x_text_url .. ".")
    end

    x_text = string.lower(x_text)

    local msg

    msg = rex.match(x_text, "<h3>" .. k .. "</h3><pre>(.*)</pre><hr /><br /><h3>", 1, "s")
    if  utils.is_empty(msg) then
        msg = rex.match(x_text, "<h3>" .. k .. "</h3><pre>(.*)</pre><hr /><br />", 1, "s")
        if utils.is_empty(msg) then
           msg = rex.match(x_text, "<h3>" .. k .. "</h3><pre>(.*)</pre><hr/><br/>", 1, "s")
        else
            error("Could not parse file: " .. x_text .. "\n")
        end
    end

    local alert_time, alert_date -- won't use alert_date for now. maybe for a custom alerts.json file

    if msg ~= nil then
        alert_time, alert_date = rex.match(msg, "^(.*)est(.*)$", 1, "m")
        if utils.is_empty(alert_time) == false then
            alert_time = wxutils.reformat_nws_text_time(alert_time)
        end
    end

    if k == "hazardous_weather_outlook" then
        local one, two, three = rex.match(msg, "(.*)lez061(.*)this hazardous weather outlook is(.*)", 1, "s")
        if utils.is_empty(one) == false then
            msg = one .. "<br />" .. three
        end
    end


    msg = utils.remove_html(msg)
    msg = utils.trim_spaces(msg)
    msg = utils.newline_to_br(msg)

    local filename = k
    filename = string.gsub(filename, ' ', '-')
    filename = filename .. ".html"

    page.set_template_name("specialstatement")
    page.set_template_variable("msg", msg)
    page.set_template_variable("basic_page", true)
    local html_output = page.get_output(k)

    local output_filename =  config.get_value_for("htmldir") .. filename
    local o = assert(io.open(output_filename, "w"))
    o:write(html_output)
    o:close()


    local h_button = {}

    h_button.alert = utils.ucfirst_each_word(k)
    h_button.url   = filename
    h_button.alerttime = alert_time
    h_button.wxhome = config.get_value_for("wxhome")

    a_alert_button_loop[alert_counter] = h_button

    alert_counter = alert_counter + 1

--    alert_buttons_exist = true

end



local meso_loop = get_mesoscale_info()


-- possible to-do: create a custom json file that lists all of the headlines:
-- hwo, mds, special weather statements, watches, warnings, advisories, etc.
-- for what purpose? i don't know yet.


page.set_template_name("wxindex")
page.set_template_variable("basic_page", false)
page.set_template_variable("refresh_button", true)
page.set_template_variable("refresh_button_url", config.get_value_for("home_page"))
page.set_template_variable("no_important_hazardous_outlook_exists", no_important_hazardous_outlook_exists)
page.set_template_variable("hazardous_outlook_time", haz_time)

local a_reversed_alert_button_loop = utils.reverse_list(a_alert_button_loop)
page.set_template_variable("buttonalerts_loop", a_reversed_alert_button_loop)

page.set_template_variable("conditions_time", h_conditions.updatedate)
page.set_template_variable("conditions_weather", h_conditions.weather)
page.set_template_variable("conditions_temperature", h_conditions.temperature)
page.set_template_variable("forecast_time", forecast_creation_date)
page.set_template_variable("discussion_time", discussion_time)
page.set_template_variable("marine_time", marine_time)
page.set_template_variable("wxhome", config.get_value_for("wxhome"))
page.set_template_variable("mesoscale_loop", meso_loop)

local html_output = page.get_output("Toledo Weather")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_index_output_file")
local o = assert(io.open(output_filename, "w"))
o:write(html_output)
o:close()




