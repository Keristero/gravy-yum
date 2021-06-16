local helpers = {}

function Split(string,delimiter)
    local table = {}
    for tag, line in string:gmatch('([^'..delimiter..']+)') do
        table[#table+1] = tag
    end
    return table
end

function helpers.split(str,delimiter)
    return ( Split(str,delimiter) )
end

return helpers