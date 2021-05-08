#!/bin/sh


upnplog(){
    echo "$1"
    logger boostupnp  "$1"
}

# get public ip address
ip_regex="[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"

URL=("pv.sohu.com/cityjson" "ip.cn/api/index?ip=&type=0" "ip.cip.cc" "myip.ipip.net" "members.3322.org/dyndns/getip" "ip.360.cn/IPShare/info" "http://myip.ipip.net/s" "http://ip.3322.net")
_url=${URL[$(rand 1 ${#URL[@]})]}

if [ "$_url" = "ip.360.cn/IPShare/info" ]; then
    ip=curl -s --referer "http://ip.360.cn/" "$_url" | egrep -o $ip_regex
else
    ip=curl -s "$_url" | egrep -o $ip_regex
fi
upnplog "My public IP address is: $ip"

# check public ip
if [ -z "$ip" ];then
    upnplog "No validate public IP, exit !"
exit
fi


if expr "$ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
  upnplog "Validate public IP"
else
  upnplog "Wrong IP address"
  exit
fi

# get upnp configed external ip
upnp_ext_ip=$(uci get upnpd.config.external_ip)
upnplog "My upnp external IP address is: $upnp_ext_ip"


if [ "$ip" = "$upnp_ext_ip" ];then
    upnplog "Upnp external IP up to date. Exit."
    exit
fi

# ok, set new external ip to upnp
uci set upnpd.config.external_ip=$ip
uci commit upnpd

# restart upnpd
/etc/init.d/miniupnpd restart &

upnplog "Configed new external for upnp: $ip"
