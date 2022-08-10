# fw-builder
该软件是一套基于模版模式的通用框架，不同的模版对应不同的功能

## 项目目录结构
```
.
├── fwb.n #主配置文件
└── nodes #节点目录
    ├── node1 #子节点
    │   └── fwb.n #子节点配置文件
    └── node2 #子节点
        └── fwb.n #子节点配置文件
```
## 使用环境

```
支持build-essential、cmake、git、perl、sed、awk、grep
```

## 案例

* fwb.n

```
TEMPLATE := common

DEPEND := [
    node1
    node2
]

TRACE := {
#!/bin/bash
if [ "$1" == "IN" ];then
    echo "${FBAU_CURRENT_NODE_NAME} IN"
elif [ "$1" == "OUT" ];then
    echo "${FBAU_CURRENT_NODE_NAME} OUT"
fi
}
```

* nodes/node1/fwb.n、nodes/node2/fwb.n

```
TRACE := {
#!/bin/bash
if [ "$1" == "IN" ];then
    echo "${FBAU_CURRENT_NODE_NAME} IN"
elif [ "$1" == "OUT" ];then
    echo "${FBAU_CURRENT_NODE_NAME} OUT"
fi
}
```

进入项目根目录，调用fw-build/build.sh

案例功能：使用common模版，主节点依赖node1、node2，每次执行会调用配置内的TRACE，其中IN是开始执行该节点时调用，OUT是依赖执行后调用。执行顺序'主节点(IN) -> node1(IN) -> node1(OUT) -> node2(IN) -> node2(OUT) ->主节点(OUT)

## 配置支持的格式

* 值配置
```
KEY := value
```
* 数组配置
```
ARRAY := [
  value1
  value2
  value3
]
```
* HOOK配置
```
HOOK := {
#!/bin/bash
echo "HelloWorld"
}
```
## 基础参数
TEMPLATE(必填)：在主配置文件中设置，选择使用哪个模版

DEPEND(非必填): 可在任意配置文件中设置，表示该节点依赖哪些其他节点

## 基础环境变量
FBAU_PROJECT: 项目目录

FBAU_CURRENT_NODE_PATH: 当前工作节点的目录(当节点工作时，工作目录也在该目录)

FBAU_CURRENT_NODE_NAME: 当前工作节点的名称

其他模版的使用方法见[Wiki](https://github.com/lizhijian1437/fw-builder/wiki)
