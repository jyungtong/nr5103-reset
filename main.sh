#!/bin/sh
# set -x

mkdir -p /var/log/app
exec > >(ts '[%Y-%m-%d %H:%M:%S%z]' | tee -a /var/log/app/app.log) 2>&1

if [ -z "$ROUTER_PASSWORD" ]; then
  echo "Error: ROUTER_PASSWORD environment variable is not set."
  exit 1
fi

resetRouter() {
  NR5103E_IP="192.168.1.1"
  PASSWORD_BASE64="$(echo -n "$ROUTER_PASSWORD" | base64)"
  COOKIES_PATH="/tmp/nr5103e-cookies"

  echo "logging in..."
  SESSIONKEY="$(curl --insecure "https://$NR5103E_IP/UserLogin" --cookie-jar $COOKIES_PATH --data-raw "{'Input_Account':'admin','Input_Passwd':'$PASSWORD_BASE64'}" --silent | jq '.sessionkey')"
  echo "==== logged in: ${SESSIONKEY:-no session key}"
  sleep 2

  SESSIONKEY="$(curl --insecure -X PUT "https://$NR5103E_IP/cgi-bin/DAL?oid=cellwan_band&sessionkey=$SESSIONKEY" --cookie $COOKIES_PATH --data-raw '{"INTF_Preferred_Access_Technology":"NR5G-SA"}' --silent | jq '.sessionkey')"
  echo "==== set to SA (force disconnect): ${SESSIONKEY:-no session key}"
  sleep 3

  SESSIONKEY="$(curl --insecure -X PUT "https://$NR5103E_IP/cgi-bin/DAL?oid=cellwan_band&sessionkey=$SESSIONKEY" --cookie $COOKIES_PATH --data-raw '{"INTF_Preferred_Access_Technology":"NR5G-NSA"}' --silent | jq '.sessionkey')"
  echo "==== set to NSA: ${SESSIONKEY:-no session key}"
  sleep 2

  echo "logging out..."
  curl --insecure "https://$NR5103E_IP/cgi-bin/UserLogout?sessionkey=$SESSIONKEY" --cookie $COOKIES_PATH -X POST --silent
  rm $COOKIES_PATH
  echo "===DONE=== router connection reset"

  sleep 5
}

failure_count=0
while true; do
  if ! ping -c1 -W1 8.8.8.8 >/dev/null; then
    failure_count=$((failure_count + 1))
    echo "Ping failed. Failure count: $failure_count"
    if [ "$failure_count" -ge 3 ]; then
      echo "Internet connection down for 3 consecutive checks. Resetting router."
      resetRouter
      failure_count=0
    fi
  else
    failure_count=0
  fi
  sleep 2
done
