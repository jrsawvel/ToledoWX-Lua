

local Mailgun = require("mailgun").Mailgun

local utils  = require "utils"
local config = require "config"



local M = {}


function M.send_alert(alert, link)

    local m = Mailgun({
        domain         = config.get_value_for("mailgun_domain"),
        api_key        = "api:" .. config.get_value_for("mailgun_api_key"),
        default_sender = config.get_value_for("mailgun_from")
    })

    local email_rcpt = config.get_value_for("email_rcpt")

    local site_name = config.get_value_for("site_name")

    local date_time = utils.get_date_time()

    local subject = "WX Alert: " .. alert

    local message = date_time .. " - " .. site_name ..  "\n\n" .. alert .. "\n\n" .. link

    m:send_email({
        to      = "<" .. email_rcpt .. ">",
        subject = subject,
        html    = false,
        body    = message
    })

end


return M
