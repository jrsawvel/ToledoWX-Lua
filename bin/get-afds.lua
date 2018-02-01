#!/usr/bin/env lua


local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"



function get_afd(url) 

    local content = {}

    local num, status_code, headers, status_string = http.request {
        method = "GET",
        url = url,
        headers = {
            ["User-Agent"] = "Mozilla/5.0 (X11; CrOS armv7l 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.97 Safari/537.36",
            ["Accept"] = "*/*"
        },
        sink = ltn12.sink.table(content)   
    }

    -- get body as string by concatenating table filled by sink
    content = table.concat(content)
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
