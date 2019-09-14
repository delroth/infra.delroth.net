{ ... }: {
  # Make CFS less stupid and apply niceness across task groups.
  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 0;
    "kernel.sched_migration_cost_ns" = 5000000;
  };
}
