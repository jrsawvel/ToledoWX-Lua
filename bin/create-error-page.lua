#!/usr/local/bin/lua


local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"


local error_file = config.get_value_for("errors_file")
local f = assert(io.open(error_file, "r"))
local text = f:read("a")
f:close()

text = utils.newline_to_br(text)

page.set_template_name("errors")
page.set_template_variable("back_and_refresh", true)
page.set_template_variable("refresh_button_url", config.get_value_for("errors_home_page"))
page.set_template_variable("error_messages", text)

local html_output = page.get_output("Errors")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_error_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()
