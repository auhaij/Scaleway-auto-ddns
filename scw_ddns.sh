#!/bin/bash


# Telegram Bot 相关参数
telegram_bot_token="YOUR_TELEGRAM_BOT_TOKEN"
telegram_chat_id="YOUR_TELEGRAM_CHAT_ID"

# Cloudflare 相关参数
email=""
api_key=""
zone_id=""
hostname="test.eu.org"
recordType="AAAA"
# 小云朵
proxy="true"
# scaleway实例的public_dns
public_dns=""

# 获取当前 IP 地址
ipv6=$(dig +short AAAA ${public_dns} | grep -vE "^;;" | head -n 1)


# 更新 DNS 记录

listDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${recordType}&name=${hostname}"
createDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records"

res=$(curl -s -X GET "$listDnsApi" -H "X-Auth-Email:$email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json")
#当前记录
recordId=$(echo "$res" | jq -r ".result[0].id")
recordIp=$(echo "$res" | jq -r ".result[0].content")

    if [[ $recordIp = "$ipv6" ]]; then
      echo "更新失败，当前记录不需要修改"
      resSuccess=false
    elif [[ $recordId = "null" ]]; then
      res=$(curl -s -X POST "$createDnsApi" -H "X-Auth-Email:$email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$hostname\",\"content\":\"$ipv6\",\"proxied\":$proxy}")
      resSuccess=$(echo "$res" | jq -r ".success")
    else
      updateDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${recordId}"
      res=$(curl -s -X PUT "$updateDnsApi"  -H "X-Auth-Email:$email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$hostname\",\"content\":\"$ipv6\",\"proxied\":$proxy}")
      resSuccess=$(echo "$res" | jq -r ".success")
    fi

# 发送 Telegram 消息
message=""
if [[ $resSuccess = "true" ]]; then
  message="$hostname 更新成功"
else
  message="$hostname 更新失败"
fi

curl -s -X POST "https://api.telegram.org/bot$telegram_bot_token/sendMessage" \
     -d "chat_id=$telegram_chat_id" \
     -d "text=$message"




