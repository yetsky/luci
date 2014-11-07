--[[
--gogoCLIENT configuration page. Made by 981213
--
]]--

local fs = require "nixio.fs"
local uci = luci.model.uci.cursor_state()
local net = require "luci.model.network"

m = Map("gw6c", translate("gogoCLIENT"),
        translatef("The gogoCLIENT™ is a ubiquities IP app that provides full IP connectivity regardless of the underlying protocol. It has a small footprint and can easily be integrated in devices to provide full compatibility with IPv6 or to provide IPv6 or IPv4 connectivity."))
net = net.init(m.uci)

basic = m:section(TypedSection, "basic", translate("Basic Settings"))

switch = basic:option(Flag, "disabled", translate("Disabled"))
function switch.write(self, section, value)
	os.execute("/etc/init.d/gw6c restart &")
	Flag.write(self, section, value)
end

userid = basic:option(Value, "userid", translate("User Name"))
passwd = basic:option(Value, "passwd", translate("Password"), translate("Leave empty if connecting anonymously."))

server = basic:option(Value, "server", translate("Server Address"))
server.optional = false

auth_method = basic:option(ListValue, "auth_method", translate("Authentication Method"),translate("Use anonymous with anonymous access and any if you are account holder"))
auth_method:value("anonymous")
auth_method:value("any")
auth_method:value("passds-3des-1")
auth_method:value("digest-md5")
auth_method:value("plain")

routing = m:section(TypedSection, "routing", translate("Routing Settings"))

host_type = routing:option(ListValue, "host_type", translate("Host Type"))
host_type:value("host")
host_type:value("router")

routing:option(Value, "prefixlen", translate("Prefix Length"))
ifprefix = routing:option(Value, "ifprefix", translate("Interface"), translate("Specifies the interface to podcast IPv6 Address"))
ifprefix.template = "cbi/network_netlist"
ifprefix.nocreate = true
ifprefix.unspecified = false

routing:option(Value, "dns_server", translate("DNS Server(s)"),translate("DNS server list to which the reverse prefix will be delegated. Separate servers with : ."))

return m


