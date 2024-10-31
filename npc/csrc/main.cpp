#include "include/include.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

bool rst_n_sync = false; //read from rtl by dpi-c.
bool dut_status = false; //read from rtl by dpi-c. true for instruction commit

void step_and_dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top)
{
  top->eval();
  contextp->timeInc(1);
  IFDEF(TRACE_ON, tfp->dump(contextp->time()));
}

int main(int argc, char *argv[]) {
  ///////////////////////////////// verilator init: /////////////////////////////////
  VerilatedContext* contextp = new VerilatedContext;
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vtop* top = new Vtop;
  IFDEF(TRACE_ON, contextp->traceEverOn(true); top->trace(tfp, 0); tfp->open("build/sim.vcd"));    // Trace 0 levels of hierarchy (or see below)
  ///////////////////////////////// init npc status: ////////////////////////////////
  top->i_rst_n = !0;
  top->i_clk = 0;
  step_and_dump_wave(contextp,tfp,top);       //init reg status,use for difftest_init.
  npc_init(argc,argv);

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish() && contextp->time() < DEBUG_TIME)
  {
    top->i_clk = !top->i_clk;                 // clk = ~clk;
    IFDEF(DIFFTEST_ON,
    top->eval();                              // update rst_n_sync
    if(dut_status) {
      if(top->i_clk && rst_n_sync){
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
