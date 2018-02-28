#!/usr/local/bin/lua

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

local config = require "config"
local page   = require "page"

page.set_template_name("radar");

page.set_template_variable("back_and_refresh", true)

page.set_template_variable("refresh_button_url", config.get_value_for("radar_home_page"))

local html_output = page.get_output("Radar")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_radar_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()
