#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VCPU_top.h"
#include <common.h>
#include <isa.h>

CPU_state cpu = {};

void init_monitor(int, char *[]);

int main(int argc, char **argv)
{
    if (false && argc && argv){}
    VerilatedContext *contextp = new VerilatedContext;
    // contextp->debug(0);
    // contextp->randReset(2);
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);
    VerilatedVcdC* tfp = new VerilatedVcdC; //初始化VCD对象指针
    VCPU_top *top = new VCPU_top{contextp};
    top->trace(tfp, 0);
    tfp->open("build/testbench.vcd"); //设置输出的文件

    init_monitor(argc, argv);

    top->rst = 0;
    top->clk = 0;

    while (!contextp->gotFinish() && contextp->time()<100000)
    {
        contextp->timeInc(1);
        top->clk = !top->clk;
        if (!top->clk)
        {
            if (contextp->time() > 1 && contextp->time() < 10)
            {
                top->rst = 1; // Assert reset
            }
            else
            {
                top->rst = 0; // Deassert reset
            }
        }
        top->eval();
        tfp->dump(contextp->time());
    }
    
    top->final();
    tfp->close();
    delete top;
    return 0;
}