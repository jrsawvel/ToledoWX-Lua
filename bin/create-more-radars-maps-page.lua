#!/usr/local/bin/lua


package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

local config = require "config"
local page   = require "page"

page.set_template_name("moreradarsmaps");

page.set_template_variable("imagehome", config.get_value_for("imagehome"))

page.set_template_variable("back_and_refresh", true);

page.set_template_variable("refresh_button_url", config.get_value_for("more_radars_maps_home_page"))

local html_output = page.get_output("More Radars and Maps")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_more_radars_maps_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()
