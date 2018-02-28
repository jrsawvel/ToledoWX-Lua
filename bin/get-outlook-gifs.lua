#!/usr/local/bin/lua

-- download SPC convective outlook html pages

local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"


function download_gif(gif_file)

    local spc_gif_url = config.get_value_for("spcoutlookgifhome") .. "/" .. gif_file

    local imagedir = config.get_value_for("imagedir")

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
        error("Failed to download gif file.")
    end
end



-------------------------------------------



local filename = config.get_value_for("htmldir") .. config.get_value_for("wx_outlook_home_output_file")

-- escape char is percent sign. want to include hyphen in file names
if ( string.match(filename, '^[a-zA-Z0-9/.%-_]+$') == nil ) then
    error("Bad filename |" .. filename .. "|.")
end


local gif_file_hash      = {}
local prob_gif_file_hash = {}

for ctr=1, 3 do
    local configparam = "day" .. ctr .. "outlookhtml"
    local dayurl      = config.get_value_for(configparam)

    local content = {}

    local num, status_code, headers, status_string = http.request {
        method = "GET",
        url = dayurl,
        headers = {
            ["User-Agent"] = "Mozilla/5.0 (X11; CrOS armv7l 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.97 Safari/537.36",
            ["Accept"] = "*/*"
        },
        sink = ltn12.sink.table(content)
    }

    if ( status_code == 200 ) then
        -- get body as string by concatenating table filled by sink
        content = table.concat(content)

        local time_gif
        local gif_file
        local srch = '<a href="day' .. ctr .. 'otlk_(.*)_prt.html">'

        time_gif = string.match(content, srch)
        if ( time_gif == nil ) then
            error("Unable to parse HTML file for " .. configparam .. ".\n")
        end
        
        gif_file = "day" .. ctr .. "otlk_" .. time_gif .. ".gif"

        gif_file_hash["day" .. ctr] = gif_file

        download_gif(gif_file)

        if ( ctr == 1 ) then
            prob_gif_file_hash["tornado"] = "day1probotlk_" .. time_gif .. "_torn.gif"
            prob_gif_file_hash["wind"]    = "day1probotlk_" .. time_gif .. "_wind.gif"
            prob_gif_file_hash["hail"]    = "day1probotlk_" .. time_gif .. "_hail.gif"

            download_gif(prob_gif_file_hash["tornado"])
            download_gif(prob_gif_file_hash["wind"])
            download_gif(prob_gif_file_hash["hail"])
        end

    else
        error("File not downloaded - " .. status_string)
    end
end


page.set_template_name("outlookhome")

page.set_template_variable("imagehome", config.get_value_for("imagehome"))
page.set_template_variable("wxhome",    config.get_value_for("wxhome"))

page.set_template_variable("day1gif", gif_file_hash["day1"])  
page.set_template_variable("day2gif", gif_file_hash["day2"])  
page.set_template_variable("day3gif", gif_file_hash["day3"])  

page.set_template_variable("day1tornadogif", prob_gif_file_hash["tornado"])
page.set_template_variable("day1windgif",    prob_gif_file_hash["wind"])
page.set_template_variable("day1hailgif",    prob_gif_file_hash["hail"])

page.set_template_variable("basic_page", true);

local html_output = page.get_output("Convective Outlook Home")

local o = assert(io.open(filename, "w"))
o:write(html_output)
o:close()
