# "一生一芯"工程项目

这是"一生一芯"的工程项目. 通过运行
```bash
bash init.sh subproject-name
```
进行初始化, 具体请参考[实验讲义][lecture note].

[lecture note]: https://ysyx.oscc.cc/docs/


# TODO
**1. 目前为Multi-cycle CPU，还未加入流水线**

**2. 目前进度为为接入ysyxSoC，添加了mrom和sram， bootloader v1.0， 测试了cpu-tests**

**3. 后续会逐渐把Verilator替换为SV+UVM或者Python+cocotb等更适合于业界的验证平台(可能鸽了直接验开源的soc/cpu)**

# NPC架构图
DVT自动生成

![image](/npc/schematic_of_u_top_top_.png)
