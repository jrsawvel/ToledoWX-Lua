# ToledoWX-Lua

ToledoWX-Lua displays Toledo, Ohio weather information that is pulled from National Weather Serivce XML files, JSON files, plain text files, and HTML pages. The code also fetches JSON data from [DarkSky.net](https://darksky.net).

This code will be based upon Lua, instead of Perl, which is what I used to create the original ToledoWX code, located at <https://github.com/jrsawvel/ToledoWX>. The original ToledoWX manages my site <http://toledoweather.info>.

The templating system used for this version relies on Lua's implementation of [Mustache](https://github.com/Olivine-Labs/lustache).

The ToledoWX-Lua test website is located at <http://toledoweatherlua.soupmode.com>.

To access the Dark Sky data, I use my Lua-based [Dark Sky API wrapper and related utilities](https://github.com/jrsawvel/Dark-Sky-API-Lua). 

Except for a couple minor areas, ToledoWX-Lua uses scripts in batch to produce the same content and look as what's created by ToledoWX. The Lua version does not send a Yo notification, and this version does not display "minutely" Dark Sky data for for the Toledo suburb of Oregon.

Here are the list of modules, installed from [LuaRocks](https://luarocks.org), except where noted. The text contained within the parens is the name used in Lua's `require` statement.

* luasocket - (socket.http)
* luasec - (ssl.https)
* lyaml - (lyaml) - installed from http://rocks.moonscript.org 
* lustache - (lustache)
* lua-cjson - (cjson)
* feedparser - (feedparser) - needed to parse RSS files
* luaexpat - required by feedparser
* lrexlib-pcre - (rex_pcre) - Perl compatible regexing
* html-entities - (htmlEntities)


*created January 2018* - *updated March 2018*
