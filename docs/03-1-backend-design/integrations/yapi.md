# 技术设计阶段，yapi-skill的 Used Guide

## 什么时候用
- 当api-design.md里接口定义已经比较稳定，准备同步到（新增-更新）YAPI系统里使用

## 怎么用
- 检查yapi-skill是否存在，提示用户检查yapi-skill和YAPI系统的状态。
- 先按照yapi-skill的要求，从AGENTS.md或者CLAUDE.md里获取YAPI项目ID和YAPI的项目token，如果没有,跳过YAPI导入操作。
- 从AGENTS.md或者CLAUDE.md里获取要导入的YAPI分类ID，如果没有,跳过YAPI导入操作。
- 依次从`api-index.md`获取本次改动的API，每次处理一个API。从`api-design.md`拿到API的设计详情，再分析转换成YAPI接口新增或者更新接口(/api/interface/save)要求的接口格式。
- YAPI系统支持mock数据，此时要分析这个接口定义和当前模块的业务场景(通过当前模块下的AGENTS.md)，生成合理的mock数据，填充到接口定义里
- 调用YAPI系统的新增或者更新接口(/api/interface/save)，将转换好的接口依次导入到指定的项目和分类里并且把接口地址和mock地址同步到`api-index.md`里
- 导入完成后，输出导入结果，包括成功的接口数量和失败的接口数量，以及失败的接口列表和错误信息
- 如果导入过程中发生任何错误，终止操作，输出错误信息，并提示用户检查接口定义和YAPI系统的状态

## 不建议用的场景
- api-design.md里的接口定义还不稳定，频繁变动，尚未准备好同步到YAPI系统里使用
- 没有正确配置环境变量，无法访问YAPI系统，或者没有申请到有效的项目ID和token
- 需要对接口定义进行大量修改和调整，尚未准备好进行批量导入到YAPI系统