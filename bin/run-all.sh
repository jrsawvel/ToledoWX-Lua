#!/bin/bash

bindir=/home/toledoweatherlua/ToledoWXLua/bin
errfile=/home/toledoweatherlua/log/error.txt

echo marine forecast
$bindir/get-marine-forecast.lua           2>> $errfile
echo afds
$bindir/get-afds.lua                      2>> $errfile
echo radar page
$bindir/create-radar-page.lua             2>> $errfile
echo more radars and maps
$bindir/create-more-radars-maps-page.lua  2>> $errfile
echo external links
$bindir/create-external-links-page.lua    2>> $errfile
echo outlook day 4-8
$bindir/get-outlook-day-4-8.lua           2>> $errfile
echo co outlooks
$bindir/get-co-outlooks.lua               2>> $errfile
echo cle afd
$bindir/get-discussion.lua                2>> $errfile
echo det afd
$bindir/get-det-discussion.lua            2>> $errfile
echo n.in. afd
$bindir/get-nind-discussion.lua           2>> $errfile
echo hazardous outlook
$bindir/get-hazardous.lua                 2>> $errfile
echo forecast
$bindir/get-forecast.lua                  2>> $errfile
echo hourly forecast
$bindir/get-hourly-forecast.lua           2>> $errfile
echo conditions
$bindir/get-conditions.lua                2>> $errfile
echo index page
$bindir/create-index-page.lua             2>> $errfile
echo flash briefing
$bindir/create-flash-briefing.lua         2>> $errfile
echo spc images
$bindir/get-spc-images.lua                2>> $errfile
echo outlook gifs
$bindir/get-outlook-gifs.lua              2>> $errfile
echo dark sky info
$bindir/get-darksky-info.lua              2>> $errfile
echo error page
$bindir/create-error-page.lua             2>> $errfile
