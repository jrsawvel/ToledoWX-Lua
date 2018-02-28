#!/usr/local/bin/lua


local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"



function download_gif(gif_file, imagedir)

    local spc_gif_url = config.get_value_for("day48outlookgif")
    local dayfilename = imagedir .. gif_file

    if ( string.match(dayfilename, '^[a-zA-Z0-9/.-_]+$') == nil ) then
        error("Bad data in first argument for filename when downloading gif.") 
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





local htmldir     = config.get_value_for("htmldir")
local configparam = "day48outlookhtml"
local dayurl      = config.get_value_for(configparam)
local dayfilename = htmldir .. "day48otlk.html"

if ( string.match(dayfilename, '^[a-zA-Z0-9/.-_]+$') == nil ) then
    error("Bad data in first argument for filename.") 
end

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

    local text;

    text = string.match(content, '<pre>(.*)</pre>') 
    if ( text == nil ) then 
        error("Unable to parse HTML file for " .. configparam .. ".\n")
    end

    text = utils.remove_html(text)
    text = utils.trim_spaces(text)
    text = utils.newline_to_br(text)
    text = string.lower(text)

    page.set_template_name("convectiveoutlook")
    page.set_template_variable("text", text)
    page.set_template_variable("back_and_home", true)
    page.set_template_variable("back_button_url", config.get_value_for("outlook_home_page"))

    local html_output = page.get_output("Day 4-8 Convective Outlook")

    local o = assert(io.open(dayfilename, "w"))
    o:write(html_output)
    o:close()
else
    error("File not downloaded - " .. status_string)
end


local imagedir = config.get_value_for("imagedir")

download_gif("day48prob.gif", imagedir)

