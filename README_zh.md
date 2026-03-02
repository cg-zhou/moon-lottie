# MoonBit Lottie

[English](./README.md) | [简体中文](./README_zh.md)

一个使用 MoonBit 实现的 Lottie 动画播放器。

🎬 **[在线演示](https://lottie.cg-zhou.top)**

## 统计数据

[![Passed](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/tests-passed.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Total Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-total.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Source Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-source.json)](https://github.com/cg-zhou/moon-lottie/actions)

## 功能特性
- ✅ **核心特性支持**：支持常用形状（矩形、椭圆、路径）、填色、描边、渐变以及路径修整（Trim Path）。
- ✅ **图层与组合**：完整支持图层变换、预合成嵌套、蒙版（Masks）和遮罩（Matte）。
- ✅ **调试友好**：解析时会自动识别并报告不支持的 Lottie 字段，方便快速定位渲染差异原因。
- ✅ **灵活渲染**：针对不同平台提供 SVG 字符串输出和 Wasm 平台的 Canvas 直接渲染。
- **TODO：**：更多功能持续开发中

## 快速开始
```bash
# 运行测试
moon test

# 在本地构建并启动演示项目
moon build --target wasm-gc
cd demo && npx serve .
```

## 开源协议
MIT
