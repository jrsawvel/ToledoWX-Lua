#!/usr/local/bin/lua


local http  = require "socket.http"
local ltn12 = require "ltn12"
local io    = require "io"

package.path = package.path .. ';/home/toledoweatherlua/ToledoWXLua/lib/?.lua'

-- my modules
local config = require "config"
local page   = require "page"
local utils  = require "utils"


local url = config.get_value_for("forecast_discussion")

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
-- $content =~ s/^[.]/<br \/>/gm;
content = string.lower(content)
content = string.match(content, '<pre class="glossaryproduct">(.*)</pre>')
content = utils.trim_spaces(content)
content = utils.newline_to_br(content)

page.set_template_name("discussion")
page.set_template_variable("forecast_discussion", content)
page.set_template_variable("back_and_home", true)
page.set_template_variable("back_button_url", config.get_value_for("afds_home_page"))

local html_output = page.get_output("Cle NWS Area Forecast Discussion")
local output_filename =  config.get_value_for("htmldir") .. config.get_value_for("wx_discussion_output_file")
local o = assert(io.open(output_filename, "w"))
o:write(html_output)
o:close()
