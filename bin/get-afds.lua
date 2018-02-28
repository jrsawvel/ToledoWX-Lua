#!/usr/local/bin/lua


local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"



function get_afd(url) 
    local content, code, headers, status = utils.get_web_page(url)
    content = string.lower(content)
    content = string.match(content, '<pre class="glossaryproduct">(.*)</pre>')
    content = utils.trim_spaces(content)
    content = utils.newline_to_br(content)
    return content
end




local cleveland = get_afd(config.get_value_for("forecast_discussion"))
local detroit   = get_afd(config.get_value_for("det_forecast_discussion"))
local indiana   = get_afd(config.get_value_for("nind_forecast_discussion"))

page.set_template_name("afds");
page.set_template_variable("cleveland", cleveland);
page.set_template_variable("detroit",   detroit);
page.set_template_variable("indiana",   indiana);
page.set_template_variable("basic_page", true);

local html_output = page.get_output("Area Forecast Discussion")

local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_afds_output_file")
local o = assert(io.open(output_filename, "w"))
o:write(html_output)
o:close()
