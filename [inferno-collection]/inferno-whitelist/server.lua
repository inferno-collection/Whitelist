-- Inferno Collection Whitelist Version 1.21 Beta
--
-- Copyright (c) 2019, Christopher M, Inferno Collection. All rights reserved.
--
-- This project is licensed under the following:
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, and merge the software, under the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. THE SOFTWARE MAY NOT BE SOLD.
--

--
-- Resource Configuration
-- PLEASE RESTART SERVER AFTER MAKING CHANGES TO THIS CONFIGURATION
--

local Config = {} -- Do not edit this line
-- Time in minutes between whitelist refresh intervals
Config.RefreshTime = 30
-- The URL of your PasteBin
-- Should look like: https://pastebin.com/eyba7r
Config.PasteBinURL = "https://pastebin.com/rnzkxbEa"
-- API Dev Key for PasteBin.com
-- "Your Unique Developer API Key" from https://pastebin.com/api
-- Should look like: d460f1e7a0ba23662fb8d56g77g7147y
Config.APIDevKey = "bd46018a7b09a2626fb8da57771de478"
-- API User Key for PasteBin.com
-- Use the API Dev Key, and your username and password here: https://pastebin.com/api/api_user_key.html
-- Should look like: b4ca9es8cadae90fge7ghfy8361c9f4m
Config.APIUserKey = "9e3dbd9365bf77e42b9f500a06e45cd4"

--
--		Nothing past this point needs to be edited, all the settings for the resource are found ABOVE this line.
--		Do not make changes below this line unless you know what you are doing!
--

local Whitelist = false
-- Removes everything from the URL except the key at the end
Config.APIPasteKey = Config.PasteBinURL:match("([^/]+)$")

AddEventHandler("onResourceStart", function(Resource)
    if (GetCurrentResourceName() == Resource) then
        if Config.PasteBinURL == "" or Config.APIDevKey == "" or APIUserKey == "" then
            print("===================================================================")
            print("=========================Inferno-Whitelist=========================")
            print("==========================CRITICAL ERROR===========================")
            print("The Inferno Whitelist resource config cannot be blank! Please make ")
            print("sure all values are filled. See this wiki page for more info: https")
            print("://github.com/inferno-collection/Whitelist/wiki/Installation-Guide")
            print("===================================================================")

            return
        end

        Citizen.CreateThread(function()
            while true do
                PerformHttpRequest("https://pastebin.com/api/api_raw.php", function (Code, Body)
                    if Code ~= 200 then
                        print("===================================================================")
                        print("=========================Inferno-Whitelist=========================")
                        print("==========================CRITICAL ERROR===========================")
                        print("Inferno-Whitelist was NOT able to load the whitelist file: no playe")
                        print("rs will be allowed to join the server until this issue is fixed.")
                        print("")
                        print("Error Code Received: " .. Code)
                        print("===================================================================")
                    else
                        Whitelist = json.decode(Body)

                        print("===================================================================")
                        print("=========================Inferno-Whitelist=========================")
                        print("The whitelist file has been loaded successfully! Players that join ")
                        print("will now checked upon entry to the server. Have a nice day!")
                        print("===================================================================")
                    end
                -- Send a POST request to the PasteBin API with the provided details from the config
                end, "POST", "api_option=show_paste&api_user_key=" .. Config.APIUserKey .. "&api_dev_key=" .. Config.APIDevKey .. "&api_paste_key=" .. Config.APIPasteKey)

                Citizen.Wait(Config.RefreshTime * 60000)
                print("===================================================================")
                print("=========================Inferno-Whitelist=========================")
                print("Collecting latest version of whitelist... Please stand by.")
                print("===================================================================")
            end
        end)
    end
end)

AddEventHandler("playerConnecting", function(Name, _, Deferrals)
    -- Defer the client while we start the checking process
    Deferrals.defer()
    -- The client only sees this message if they are deferred for more than a few seconds
    Deferrals.update("Welcome " .. Name .. ", we are checking your whitelist status, please stand by.")

    local IDs = GetPlayerIdentifiers(source)

    if Whitelist then
        local Whitelisted = false

        -- Fast-track method
        -- As long as identifiers are in lowercase in the `whitelist.json` file, this method will work, and is much faster than the other method.
        for _, ID in pairs(IDs) do
            if Whitelist[ID] then
                Whitelisted = true
                
                print(Name .. " was approved with ID '" .. tostring(ID) .. "' using the Fast-Track method.")

                break
            end
        end

        -- Loop method
        -- If user cannot be found using the fast-track method, the whitelist will be searched line-by-line. Not stressful for the server, just slow.
        if not Whitelisted then
            for Entry, _ in pairs(Whitelist) do
                for _, ID in pairs(IDs) do
                    if ID:lower() == Entry:lower() then
                        Whitelisted = true

                        print("===================================================================")
                        print("=========================Inferno-Whitelist=========================")
                        print("=============================ATTENTION=============================")
                        print(Name .. " was approved with ID '" .. tostring(ID) .. "' using the")
                        print("Loop method, that's bad! Please check their whitelist entry/s, and ")
                        print("ensure it is in all lowercase, so they can join faster next time!")
                        print("===================================================================")

                        goto EndLoopMethod
                    end
                end
            end
        end

        ::EndLoopMethod::

        if Whitelisted then
            -- Allow client access to server
            Deferrals.done()
        else
            -- Deny the client access to the server
            Deferrals.done("Sorry " .. Name .. ", it appears you are not whitelisted. If you believe this is in error, contact server staff.")
        end

    else
        Deferrals.done("Sorry " .. Name .. ", the server is experiencing some issues at the moment, could you please inform the staff? Thank you!")

        print("===================================================================")
        print("=========================Inferno-Whitelist=========================")
        print("==========================CRITICAL ERROR===========================")
        print("Inferno-Whitelist was NOT able to load the whitelist file: no playe")
        print("rs will be allowed to join the server until this issue is fixed.")
        print("===================================================================")
    end
end)