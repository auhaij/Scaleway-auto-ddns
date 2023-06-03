#!/bin/bash

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

    if [[ $resSuccess = "true" ]]; then
      echo "$hostname更新成功"
    else
      echo "$hostname更新失败"
    fi




