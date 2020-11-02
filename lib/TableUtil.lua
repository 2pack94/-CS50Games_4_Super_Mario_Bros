--[[
    A Collection of useful functions for table handling
]]

--[[
    check if a value exists in a table.
]]
function table.contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--[[
    Utility function for slicing tables, a la Python.
    https://stackoverflow.com/questions/24821045/does-lua-have-something-like-pythons-slice
]]
function table.slice(tbl, first, last, step)
    local sliced = {}
  
    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced+1] = tbl[i]
    end
  
    return sliced
end

--[[
    recursively deepcopy a table.
    the second argument 'copies' must not be supplied (must be nil)
    http://lua-users.org/wiki/CopyTable
]]
function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--[[
    Recursive table printing function.
    https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
]]
function print_r ( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

--[[
    quicksort: unstable, in-place, recursive
    https://www.geeksforgeeks.org/quick-sort/
    this quicksort implementation consists of the functions sortUnstableWithHelperTbl and _partitionUnstableWithHelperTbl
    unstable: no preservation of the relative order of elements in the case of equal values.
    in-place: The Algorithm only needs the input table itself to work (no additional table/ memory is needed)
    the elements in target_tbl are sorted according to the values in helper_tbl
    the element in target_tbl with the highest corresponding value in helper_tbl will be the last and vice versa
    target_tbl and helper_tbl are returned by reference
]]
local function _partitionUnstableWithHelperTbl(target_tbl, helper_tbl, low, high)
    -- pivot: Element to be placed at right position. left elements will be smaller, right elements will be bigger
    -- always choose last element as pivot
    local pivot = helper_tbl[high]
    -- Index where a smaller element shall be placed (initialized as 1 index smaller than the first element to compare)
    local i = low - 1

    for j = low, high - 1 do
        -- if current element is smaller than the pivot
        if helper_tbl[j] < pivot then
            i = i + 1
            -- no need to swap an element with itself (i is j until the first element does not meet the above comparison condition)
            if i ~= j then
                local tmp = helper_tbl[j]
                helper_tbl[j] = helper_tbl[i]
                helper_tbl[i] = tmp

                tmp = target_tbl[j]
                target_tbl[j] = target_tbl[i]
                target_tbl[i] = tmp
            end
        end
    end
    -- place pivot to its final and correct position
    local tmp = helper_tbl[high]
    helper_tbl[high] = helper_tbl[i + 1]
    helper_tbl[i + 1] = tmp

    tmp = target_tbl[high]
    target_tbl[high] = target_tbl[i + 1]
    target_tbl[i + 1] = tmp

    return i + 1
end

-- low: Starting index of (sub-)table
-- high: Ending index of (sub-)table
-- if low or high are not supplied (when invoking from extern), it will sort the whole table
function sortUnstableWithHelperTbl(target_tbl, helper_tbl, low, high)
    low = low or 1
    high = high or #target_tbl
    if low < high then
        -- part_i is partitioning index, tbl[part_i] is now at right place
        local part_i = _partitionUnstableWithHelperTbl(target_tbl, helper_tbl, low, high)

        -- sort left sub-table, before part_i
        sortUnstableWithHelperTbl(target_tbl, helper_tbl, low, part_i - 1)
        -- sort right sub-table, after part_i
        sortUnstableWithHelperTbl(target_tbl, helper_tbl, part_i + 1, high)
    end
end

--[[
    same as above, just sort in reverse order
    the element in target_tbl with the lowest corresponding value in helper_tbl will be the last and vice versa
]]
local function _partitionReverseUnstableWithHelperTbl(target_tbl, helper_tbl, low, high)
    local pivot = helper_tbl[high]
    local i = low - 1

    for j = low, high - 1 do
        if helper_tbl[j] > pivot then
            i = i + 1
            if i ~= j then
                local tmp = helper_tbl[j]
                helper_tbl[j] = helper_tbl[i]
                helper_tbl[i] = tmp

                tmp = target_tbl[j]
                target_tbl[j] = target_tbl[i]
                target_tbl[i] = tmp
            end
        end
    end
    local tmp = helper_tbl[high]
    helper_tbl[high] = helper_tbl[i + 1]
    helper_tbl[i + 1] = tmp

    tmp = target_tbl[high]
    target_tbl[high] = target_tbl[i + 1]
    target_tbl[i + 1] = tmp

    return i + 1
end

function sortReverseUnstableWithHelperTbl(target_tbl, helper_tbl, low, high)
    low = low or 1
    high = high or #target_tbl
    if low < high then
        local part_i = _partitionReverseUnstableWithHelperTbl(target_tbl, helper_tbl, low, high)
        sortReverseUnstableWithHelperTbl(target_tbl, helper_tbl, low, part_i - 1)
        sortReverseUnstableWithHelperTbl(target_tbl, helper_tbl, part_i + 1, high)
    end
end

--[[
    quicksort: stable, out-of-place, recursive
    https://www.geeksforgeeks.org/stable-quicksort/
    stable: preservation of the relative order of elements in the case of equal values.
    out-of-place: The Algorithm needs additional table(s) for storing intermediate results to work
    This implementation is about factor 10 slower with random input and
    about factor 10 faster with (almost) sorted/ reverse sorted input than the unstable quicksort.
    the elements in target_tbl are sorted according to the values in helper_tbl
    the element in target_tbl with the highest corresponding value in helper_tbl will be the last and vice versa
    return: sorted target_tbl, helper_tbl
]]
function sortStableWithHelperTbl(target_tbl, helper_tbl)
    if #target_tbl < 2 then
        -- last step in decomposing the tables
        return target_tbl, helper_tbl
    else
        -- use middle element as pivot
        -- always execute the same actions for helper_tbl and target_tbl (variables with suffix _h and _t)
        local mid = math.ceil(#target_tbl / 2)
        local pivot_h = helper_tbl[mid]
        local pivot_t = target_tbl[mid]

        -- put elements smaller than the pivot into "smaller"
        -- put elements that are bigger than pivot into "greater"
        local smaller_h, greater_h = {}, {}
        local smaller_t, greater_t = {}, {}

        for i = 1, #target_tbl do
            if i ~= mid then
                if helper_tbl[i] < pivot_h then
                    table.insert(smaller_h, helper_tbl[i])
                    table.insert(smaller_t, target_tbl[i])
                elseif helper_tbl[i] > pivot_h then
                    table.insert(greater_h, helper_tbl[i])
                    table.insert(greater_t, target_tbl[i])
                -- If value is same, then consider position to decide the list.
                -- this is important to achieve stability
                else
                    if i < mid then
                        table.insert(smaller_h, helper_tbl[i])
                        table.insert(smaller_t, target_tbl[i])
                    else
                        table.insert(greater_h, helper_tbl[i])
                        table.insert(greater_t, target_tbl[i])
                    end
                end
            end
        end
        -- recursively sort "smaller" and "greater" tables
        -- construct the table {smaller + pivot + greater}
        local ret_tbl_t, ret_tbl_h = sortStableWithHelperTbl(smaller_t, smaller_h)
        local ret_tbl_tmp_t, ret_tbl_tmp_h = sortStableWithHelperTbl(greater_t, greater_h)
        table.insert(ret_tbl_h, pivot_h)
        table.insert(ret_tbl_t, pivot_t)
        table.extend(ret_tbl_h, ret_tbl_tmp_h)
        table.extend(ret_tbl_t, ret_tbl_tmp_t)

        return ret_tbl_t, ret_tbl_h
    end
end

--[[
    same as above, just sort in reverse order
    the element in target_tbl with the lowest corresponding value in helper_tbl will be the last and vice versa
    return: reverse sorted target_tbl, helper_tbl
]]
function sortReverseStableWithHelperTbl(target_tbl, helper_tbl)
    if #target_tbl < 2 then
        return target_tbl, helper_tbl
    else
        local mid = math.ceil(#target_tbl / 2)
        local pivot_h = helper_tbl[mid]
        local pivot_t = target_tbl[mid]

        local smaller_h, greater_h = {}, {}
        local smaller_t, greater_t = {}, {}

        for i = 1, #target_tbl do
            if i ~= mid then
                if helper_tbl[i] < pivot_h then
                    table.insert(smaller_h, helper_tbl[i])
                    table.insert(smaller_t, target_tbl[i])
                elseif helper_tbl[i] > pivot_h then
                    table.insert(greater_h, helper_tbl[i])
                    table.insert(greater_t, target_tbl[i])
                else
                    if i < mid then
                        table.insert(greater_h, helper_tbl[i])
                        table.insert(greater_t, target_tbl[i])
                    else
                        table.insert(smaller_h, helper_tbl[i])
                        table.insert(smaller_t, target_tbl[i])
                    end
                end
            end
        end
        local ret_tbl_t, ret_tbl_h = sortReverseStableWithHelperTbl(greater_t, greater_h)
        local ret_tbl_tmp_t, ret_tbl_tmp_h = sortReverseStableWithHelperTbl(smaller_t, smaller_h)
        table.insert(ret_tbl_h, pivot_h)
        table.insert(ret_tbl_t, pivot_t)
        table.extend(ret_tbl_h, ret_tbl_tmp_h)
        table.extend(ret_tbl_t, ret_tbl_tmp_t)

        return ret_tbl_t, ret_tbl_h
    end
end
