#!/usr/local/bin/lua


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

local config = require "config"
local page   = require "page"

page.set_template_name("links");

page.set_template_variable("basic_page", true);

local html_output = page.get_output("External Links")

-- print(html_output)


local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_links_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()
