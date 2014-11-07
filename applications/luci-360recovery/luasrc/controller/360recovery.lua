--[[
360recovery Luci configuration page.Made by 981213
]]--

module("luci.controller.360recovery", package.seeall)

function index()
	
	local page
	page = entry({"admin", "system", "360recovery"}, call("action_360recovery"), _("刷写360加密固件"), 45)
	page.dependent = true
end

function action_360recovery()
	local sys = require "luci.sys"
	local fs  = require "luci.fs"

	local upgrade_avail = nixio.fs.access("/lib/upgrade/platform.sh")
	local reset_avail   = os.execute([[grep '"rootfs_data"' /proc/mtd >/dev/null 2>&1]]) == 0

	local restore_cmd = "tar -xzC/ >/dev/null 2>&1"
	local backup_cmd  = "sysupgrade --create-backup - 2>/dev/null"
	local image_tmp   = "/tmp/firmware_encrypted.img"
	local image_tmp_dec   = "/tmp/firmware_decrypted.img"

	local function image_supported()
		-- XXX: yay...
		return ( 0 == os.execute(
			"rom_decrypt "..image_tmp.." "..image_tmp_dec.." 2>&1 > /dev/null"
		) )
	end

	local function image_checksum()
		return (luci.sys.exec("md5sum %q" % image_tmp):match("^([^%s]+)"))
	end

	local function storage_size()
		local size = 0
		if nixio.fs.access("/proc/mtd") then
			for l in io.lines("/proc/mtd") do
				local d, s, e, n = l:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+"([^%s]+)"')
				if n == "linux" or n == "firmware" then
					size = tonumber(s, 16)
					break
				end
			end
		elseif nixio.fs.access("/proc/partitions") then
			for l in io.lines("/proc/partitions") do
				local x, y, b, n = l:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
				if b and n and not n:match('[0-9]') then
					size = tonumber(b) * 1024
					break
				end
			end
		end
		return size
	end


	local fp
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not fp then
				fp = io.open(image_tmp, "w")
			end
			if chunk then
				fp:write(chunk)
			end
			if eof then
				fp:close()
			end
		end
	)

	if luci.http.formvalue("image") or luci.http.formvalue("step") then
		--
		-- Initiate firmware flash
		--
		local step = tonumber(luci.http.formvalue("step") or 1)
		if step == 1 then
			if image_supported() then
				luci.template.render("360recovery_upgrade", {
					checksum = image_checksum(),
					storage  = storage_size(),
					size     = nixio.fs.stat(image_tmp).size,
				})
			else
				nixio.fs.unlink(image_tmp)
				luci.template.render("360recovery", {
					reset_avail   = reset_avail,
					upgrade_avail = upgrade_avail,
					image_invalid = true
				})
			end
		--
		-- Start sysupgrade flash
		--
		elseif step == 2 then
			luci.template.render("admin_system/applyreboot", {
				title = luci.i18n.translate("Flashing..."),
				msg   = luci.i18n.translate("The system is flashing now.<br /> DO NOT POWER OFF THE DEVICE!<br /> Wait a few minutes before you try to reconnect. It might be necessary to renew the address of your computer to reach the device again, depending on your settings."),
				addr  = "192.168.1.1"
			})
			os.execute("killall uhttpd dropbear && sleep 1 && mtd -r write "..image_tmp_dec.." firmware && reboot &")
		end
	else
		--
		-- Overview
		--
		luci.template.render("360recovery", {
			reset_avail   = reset_avail,
			upgrade_avail = upgrade_avail
		})
	end
end

