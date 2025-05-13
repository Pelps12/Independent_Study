`timescale 1ns/1ps

module OneSecPulse_tb;

  // DUT signals
  reg         clk;
  reg         rst_n;
  wire        pulse_1s;

  // Instantiate the design under test
  WDT_Basic #(
    .CLK_FREQ_HZ(3_000_000)
  ) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .pulse_1s (pulse_1s)
  );

  // Clock generator: 3 MHz => T = 333.333 ns, half-period ≈ 166.667 ns
  parameter real HALF_PERIOD = 166.667;
  initial begin
    clk = 0;
    forever #(HALF_PERIOD) clk = ~clk;
  end

  // VCD dump and stimulus
  initial begin
    // --- VCD Dump Setup ---
    $dumpfile("trace.vcd");
    $dumpvars(0, OneSecPulse_tb);

    // --- Reset ---
    rst_n = 0;
    #100;           // hold reset for 100 ns
    rst_n = 1;

    // --- Run long enough to capture a couple of pulses ---
    #5000000000;    // 2 seconds in ns

    $display("Simulation complete at %0t ns", $time);
    $finish;
  end

  // Optional monitor for console output
  initial begin
    $display("Time (ns) | pulse_1s");
    $monitor("%10t |    %b", $time, pulse_1s);
  end

endmodule
