---
layout:         post
title:          配置 linux 代理 clash 
subtitle:
# date:           2024-05-12
author:         Steel Shadow
# header-img:     img
# header-style:   text
mathjax:        true
tags:
    - proxy
---

# 参考资料

+ [clash wiki](https://clash.wiki/)
+ [external-controller api](https://clash.gitbook.io/doc)

## 修改 clash 配置文件（external-controller）

clash 暴露 API 接口用于外部控制，文档见

+ <https://clash.wiki/runtime/external-controller.html>
+ <https://clash.gitbook.io/doc/restful-api>

在配置文件中指定

```yaml
allow-lan: false # 如果使用 docker，本项必须为 true
external-controller: "127.0.0.1:9090" # 暴露端口，可以向其他主机也暴露
secret: "" # 如果允许除了本机外访问，为安全，要设置秘钥，详见文档
```

## 在 linux cli 中开启 clash 代理

<https://clash.wiki/introduction/service.html>

docker 性能十分糟糕，且据文档所说：`在容器中运行 Clash Premium 是不被推荐的`。

推荐使用 systemd。

```shell
systemctl status clash
● clash.service - Clash 守护进程, Go 语言实现的基于规则的代理.
     Loaded: loaded (/etc/systemd/system/clash.service; enabled; preset: enabled)
     Active: active (running) since Sun 2024-05-12 09:28:00 UTC; 1min 41s ago
   Main PID: 115980 (clash)
      Tasks: 7 (limit: 1130)
     Memory: 7.5M (peak: 7.8M)
        CPU: 45ms
     CGroup: /system.slice/clash.service
             └─115980 /usr/local/bin/clash -d /etc/clash
```

## web dashboard GUI

使用 external-controller 后，将其作为后端，在前端 web 上管理 clash。

更多搜索 github，以下给出2例

(可使用 nginx 反向代理)

+ 默认使用 https <https://clash.razord.top/>
+ 默认使用 http <http://yacd.haishan.me/>
