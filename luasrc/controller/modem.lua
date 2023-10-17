module("luci.controller.modem", package.seeall)

function index()
	entry({"admin", "modem"}, firstchild(), _("蜂窝"), 25).dependent=false
	entry({"admin", "modem", "nets"}, template("zmode/net_status"), _("信号状态"), 97)
	entry({"admin", "modem", "at"}, template("zmode/at"), _("调试工具"), 98)
	entry({"admin", "modem", "modem"}, cbi("modem"), _("模块设置"), 99) 
	entry({"admin", "modem", "get_csq"}, call("action_get_csq"))
	entry({"admin", "modem", "send_atcmd"}, call("action_send_atcmd"))
end

function action_send_atcmd()
	local rv ={}
	local file
	local p = luci.http.formvalue("p")
	local set = luci.http.formvalue("set")
	fixed = string.gsub(set, "\"", "~")
	port= string.gsub(p, "\"", "~")
	rv["at"] = fixed 
	rv["port"] = port

	os.execute("/usr/share/modem/atcmd.sh \'" .. port .. "\' \'" .. fixed .. "\'")
	result = "/tmp/result.at"
	file = io.open(result, "r")
	if file ~= nil then
		rv["result"] = file:read("*all")
		file:close()
	else
		rv["result"] = " "
	end
	os.execute("/usr/share/modem/delatcmd.sh")
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)

end

function action_get_csq()
	os.execute("/usr/share/modem/zinfo.sh")
	local file
	stat = "/tmp/cpe_cell.file"
	file = io.open(stat, "r")
	local rv ={}

	-- echo 'RM520N-GL'
	-- echo 'conntype'
	-- echo '1e0e:9001'
	-- echo $COPS #运营商
	-- echo '' #端口
	-- echo '' #温度
	-- echo '' #协议 
    rv["modem"] = file:read("*line")
	rv["conntype"] = file:read("*line")
	rv["date"] = file:read("*line")
	rv["modid"] = file:read("*line")
	rv["simsel"] = file:read("*line")
	rv["cops"] = file:read("*line")
	rv["port"] = file:read("*line")
	rv["tempur"] = file:read("*line")
	rv["proto"] = file:read("*line")
	file:read("*line")


	-- echo $IMEI #imei
	-- echo $IMSI #imsi
	-- echo $ICCID #iccid
	-- echo $phone #phone
	rv["imei"] = file:read("*line")
	rv["imsi"] = file:read("*line")
	rv["iccid"] =file:read("*line")
	rv["phone"] = file:read("*line")
	file:read("*line")


	-- echo $MODE
	-- echo $CSQ
	-- echo $CSQ_PER
	-- echo $CSQ_RSSI
	-- echo '' #参考信号接收质量 RSRQ ecio
	-- echo '' #参考信号接收质量 RSRQ ecio1
	-- echo '' #参考信号接收功率 RSRP rscp
	-- echo '' #参考信号接收功率 RSRP rscp1
	-- echo '' #信噪比 SINR  rv["sinr"]
	-- echo '' #连接状态监控 rv["netmode"]
	rv["mode"] = file:read("*line")
	rv["csq"] = file:read("*line")
	rv["per"] = file:read("*line")
	rv["rssi"] = file:read("*line")
	rv["ecio"] = file:read("*line")
	rv["ecio1"] = file:read("*line")
	rv["rscp"] = file:read("*line")
	rv["rscp1"] = file:read("*line")
	rv["sinr"] = file:read("*line")
	rv["netmode"] = file:read("*line")
	file:read("*line")
	
	rssi = rv["rssi"]
	ecio = rv["ecio"]
	rscp = rv["rscp"]
	ecio1 = rv["ecio1"]
	rscp1 = rv["rscp1"]
	if ecio == nil then
		ecio = "-"
	end
	if ecio1 == nil then
		ecio1 = "-"
	end
	if rscp == nil then
		rscp = "-"
	end
	if rscp1 == nil then
		rscp1 = "-"
	end

	if ecio ~= "-" then
		rv["ecio"] = ecio .. " dB"
	end
	if rscp ~= "-" then
		rv["rscp"] = rscp .. " dBm"
	end
	if ecio1 ~= " " then
		rv["ecio1"] = ecio1 .. " dB"
	end
	if rscp1 ~= " " then
		rv["rscp1"] = rscp1 .." dBm"
	end

	rv["mcc"] = file:read("*line")
	rv["mnc"] = file:read("*line")
    rv["rnc"] = file:read("*line")
	rv["rncn"] = file:read("*line")
	rv["lac"] = file:read("*line")
	rv["lacn"] = file:read("*line")
	rv["cid"] = file:read("*line")
	rv["cidn"] = file:read("*line")
	rv["lband"] = file:read("*line")
	rv["channel"] = file:read("*line")
	rv["pci"] = file:read("*line")
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end