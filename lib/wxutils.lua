
-- module wxutils.lua
-- weather-related functions for ToledoWXLua

local M = {}

local utils    = require "utils"



-- sometimes, need to pull the time from nws messages and not from xml files 
-- because it's not listed in an xml file.

function M.reformat_nws_text_time(str, zone)
-- # format: 509 am to 5:09 am and 1442 to 2:42 pm

    local time = utils.split(str, ' ')

    local prd = time[2]  -- am or pm

    if string.len(time[1]) == 3 then
        time[1] = "0" .. str
    end 

    local hr  = string.sub(time[1], 1, 2)
    local min = string.sub(time[1], 3, 4)

    hr = tonumber(hr)
    min = tonumber(min)

    if  zone ~= nil and zone == "cdt" then
        hr = hr + 1
        if hr == 13 then
            hr = 1
        end

        if hr == 12 and prd == "am" then
            prd = "pm"
        elseif hr == 12 and prd == "pm" then 
            prd = "am"
        end
    end

    return string.format("%d:%02d%s", hr, min, prd)
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

    local hrminsec = utils.split(xtime, '-')

    local time = utils.split(hrminsec[1], ':')

    local hr  = time[1]
    local min = time[2]

    if ( utils.is_numeric(hr) == false ) then
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

    local yrmonday = utils.split(xdate, '-')

    local date_str = string.format("%s %d, %d", months[tonumber(yrmonday[2])], yrmonday[3], yrmonday[1])

    hash["date"]   = date_str
    hash["time"]   = time_str
    hash["period"] = prd

     return hash
end





-- http://usatoday30.usatoday.com/weather/winter/windchill/wind-chill-formulas.htm
-- http://en.wikipedia.org/wiki/Wind_chill
-- http://search.cpan.org/~jtrammell/Temperature-Windchill-0.04/lib/Temperature/Windchill.pm
-- https://github.com/trammell/temperature-windchill

function M.calc_wind_chill (tempf, windmph)  
    
    tempf = tonumber(tempf)
    windmph = tonumber(windmph)

    if ( tempf == nil or windmph == nil ) then
        return 999
    end

--    if ( utils.is_numeric(tempf) == false or utils.is_numeric(windmph) == false ) then
--            return 999
--    end 


    if ( tempf > 50 or windmph < 3 ) then
        return 999
    end 
    
    -- 2001 formula : Wind chill temperature = 35.74 + 0.6215T - 35.75V (**0.16) + 0.4275TV(**0.16)
    -- V = wind in mph and T = air temp in F degrees

    local pow = windmph ^ 0.16
    local wc = 35.74 + (0.6215 * tempf) - (35.75 * pow) + (0.4275 * tempf * pow)
    return utils.round(wc)
end




--  http://www.climate.umn.edu/snow_fence/components/winddirectionanddegreeswithouttable3.htm
--  http://stackoverflow.com/questions/7490660/converting-wind-direction-in-angles-to-text-words
function M.wind_direction_degrees_to_cardinal(wind_degrees)  

    local cardinal_arr = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"}

--     local val = utils.round((wind_degrees/22.5)+.5)
    local val = utils.round(wind_degrees/22.5)

    local idx = val % 16

    return cardinal_arr[idx+1]
end


function M.wind_direction_degrees_to_cardinal_full_name(wind_degrees)  

    local cardinal_arr = {"north", "north-northeast", "northeast", "east-northeast", "east", "east-southeast", "southeast", "south-southeast", "south", "south-southwest", "southwest", "west-southwest", "west", "west-northwest", "northwest", "north-northwest"}

--     local val = utils.round((wind_degrees/22.5)+.5)
    local val = utils.round(wind_degrees/22.5)

    local idx = val % 16

    return cardinal_arr[idx+1]
end




-- http://andrew.rsmas.miami.edu/bmcnoldy/Humidity.html
-- RH: =100*(EXP((17.625*TD)/(243.04+TD))/EXP((17.625*T)/(243.04+T))) 
-- http://www.reahvac.com/tools/humidity-formulas/

function M.calc_relative_humidity(Tf, Tdf)

    Tf  = tonumber(Tf)
    Tdf = tonumber(Tdf)

    if ( Tf == nil or Tdf == nil ) then
        return 0
    end

--    if ( utils.is_numeric(Tf) == false or utils.is_numeric(Tdf) == false ) then
--        return 0
--    end 

    -- convert to celsius

    local Tc  = 5.0/9.0 * (Tf - 32.0)

    local Tdc = 5.0/9.0 * (Tdf - 32.0)

    -- "The next set of formulas assumes a standard atmospheric pressure. 
    -- These formulas will calculate saturation vapor pressure(Es) and 
    -- actual vapor pressure(E) in millibars."

    local Es = 6.11*10.0^(7.5*Tc/(237.7+Tc))

    local E  = 6.11*10.0^(7.5*Tdc/(237.7+Tdc))

    local RH = (E/Es)*100

    return utils.round(RH)

end




-- http://en.wikipedia.org/wiki/Heat_index#Table_of_Heat_Index_values
-- https://code.google.com/p/yweather/issues/detail?id=20
-- Calculate Feels Like (given temperature in fahrenheit and humidity)
-- source http://en.wikipedia.org/wiki/Heat_index#Formula

function M.calc_heat_index (tempf, humid) 

    local feels=0
    local rounded=0

    if ( utils.is_numeric(tempf) == false or utils.is_numeric(humid) == false ) then
        return rounded
    end

    tempf = tonumber(tempf)
    humid = tonumber(humid)

    -- heat index calculation is only useful when temperature > 80F and humidity > 40%
    if (humid >= 40 and tempf >= 80) then
        feels = -42.379 + 2.04901523 * tempf + 10.14333127 * humid
            - 0.22475541 * tempf * humid - 6.83783 * 10^(-3)*(tempf^(2))
            - 5.481717 * 10^(-2)*(humid^(2))
            + 1.22874 * 10^(-3)*(tempf^(2))*(humid)
            + 8.5282 * 10^(-4)*(tempf)*(humid^(2))
            - 1.99 * 10^(-6)*(tempf^(2))*(humid^(2))

        rounded = utils.round(feels)    
    end 

    return rounded
end



return M
