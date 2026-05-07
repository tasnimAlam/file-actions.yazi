local M = {}

--luacheck: ignore output err
function M.init(_, opts)
	local output, err = Command("which"):arg("ffmpeg"):output()

	if not output.status.success then
		ya.notify({
			title = "FFmpeg Required",
			content = "This action requires FFmpeg. Please install it to continue.",
			timeout = 6.0,
			level = "warn",
		})
		return
	end

	local width, input_event = ya.input({
		title = "Width in px (-1 = original)",
		value = "-1",
		pos = { "top-center", y = 1, w = 25 },
	})
	if input_event ~= 1 then return end

	-- stylua: ignore
	output, err = Command("./video2gif.sh")
		:cwd(opts.workpath)
		:env("fps", "15")
		:env("width", width ~= "" and width or "-1")
		:env("selection", table.concat(opts.selected, "\t"))
		:output()

	if opts.flags.debug then
		ya.err("====debug info====")
		if err ~= nil then
			ya.err("err:" .. tostring(err))
		else
			ya.err("OK? :" .. tostring(output.status.success))
			ya.err("Code:" .. tostring(output.status.code))
			ya.err("stdout:" .. output.stdout)
			ya.err("stderr:" .. output.stderr)
		end
	end

	if output and output.status.success then
		ya.notify({
			title = "Video to GIF",
			content = output.stdout ~= "" and output.stdout or "Conversion complete.",
			timeout = 5.0,
			level = "info",
		})
	else
		local err_msg = (output and output.stderr ~= "") and output.stderr or "Conversion failed."
		ya.notify({
			title = "Video to GIF Failed",
			content = err_msg,
			timeout = 6.0,
			level = "error",
		})
	end
end

return M
