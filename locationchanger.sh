#!/bin/bash

INSTALL_DIR=/usr/local/bin
SCRIPT_NAME=$INSTALL_DIR/locationchanger
LAUNCH_AGENTS_DIR=$HOME/Library/LaunchAgents
PLIST_NAME=$LAUNCH_AGENTS_DIR/LocationChanger.plist

sudo -v

sudo mkdir -p $INSTALL_DIR
cat << "EOT" | sudo tee $SCRIPT_NAME > /dev/null
#!/bin/bash

# 此脚本根据 Wi-Fi 网络的名称更改网络位置。

# 最大日志行数
LOG_MAX_LINES=1000
# 日志文件路径
LOG_FILE="$HOME/Library/Logs/LocationChanger.log"

# 如果日志超过LOG_MAX_LINES，只保留最后一部分
if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt $LOG_MAX_LINES ]; then
    tail -n $LOG_MAX_LINES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
exec 2>&1 >> $LOG_FILE

sleep 3

ts() {
    date +"[%Y-%m-%d %H:%M] $*"
}

ID=`whoami`
SSID=`system_profiler SPAirPortDataType | grep -A2 'Status: Connected' | tail -n1 | sed 's/:$//' | xargs`

ts "I am '$ID'"
ts "Connected to '$SSID'"

# 全部位置信息
LOCATION_NAMES=`scselect | tail -n +2 | cut -d \( -f 2- | sed 's/)$//'`
# 当前位置
CURRENT_LOCATION=`scselect | tail -n +2 | egrep '^\ +\*' | cut -d \( -f 2- | sed 's/)$//'`

# 映射SSID -> NEW_LOCATION
# 默认位置为SSID, 如果配置映射取映射值
NEW_LOCATION="$SSID"
CONFIG_FILE=$HOME/.locations/locations.conf
ts "Probing '$CONFIG_FILE'"
if [ -f $CONFIG_FILE ]; then
    ts "Reading to '$CONFIG_FILE'"
    ESSID=`echo "$SSID" | sed 's/[.[\*^$]/\\\\&/g'`
    MAP_LOCATION=`grep "^$ESSID=" $CONFIG_FILE | cut -d = -f 2`
    if [ "$MAP_LOCATION" != "" ]; then
        ts "Will switch the location to '$MAP_LOCATION' (configuration file)"
        NEW_LOCATION=$MAP_LOCATION
    else
        ts "Will switch the location to '$NEW_LOCATION'"
    fi
fi

# 判断NEW_LOCATION是否在位置列表中 (不在默认切换Automatic)
E_NEW_LOCATION=`echo "$NEW_LOCATION" | sed 's/[.[\*^$]/\\\\&/g'`
if ! echo "$LOCATION_NAMES" | grep -q "^$E_NEW_LOCATION$"; then
  NEW_LOCATION="Automatic"
  # 二次确认是否存在
  if echo "$LOCATION_NAMES" | grep -q "^$NEW_LOCATION$"; then
    ts "Location '$SSID' was not found. Will default to '$NEW_LOCATION'"
  else
    ts "Location '$SSID' was not found. The following locations are available: $LOCATION_NAMES"
    exit 1
  fi
fi

# 切换位置，执行相应钩子
if [ "$NEW_LOCATION" != "" ]; then
    if [ "$NEW_LOCATION" != "$CURRENT_LOCATION" ]; then
        ts "Changing the location to '$NEW_LOCATION'"
        scselect "$NEW_LOCATION"
        SCRIPT="$HOME/.locations/$NEW_LOCATION"
        if [ -f "$SCRIPT" ]; then
            ts "Running '$SCRIPT'"
            "$SCRIPT"
        fi
    else
        ts "Already at '$NEW_LOCATION'"
    fi
fi
EOT

sudo chmod +x $SCRIPT_NAME

mkdir -p $LAUNCH_AGENTS_DIR
cat > $PLIST_NAME << EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.eprev.locationchanger</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/locationchanger</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Library/Preferences/SystemConfiguration</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOT

launchctl load -w $PLIST_NAME
