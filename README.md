# file-actions.yazi

> **Original code:** [BBOOXX/file-actions.yazi](https://github.com/BBOOXX/file-actions.yazi)

a file action script plugin for [Yazi](https://github.com/sxyazi/yazi) that allows users to pass selected files into action scripts to perform corresponding actions on the files.

> [!NOTE]
> The latest main branch of Yazi is required at the moment.

## Installation
On **Linux** and **Mac**, install **file-actions.yazi** using the following command:
```sh
git clone https://github.com/tasnimAlam/file-actions.yazi.git ~/.config/yazi/plugins/file-actions.yazi
```
or 

```sh
ya pkg -a tasnimAlam/file-actions
```


## Configuration
```toml
# keymap.toml
[[mgr.prepend_keymap]]
on = [ "F" ]
run = "plugin file-actions -- --around "
desc= "Perform actions on selected files"

```

## Action Script Setup
To set up an action script, create a new folder within the actions directory, ensuring it contains both `init.lua` and `info.lua` files.

### info.lua
The `info.lua` file describes the action script. Here’s the basic format:
```lua
local config = {
	name = "Script Name",   -- Name of the script
	enableMimes = {},       -- Supported file mimes by the script
	disableMimes = {},      -- Unsupported file mimes by the script
	single_or_multi = "",   -- Script to support either "single" or "multi" file, or both.
}
return config
```

### init.lua
The `init.lua` file contains the main logic of the script. Here’s an example:
```lua
local M = {}

--luacheck: ignore output err
function M.init(_, opts)
	-- stylua: ignore
	-- The script here won't work without "./"
	-- The script file must have execution permissions
	local output, err = Command("./blablabla.sh")
		:cwd(opts.workpath) -- Enter the directory of the action plugin
		-- To avoid issues with spaces in filenames, here we use Tab to separate
		-- Therefore, in the script file, it must declare IFS=$'\t'
		:env("selection", table.concat(opts.selected, "\t"))
		:output()

	-- For detailed usage of the 'output' and 'err' variables,
	-- please refer to: https://yazi-rs.github.io/docs/plugins/utils#output
end

return M
```

### Execution Script Example

```bash
#!/usr/bin/env bash
set -e
IFS=$'\t'
# Setting the Internal Field Separator (IFS) to a tab character to handle file names with spaces.

OS="$(uname -s)"
case "$OS" in
	Darwin) echo "Mac" ;;
	Linux) echo "Linux" ;;
	*) echo "Unsupported operating system"; exit 1 ;;
esac

# Loop through the list of selected files.
for file in ${selection}; do
	echo "$file"
done
```

This script is a basic template and should be modified according to the specific needs of your action scripts. Make sure to test the script in your environment before using it in production.

### Directory Structure
```
~/.config/yazi/
├── init.lua
├── plugins/
│   └── file-actions.yazi/
│       ├── init.lua
│       └── actions/
│           ├── action1/
│           │   ├── init.lua
│           │   ├── info.lua
│           │   └── blabla.sh
│           └── action2/
│               ├── init.lua
│               ├── info.lua
│               └── blabla.sh
└── yazi.toml
```
