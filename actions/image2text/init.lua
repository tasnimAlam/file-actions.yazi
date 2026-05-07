local M = {}

--luacheck: ignore output err
function M.init(_, opts)
	local output, err = Command("which"):arg("tesseract"):output()

	if not output.status.success then
		ya.notify({
			title = "Tesseract Required",
			content = "This action requires Tesseract OCR. Please install it to continue.",
			timeout = 6.0,
			level = "warn",
		})
		return
	end

	-- stylua: ignore
	output, err = Command("./image2text.sh")
		:cwd(opts.workpath)
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
			title = "Image to Text",
			content = output.stdout ~= "" and output.stdout or "OCR complete.",
			timeout = 5.0,
			level = "info",
		})
	else
		local err_msg = (output and output.stderr ~= "") and output.stderr or "OCR failed."
		ya.notify({
			title = "Image to Text Failed",
			content = err_msg,
			timeout = 6.0,
			level = "error",
		})
	end
end

return M
