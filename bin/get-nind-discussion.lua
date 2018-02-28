#!/usr/local/bin/lua


local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"


local url = config.get_value_for("nind_forecast_discussion")

local content, code, headers, status = utils.get_web_page(url)

content = string.lower(content)
content = string.match(content, '<pre class="glossaryproduct">(.*)</pre>')
content = utils.trim_spaces(content)
content = utils.newline_to_br(content)

page.set_template_name("discussion")
page.set_template_variable("forecast_discussion", content)
page.set_template_variable("back_and_home", true)
page.set_template_variable("back_button_url", config.get_value_for("afds_home_page"))

local html_output = page.get_output("N. IN. NWS Area Forecast Discussion")
local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_nind_discussion_output_file")
local o = assert(io.open(output_filename, "w"))
o:write(html_output)
o:close()
