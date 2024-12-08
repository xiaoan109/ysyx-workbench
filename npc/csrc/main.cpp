#include "include/include.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define TOP VysyxSoCFull

bool rst_n_sync = false; //read from rtl by dpi-c.
bool dut_status = false; //read from rtl by dpi-c. true for instruction commit

void step_and_dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,TOP* top)
{
  top->eval();
  contextp->timeInc(1);
  IFDEF(TRACE_ON, tfp->dump(contextp->time()));
}

void reset(VerilatedContext* contextp,VerilatedVcdC* tfp,TOP* top, int n) {
	top->reset = 1;
 	while (n -- > 0) {
    top->clock = !top->clock;
    step_and_dump_wave(contextp,tfp,top);
  }
	top->reset = 0;
}

int main(int argc, char *argv[]) {
  ///////////////////////////////// verilator init: /////////////////////////////////
  Verilated::commandArgs(argc, argv);
  VerilatedContext* contextp = new VerilatedContext;
  VerilatedVcdC* tfp = new VerilatedVcdC;
  TOP* top = new TOP;
  IFDEF(TRACE_ON, contextp->traceEverOn(true); top->trace(tfp, 0); tfp->open("build/sim.vcd"));    // Trace 0 levels of hierarchy (or see below)
  ///////////////////////////////// init npc status: ////////////////////////////////
  top->clock = 0;
  step_and_dump_wave(contextp,tfp,top);       //init reg status,use for difftest_init.
  npc_init(argc,argv);
  reset(contextp,tfp,top,20);

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish() && contextp->time() < DEBUG_TIME)
  {
    top->clock = !top->clock;                 // clk = ~clk;
    IFDEF(DIFFTEST_ON,
    top->eval();                              // update rst_n_sync
    if(dut_status) {
      if(top->clock && rst_n_sync){
        if(!difftest_check()){                  // check last cycle reg/mem.
          break;
        }
        difftest_step();                        // ref step and update regs/mem.
      }
    }
    )
    step_and_dump_wave(contextp,tfp,top);
  }

  ///////////////////////////////// exit: /////////////////////////////////
  step_and_dump_wave(contextp,tfp,top);
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;

  return 0;
}
