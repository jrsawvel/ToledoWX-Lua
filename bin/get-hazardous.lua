#!/usr/local/bin/lua


local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"


local url = config.get_value_for("hazardous_outlook")

local content, code, headers, status = utils.get_web_page(url)

content = string.lower(content)

content = string.match(content, 'hwocle(.*)lez061')

if ( content ~= nil ) then 
    content = utils.trim_spaces(content)
end

content = utils.newline_to_br(content)

page.set_template_name("hazardous");

page.set_template_variable("hazardous_outlook", content);

page.set_template_variable("basic_page", true);

local html_output = page.get_output("Hazardous Outlook")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_hazardous_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()
