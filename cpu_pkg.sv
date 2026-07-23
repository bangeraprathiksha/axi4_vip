package cpu_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  // Transaction
  `include "cpu_seq_item.sv"

  // Sequence
  `include "cpu_sequence.sv"

  // Sequencer
  `include "cpu_sequencer.sv"

  // Driver
  `include "cpu_driver.sv"

  // Monitors
  `include "cpu_active_monitor.sv"
  `include "cpu_passive_monitor.sv"

  // Agents
  `include "cpu_active_agent.sv"
  `include "cpu_passive_agent.sv"

  // Subscriber
  `include "cpu_subscriber.sv"

  // Scoreboard
  `include "cpu_scoreboard.sv"

  // Environment
  `include "cpu_env.sv"

  // Test
  `include "cpu_test.sv"

endpackage
