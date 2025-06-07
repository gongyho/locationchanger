# 位置切换器 (Location Changer)
forked from [eprev/locationchanger](https://github.com/eprev/locationchanger)

该工具可根据Wi-Fi网络名称自动切换MacOS的[网络位置](https://support.apple.com/en-us/HT202480)，并在切换时运行自定义脚本。
> 支持 macOS Sequoia(15.x)
> 
> 其他 macOS版本 待测试

## 安装与更新

```
curl -L https://github.com/gongyho/locationchanger/raw/master/locationchanger.sh | bash
```

安装时会要求输入root密码，将`locationchanger`安装到*/usr/local/bin*目录。

## !!! 卸载方法 !!!

```
curl -L https://github.com/gongyho/locationchanger/raw/master/locationchanger_uninstall.sh | bash
```

该操作将删除`/usr/local/bin/locationchanger`和`~/Library/LaunchAgents/LocationChanger.plist`

## 基本使用

您需要按照Wi-Fi网络名称来命名网络位置。例如，若需要为"Corp Wi-Fi"无线网络设置特定网络配置，则应创建名为"Corp Wi-Fi"的位置。当连接至该无线网络时，系统将自动切换至对应网络位置。若连接的网络没有对应位置配置，则会切换至默认位置("Automatic")。

如需在连接特定Wi-Fi时运行脚本，请将脚本存放于`~/.locations`目录，并按Wi-Fi网络命名（需确保已配置对应网络位置）。例如，以下脚本在连接"Corp Wi-Fi"时修改安全设置：

```bash
#!/usr/bin/env bash
exec 2>&1

# Require password immediately after sleep or screen saver begins
osascript -e 'tell application "System Events" to set require password to wake of security preferences to true'
```

将此脚本保存为`~/.locations/Corp Wi-Fi`。同时可创建`~/.locations/Automatic`来恢复默认设置：

```bash
#!/usr/bin/env bash
exec 2>&1

# Don’t require password immediately after sleep or screen saver begins
osascript -e 'tell application "System Events" to set require password to wake of security preferences to false'
```

## 别名功能

若需为不同无线网络共享同一网络位置（例如路由器同时广播2.4GHz和5GHz信号），可创建配置文件`~/.locations/locations.conf`（纯文本键值对文件，等号两边无空格）：

```bash
Wi-Fi_5GHz=Wi-Fi
```

其中键名为无线网络名称，键值为目标位置名称。

## 故障排查

每次无线网络变更时，工具会记录详细日志：
> 日志最大保存1000行
```bash
tail -f ~/Library/Logs/LocationChanger.log
```

示例输出：

```
Connected to 'Wi-Fi_5GHz'
Will switch the location to 'Wi-Fi' (configuration file)
Changing the location to 'Wi-Fi'
Running '~/.locations/Wi-Fi'
```