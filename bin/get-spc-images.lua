#!/usr/bin/env lua

-- download SPC convective outlook html pages

local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"


function download_gif(gif_file, url)

    local imagedir = config.get_value_for("imagedir")

    local dayfilename = imagedir .. gif_file

    if ( string.match(dayfilename, '^[a-zA-Z0-9/.%-_]+$') == nil ) then
        error("Bad filename " .. dayfilename ".")
    end

    local bincontent = {}

    local num, status_code, headers, status_string = http.request {
        method = "GET",
        url = url,
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



-------------------------------------------



local md_img  = config.get_value_for("spc_md_image_url")
local box_img = config.get_value_for("spc_watch_box_image_url")

local filename = string.match(md_img, '^.*[/](.*)$')
if ( filename == nil ) then
    error("Cannot obtain file name from " .. md_img .. ".")
end

download_gif(filename, md_img)

filename = nil

filename = string.match(box_img, '^.*[/](.*)$')
if ( filename == nil ) then
    error("Cannot obtain file name from " .. box_img .. ".")
end

download_gif(filename, box_img)

