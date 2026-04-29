Popup = {
	Key = {
		cands = {
			{ on = "j", desc = "Next item" },
			{ on = "<Down>", desc = "Next item" },
			{ on = "k", desc = "Previous item" },
			{ on = "<Up>", desc = "Previous item" },
			{ on = "G", desc = "Last item" },
			{ on = "g", desc = "First item" },
			{ on = "<Esc>", desc = "Cancel" },
			{ on = "<Enter>", desc = "Confirm" },
		},
		key_to_action = {
			[1] = "next", -- on = "j"
			[2] = "next", -- on = "<Down>"
			[3] = "prev", -- on = "k"
			[4] = "prev", -- on = "<up>"
			[5] = "last", -- on = "G"
			[6] = "first", -- on = "gg"
			[7] = "cancel", -- on = "<Esc>"
			[8] = "confirm", -- on = "<Enter>"
		},
	},
}

Popup.Menu = {
	_id = "file-actions",
}

function Popup.Menu:new(area)
	--- UI entry point
	--- https://github.com/sxyazi/yazi/pull/2205
	self._area = Popup.center_layout(area, self._popup_height)
	return self
end

function Popup.Menu:reflow()
	--- https://github.com/sxyazi/yazi/pull/2205
	return { self }
end

function Popup.Menu:redraw()
	--- https://github.com/sxyazi/yazi/pull/2205
	return self.render(self._area, self._popup_items, self._popup_cursor)
end

function Popup.Menu:init(item_list, around, onConfirm, onCancel)
	--- Initialize object
	local newObj = {
		-- Scroll offset: number of reserved rows above and below the cursor
		scroll_offset = 3,
		-- Maximum number of items in the display window
		window_size = 10,
		-- Wrap/around mode
		around = around or false,
		-- Menu items
		item_list = item_list,
		-- Execute this on confirm
		onConfirm = onConfirm or function(cursor)
			return cursor
		end,
		-- Execute this on cancel
		onCancel = onCancel or function()
			return
		end,
	}
	self.__index = self
	return setmetatable(newObj, self)
end

local miscellaneous = ya.sync(function()
	--- Miscellaneous
	local result = {}
	-- File under cursor
	result.cursor_files = {}
	local hovered = cx.active.current.hovered
	-- No file under cursor when folder is empty
	if hovered and not hovered.url.is_archive then
		table.insert(result.cursor_files, tostring(cx.active.current.hovered.url))
	end

	-- Selected files
	result.selected_files = {}
	for _, url in pairs(cx.active.selected) do
		if not url.is_archive then
			table.insert(result.selected_files, tostring(url))
		end
	end
	-- Action script path
	result.actions_path = string.format("%s/.config/yazi/plugins/file-actions.yazi/actions", os.getenv("HOME"))
	return result
end)

function Popup.center_layout(area, height)
	-- Return rect centered in parent area
	-- height: window area height
	local r = rt.mgr.ratio
	--luacheck: ignore parent_layout preview_layout
	local parent_layout, current_layout, preview_layout = table.unpack(ui
		.Layout()
		-- Layout defined in config file
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Ratio(r.parent, r.all),
			ui.Constraint.Ratio(r.current, r.all),
			ui.Constraint.Ratio(r.preview, r.all),
		})
		:split(area))
	--luacheck: ignore left_margin right_margin
	local left_margin, centered_content_layout, right_margin = table.unpack(ui
		.Layout()
		-- Left, center, right
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Ratio(1, 6),
			ui.Constraint.Ratio(4, 6),
			ui.Constraint.Ratio(1, 6),
		})
		:split(current_layout))

	--luacheck: ignore top_margin bottom_margin
	local top_margin, centered_ontent = table.unpack(ui
		.Layout()
		-- Top and center, no bottom
		:direction(ui.Layout.VERTICAL)
		:constraints({
			ui.Constraint.Length(1),
			ui.Constraint.Length(height + 2), -- Window height plus padding
		})
		:split(centered_content_layout))

	return centered_ontent
end

function Popup.Menu.render(area, items, cursor)
	-- area : rect
	-- items : menu items
	-- cursor : cursor position in window
	local list_items = {}
	for i, item in ipairs(items) do
		list_items[#list_items + 1] = ui.Line(item):style(i == cursor and th.indicator.current or nil)
	end
	return {
		-- Clear area
		ui.Clear(area),
		-- Border
		ui.Border(ui.Edge.ALL):area(area):type(ui.Border.ROUNDED):style(th.mgr.border_style),
		-- List
		ui.List(list_items):area(area:pad(ui.Pad.xy(1, 1))),
	}
end

Popup.Menu.draw_popup = ya.sync(function(self, display, height, items, cursor)
	-- Draw window
	-- display : draw the window?
	-- height : window height
	-- items : menu items
	-- cursor : cursor position in window

	Popup.Menu._popup_height = display and height or nil
	Popup.Menu._popup_items = display and items or nil
	Popup.Menu._popup_cursor = display and cursor or nil

	if display then
		self.children = self.children or Modal:children_add(Popup.Menu, 10)
	else
		Modal:children_remove(self.children)
		self.children = nil
	end
	ui.render()
end)

function Popup.Menu:show()
	-- Display range start
	local window_start = 1
	-- Window height
	local window_height = math.min(self.window_size, #self.item_list)
	-- Display range end - use smaller window if fewer items
	local window_end = window_height
	-- Cursor position within window
	local window_cursor = 1
	-- Actual cursor position
	local cursor = 1
	while true do
		-- Draw window
		Popup.Menu.draw_popup(
			true,
			window_height,
			{ table.unpack(self.item_list, window_start, window_end) },
			window_cursor
		)

		-- Get input
		local key = ya.which({ cands = Popup.Key.cands, silent = true })
		local key_action = Popup.Key.key_to_action[key]

		::handle_key_action::
		-- Adjust cursor position or window display range based on action
		if key_action == "next" then
			-- Cursor can move down before reaching boundary
			-- Or cursor can move down if window has scrolled to bottom
			if window_cursor < (window_height - self.scroll_offset) or window_end == #self.item_list then
				-- Wrap mode
				if self.around and window_cursor == window_height then
					key_action = "first" -- Jump to top
					goto handle_key_action
				else
					-- Ensure within bounds
					window_cursor = math.min(window_cursor + 1, window_height)
					cursor = math.min(cursor + 1, #self.item_list)
				end
			-- Scroll content when reaching boundary (adjust sliding window)
			-- Scrolling to bottom moves cursor, no need to worry about window continuing to slide
			elseif window_cursor == (window_height - self.scroll_offset) then
				window_start = window_start + 1
				window_end = window_end + 1
				cursor = cursor + 1
			end
		-- Cursor can move up before reaching boundary
		-- Or cursor can move up if window has scrolled to top
		elseif key_action == "prev" then
			if window_cursor > (1 + self.scroll_offset) or window_start == 1 then
				-- Wrap mode
				if self.around and window_cursor == 1 then
					key_action = "last" -- Jump to bottom
					goto handle_key_action
				else
					-- Ensure within bounds
					window_cursor = math.max(window_cursor - 1, 1)
					cursor = math.max(cursor - 1, 1)
				end
			-- Scroll content when reaching boundary (adjust sliding window)
			-- Scrolling to top moves cursor, no need to worry about window continuing to slide
			elseif window_cursor == (1 + self.scroll_offset) then
				window_start = window_start - 1
				window_end = window_end - 1
				cursor = cursor - 1
			end
		elseif key_action == "last" then -- Jump to bottom
			window_cursor = window_height
			window_start = #self.item_list - window_height + 1
			window_end = #self.item_list
			cursor = #self.item_list
		elseif key_action == "first" then -- Jump to top
			window_cursor = 1
			window_start = 1
			window_end = window_height
			cursor = 1
		elseif key_action == "confirm" then -- Confirm
			-- Restore interface
			Popup.Menu.draw_popup(false)
			self.onConfirm(cursor)
			break
		elseif key_action == "cancel" or key_action == nil then -- Cancel or undefined input
			-- Restore interface
			Popup.Menu.draw_popup(false)
			self.onCancel()
			break
		end
	end
end

local entry = function(_, job)
	-- Plugin parameters
	local flags = { around = false, debug = false }
	for k, v in pairs(job.args) do
		flags[k] = v
	end

	local sync_state = miscellaneous()
	-- No file selected and no file under cursor
	if #sync_state.cursor_files == 0 and #sync_state.selected_files == 0 then
		return
	end

	-- No file selected, use file under cursor
	if #sync_state.selected_files == 0 then
		sync_state.selected_files = sync_state.cursor_files
	end

	-- Get file MIME type
	local selected_mimetype_set = {}
	-- stylua: ignore
	local file_child, file_err = Command("file")
		:arg({ "-bL", "--mime-type" })
		:arg(sync_state.selected_files)
		:stdout(Command.PIPED)
		:spawn()

	if flags.debug and file_err then
		ya.err("file_err:" .. tostring(file_err))
	end

	while true do
		local line, event = file_child:read_line()
		if event == 0 then
			local mimetype = string.gsub(line, "%s$", "")
			selected_mimetype_set[mimetype] = true
		elseif event == 2 then
			break
		end
	end


	-- Get action list
	-- stylua: ignore
	local action_child, action_err = Command("sh")
		:cwd(ya.quote(sync_state.actions_path))
		:arg({"-c","ls -d */" })
		:stdout(Command.PIPED)
		:spawn()

	if flags.debug and action_err then
		ya.err("action_err:" .. tostring(action_err))
	end

	local action_paths = {}
	local action_names = {}
	while true do
		local line, event = action_child:read_line()
		if event == 0 then
			local action_path = string.gsub(line, "/%s$", "")
			-- Load action script configuration
			local action_config = dofile(string.format("%s/%s/info.lua", sync_state.actions_path, action_path))
			-- Single file
			if action_config.single_or_multi == "single" and #sync_state.selected_files ~= 1 then
				goto continue_get_action
			end
			-- Multiple files
			if action_config.single_or_multi == "multi" and #sync_state.selected_files == 1 then
				goto continue_get_action
			end
			-- Check disallowed MIME types
			if action_config.disableMimes ~= nil then
				for _, mimetype in pairs(action_config.disableMimes) do
					if selected_mimetype_set[mimetype] then
						-- Skip directly
						goto continue_get_action
					end
				end
			end
			-- Check allowed MIME type list - exists and not empty
			if action_config.enableMimes ~= nil and #action_config.enableMimes ~= 0 then
				-- Convert allowed table to set for quick lookup
				local enableMimes_set = {}
				for _, mimetype in pairs(action_config.enableMimes) do
					enableMimes_set[mimetype] = true
				end
				for selected_mimetype in pairs(selected_mimetype_set) do
					-- File MIME is outside allowed range
					if not enableMimes_set[selected_mimetype] then
						goto continue_get_action
					end
				end
			end
			-- No allow list or all selected files are within allowed range - add directly
			table.insert(action_names, action_config.name)
			table.insert(action_paths, action_path)
		elseif event == 2 then
			break
		end
		::continue_get_action::
	end

	-- Action list is empty
	if #action_paths == 0 then
		ya.notify({
			title = "Action Script Not Found ",
			content = "No action script available for this file type.",
			timeout = 6.0,
			level = "warn",
		})
		return
	end

	local onConfirm = function(cursor)
		local mod = dofile(string.format("%s/%s/init.lua", sync_state.actions_path, action_paths[cursor]))
		mod:init({
			-- Script working directory
			workpath = sync_state.actions_path .. "/" .. action_paths[cursor],
			-- Selected files
			selected = sync_state.selected_files,
			-- Plugin parameters
			flags = flags,
		})
	end

	local menu = Popup.Menu:init(action_names, flags.around, onConfirm)
	menu:show()
end

return { entry = entry }
