
-- dsutils.lua
-- March 2018
-- jr@sawv.org



local M = {}



--  http://www.climate.umn.edu/snow_fence/components/winddirectionanddegreeswithouttable3.htm
--  http://stackoverflow.com/questions/7490660/converting-wind-direction-in-angles-to-text-words
function M.degrees_to_cardinal(wind_degrees)  
    local arg_type = math.type(wind_degrees)
    if arg_type ~= "integer" and arg_type ~= "float" then
        return wind_degrees
    end
    local cardinal_arr = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"}
    -- local val = M.round((wind_degrees/22.5)+.5)
    local val = M.round(wind_degrees/22.5)
    local idx = val % 16
    return cardinal_arr[idx+1]
end



function M.degrees_to_cardinal_fullname(wind_degrees)  
    local arg_type = math.type(wind_degrees)
    if arg_type ~= "integer" and arg_type ~= "float" then
        return wind_degrees
    end
    local cardinal_arr = {"North", "North-Northeast", "Northeast", "East-Northeast", "East", "East-Southeast", "Southeast", "South-Southeast", "South", "South-Southwest", "Southwest", "West-Southwest", "West", "West-Northwest", "Northwest", "North-Northwest"}
    -- local val = M.round((wind_degrees/22.5)+.5)
    local val = M.round(wind_degrees/22.5)
    local idx = val % 16
    return cardinal_arr[idx+1]
end



function M.round (x)
    local f = math.floor(x)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return math.floor(x + 0.5)
    end
end



function M.format_date_iso(es)
    if es == nil then
        return os.date("%Y-%m-%dT%H:%M:%SZ")
    else 
        return os.date("%Y-%m-%dT%H:%M:%SZ", es)
    end
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



function M.millibars_to_inches(mb)
    if mb == nil then
        return 0.0
    end
    if math.type(mb) ~= "float" then
        return mb
    end
    return string.format("%.2f", mb * 0.0295301)
end



-- from the old forecast.io api docs:
--   A value of 0 corresponds to clear sky, 
--   0.4 to scattered clouds, 
--   0.75 to broken cloud cover, 
--   and 1 to completely overcast skies.
-- I'm also referencing:
--   https://forecast.weather.gov/glossary.php?word=SKY%20CONDITION
-- then creating my own break points.

function M.cloud_cover_description(cloud_cover) 
    local arg_type = math.type(cloud_cover)
    if arg_type ~= "integer" and arg_type ~= "float" then
        return cloud_cover
    end
    if cloud_cover < .12 then
        return "Clear"
    elseif cloud_cover >= .12 and cloud_cover < .3 then
        return "Mostly Clear"
    elseif cloud_cover >= .3 and cloud_cover < .625 then
        return "Partly Cloudy"
    elseif cloud_cover >= .625 and cloud_cover <= .875 then
        return "Mostly Cloudy"
    elseif cloud_cover > .875 then
        return "Cloudy"
    end
    return cloud_cover
end



-- old doc info https://developer.forecast.io/docs/v2
--      precipIntensity: A numerical value representing the average expected intensity 
--      (in inches of liquid water per hour) of precipitation occurring at the given 
--      time conditional on probability (that is, assuming any precipitation occurs at all). 
--      A very rough guide is that a value of 0 corresponds to no precipitation, 
--      0.002 corresponds to very light precipitation, 
--      0.017 corresponds to light precipitation, 
--      0.1 corresponds to moderate precipitation, 
--      and 0.4 corresponds to very heavy precipitation.

function M.calc_precip_intensity_and_color(intensity)
    local desc  = "No Precip"
    local color = "#000000;"

    if intensity == nil or type(intensity) ~= "number" then
        return desc, color
    end

    -- easier to understand with whole numbers
    intensity = intensity * 1000

    if intensity > 0 and intensity < 17 then
        desc  = "Very Light"
        color = "#c0c0c0;"   -- very light grey    
    elseif intensity >= 17 and intensity < 50 then
        desc  = "Light"
        color = "#888888;"   -- medium grey 
    elseif intensity >= 50 and intensity < 75 then
        desc  = "Light to Moderate"
        color = "#006600;"   -- green
    elseif intensity >= 75 and intensity < 125 then
        desc  = "Moderate"
        color = "#cccc00;"   -- dark green-yellow
    elseif intensity >= 125 and intensity < 200 then
        desc  = "Moderate to Heavy"
        color = "#cc6600;"   -- dark orange
    elseif intensity >= 200 and intensity < 299 then
        desc  = "Heavy"
        color = "#cc0000;"   -- dark red
    elseif intensity >= 300 and intensity < 400 then
        desc  = "Heavy to Very Heavy"
        color = "#990066;"   -- dark purple
    elseif intensity >= 400 then
        desc  = "Very Heavy"
        color = "#000099;"   -- dark blue
    end
    return desc, color
end



-- https://en.wikipedia.org/wiki/Ultraviolet_index
function M.get_uvindex_info(uvi)
    local rating = "Missing"
    local color  = "#000000;"

    if uvi == nil or type(uvi) ~= "number" then
        return rating, color
    end

    if uvi < 3.0 then
        rating = "Low"
        color  = "#008000;" -- green
    elseif uvi >= 3.0 and uvi < 6.0 then
        rating = "Moderate"
        color  = "#ffd700;" -- yellow gold
    elseif uvi >= 6.0 and uvi < 8.0 then
        rating = "High"
        color  = "#ff6600;" -- orange
    elseif uvi >= 8.0 and uvi < 11.0 then
        rating = "Very High"
        color  = "#CC3300;" -- red
    elseif uvi >= 11.0 then
        rating = "Extreme"
        color  = "#8a2be2;" -- blue violet
    end

    return rating, color
end



function M.get_moon_phase_description(mp)
    if mp == nil or type(mp) ~= "number" then
        return "Missing"
    end

    if mp == 0.0 then
        return "New Moon"
    elseif mp == 0.25 then
        return "First Quarter Moon"
    elseif mp == 0.50 then
        return "Full Moon"
    elseif mp == 0.75 then
        return "Last Quarter Moon"
    elseif mp > 0.0 and mp < 0.25 then
        return "Waxing Crescent"
    elseif mp > 0.25 and mp < 0.50 then
        return "Waxing Gibbous"
    elseif mp > 0.50 and mp < 0.75 then
        return "Waning Gibbous"
    elseif mp > 0.75 then
        return "Waining Crescent"
    end
end



return M
