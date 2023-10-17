#!/bin/sh
#By Zy143L

PROGRAM="RM520N_MODEM"
printMsg() {
    local msg="$1"
    logger -t "${PROGRAM}" "${msg}"
} #日志输出调用API
sleep 2 && /sbin/uci commit
Modem_Enable=`uci -q get modem.@ndis[0].enable` || Modem_Enable=1
#模块启动

Sim_Sel=`uci -q get modem.@ndis[0].simsel`|| Sim_Sel=0
echo "simsel: $Sim_Sel" >> /tmp/rm520n.log
#SIM选择

Enable_IMEI=`uci -q get modem.@ndis[0].enable_imei` || Enable_IMEI=0
#IMEI修改开关

RF_Mode=`uci -q get modem.@ndis[0].smode` || RF_Mode=0
#网络制式 0: Auto, 1: 4G, 2: 5G
NR_Mode=`uci -q get modem.@ndis[0].nrmode` || NR_Mode=0
#0: Auto, 1: SA, 2: NSA
Band_LTE=`uci -q get modem.@ndis[0].bandlist_lte` || Band_LTE=0
Band_SA=`uci -q get modem.@ndis[0].bandlist_sa` || Band_SA=0
Band_NSA=`uci -q get modem.@ndis[0].bandlist_nsa` || Band_NSA=0
Enable_PING=`uci -q get modem.@ndis[0].pingen` || Enable_PING=0
PING_Addr=`uci -q get modem.@ndis[0].pingaddr` || PING_Addr="119.29.29.29"
PING_Count=`uci -q get modem.@ndis[0].count` || PING_Count=10

if [ "$Modem_Enable" == 0 ]; then
    echo 1 >/sys/class/gpio/cpe-pwr/value
    printMsg "禁用移动网络"
    echo "Modem_Enable: $Modem_Enable 模块禁用" >> /tmp/rm520n.log
fi

if [ ${Enable_PING} == 1 ];then
    /usr/share/modem/pingCheck.sh &
fi

if [ ${Enable_IMEI} == 1 ];then
    IMEI_file="/tmp/IMEI"
    if [ -e "$IMEI_file" ]; then
        last_IMEI=$(cat "$IMEI_file")
    else
        last_IMEI=-1
    fi
    IMEI=`uci -q get modem.@ndis[0].modify_imei`
    if [ "$IMEI" != "$last_IMEI" ]; then
        /usr/share/modem/moimei ${IMEI} 1>/dev/null 2>&1
        printMsg "IMEI: ${IMEI}"
        echo "修改IMEI $IMEI" >> /tmp/rm520n.log
        echo "$IMEI" > "$IMEI_file"
    else
        echo "IMEI未变动, 不执行操作" >> /tmp/rm520n.log
    fi
fi
# 网络模式选择
#---------------------------------
RF_Mode_file="/tmp/RF_Mode"
if [ -e "$RF_Mode_file" ]; then
    last_RF_Mode=$(cat "$RF_Mode_file")
else
    last_RF_Mode=-1
fi
#--
if [ "$RF_Mode" != "$last_RF_Mode" ]; then
    if [ "$RF_Mode" == 0 ]; then
        echo "RF_Mode: $RF_Mode 自动网络" >> /tmp/rm520n.log
        sendat 2 'AT+QNWPREFCFG="mode_pref",AUTO' >> /tmp/rm520n.log
    elif [ "$RF_Mode" == 1 ]; then
        echo "RF_Mode: $RF_Mode 4G网络" >> /tmp/rm520n.log
        sendat 2 'AT+QNWPREFCFG="mode_pref",LTE' >> /tmp/rm520n.log
    elif [ "$RF_Mode" = 2 ]; then
        echo "RF_Mode: $RF_Mode 5G网络" >> /tmp/rm520n.log
        sendat 2 'AT+QNWPREFCFG="mode_pref",NR5G' >> /tmp/rm520n.log
    fi
    echo "$RF_Mode" > "$RF_Mode_file"
else
    echo "RF_Mode未变动, 不执行操作" >> /tmp/rm520n.log
fi
#-------------------------

# LTE锁频
#-------------------------
Band_LTE_file="/tmp/Band_LTE"
if [ -e "$Band_LTE_file" ]; then
    last_Band_LTE=$(cat "$Band_LTE_file")
else
    last_Band_LTE=-1
fi
#--
if [ "$Band_LTE" != "$last_Band_LTE" ]; then
    if [ "$Band_LTE" == 0 ]; then
        sendat_command='AT+QNWPREFCFG="lte_band",1:3:5:8:34:38:39:40:41'
        sendat_result=$(sendat 2 "$sendat_command")
        echo "LTE自动: $sendat_result" >> /tmp/rm520n.log
    else
        sendat_command="AT+QNWPREFCFG=\"lte_band\",$Band_LTE"
        sendat_result=$(sendat 2 "$sendat_command")
        echo "LTE锁频: $sendat_result" >> /tmp/rm520n.log
    fi
    echo "$Band_LTE" > "$Band_LTE_file"
else
    echo "Band_LTE未变动, 不执行操作" >> /tmp/rm520n.log
fi
#----------------------

# SA/NSA模式切换
#----------------------
NR_Mode_file="/tmp/NR_Mode"
if [ -e "$NR_Mode_file" ]; then
    last_NR_Mode=$(cat "$NR_Mode_file")
else
    last_NR_Mode=-1
fi
#--
if [ "$NR_Mode" != "$last_NR_Mode" ]; then
    if [ "$NR_Mode" == 0 ]; then
        echo "NR_Mode: $NR_Mode 自动网络" >> /tmp/rm520n.log
        sendat 2 'AT+QNWPREFCFG="nr5g_disable_mode",0' >> /tmp/rm520n.log
    elif [ "$NR_Mode" = 1 ]; then
        echo "NR_Mode: $NR_Mode SA网络" >> /tmp/rm520n.log
        sendat 2 'AT+QNWPREFCFG="nr5g_disable_mode",2' >> /tmp/rm520n.log
    elif [ "$NR_Mode" = 2 ]; then
        echo "NR_Mode: $NR_Mode NSA网络" >> /tmp/rm520n.log
        sendat 2 'AT+QNWPREFCFG="nr5g_disable_mode",1' >> /tmp/rm520n.log
    fi
    echo "$NR_Mode" > "$NR_Mode_file"
else
    echo "NR_Mode未变动, 不执行操作" >> /tmp/rm520n.log
fi
#----------------------

# SA锁频
#----------------------
band_sa_file="/tmp/Band_SA"
if [ -e "$band_sa_file" ]; then
    last_Band_SA=$(cat "$band_sa_file")
else
    last_Band_SA=-1
fi
#--
if [ "$Band_SA" != "$last_Band_SA" ]; then
    if [ "$Band_SA" == 0 ]; then
        sendat_command='AT+QNWPREFCFG="nr5g_band",1:3:8:28:41:78'
        sendat_result=$(sendat 2 "$sendat_command")
        echo "SA自动: $sendat_result" >> /tmp/rm520n.log
    else
        sendat_command="AT+QNWPREFCFG=\"nr5g_band\",$Band_SA"
        sendat_result=$(sendat 2 "$sendat_command")
        echo "SA锁频: $sendat_result" >> /tmp/rm520n.log
    fi
    echo "$Band_SA" > "$band_sa_file"
else
    echo "Band_SA未变动, 不执行操作" >> /tmp/rm520n.log
fi
#-------------------

# NSA锁频
#-------------------
band_nsa_file="/tmp/Band_NSA"
if [ -e "$band_nsa_file" ]; then
    last_Band_NSA=$(cat "$band_nsa_file")
else
    last_Band_NSA=-1
fi

if [ "$Band_NSA" != "$last_Band_NSA" ]; then
    if [ "$Band_NSA" == 0 ]; then
        sendat_command='AT+QNWPREFCFG="nsa_nr5g_band",41:78'
        sendat_result=$(sendat 2 "$sendat_command")
        echo "NSA自动: $sendat_result" >> /tmp/rm520n.log
        echo 0 > /tmp/Band_NSA
    else
        sendat_command="AT+QNWPREFCFG=\"nsa_nr5g_band\",$Band_SA"
        sendat_result=$(sendat 2 "$sendat_command")
        echo "NSA锁频: $sendat_result" >> /tmp/rm520n.log
        echo 1 > /tmp/Band_NSA
    fi
    echo "$Band_NSA" > "$band_nsa_file"
else
    echo "Band_NSA未变动, 不执行操作" >> /tmp/rm520n.log
fi
#-----------------
if [ ! -f "/tmp/sim_sel" ] || [ "$(cat /tmp/sim_sel)" != "$Sim_Sel" ]; then
    case "$Sim_Sel" in
        0)
            printMsg "外置SIM卡"
            sendat 2 "AT+QUIMSLOT=1"
            echo "外置SIM卡" >> /tmp/rm520n.log
            echo 0 > /tmp/sim_sel
            sleep 20 && /sbin/ifup wan up &
            sleep 20 && /sbin/ifup wan6 up &
        ;;
        1)
            printMsg "内置SIM1"
            echo 1 > /sys/class/gpio/cpe-sel0/value
            sendat 2 "AT+QUIMSLOT=2"
            sendat 2 "AT+CFUN=1,1"
            echo "内置SIM卡1" >> /tmp/rm520n.log
            echo 1 > /tmp/sim_sel
            sleep 30 && /sbin/ifup wan up &
            sleep 30 && /sbin/ifup wan6 up &
        ;;
        2)
            printMsg "内置SIM2"
            echo 0 > /sys/class/gpio/cpe-sel0/value
            sendat 2 "AT+QUIMSLOT=2"
            sendat 2 "AT+CFUN=1,1"
            echo "内置SIM卡2" >> /tmp/rm520n.log
            echo 2 > /tmp/sim_sel
            sleep 30 && /sbin/ifup wan up &
            sleep 30 && /sbin/ifup wan6 up &
        ;;
        *)
            printMsg "错误状态"
            sendat 2 "AT+QUIMSLOT=1"
            sendat 2 "AT+CFUN=1,1"
            echo 3 > /tmp/Sim_Sel
            echo "SIM状态错误" >> /tmp/rm520n.log
            sleep 30 && /sbin/ifup wan up
            sleep 30 && /sbin/ifup wan6 up
        ;;
        esac
else
    echo "SIM无变动" >> /tmp/rm520n.log
fi

# /bin/sh /usr/share/zinfo.sh &

exit
