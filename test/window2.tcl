# 2018 May 19
#
# The author disclaims copyright to this source code.  In place of
# a legal notice, here is a blessing:
#
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#
#***********************************************************************
#

package require sqlite3
package require Pgtcl

set db [pg_connect -conninfo "dbname=postgres user=postgres password=postgres"]
sqlite3 sqlite ""

proc execsql {sql} {

  set lSql [list]
  set frag ""
  while {[string length $sql]>0} {
    set i [string first ";" $sql]
    if {$i>=0} {
      append frag [string range $sql 0 $i]
      set sql [string range $sql $i+1 end]
      if {[sqlite complete $frag]} {
        lappend lSql $frag
        set frag ""
      }
    } else {
      set frag $sql
      set sql ""
    }
  }
  if {$frag != ""} {
    lappend lSql $frag
  }
  #puts $lSql

  set ret ""
  foreach stmt $lSql {
    set res [pg_exec $::db $stmt]
    set err [pg_result $res -error]
    if {$err!=""} { error $err }
    for {set i 0} {$i < [pg_result $res -numTuples]} {incr i} {
      if {$i==0} {
        set ret [pg_result $res -getTuple 0]
      } else {
        append ret "   [pg_result $res -getTuple $i]"
      }
      # lappend ret {*}[pg_result $res -getTuple $i]
    }
    pg_result $res -clear
  }

  set ret
}

proc execsql_test {tn sql} {
  set res [execsql $sql]
  puts $::fd "do_execsql_test $tn {"
  puts $::fd "  [string trim $sql]"
  puts $::fd "} {$res}"
  puts $::fd ""
}

proc start_test {name date} {
  set dir [file dirname $::argv0]
  set output [file join $dir $name.test]
  set ::fd [open $output w]
puts $::fd [string trimleft "
# $date
#
# The author disclaims copyright to this source code.  In place of
# a legal notice, here is a blessing:
#
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#
#***********************************************************************
# This file implements regression tests for SQLite library.
#

####################################################
# DO NOT EDIT! THIS FILE IS AUTOMATICALLY GENERATED!
####################################################
"]
  puts $::fd {set testdir [file dirname $argv0]}
  puts $::fd {source $testdir/tester.tcl}
  puts $::fd "set testprefix $name"
  puts $::fd ""
}

proc -- {args} {
  puts $::fd "# $args"
}

proc ========== {args} {
  puts $::fd "#[string repeat = 74]"
  puts $::fd ""
}

proc finish_test {} {
  puts $::fd finish_test
  close $::fd
}

#=========================================================================


start_test window2 "2018 May 19"

execsql_test 1.0 {
  DROP TABLE IF EXISTS t1;
  CREATE TABLE t1(a INTEGER PRIMARY KEY, b TEXT, c TEXT, d INTEGER);
  INSERT INTO t1 VALUES(1, 'odd',  'one',   1);
  INSERT INTO t1 VALUES(2, 'even', 'two',   2);
  INSERT INTO t1 VALUES(3, 'odd',  'three', 3);
  INSERT INTO t1 VALUES(4, 'even', 'four',  4);
  INSERT INTO t1 VALUES(5, 'odd',  'five',  5);
  INSERT INTO t1 VALUES(6, 'even', 'six',   6);
}

execsql_test 1.1 {
  SELECT c, sum(d) OVER (PARTITION BY b ORDER BY c) FROM t1;
}

execsql_test 1.2 {
  SELECT sum(d) OVER () FROM t1;
}

execsql_test 1.3 {
  SELECT sum(d) OVER (PARTITION BY b) FROM t1;
}

==========
execsql_test 2.1 {
  SELECT a, sum(d) OVER (
    ORDER BY d
    ROWS BETWEEN 1000 PRECEDING AND 1 FOLLOWING
  ) FROM t1
}
execsql_test 2.2 {
  SELECT a, sum(d) OVER (
    ORDER BY d
    ROWS BETWEEN 1000 PRECEDING AND 1000 FOLLOWING
  ) FROM t1
}
execsql_test 2.3 {
  SELECT a, sum(d) OVER (
    ORDER BY d
    ROWS BETWEEN 1 PRECEDING AND 1000 FOLLOWING
  ) FROM t1
}
execsql_test 2.4 {
  SELECT a, sum(d) OVER (
    ORDER BY d
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ) FROM t1
}
execsql_test 2.5 {
  SELECT a, sum(d) OVER (
    ORDER BY d
    ROWS BETWEEN 1 PRECEDING AND 0 FOLLOWING
  ) FROM t1
}

execsql_test 2.6 {
  SELECT a, sum(d) OVER (
    PARTITION BY b
    ORDER BY d 
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ) FROM t1
}

execsql_test 2.7 {
  SELECT a, sum(d) OVER (
    PARTITION BY b
    ORDER BY d 
    ROWS BETWEEN 0 PRECEDING AND 0 FOLLOWING
  ) FROM t1
}

execsql_test 2.8 {
  SELECT a, sum(d) OVER (
    ORDER BY d 
    ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING
  ) FROM t1
}

execsql_test 2.9 {
  SELECT a, sum(d) OVER (
    ORDER BY d 
    ROWS BETWEEN UNBOUNDED PRECEDING AND 2 FOLLOWING
  ) FROM t1
}

execsql_test 2.10 {
  SELECT a, sum(d) OVER (
    ORDER BY d 
    ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING
  ) FROM t1
}

execsql_test 2.11 {
  SELECT a, sum(d) OVER (
    ORDER BY d 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) FROM t1
}

execsql_test 2.13 {
  SELECT a, sum(d) OVER (
    ORDER BY d 
    ROWS BETWEEN 2 PRECEDING AND UNBOUNDED FOLLOWING
  ) FROM t1
}

execsql_test 2.14 {
  SELECT a, sum(d) OVER (
    ORDER BY d 
    ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
  ) FROM t1
}

execsql_test 2.15 {
  SELECT a, sum(d) OVER (
    PARTITION BY b
    ORDER BY d 
    ROWS BETWEEN 1 PRECEDING AND 0 PRECEDING
  ) FROM t1
}

execsql_test 2.16 {
  SELECT a, sum(d) OVER (
    PARTITION BY b
    ORDER BY d 
    ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING
  ) FROM t1
}

execsql_test 2.17 {
  SELECT a, sum(d) OVER (
    PARTITION BY b
    ORDER BY d 
    ROWS BETWEEN 1 PRECEDING AND 2 PRECEDING
  ) FROM t1
}

execsql_test 2.18 {
  SELECT a, sum(d) OVER (
    PARTITION BY b
    ORDER BY d 
    ROWS BETWEEN UNBOUNDED PRECEDING AND 2 PRECEDING
  ) FROM t1
}

execsql_test 2.19 {
  SELECT a, sum(d) OVER (
    PARTITION BY b
    ORDER BY d 
    ROWS BETWEEN 1 FOLLOWING AND 3 FOLLOWING
  ) FROM t1
}

execsql_test 2.20 {
  SELECT a, sum(d) OVER (
    ORDER BY d 
    ROWS BETWEEN 1 FOLLOWING AND 2 FOLLOWING
  ) FROM t1
}

execsql_test 2.21 {
  SELECT a, sum(d) OVER (
    ORDER BY d 
    ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING
  ) FROM t1
}

execsql_test 2.22 {
  SELECT a, sum(d) OVER (
    PARTITION BY b
    ORDER BY d 
    ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING
  ) FROM t1
}

==========
puts $::fd finish_test
==========

# execsql_test 3.1 {
#   SELECT a, sum(d) OVER (
#     PARTITION BY b ORDER BY d
#     RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
#   ) FROM t1
# }
# 
# execsql_test 3.2 {
#   SELECT a, sum(d) OVER (
#     ORDER BY b
#     RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
#   ) FROM t1
# }
# 
# execsql_test 3.3 {
#   SELECT a, sum(d) OVER (
#     ORDER BY d
#     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
#   ) FROM t1
# }

finish_test


