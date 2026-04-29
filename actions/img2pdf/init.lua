local M = {}

--luacheck: ignore output err
function M.init(_, opts)
	local output, err = Command("which"):arg("magick"):output()

	if not output.status.success then
		ya.notify({
			title = "ImageMagick Required",
			content = "This action requires ImageMagick. Please install it to continue.",
			timeout = 6.0,
			level = "warn",
		})
		return
	end

	local output_name, input_event = ya.input({
		title = "Output PDF filename",
		value = "output.pdf",
		pos = {
			"top-center",
			y = 1,
			w = 40,
		},
	})

	if input_event ~= 1 then return end

	if not output_name or output_name == "" then
		output_name = "output.pdf"
	end

	if not output_name:match("%.pdf$") then
		output_name = output_name .. ".pdf"
	end

	-- stylua: ignore
	output, err = Command("./img2pdf.sh")
		:cwd(opts.workpath)
		:env("output_name", output_name)
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
			title = "Images to PDF",
			content = "Created: " .. output_name,
			timeout = 5.0,
			level = "info",
		})
	else
		local err_msg = (output and output.stderr ~= "") and output.stderr or "Conversion failed."
		ya.notify({
			title = "Images to PDF Failed",
			content = err_msg,
			timeout = 6.0,
			level = "error",
		})
	end
end

return M
