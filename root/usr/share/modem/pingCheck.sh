#!/bin/sh

count=0
LOCK_FILE="/tmp/pingCheck.lock"
if [ -e "$LOCK_FILE" ]; then
    echo "pingCheck互斥" >> /tmp/pingCheck.log
    exit 1
fi
SLEEP_FILE="/tmp/pingCheck.file"
if [ -e "$SLEEP_FILE" ]; then
    sleep 1
else
    sleep 120
    touch "$SLEEP_FILE"
fi
touch "$LOCK_FILE"
REST_FILE="/tmp/pingCheck.rest"
while :; do
    pingen=$(uci -q get modem.@ndis[0].pingen)||pingen="0"

    if [ "$pingen" == "1" ]; then
        pingaddr=$(uci -q get modem.@ndis[0].pingaddr) || pingaddr="119.29.29.29"
        if ping -c 1 -w 1 "$pingaddr"; then
            echo "SIM卡准备就绪，网络连接正常" > /tmp/pingCheck.log
            sleep 30
            continue
        fi
        result=$(sendat 3 "AT+CPIN?")

        if echo "$result" | grep -q "READY"; then
            if ping -c 1 -w 1 "$pingaddr"; then
                echo "SIM卡准备就绪，网络连接正常" > /tmp/pingCheck.log
                sleep 30
                continue
            else
                echo "SIM卡准备就绪，但网络连接失败，重启WAN口" >> /tmp/pingCheck.log
                /sbin/ifup wan
                /sbin/ifup wan6
                sleep 2
            fi
        else
            echo "SIM卡未准备就绪" >> /tmp/pingCheck.log
            if [ -e "$REST_FILE" ]; then
                rm -rf "$LOCK_FILE"
                exit 0
            else
                touch "$REST_FILE"
                sendat 3 'AT+CFUN=1,1'
                echo "尝试重启一次5G模块" >> /tmp/pingCheck.log
                sleep 30
            fi
        fi
    else
        echo "Ping测试已禁用" >> /tmp/pingCheck.log
        rm -rf "$LOCK_FILE"
        exit 0
    fi

    count=$((count + 1)) 

    max_count=$(uci -q get modem.@ndis[0].count) || max_count="5"

    if [ "$max_count" -gt 0 ] && [ "$count" -ge "$max_count" ]; then
        echo "达到最大检测次数，退出" >> /tmp/pingCheck.log
        rm -rf "$LOCK_FILE"
        exit 0
    fi

    sleep 30
done
