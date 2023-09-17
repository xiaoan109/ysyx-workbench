#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"
#include <common.h>
#include <isa.h>

CPU_state cpu = {};
bool rst_n_sync = false; // read from rtl by dpi-c.

void init_monitor(int, char *[]);
bool difftest_check();
void difftest_step();
void print_regs();

void step_and_dump_wave(VerilatedContext *contextp, VerilatedVcdC *tfp, Vtop *top)
{
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
}

int main(int argc, char **argv)
{
    if (false && argc && argv)
    {
    }
    VerilatedContext *contextp = new VerilatedContext;
    // contextp->debug(0);
    // contextp->randReset(2);
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);
    VerilatedVcdC *tfp = new VerilatedVcdC; // 初始化VCD对象指针
    Vtop *top = new Vtop{contextp};
    top->trace(tfp, 0);
    Verilated::mkdir("logs");
    tfp->open("logs/testbench.vcd"); // 设置输出的文件

    

    top->i_rst_n = !0;
    top->i_clk = 0;
    step_and_dump_wave(contextp, tfp, top);
    init_monitor(argc, argv);
    while (!contextp->gotFinish())
    {

        top->i_clk = !top->i_clk;
#ifdef DIFFTEST_ON
        top->eval(); // update rst_n_sync
        if (top->i_clk && rst_n_sync)
        {
            if (!difftest_check())
            { // check last cycle reg/mem.
                print_regs();
                break;
            }
            difftest_step(); // ref step and update regs/mem.
        }
#endif
        step_and_dump_wave(contextp, tfp, top);
    }

    step_and_dump_wave(contextp, tfp, top);

    top->final();
    tfp->close();
    delete tfp;
    delete top;
    delete contextp;
    return 0;
}