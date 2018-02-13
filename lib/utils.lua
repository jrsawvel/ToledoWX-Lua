
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


function M.table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    for key, value in pairs (tt) do
      io.write(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        io.write(string.format("[%s] => table\n", tostring (key)));
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write("(\n");
        M.table_print (value, indent + 7, done)
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write(")\n");
      else
        io.write(string.format("[%s] => %s\n",
            tostring (key), tostring(value)))
      end
    end
  else
    io.write(tt .. "\n")
  end
end


function M.split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


function M.is_numeric(str)
    if ( str == nil ) then
        return false
    end

    local s = string.match(str, '^[0-9]+$')

    if ( s == nil ) then
        return false
    end

    return true
end


--convert this 2018-02-09T18:02:23-05:00 into a better format
function M.reformat_nws_date_time(str) 

    local hash = {}

    if ( str == nil ) then
        hash["date"]   = "-"
        hash["time"]   = "-"
        hash["period"] = "-"
        return hash
    end

    local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

    local xdate, xtime = string.match(str, '(.*)T(.*)')

    local hrminsec = M.split(xtime, '-')

    local time = M.split(hrminsec[1], ':')

    local hr  = time[1]
    local min = time[2]

    if ( M.is_numeric(hr) == false ) then
        hash["date"]   = "-"
        hash["time"]   = "-"
        hash["period"] = "-"
        return hash
    end

    local prd = "am"

    hr = tonumber(hr)

    if ( hr > 12 ) then
        prd = "pm"
    end

    if ( hr > 12 ) then
        hr = hr - 12
    end

    if ( hr == 0 ) then
        hr = 12
    end

    local time_str = string.format("%d:%02d", hr, min)

    local yrmonday = M.split(xdate, '-')

    local date_str = string.format("%s %d, %d", months[tonumber(yrmonday[2])], yrmonday[3], yrmonday[1])

    hash["date"]   = date_str
    hash["time"]   = time_str
    hash["period"] = prd

     return hash
end



return M



-- http://lua-users.org/wiki/SplitJoin

--[[
function M.string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

-- hrminsec = string.split(xdate, '-')

function M.string:split( inSplitPattern, outResults )
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )

   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end

-- hrminsec = string.split(xdate, '-')
]]



