#!/usr/bin/env bash
# ==============================================================================
#  Script:     dev_helpers.sh
#  Author:     Saket Upadhyay
#  ------
#  Purpose:
#    This script provides a set of system configuration functions and aliases
#    intended to assist in preparing Linux systems for performance profiling,
#    low-level tracing, or other CPU/memory-sensitive debugging workflows.
#    > NOTE : Tested for Intel CPUs only.
#
#  Description:
#    - Enables or disables kernel-level security and tracing configurations
#    - Provides control over CPU features such as SMT, frequency scaling,
#      ASLR, and E-core management
#    - Manages access to RDPMC (Read Performance-Monitoring Counters)
#    - Offers convenience aliases for quickly switching between system modes
#    - Intended to be sourced by shell environments, not executed directly
#
#  Usage:
#    source ./dev_helpers.sh
#
#  Functions:
#    - enable_tracing_privileges       : Grants access to perf, ptrace, kptr
#    - disable_aslr                    : Disables address space layout randomization
#    - undo_debug_privileges           : Restores kernel defaults for tracing/debugging
#    - disable_e_cores                 : Disables efficiency (low-power) CPU cores
#    - restore_all_cores               : Re-enables all CPU cores
#    - switch_to_single_core_mode      : Disables all but the primary core (cpu0)
#    - disable_smt / enable_smt        : Disables/enables hyper-threading
#    - disable_frequency_scaling       : Sets all CPU governors to 'performance'
#    - enable_frequency_scaling        : Restores default frequency scaling behavior
#
#  Aliases:
#    - vtune_mode        : Enables perf tracing, disables SMT, ASLR, and scaling
#    - debug_off         : Restores all system settings to default values
#    - single_core_mode  : Enables single-core mode (cpu0 only)
#    - restore_cores     : Re-enables all logical cores
#
#  Notes:
#    - This script must be sourced into the current shell environment.
#      Direct execution will result in an error and immediate exit.
#    - Elevated privileges (sudo/root) are required for most operations.
#
# ==============================================================================


# MIT License

# Copyright (c) 2025 Saket Upadhyay

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ==============================================================================

## VARS
RPMC_PATH="/sys/bus/event_source/devices/cpu/rdpmc"
_setvars_this_script_name="dev_helpers.sh"

# Prevent direct execution (Inspired from Intel's Vtune setvars.sh)
local_exit_call() {
  script_return_code=$1

  # make sure we're dealing with numbers
  # TODO: add check for non-numeric return codes.
  if [ "$script_return_code" = "" ] ; then
    script_return_code=255
  fi

  if [ "$script_return_code" -eq 0 ] ; then
    SETVARS_COMPLETED=1 ; export SETVARS_COMPLETED
  fi

  exit "$script_return_code"
}


_get_current_proc_name() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    # Zsh: use 'ps' to get the command name of the current process
    curr_script="$(ps -p "$$" -o comm=)"
  else
    # Bash or other POSIX shells: resolve symlinks manually
    curr_script="$1"
    while [ -L "$script" ]; do
      curr_script="$(readlink "$curr_script")"
    done
  fi
  basename -- "$curr_script"
}



# If invoked directly, show error and exit
if [ "$_setvars_this_script_name" = "$(_get_current_proc_name "$0")" ]; then
  echo ""
  echo "❌ This script is meant to be sourced, not executed directly."
  echo "💡 Use: source "$(realpath ${0})""
  local_exit_call 255
fi


# === FUNCTIONS ===

enable_tracing_privileges() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  if [ "$($SUDO_CMD cat /proc/sys/kernel/perf_event_paranoid)" -ne -1 ]; then
    echo -1 | $SUDO_CMD tee /proc/sys/kernel/perf_event_paranoid > /dev/null
    echo "✅ perf_event_paranoid set to -1"
  else
    echo "ℹ️  perf_event_paranoid is already -1"
  fi

  if [ "$($SUDO_CMD cat /proc/sys/kernel/kptr_restrict)" -ne 0 ]; then
    echo 0 | $SUDO_CMD tee /proc/sys/kernel/kptr_restrict > /dev/null
    echo "✅ kptr_restrict set to 0"
  else
    echo "ℹ️  kptr_restrict is already 0"
  fi

  if [ "$($SUDO_CMD cat /proc/sys/kernel/yama/ptrace_scope)" -ne 0 ]; then
    echo 0 | $SUDO_CMD tee /proc/sys/kernel/yama/ptrace_scope > /dev/null
    echo "✅ ptrace_scope set to 0"
  else
    echo "ℹ️  ptrace_scope is already 0"
  fi


if [ -f "$RPMC_PATH" ]; then
  CURRENT_RDPMC="$($SUDO_CMD cat $RPMC_PATH)"

  if [ "$CURRENT_RDPMC" -ne 2 ]; then
    echo 2 | $SUDO_CMD tee $RPMC_PATH > /dev/null
    echo "✅ RDPMC is now enabled for programmable counters only (value set to 2)."
  else
    echo "ℹ️  RDPMC is already set to 2 (programmable counters only)."
  fi
else
  echo "❌ RDPMC configuration file not found: $RPMC_PATH"
  echo "   This likely means your kernel or hardware does not support user-space RDPMC access."
fi


}

disable_aslr(){
    if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi
    if [ "$($SUDO_CMD cat /proc/sys/kernel/randomize_va_space)" -ne 0 ]; then
    echo 0 | $SUDO_CMD tee /proc/sys/kernel/randomize_va_space > /dev/null
    echo "✅ ASLR disabled (randomize_va_space = 0)"
  else
    echo "ℹ️  ASLR already disabled"
  fi
}

disable_e_cores() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  local P_CORE_FREQ=3200000
  local D_COUNT=0

  for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
    if [ -f "$CPU/cpufreq/base_frequency" ] && [ "$(cat "$CPU/cpufreq/base_frequency")" -ne 0 ]; then
      if [ "$(cat "$CPU/cpufreq/base_frequency")" -lt "$P_CORE_FREQ" ]; then
        echo "Disabling E-Core: $CPU"
        echo 0 | $SUDO_CMD tee "$CPU/online"
        D_COUNT=$((D_COUNT + 1))
      fi
    fi
  done

  echo "✅ $D_COUNT E-Cores disabled"
}

disable_frequency_scaling() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  for GOVERNOR in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" | sudo tee "$GOVERNOR" > /dev/null
  done

  echo 1 | $SUDO_CMD tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null


  echo "✅ Frequency scaling disabled, turbo disabled"
}

enable_frequency_scaling() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  for GOVERNOR in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" | sudo tee "$GOVERNOR" > /dev/null
  done

  echo 0 | $SUDO_CMD tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null


  echo "✅ Frequency scaling enabled, turbo disabled"
}


disable_smt() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  if [ "$(cat /sys/devices/system/cpu/smt/active)" -ne 0 ]; then
    echo off | $SUDO_CMD tee /sys/devices/system/cpu/smt/control
    echo "✅ SMT (Hyper-threading) disabled"
  else
    echo "ℹ️  SMT already disabled"
  fi
}



enable_smt() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  if [ "$(cat /sys/devices/system/cpu/smt/active)" -ne 1 ]; then
    echo on | $SUDO_CMD tee /sys/devices/system/cpu/smt/control
    echo "✅ SMT (Hyper-threading) enabled"
  else
    echo "ℹ️  SMT already enabled"
  fi
}


restore_all_cores() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges to restore cores..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  for CPU in /sys/devices/system/cpu/cpu[1-9]*; do
    echo 1 | $SUDO_CMD tee "$CPU/online" > /dev/null
  done

  echo "✅ All cores re-enabled"
}

switch_to_single_core_mode() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  for CPU in /sys/devices/system/cpu/cpu[1-9]*; do
    echo 0 | $SUDO_CMD tee "$CPU/online"
  done

  echo "✅ Switched to single-core mode (only cpu0 active)"
}


undo_debug_privileges() {
  if [ "$EUID" -ne 0 ]; then
    echo "🔐 Requesting elevated privileges to restore defaults..."
    if ! sudo -v; then
      echo "❌ Failed to gain sudo access. Aborting." >&2
      return 1
    fi
    SUDO_CMD="sudo"
  else
    SUDO_CMD=""
  fi

  echo 2 | $SUDO_CMD tee /proc/sys/kernel/perf_event_paranoid > /dev/null
  echo "🔁 perf_event_paranoid reset to 2 (default)"

  echo 1 | $SUDO_CMD tee /proc/sys/kernel/kptr_restrict > /dev/null
  echo "🔁 kptr_restrict reset to 1 (default)"

  echo 1 | $SUDO_CMD tee /proc/sys/kernel/yama/ptrace_scope > /dev/null
  echo "🔁 ptrace_scope reset to 1 (default)"

  echo 2 | $SUDO_CMD tee /proc/sys/kernel/randomize_va_space > /dev/null
  echo "🔁 ASLR re-enabled (randomize_va_space = 2)"



  if [ -f "$RPMC_PATH" ]; then
    CURRENT_RDPMC="$($SUDO_CMD cat $RPMC_PATH)"

    if [ "$CURRENT_RDPMC" -ne 0 ]; then
      echo 0 | $SUDO_CMD tee $RPMC_PATH > /dev/null
      echo "🔁 RDPMC reset to 0 (default)"
    else
      echo "ℹ️  RDPMC is already set to 0"
    fi
  else
    echo "❌ RDPMC file not found: $RPMC_PATH"
    echo "   This likely means your kernel or hardware does not support user-space RDPMC access."
  fi


  enable_smt
  restore_all_cores
  enable_frequency_scaling

  echo "✅ Kernel debug settings restored to secure defaults"
}

#  ===============================================================================

# QUICK ALIASES

alias debug_off='undo_debug_privileges'
alias single_core_mode='switch_to_single_core_mode'
alias restore_cores='restore_all_cores'
alias vtune_mode='enable_tracing_privileges && disable_frequency_scaling && disable_smt && disable_aslr'

# Only show banner if QUIET_LOAD is not set
if [ -z "$QUIET_LOAD" ]; then
  echo "🛠️  System testing functions and aliases loaded."
  echo "[https://github.com/Saket-Upadhyay/systems-dev-helpers.git]"
  echo ""
  echo "📦 Functions:"
  echo "   • enable_tracing_privileges     – Enable perf, ptrace, kptr access"
  echo "   • disable_aslr                  – Disable address space randomization"
  echo "   • undo_debug_privileges         – Restore all kernel debug defaults"
  echo "   • disable_e_cores               – Disable efficiency cores"
  echo "   • restore_all_cores             – Re-enable all CPU cores"
  echo "   • switch_to_single_core_mode    – Run with only one core (cpu0)"
  echo "   • disable_smt                   – Disable hyper-threading"
  echo "   • disable_frequency_scaling     – Set governor to 'performance'"
  echo ""
  echo "⚡ Aliases:"
  echo "   • vtune_mode        → enable_tracing_privileges + tuning"
  echo "   • debug_off         → undo_debug_privileges"
  echo "   • single_core_mode  → switch_to_single_core_mode"
  echo "   • restore_cores     → restore_all_cores"
fi
