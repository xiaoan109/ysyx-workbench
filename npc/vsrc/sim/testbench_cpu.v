`timescale 1 ns / 1 ps
module testbench_cpu;
    integer numcycles;  //number of cycles in test
    reg clk,rst;  //clk and reset signals
    string testcase; //name of testcase
    longint img_size;
    CPU_top u_CPU_top(
                .clk(clk),
                .rst(rst)
            );

    // initial begin
        // if($test$plusargs("DUMP_FSDB"))begin
        //     $fsdbDumpfile("wave.fsdb");
        //     $fsdbDumpvars();
        //     $fsdbDumpMDA();
        // end
    // end


    initial begin : Testbench
        run_riscv_test();
        $finish();
    end

    import "DPI-C" function longint init_mem(input string testcase);
    task loadtestcase;  //load intstructions to instruction mem
        begin
            if($value$plusargs("TESTNAME=%s",testcase))begin
                img_size = init_mem({"tests/", testcase, "-riscv32e-npc.bin"});
                $display("---Begin test case %s-----", testcase);
            end
            else begin
                img_size = init_mem("");
                $display("---Begin test case builtin-----");
            end


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
                $display("OK: end of cycle %d reg %h need to be %h, get %h", numcycles-1, regid, results, debugdata);
            end
            else begin
                $display("!!!Error: end of cycle %d reg %h need to be %h, get %h", numcycles-1, regid, results, debugdata);
            end
        end
    endtask

    integer maxcycles =1000000;
    // TODO: fix dpi-c BUG
    import "DPI-C" function void set_gpr_ptr(input logic [31:0] a []);
    // import "DPI-C" function void dump_gpr();
    import "DPI-C" function void difftest_step(input int pc);
    import "DPI-C" function void set_pc(input int pc);
    import "DPI-C" function void set_regfile();
    task run;
        integer i;
        begin
            i = 0;
            while( (u_CPU_top.instr!=32'h00100073) && (i<maxcycles))begin //TODO
                step();
                set_gpr_ptr(u_CPU_top.u_RegFile.rf);
                set_regfile();
                set_pc(u_CPU_top.pc);
                difftest_step(u_CPU_top.pc);
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
                $display("OK:test case %s finshed OK at cycle %d.\n\033[1;32mHIT GOOD TRAP\033[0m", testcase, numcycles-1);
            end
            else if(u_CPU_top.u_RegFile.rf[10]==32'h1)begin
                $display("!!!ERROR:test case %s finshed with error in cycle %d.\n\033[1;31mHIT BAD TRAP\033[0m", testcase, numcycles-1);
            end
            else begin
                $display("!!!ERROR:test case %s unknown error in cycle %d.", testcase, numcycles-1);
            end
        end
    endtask

    import "DPI-C" function void free_mem();
    import "DPI-C" function void init_difftest(input string ref_so_file, input longint img_size, input int port);
    task run_riscv_test;
        begin
            loadtestcase();
            init_difftest("riscv32-nemu-interpreter-so", img_size, 0);
            resetcpu();
            run();
            checkmagnum();
            free_mem();
        end
    endtask
endmodule
