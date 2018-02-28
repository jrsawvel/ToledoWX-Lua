#!/usr/local/bin/lua


local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

local config = require "config"
local page   = require "page"
local utils  = require "utils"


local url = config.get_value_for("marine_forecast")

content, code, headers, status = utils.get_web_page(url)

content = string.lower(content)

content = string.match(content, '<pre class="glossaryproduct">(.*)</pre>')

content = utils.trim_spaces(content)

content = utils.newline_to_br(content)

page.set_template_name("marine");

page.set_template_variable("marineforecast", content);

page.set_template_variable("basic_page", true);

local html_output = page.get_output("Marine Forecast")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_marine_output_file")

local o = assert(io.open(output_filename, "w"))

o:write(html_output)

o:close()
