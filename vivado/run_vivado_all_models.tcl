# ============================================================
#  run_vivado_all_models.tcl
#
#  Synthesizes every generated design with Vivado and writes one JSON line per design to
#  vivado_metrics.jsonl (merge it into the results JSON with merge_vivado_results.py).
#
#  Languages: v (Verilog-2001), sv (SystemVerilog), vhd (VHDL-2008). One file per language per
#  task folder, named after the top module (adder/add.v); the file name is passed to -top.
#
#  Run from the results folder (it is the working folder: Generated_RTL/ must be inside it):
#    cd results/open_models
#    vivado -mode batch -source ../../vivado/run_vivado_all_models.tcl -log vivado_all.log
#  Another folder:  ... -log vivado_all.log -tclargs /path/to/results_folder   (-log must point inside it)
#
#  Per design it records LUT, FF, DSP, BRAM, total/dynamic/static power, WNS and
#  delay = clock period - WNS. Combinational designs get a virtual clock + 0 ns I/O delays.
#  Reports for every design are kept in vivado_work/<model>/<task>/<lang>/ (util / timing / power).
# ============================================================

# Results folder: first -tclargs argument, else the current directory.
if {[info exists ::argv] && [llength $::argv] > 0} {
    set BASE_DIR [file normalize [lindex $::argv 0]]
} else {
    set BASE_DIR [file normalize [pwd]]
}
set GENERATED_RTL_DIR "$BASE_DIR/Generated_RTL"
set WORK_DIR          "$BASE_DIR/vivado_work"
set METRICS_JSONL     "$BASE_DIR/vivado_metrics.jsonl"
set LOG_FILE          "$BASE_DIR/vivado_all.log"   ;# must match -log in the command above
set TARGET_PART       "xc7s50csga324-1"
set CLK_PERIOD        10.0     ;# ns
set RUN_IMPL          0        ;# 1 = opt/place/route, report from routed design (slow)
set ONLY_MODELS       {}       ;# e.g. {starcoder2-7b} = only these model folders (writes vivado_metrics_<model>.jsonl, old file untouched)
set ONLY_FAILED_FROM  ""       ;# e.g. "$BASE_DIR/vivado_metrics.jsonl" = re-run only designs that failed there
                                ;# (writes vivado_metrics_failed.jsonl; use batch mode + -log to capture real errors)

# ── helpers ───────────────────────────────────────────────────
proc read_file {path} {
    set fh [open $path r]; set t [read $fh]; close $fh; return $t
}

proc jstr {s} {
    set s [string map [list \\ \\\\ \" \\\" \n \\n \r \\r \t \\t] $s]
    return "\"$s\""
}
proc jnum {v} {
    if {[string is double -strict $v]} { return $v }
    return null
}
proc jbool {v} { expr {$v ? "true" : "false"} }

# first capture group of the first pattern that matches, else "null"
proc first_match {txt pats} {
    foreach p $pats {
        if {[regexp -- $p $txt -> v]} { return $v }
    }
    return null
}

proc rpt {path} {
    if {![file exists $path]} { return "" }
    return [read_file $path]
}

proc parse_luts {txt} {
    first_match $txt {
        {Slice LUTs\*?\s*\|\s*(\d+)}
        {CLB LUTs\*?\s*\|\s*(\d+)}
        {LUT as Logic\s*\|\s*(\d+)}
    }
}
proc parse_ffs {txt} {
    first_match $txt {
        {Slice Registers\s*\|\s*(\d+)}
        {CLB Registers\s*\|\s*(\d+)}
        {Register as Flip Flop\s*\|\s*(\d+)}
    }
}
proc parse_dsp {txt} {
    first_match $txt {
        {\|\s*DSPs\s*\|\s*(\d+)}
        {\|\s*DSP48 Blocks\s*\|\s*(\d+)}
    }
}
proc parse_bram {txt} {
    first_match $txt {
        {\|\s*Block RAM Tile\s*\|\s*([\d.]+)}
    }
}
proc parse_power_total {txt} {
    first_match $txt {{Total On-Chip Power \(W\)\s*\|\s*([\d.]+)}}
}
proc parse_power_dyn {txt} {
    first_match $txt {{\|\s*Dynamic \(W\)\s*\|\s*([\d.]+)}}
}
proc parse_power_static {txt} {
    first_match $txt {{Device Static \(W\)\s*\|\s*([\d.]+)}}
}

# WNS from the "Design Timing Summary" table:
#   header line (WNS(ns) TNS(ns) ...), a dashes line, then the value line.
# Returns "null" when the value is NA (no constrained paths) - never a dashes string.
proc parse_wns {txt} {
    set lines [split $txt "\n"]
    set n [llength $lines]
    for {set i 0} {$i < $n} {incr i} {
        if {[regexp {WNS\(ns\)\s+TNS\(ns\)} [lindex $lines $i]]} {
            set vline [lindex $lines [expr {$i + 2}]]
            set tok [lindex [regexp -inline -all {\S+} $vline] 0]
            if {[string is double -strict $tok]} { return $tok }
            return null
        }
    }
    return null
}

# ERROR: lines that Vivado wrote to the log since byte offset `off`.
# Best effort: the log may not be fully flushed yet.
proc log_errors {logfile off} {
    if {![file exists $logfile]} { return "" }
    set fh [open $logfile r]
    seek $fh $off
    set txt [read $fh]
    close $fh
    set errs {}
    foreach line [split $txt "\n"] {
        if {[regexp {^ERROR:} $line]} { lappend errs [string trim $line] }
    }
    return [join [lrange $errs 0 4] " | "]
}

proc write_reports {pdir prefix} {
    catch { report_utilization    -file "$pdir/${prefix}util.rpt" }
    catch { report_timing_summary -file "$pdir/${prefix}timing.rpt" }
    catch { report_power          -file "$pdir/${prefix}power.rpt" }
}

# ── synthesize (and optionally implement) one file ────────────
proc run_design {src lang pdir part period run_impl logfile} {
    array set r {ok false luts null ffs null dsp null bram null pwr null pdyn null
                 pstat null wns null dly null clk none stage synth err ""}
    set log_off 0
    if {[file exists $logfile]} { set log_off [file size $logfile] }

    if {[catch {
        create_project -in_memory -part $part
        add_files -norecurse $src
        switch $lang {
            v       { set_property FILE_TYPE {Verilog}       [get_files $src] }
            sv      { set_property FILE_TYPE {SystemVerilog} [get_files $src] }
            default { set_property FILE_TYPE {VHDL 2008}     [get_files $src] }
        }
        set top [file rootname [file tail $src]]
        synth_design -top $top -part $part -mode out_of_context

        # --- constraints: real clock if there is a clock-like input, else virtual ---
        set clk_name ""
        foreach p [get_ports -quiet -filter {DIRECTION == IN}] {
            if {[regexp -nocase {clk|clock} [get_property NAME $p]]} {
                set clk_name [get_property NAME $p]; break
            }
        }
        if {$clk_name ne ""} {
            create_clock -name clk -period $period [get_ports $clk_name]
            set cref clk;  set r(clk) $clk_name
            set in_ports [get_ports -quiet -filter "DIRECTION == IN && NAME != $clk_name"]
        } else {
            create_clock -name vclk -period $period
            set cref vclk; set r(clk) virtual
            set in_ports [get_ports -quiet -filter {DIRECTION == IN}]
        }
        set out_ports [get_ports -quiet -filter {DIRECTION == OUT}]
        if {[llength $in_ports]  > 0} { set_input_delay  0 -clock $cref $in_ports }
        if {[llength $out_ports] > 0} { set_output_delay 0 -clock $cref $out_ports }

        write_reports $pdir ""
        set prefix ""

        if {$run_impl} {
            opt_design
            place_design
            route_design
            write_reports $pdir "impl_"
            set prefix "impl_"
            set r(stage) impl
        }

        set util [rpt "$pdir/${prefix}util.rpt"]
        set tim  [rpt "$pdir/${prefix}timing.rpt"]
        set pwr  [rpt "$pdir/${prefix}power.rpt"]
        set r(luts)  [parse_luts $util]
        set r(ffs)   [parse_ffs  $util]
        set r(dsp)   [parse_dsp  $util]
        set r(bram)  [parse_bram $util]
        set r(pwr)   [parse_power_total  $pwr]
        set r(pdyn)  [parse_power_dyn    $pwr]
        set r(pstat) [parse_power_static $pwr]
        set r(wns)   [parse_wns $tim]
        if {[string is double -strict $r(wns)]} {
            set r(dly) [format %.3f [expr {$period - $r(wns)}]]
        }
        if {$r(clk) eq "virtual" && [string is integer -strict $r(ffs)] && $r(ffs) > 0} {
            set r(clk) "virtual_but_has_FFs"   ;# flip-flops exist but no clock-like port was found
        }
        set r(ok) true
    } catch_err]} {
        set r(err) [string trim $catch_err]
        after 500                      ;# let Vivado flush the log
        set le [log_errors $logfile $log_off]
        if {$le ne ""} { set r(err) $le }
        catch { file mkdir $pdir; set fh [open "$pdir/errors.txt" w]; puts $fh $r(err); close $fh }
    }
    catch { close_project }
    return [array get r]
}

proc metrics_line {model task lang res} {
    array set r $res
    return [format {{"model":%s,"task_id":%s,"lang":%s,"stage":%s,"success":%s,"area":%s,"ff":%s,"dsp":%s,"bram":%s,"power":%s,"power_dynamic":%s,"power_static":%s,"wns":%s,"delay":%s,"clock":%s,"error":%s}} \
        [jstr $model] [jstr $task] [jstr $lang] [jstr $r(stage)] [jbool $r(ok)] \
        [jnum $r(luts)] [jnum $r(ffs)] [jnum $r(dsp)] [jnum $r(bram)] \
        [jnum $r(pwr)] [jnum $r(pdyn)] [jnum $r(pstat)] [jnum $r(wns)] [jnum $r(dly)] \
        [jstr $r(clk)] [jstr $r(err)]]
}

# lets you source this file in tclsh to unit-test the parsers
if {[info exists ::PARSE_TEST]} { return }

# ════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════
file mkdir $WORK_DIR
puts "Work dir: $WORK_DIR | Part: $TARGET_PART | Clock: $CLK_PERIOD ns | Impl: $RUN_IMPL"

set model_dirs [glob -nocomplain -type d "$GENERATED_RTL_DIR/*"]
if {[llength $model_dirs] == 0} { puts "No model folders in $GENERATED_RTL_DIR"; return }

set only_failed [dict create]
if {$ONLY_FAILED_FROM ne ""} {
    foreach line [split [read_file $ONLY_FAILED_FROM] "\n"] {
        if {[regexp {"success":false} $line] &&
            [regexp {"model":"([^"]*)","task_id":"([^"]*)","lang":"([^"]*)"} $line -> fm ft fl]} {
            dict set only_failed "$fm/$ft/$fl" 1
        }
    }
    set METRICS_JSONL "[file rootname $METRICS_JSONL]_failed.jsonl"
    puts "Re-running [dict size $only_failed] previously failed designs -> $METRICS_JSONL"
}

if {[llength $ONLY_MODELS] > 0} {
    set METRICS_JSONL "[file rootname $METRICS_JSONL]_[join $ONLY_MODELS _].jsonl"
    puts "Only models: $ONLY_MODELS -> $METRICS_JSONL"
}

set out [open $METRICS_JSONL w]
fconfigure $out -encoding utf-8
set grand_pass 0; set grand_total 0

foreach model_dir $model_dirs {
    set model [file tail $model_dir]
    if {[llength $ONLY_MODELS] > 0 && [lsearch -exact $ONLY_MODELS $model] < 0} { continue }
    puts "\n[string repeat = 62]\n  MODEL: $model\n[string repeat = 62]"
    set m_pass 0; set m_total 0

    foreach bench_dir [glob -nocomplain -type d "$model_dir/*"] {
        set task [file tail $bench_dir]
        foreach {lang ext} {v .v  sv .sv  vhd .vhd} {
            ;# the notebook names each file after the top module (e.g. adder/add.v); top = file name
            set src [lindex [lsort [glob -nocomplain -directory $bench_dir *$ext]] 0]
            if {$src eq ""} { continue }            ;# invalid RTL: already recorded by the notebook
            if {$ONLY_FAILED_FROM ne "" && ![dict exists $only_failed "$model/$task/$lang"]} { continue }
            set pdir "$WORK_DIR/$model/$task/$lang"
            file mkdir $pdir

            puts "\n### DESIGN $model/$task/$lang"    ;# marker: merge_vivado_results.py reads the log with it
            puts -nonewline "  \[$task / [string toupper $lang]\]  "
            set res [run_design $src $lang $pdir $TARGET_PART $CLK_PERIOD $RUN_IMPL $LOG_FILE]
            array set r $res
            incr m_total
            if {$r(ok)} {
                incr m_pass
                puts "PASS  LUT=$r(luts) FF=$r(ffs) DSP=$r(dsp) Pwr=$r(pwr)W WNS=$r(wns) delay=$r(dly) clk=$r(clk)"
            } else {
                puts "FAIL  [string range $r(err) 0 90]"
            }
            puts $out [metrics_line $model $task $lang $res]
            flush $out
            array unset r
        }
    }
    puts "\n  -> $model: $m_pass / $m_total synthesized"
    incr grand_pass $m_pass; incr grand_total $m_total
}
close $out
puts "\nDone: $grand_pass / $grand_total passed. Metrics: $METRICS_JSONL"
