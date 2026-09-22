#!/bin/bash

PUBKEY="YOUR-PUBLIC-KEY.pub"
KEY_UNIQUE="ENCODED-PART-OF-YOUR-PUBKEY"
EXISTING_USER="root"

while IFS= read -r ip || [ -n "$ip" ]; do
  # Clean potential carriage returns and spaces
  ip=$(echo "$ip" | tr -d '\r' | xargs)
  
  # Skip empty lines or comments
  [ -z "$ip" ] || [[ "$ip" =~ ^# ]] && continue

  echo -n "Checking $ip... "

  # Check if the key already exists (-n redirects stdin away from ssh)
  ssh -n -p 45022 -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$EXISTING_USER@$ip" \
    "grep -q '$KEY_UNIQUE' /root/.ssh/authorized_keys 2>/dev/null"
  
  if [ $? -eq 0 ]; then
    echo "ALREADY PRESENT"
  else
    echo -n "Key missing, adding... "
    if ssh -n -p <Your SSH port> -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$EXISTING_USER@$ip" \
      "mkdir -p /root/.ssh && echo '$PUBKEY' >> /root/.ssh/authorized_keys && chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys" 2>/dev/null; then
      echo "SUCCESS"
    else
      echo "FAILED"
    fi
  fi
done < hosts.txt
