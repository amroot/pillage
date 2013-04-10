#!/usr/bin/lua
-- credit, notes, and release information at bottom of script. - stay clean --

local socket = require("socket")
local io = require("io")
local ltn12 = require("ltn12")
local curl = require("curl")
local par_url = require("socket.url") -- this is only to parse urls :|
local work_dir = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]

function getum(cur_url,red)
    if verbose >= 3 then verbosie=1 else verbosie=0 end
    local head_text = {}
    local body_text = {}
    local function WriteMemoryCallbackH(s)
        head_text[#head_text+1] = s
        return string.len(s)
    end
    local function WriteMemoryCallbackB(s)
        body_text[#body_text+1] = s
        return string.len(s)
    end
    local c = curl.easy_init()
    c:setopt(curl.OPT_COOKIEJAR, "cookies.txt") --initiates cookie file if needed - this needs work
    c:setopt(curl.OPT_COOKIEFILE, "cookies.txt") -- cookies from previous session if exist - needs work
    c:setopt(curl.OPT_VERBOSE, verbosie)
    c:setopt(curl.OPT_URL,cur_url)
    c:setopt(curl.OPT_FOLLOWLOCATION,1)
    --c:setopt(curl.OPT_HEADERFUNCTION,WriteMemoryCallbackH) -- add this to regex the real location header... get rid of socks? soon?
    c:setopt(curl.OPT_WRITEFUNCTION, WriteMemoryCallbackB)
    c:setopt(curl.OPT_USERAGENT, agent99)
    c:setopt(curl.OPT_MAXREDIRS,10) --max 10 to stop redirect loops
    c:setopt(curl.OPT_AUTOREFERER,1)
    c:setopt(curl.OPT_SSL_VERIFYHOST,0) --don't care about your certs
    c:setopt(curl.OPT_SSL_VERIFYPEER,0)
    code,h_err=c:perform()
    if curl.close then c:close() end
    if h_err then
        print("Error getting: ".. h_err .. "\n")
        return 0
    end
    --print(table.concat(head_text,'')) -- see header note above
    return table.concat(body_text,'')
end

function fform(linkf)
        for forms in string.gmatch(page, "<form (.-)>") do
            if fh then 
                fh:write(linkf .."," ..  forms .. "\n")
            end
            print("check: " .. linkf .. "\t" .. forms)
        end
        if forms then 
            forms = nil
            return 1 
        end
end

function furl(base_url,cur_url)
    local l = {}
    local ct = nil
    if limit then 
        ct = 0
    end
    for links in string.gmatch(page, "href=\"(.-)\"") do
        if not string.find(string.lower(links), "mailto") 
        and not string.find(string.lower(links), "javascript")
        and not blacklistext(string.lower(links)) then
            if not string.find(string.lower(links), "://") then         
             if string.starts(links,"/") then
            links = base_url .. links
            scope(links,base_url)
            else
            links = cur_url .. links
            scope(links,base_url)
        end          
            else
                scope(links,base_url)
            end
        end
    end
    links = nil
    return l
end

function scope(link, base_url)
    -- only want the url so we rebuild it without the paramas, query, or fragment. regex it day.
    local parsed_url = par_url.parse(link)
    link = parsed_url.scheme .. "://" .. parsed_url.authority .. to_string(parsed_url.path)
    if verbose >= 2 then
    print("checking scope for: " .. link)
    end
    -- check if url is already queued in url storage
    for k,v in pairs(url_store) do
        if string.lower(v) == string.lower(link) then
            stopit = 1
            break
        end
    end
    if not stopit then
        -- in scope?
        if s then
        if string.starts(string.lower(link), string.lower(base_url)) then
                    if verbose > 0 then print("add: " .. link) end
                    table.insert(url_store,link)
                end
        else
                if verbose > 0 then print("add: " .. link) end
                table.insert(url_store,link)
        end
    end
    stopit = nil
end

function blacklistext(link)
    local exts = {"png", "gif", "jpg", "jpeg", "doc", "xls", "mpp", "pdf",
        "ppt", "tiff", "bmp", "docx", "xlsx", "pptx", "ps", "psd",
        "swf", "fla", "mp3", "mp4", "m4v", "mov", "avi", "css",
        "ico", "flv", "exe", "js", "wmv"}
    for k,ext in pairs(exts) do
        if string.ends(link, ext) then
            return true        
        end
    end
    return false
end

function sleep(msec)
    msec = msec * 0.001
    socket.select(nil, nil, msec)
end

-- these wonderful string functions were obtained from http://lua-users.org/wiki/SampleCode
function to_string(tbl)
    if "nil" == type( tbl ) then
        return tostring(nil)
    elseif "table" == type( tbl ) then
        return table_print(tbl)
    elseif "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
    return End=='' or string.sub(String,-string.len(End))==End
end --end borrowed string functions

-- Alternative Get Opt from http://lua-users.org/wiki/AlternativeGetOpt
function getopt(arg, opions)
    local tab = {}
    for k, v in ipairs(arg) do
        if string.sub( v, 1, 2) == "--" then
            local x = string.find( v, "=", 1, true )
            if x then tab[ string.sub( v, 3, x-1 ) ] = string.sub( v, x+1 )
            else            tab[ string.sub( v, 3 ) ] = true
            end
        elseif string.sub( v, 1, 1 ) == "-" then
            local y = 2
            local l = string.len(v)
            local jop
            while ( y <= l ) do
                jop = string.sub( v, y, y )
                if string.find( opions, jop, 1, true ) then
                    if y < l then
                        tab[ jop ] = string.sub( v, y+1 )
                        y = l
                    else
                        tab[ jop ] = arg[ k + 1 ]
                    end
                else
                    tab[ jop ] = true
                end
                y = y + 1
            end
        end
    end
    return tab
end -- End Alternative Get Opt

ops = getopt(arg, "utwmva")
if ops["r"] then red = 1 else red = 0 end -- redirects
if ops["t"] then t = ops["t"] end -- time to pause
if ops["s"] then s = nil else s = true end -- stay in scope by default
if ops["w"] then w = ops["w"] end -- write to file
if ops["a"] then agent99 = ops["a"] else agent99 = "pillage-agent/1.0" end -- user agent
if ops["m"] then limit = tonumber(ops["m"]) end -- max urls to follow
if tonumber(ops["v"]) then verbose = tonumber(ops["v"]) else verbose = 0 end -- verbose/debug

if not ops["u"] or ops["h"] then 
    print("\npillage usage: ")
    print("\t-u\t - required: valid URL to crawl. http(s)://userid:password@www.attackersite.com:port")
    print("\t-r\t - optional: follow redirects (301 response).")
    print("\t-t\t - optional: time in milliseconds to pause between requests")
    print("\t-s\t - optional: do not stay within scope (this might crawl the world)")
    print("\t-w\t - optional: write to file in csv format. ./save.csv")
    print("\t-m\t - optional: max URLs to follow. default is never stop crawling until there are no more to crawl")
    print("\t-a\t - optional: user agent (pillage-agent/1.0 by default)")
    print("\t-c\t - optional: cookie storage (default cookiejar.txt)")
    print("\t-v\t - optional: verbosity. -v[1-3]")
    print("\t-h\t - optional: you're looking at it\n")
    print("example: ")
    print("\t" .. arg[0] .. " -u http://www.attackersite.com -r -s -a 'attacker-agent/1.0' -t 500 -m 100 -w ./attackersite-forms.csv -v1\n")
    os.exit()
else
    url = ops["u"]
end

print ("\nit begins...\n")

if string.starts(string.lower(url), "https://") then
    scheme = "https://"
elseif string.starts(string.lower(url),"http://") then
    scheme = "http://"
else
    print("hey! -u must be a url that starts with http:// or https://")
    print("\ndo-over\n")
    os.exit()
end
url_store = {url}
local ct = nil
if limit then
    if limit < 0 then
        io.write("hey! -c " .. c .. " was specified but that's not a valid max number or URLs. Continue without limmit? (Y/n)")
                local contc = io.read()
                if contc == "n" then
                        print("\ndo-over.\n")
                        os.exit()
                else
                        limit = nil
                end
    else
        ct = 0
    end
end
if w then
    fh = io.open(w, "w")
    fh:write("URL,Form\n")
end
for key,value in pairs(url_store) do
    -- start count for max urls to crawl
    if ct then
        ct = ct + 1
        if limit == ct then
            print("\nmax count reached :]\n")
            os.exit()
        end
    end
    -- start throttle
    if t then
        if tonumber(t) ~= nil then
            sleep(t)
        else
            io.write("hey! -t " .. t .. " was specified but that's not a valid time in milliseconds. Continue without throttleing? (Y/n)")
            local cont = io.read()
            if cont == "n" then
                print("\nthank you\n")
                os.exit()
            else
                t = nil
            end
        end
    end
    -- get page
    local cur_url=value
    page = getum(cur_url,red)
    if page == nil then
        print("Something went wrong. Not debuging.")
        os.exit()
    end
    if page ~= 0 then        
        -- find forms
        fnd = fform(cur_url)
        if fnd == nil then
            print("check: " .. value .. " \tno forms found")
        end
        -- find links
    local parsed_url = par_url.parse(cur_url)
        local base_url = parsed_url.scheme .. "://" .. parsed_url.authority
    furl(base_url,cur_url)
        page = nil
        fnd = nil
    end
end
if fh then
    fh:close()
end
print("\nEOF\n")
---------------------------
-- Script: pillage --
-- Version: 0.04
-- License: BSD Simplified
-- Author: Robert Gilbert - amroot.com
-- Current Release Date: April 10, 2013
-- Description: currently, pillage's only job is to find forms in web applications.  what someone does with those forms is up to them.
-- Future: Not sure. Debating parameter tampering but there's already tools for that.
-- If it can't improve on speed or reliability, that would be pointless. Given the name, it would be nice if it actually did pillage more than just forms. We'll see. 
--------------------------
-- Required: luasec
-- Debian prereq:
-- apt-get install lua5.1 liblua5.1-0-dev liblua5.1-socket-dev liblua5.1-sec-dev liblua5.1-curl-dev
--------------------------
-- Verson history:
--   0.0.4 - April 10, 2013:
--       Fixed error if -w is not specified
--       Merged includes into a single script
--   0.0.3 - June 25, 2012:
--       First release for public consumption
--------------------------
-- Short to do:
-- Form based Authentication.
-- Replace socket with regex
-- Threads - lots of threads
-- Update cookiejar
-- Better error handling and debugging
-- Submit forms for multi-stage form disc?
-- Do not add forms found previously
-- Find and log form fields 
-- Add the ability to supply a list of directories, pages, and/or URIs.
-------------------------
-- notes:
-- in before // is hierarchical and not part of the uri scheme
-------------------------
