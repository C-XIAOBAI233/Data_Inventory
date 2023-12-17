lib={}

function lib.get_timestamp()
	return os.time(os.date('*t'))
end

function lib.merge_tables(orig, new)
	local merge_task = {}
	merge_task[orig] = new

	local left = orig
	while left ~= nil do
		local right = merge_task[left]
		for new_key, new_val in pairs(right) do
			local old_val = left[new_key]
			if old_val == nil then
				left[new_key] = new_val
			else
				local old_type = type(old_val)
				local new_type = type(new_val)
				if (old_type =="table" and new_type =="table") then
					merge_task[old_val] = new_val
				else
					left[new_key] = new_val
				end
			end
		end
		merge_task[left] = nil
		left = next(merge_task)
	end
end

return lib
