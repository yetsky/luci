--[[
gogoCLIENT Luci configuration page.Made by 981213
]]--

module("luci.controller.gw6c", package.seeall)

function index()
	
	if not nixio.fs.access("/etc/config/gw6c") then
		return
	end

	local page
	page = entry({"admin", "network", "gw6c"}, cbi("gw6c"), _("gogoCLIENT"), 45)
	page.dependent = true
end
