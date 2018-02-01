
-- module: utils.lua

local M = {}


function M.trim_spaces (str)
    if (str == nil) then
        return ""
    end
   
    -- remove leading spaces 
    str = string.gsub(str, "^%s+", "")

    -- remove trailing spaces.
    str = string.gsub(str, "%s+$", "")

    return str
end


function M.newline_to_br (str) 
    str = string.gsub(str, "\r\n", "<br />")
    str = string.gsub(str, "\n", "<br />")
    return str
end


function M.get_date_time()
-- time displayed for Toledo, Ohio (eastern time zone)
-- Thu, Jan 25, 2018 - 6:50 p.m.

    local time_type = "EDT"
    local epochsecs = os.time()
    local localsecs 
    local dt = os.date("*t", epochsecs)
    
    if ( dt.isdst ) then
        localsecs = epochsecs - (4 * 3600)
    else 
        localsecs = epochsecs - (5 * 3600)
        time_type = "EST"
    end

    local dt_str = os.date("%a, %b %d, %Y - %I:%M %p", localsecs)

    return(dt_str .. " " .. time_type)
end


function M.remove_html (str)
    str = string.gsub(str, "<([^>])+>|&([^;])+;", "")
    return str
end

return M

