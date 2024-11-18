# "一生一芯"工程项目

这是"一生一芯"的工程项目. 通过运行
```bash
bash init.sh subproject-name
```
进行初始化, 具体请参考[实验讲义][lecture note].

[lecture note]: https://ysyx.oscc.cc/docs/


# TODO
**1. 目前为Multi-cycle CPU，还未加入流水线**

**2. 目前进度为为Memory接入AXI-Lite总线，还未完全测试，v1.0测试了RT-Thread**

**3. 后续会逐渐把Verilator替换为SV+UVM或者Python+cocotb等更适合于业界的验证平台**

# 架构图
DVT自动生成

![image](https://github.com/xiaoan109/ysyx-workbench/blob/master/npc/schematic_of_top.png)
