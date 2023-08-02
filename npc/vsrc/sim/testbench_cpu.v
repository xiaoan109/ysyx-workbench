import "DPI-C" function void init_mem(input string testcase);
`timescale 1 ns / 1 ps
module testbench_cpu;
    integer numcycles;  //number of cycles in test
    reg clk,rst;  //clk and reset signals
    string testcase; //name of testcase

    CPU_top u_CPU_top(
                .clk(clk),
                .rst(rst)
            );

    initial begin
        if($test$plusargs("DUMP_FSDB"))begin
            $fsdbDumpfile("wave.fsdb");
            $fsdbDumpvars;
            $fsdbDumpMDA;
        end
    end


    initial begin
        $monitor("cycle=%d, pc=%h, instruct= %h op=%h, rs1=%h,rs2=%h, rd=%h, imm=%h",
                 numcycles,  u_CPU_top.pc, u_CPU_top.instr, u_CPU_top.u_IDU.u_ControlUnit.opcode,
                 u_CPU_top.rf_raddr1,u_CPU_top.rf_raddr2,u_CPU_top.rf_waddr,u_CPU_top.imm);
        if($value$plusargs("TESTNAME=%s",testcase))begin
            run_riscv_test();
        end
    end


    task loadtestcase;  //load intstructions to instruction mem
        begin
            init_mem({"tests/", testcase, ".hex"});
            // $readmemh({testcase, ".hex"},instructions.ram);
            $display("---Begin test case %s-----", testcase);
        end
    endtask

    //useful tasks
    task step;  //step for one cycle ends 1ns AFTER the posedge of the next cycle
        begin
            #9  clk=1'b0;
            #10 clk=1'b1;
            numcycles = numcycles + 1;
            #1 ;
        end
    endtask

    task stepn; //step n cycles
        input integer n;
        integer i;
        begin
            for (i =0; i<n ; i=i+1)
                step();
        end
    endtask

    task resetcpu;  //reset the CPU and the test
        begin
            rst = 1'b1;
            step();
            #5 rst = 1'b0;
            numcycles = 0;
        end
    endtask

    task checkreg;//check registers
        input [4:0] regid;
        input [31:0] results;
        reg [31:0] debugdata;
        begin
            debugdata=u_CPU_top.u_RegFile.rf[regid]; //get register content
            if(debugdata==results)begin
                $display("OK: end of cycle %d reg %h need to be %h, get %h",
                         numcycles-1, regid, results, debugdata);
            end
            else begin
                $display("!!!Error: end of cycle %d reg %h need to be %h, get %h",
                         numcycles-1, regid, results, debugdata);
            end
        end
    endtask

    integer maxcycles =10000;

    task run;
        integer i;
        begin
            i = 0;
            while( (u_CPU_top.instr!=32'h00100073) && (i<maxcycles))begin //TODO
                step();
                i = i+1;
            end
        end
    endtask

    task checkmagnum;
        begin
            if(numcycles>maxcycles)begin
                $display("!!!Error:test case %s does not terminate!", testcase);
            end
            else if(u_CPU_top.u_RegFile.rf[10]==32'h0)begin
                $display("OK:test case %s finshed OK at cycle %d.",
                         testcase, numcycles-1);
            end
            else if(u_CPU_top.u_RegFile.rf[10]==32'h1)begin
                $display("!!!ERROR:test case %s finshed with error in cycle %d.",
                         testcase, numcycles-1);
            end
            else begin
                $display("!!!ERROR:test case %s unknown error in cycle %d.",
                         testcase, numcycles-1);
            end
        end
    endtask


    task run_riscv_test;
        begin
            loadtestcase();
            resetcpu();
            run();
            checkmagnum();
        end
    endtask
endmodule
