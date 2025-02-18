#!/bin/bash

FILE="$1"

[ -z "$FILE" ] && read -rp "$(echo -e "\n \033[32m\033[01m Input file path or URL:\033[0m") " FILE
if [[ "$FILE" =~ .*\.sh\.x$ ]]; then
  TEMP='temp.sh.x'
  rm -f $TEMP
  if [[ "$FILE" =~ ^http ]]; then
    wget -O $TEMP $FILE
    [ "$?" != 0 ] && rm -f $TEMP && echo -e "\n \033[31m\033[01m Could not download the file. The script is exit！\033[0m \n" && exit 1
  else
    [ ! -f "$FILE" ] && echo -e "\n \033[31m\033[01m $FILE is empty. The script is exit！\033[0m \n" && exit 1 || cp $FILE $TEMP
  fi
  ulimit -c unlimited
  echo "/core_dump/%e-%p-%t.core" > /proc/sys/kernel/core_pattern
  mkdir -p /core_dump
  chmod +x $TEMP
  ./$TEMP 6 start & (sleep 0.01 && kill -SIGSEGV $!)
  sleep 3
  mv -f /core_dump/* ./decode.core
  rm -rf /core_dump $TEMP
  [ -e decode.core ] && echo -e "\n\033[32m\033[01m Decode file is: decode.core \033[0m\n" || echo -e "\n\033[31m Decode file failed. \033[0m\n"

elif [[ "$FILE" =~ .*\.sh$ ]]; then
  TEMP=$(awk -F / '{print $NF}' <<< "$FILE")
  rm -f decode-$TEMP
  if [[ "$FILE" =~ ^http ]]; then
    wget -O $TEMP $FILE
    [ "$?" != 0 ] && rm -f $TEMP && echo -e "\n \033[31m\033[01m Could not download the file. The script is exit！\033[0m \n" && exit 1
  else
    [ ! -f "$FILE" ] && echo -e "\n \033[31m\033[01m $FILE is empty. The script is exit！\033[0m \n" && exit 1 || cp $FILE $TEMP
  fi

  decode[0]=$(bash <(sed "s#eval#echo#" $TEMP))
  while [[ "${decode[$((${#decode[*]}-1))]}" =~ ^"bash -c" && "${decode[$((${#decode[*]}-1))]}" =~ 'bash "$@"'$ ]]; do
    decode[${#decode[*]}]=$(sed '/base64 -d/d; s#")" bash "$@"##' <<< "${decode[$((${#decode[*]}-1))]}" | base64 -d)
  done
  echo "${decode[-1]}" > decode-$TEMP
  echo -e "\n\033[32m\033[01m Decode file is: decode-$TEMP \033[0m\n"

else
  echo -e "\n \033[31m\033[01m $FILE is unavailable. The script is exit！\033[0m \n" && exit 1
fi
