#!/bin/sh 

LOCK_FILE="/tmp/zinfo.lock"
if [ -e "$LOCK_FILE" ]; then
    echo "zinfo互斥" >> /tmp/rm520n.log
    exit 1
fi
touch "$LOCK_FILE"
source /usr/share/modem/Quectel

sim_sel=$(cat /tmp/sim_sel)
result=""

case $sim_sel in
    0)
        result="外置SIM卡"
        ;;
    1)
        result="内置SIM1"
        ;;
    2)
        result="内置SIM2"
        ;;
    *)
        result="SIM状态错误"
        ;;
esac


SIM_Check=$(sendat 3 AT+CPIN?)
if [ -z "$(echo "$SIM_Check" | grep "READY")" ]; then
    {    
    echo `sendat 2 "ATI" | sed -n '3p'|sed 's/\r$//'` #'RM520N-CN'
    echo `sendat 2 "ATI" | sed -n '2p'|sed 's/\r$//'` #'Quectel'
    echo `date "+%Y-%m-%d %H:%M:%S"`
    echo ''
    echo "未检测到SIM卡!"
    echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
    } > /tmp/cpe_cell.file
    rm -rf "$LOCK_FILE"
    exit
fi

InitData(){
    Date=''
	CHANNEL="-" 
	ECIO="-"
	RSCP="-"
	ECIO1=" "
	RSCP1=" "
	NETMODE="-"
	LBAND="-"
	PCI="-"
	CTEMP="-"
	MODE="-"
	SINR="-"
	IMEI='-'
	IMSI='-'
	ICCID='-'
	phone='-'
	conntype=''
	Model=''


}

OutData(){
    {
    echo `sendat 2 "ATI" | sed -n '3p'|sed 's/\r$//'` #'RM520N-CN'
    echo `sendat 2 "ATI" | sed -n '2p'|sed 's/\r$//'` #'Quectel'
    echo `date "+%Y-%m-%d %H:%M:%S"`
    echo ''
    echo "$result"
    # echo `sendat 2 AT+COPS? | awk -F': ' '/\:/{print $2}' | cut -d',' -f3 | tr -d '"'` #运营商
    echo $COPS #运营商
    echo 'ttyUSB2' #端口
    echo "WD" #温度
    echo '协议' #协议 
    echo '---------------------------------'
    echo `sendat 2 AT+CGSN | grep -oE '[0-9]+'|sed 's/\r$//'` #imei
    echo `sendat 2 AT+CIMI | sed -n '2p'|sed 's/\r$//'` #imsi
    echo `sendat 2 AT+QCCID | awk -F': ' '/\:/{print $2}'|sed 's/\r$//'|sed 's/\r$//'` #iccid
    echo `sendat 2 AT+CNUM | grep "+CNUM:" | sed 's/.*,"\(.*\)",.*/\1/'|sed 's/\r$//'` #phone
    echo '---------------------------------'

    # echo `sendat 2 AT+QCSQ | awk -F': ' '/\+QCSQ:/{print $2}' | cut -d',' -f1 | tr -d '"'` #TDD NR5G
    echo $MODE
    echo $CSQ # CSQ 
    echo $CSQ_PER #CSQ_PER
    echo $CSQ_RSSI
    echo $ECIO #参考信号接收质量 RSRQ ecio
    echo $ECIO1 #参考信号接收质量 RSRQ ecio1
    echo $RSCP #参考信号接收功率 RSRP rscp0
    echo $RSCP1 #参考信号接收功率 RSRP rscp1
    echo $SINR #信噪比 SINR  rv["sinr"]
    echo ""
    echo '---------------------------------'


    echo "$COPS_MCC /$COPS_MNC" #MCC / MNC
    echo ""
    echo $RNC
    echo ""
    echo $LAC  #TAC 
    echo ""
    echo ""
    echo $CID
    echo $LBAND
    echo $CHANNEL
    echo $PCI
    # echo `date "+%Y-%m-%d %H:%M:%S"`
    } > /tmp/cpe_cell.file
}

InitData
Quectel_AT
OutData
rm -rf "$LOCK_FILE"