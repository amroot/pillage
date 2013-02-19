-- these wonderful functions were obtained from:
-- http://lua-users.org/wiki/SampleCode

function to_string(tbl)
    if "nil" == type( tbl ) then
        return tostring('')
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
end

