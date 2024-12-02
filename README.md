# inactive-dimmer.nvim

A Neovim plugin that dynamically dims inactive windows to keep focus on the active one.
It adjusts the brightness of various UI elements, syntax highlighting, and background colors in inactive windows.
It gets the applied colorscheme colors and darkens them by the specified percentage where 1.0 is completely blacked out.

## Features

- **Dynamic Dimming**: Automatically dims inactive windows and restores brightness when they become active.
- **Customizable Dimming Levels**: Adjust dimming percentages for different highlight categories.
- **User-Defined Highlight Groups**: Specify custom highlight groups with their own dimming settings.
- **Flexible Configuration**: Override default highlight group categories as needed.
- **Colorscheme Friendly**: Respects your current colorscheme and updates on colorscheme changes.

## Installation

Use your favorite plugin manager to install `inactive-dimmer.nvim`.

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
	"OfferLifted/inactive-dimmer.nvim",
	event = "VimEnter",

	opts = {
		dim_percentages = {
			background = 0.25,
			foreground = 0.35,
			syntax = 0.35,
			ui = 0.35,
		},
		custom_groups = {
			-- add any custom highlight groups you want to dim differently
			-- example to dim 'Comment' by 0.5:
			-- ["Comment"] = 0.5,
		},
		highlight_categories = {
			-- override category classification for specific highlight groups
			-- example to put 'Comment' under 'syntax':
			-- ["Comment"] = "syntax",
		},
	},
}

```
