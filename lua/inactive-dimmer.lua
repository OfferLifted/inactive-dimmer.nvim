-- dim_inactive.lua
local M = {}

-- default config
M.default_config = {
	dim_percentages = {
		background = 0.2, -- background colors
		foreground = 0.35, -- text colors
		syntax = 0.35, -- syntax highlighting
		ui = 0.35, -- UI elements like line numbers, status line, etc. ?
	},
	custom_groups = {},
	highlight_categories = {},
}

local inactive_highlights_cache = nil
local user_config = {}

local function dim_color(color, percentage)
	if not color then
		return nil
	end
	local r = tonumber(color:sub(2, 3), 16)
	local g = tonumber(color:sub(4, 5), 16)
	local b = tonumber(color:sub(6, 7), 16)

	r = math.floor(r * (1 - percentage))
	g = math.floor(g * (1 - percentage))
	b = math.floor(b * (1 - percentage))

	return string.format("#%02x%02x%02x", r, g, b)
end

-- determine which category a highlight group belongs to
local function get_highlight_category(group_name)
	-- user overrides
	if user_config.highlight_categories and user_config.highlight_categories[group_name] then
		return user_config.highlight_categories[group_name]
	end

	local hl_info = vim.api.nvim_get_hl(0, { name = group_name })
	if hl_info.link then
		return get_highlight_category(hl_info.link)
	end

	if hl_info.bg then
		return "background"
	elseif hl_info.fg then
		if hl_info.bold or hl_info.italic or hl_info.underline or hl_info.undercurl then
			return "syntax"
		else
			return "foreground"
		end
	else
		return "ui"
	end
end

-- get and dim all highlight groups
local function darken_all_highlights()
	if inactive_highlights_cache then
		return inactive_highlights_cache
	end

	local highlights = vim.api.nvim_get_hl(0, {})
	local winhighlight_parts = {}

	for group, attrs in pairs(highlights) do
		local category = get_highlight_category(group)
		local bg = attrs.bg and string.format("#%06x", attrs.bg)
		local fg = attrs.fg and string.format("#%06x", attrs.fg)

		-- custom groups
		local custom_percentage = user_config.custom_groups and user_config.custom_groups[group]

		local darker_bg, darker_fg

		if custom_percentage then
			-- custom dimming percentage
			darker_bg = bg and dim_color(bg, custom_percentage)
			darker_fg = fg and dim_color(fg, custom_percentage)
		elseif category == "background" then
			local percentage = user_config.dim_percentages and user_config.dim_percentages.background
				or M.default_config.dim_percentages.background
			darker_bg = bg and dim_color(bg, percentage)
			darker_fg = fg
		else
			local percentage = user_config.dim_percentages and user_config.dim_percentages[category]
				or M.default_config.dim_percentages[category]
			darker_bg = bg
			darker_fg = fg and dim_color(fg, percentage)
		end

		if darker_bg or darker_fg then
			local hl_attrs = {
				bold = attrs.bold,
				italic = attrs.italic,
				underline = attrs.underline,
				undercurl = attrs.undercurl,
				reverse = attrs.reverse,
				strikethrough = attrs.strikethrough,
				sp = attrs.sp,
			}

			if darker_bg then
				hl_attrs.bg = darker_bg
			end
			if darker_fg then
				hl_attrs.fg = darker_fg
			end

			vim.api.nvim_set_hl(0, group .. "Inactive", hl_attrs)
			table.insert(winhighlight_parts, group .. ":" .. group .. "Inactive")
		end
	end

	inactive_highlights_cache = table.concat(winhighlight_parts, ",")
	return inactive_highlights_cache
end

local function apply_dynamic_dimming()
	darken_all_highlights()

	local augroup = vim.api.nvim_create_augroup("DimInactive", { clear = true })

	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		group = augroup,
		callback = function()
			vim.wo.winhighlight = ""
		end,
	})

	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		group = augroup,
		callback = function()
			vim.wo.winhighlight = inactive_highlights_cache
		end,
	})

	-- trigger on colorscheme load
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = augroup,
		callback = function()
			-- reset cache on colorscheme changes
			inactive_highlights_cache = nil
			apply_dynamic_dimming()
		end,
	})
end

function M.setup(config)
	user_config = vim.tbl_deep_extend("force", M.default_config, config or {})
	apply_dynamic_dimming()
end

return M
