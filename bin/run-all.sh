#!/bin/bash

bindir=/home/toledoweatherlua/ToledoWXLua/bin
errfile=/home/toledoweatherlua/ToledoWXLua/log/error.txt

$bindir/get-marine-forecast.lua           2>> $errfile
$bindir/get-afds.lua                      2>> $errfile
$bindir/create-radar-page.lua             2>> $errfile
$bindir/create-more-radars-maps-page.lua  2>> $errfile
$bindir/create-external-links-page.lua    2>> $errfile
$bindir/get-outlook-day-4-8.lua           2>> $errfile
$bindir/get-co-outlooks.lua               2>> $errfile
$bindir/get-outlook-gifs.lua              2>> $errfile
$bindir/get-spc-images.lua                2>> $errfile
$bindir/get-discussion.lua                2>> $errfile
$bindir/get-det-discussion.lua            2>> $errfile
$bindir/get-nind-discussion.lua           2>> $errfile
$bindir/get-hazardous.lua                 2>> $errfile
$bindir/get-forecast.lua                  2>> $errfile
$bindir/get-hourly-forecast.lua           2>> $errfile
$bindir/get-conditions.lua                2>> $errfile
$bindir/create-index-page.lua             2>> $errfile
$bindir/create-error-page.lua             2>> $errfile
