# dev_helpers.sh

This repository contains a collection of shell functions and aliases designed to help you quickly and consistently prepare your Linux system for **performance profiling**, **debugging**, and **low-level system configuration**. It gives you control over various CPU and memory settings, such as disabling **SMT** (hyper-threading), enabling/disabling **frequency scaling**, managing **RDPMC access**, and much more.

> **Note**: This script is meant to be **sourced** into a shell session, not executed directly. It enables quick and consistent adjustments of system settings.


## Features ✨

### **Tracing and Debugging** 🔍
- Enables access to **performance monitoring counters** (RDPMC).
- Allows **ptrace**, **kptr**, and **perf events** for system tracing.

### **CPU Management** ⚡
- **Disable** or **enable** hyper-threading (SMT).
- **Disable** efficiency cores (E-cores) to optimize power/thermal efficiency.
- Switch to **single-core mode** (only CPU0 active).
- **Restore** all CPU cores.

### **Security and Memory Management** 🔐
- **Disable** **Address Space Layout Randomization** (ASLR) for debugging.
- Manage kernel parameters related to **performance monitoring**.

### **Convenient Aliases** 💡
- Set up **easy-to-use aliases** for workflows like enabling VTune-like settings or restoring default configurations.



## Setup 🛠️

Follow these steps to get started:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Saket-Upadhyay/systems-dev-helpers.git
   ```

2. **Source the script** in your shell configuration:
   Add this line to your `.bashrc`, `.zshrc`, or the appropriate shell configuration file:
   ```bash
   source /path/to/dev_helpers.sh
   ```

3. **Reload the shell configuration**:
   - For **Bash**:
     ```bash
     source ~/.bashrc
     ```
   - For **Zsh**:
     ```bash
     source ~/.zshrc
     ```



## Usage 🚀

Once the script is sourced, you’ll have access to a variety of functions and aliases for system tuning:

### Core Functions ⚙️

- **`enable_tracing_privileges`**: Grants access to kernel-level tracing and debugging tools (e.g., **perf**, **ptrace**).
- **`disable_aslr`**: Disables **Address Space Layout Randomization** (ASLR) for debugging.
- **`undo_debug_privileges`**: Restores kernel settings to their default **secure configurations**.
- **`disable_e_cores`**: Disables **efficiency cores** on multi-core systems to optimize performance.
- **`restore_all_cores`**: **Re-enables all CPU cores**.
- **`switch_to_single_core_mode`**: Switches to **single-core mode** (only **CPU0** active).
- **`disable_smt`** / **`enable_smt`**: Disables or enables **hyper-threading** (SMT).
- **`disable_frequency_scaling`**: Forces CPU governors to **"performance"** mode, disabling dynamic frequency scaling.
- **`enable_frequency_scaling`**: Restores the **default frequency scaling** behavior.

### Aliases 🖥️

- **`vtune_mode`**: Set up the system for **performance profiling** with tracing enabled, **SMT** disabled, and **frequency scaling** disabled.
- **`debug_off`**: Restores all kernel settings to **secure default values**.
- **`single_core_mode`**: Switches to **single-core mode** (only **CPU0**).
- **`restore_cores`**: **Re-enables all CPU cores**.



### Example Usage 📚

1. **Enable VTune-like profiling mode**:

   ```bash
   vtune_mode
   ```

2. **Disable SMT and switch to single-core mode**:

   ```bash
   single_core_mode
   ```

3. **Restore all settings**:

   ```bash
   debug_off
   ```



> ⚠️**Direct Execution:**
> This script is designed to be **sourced**, not executed directly. If you try to run it as a standalone script, it will result in an error and exit immediately.

---

## Requirements 

- **Linux-based operating system**
- **`sudo` privileges** for most operations
- A **Bash** or **Zsh** shell environment


## Future Plans and Contributing 🤝

This script was originally developed as part of my memory tracing and performance analysis research. As such, some of the default configurations and tuning profiles are designed specifically for those use cases. 

The broader goal moving forward is to evolve the script into a **modular and extensible toolkit** for a wide range of system profiling, debugging, and benchmarking scenarios—enabling quick setup across diverse environments.

### Contributing

Contributions are highly encouraged. You are welcome to:

- Add new functions or profiles tailored to different performance tuning use cases
- Improve compatibility across distributions or kernel versions
- Refactor existing code for clarity or maintainability
- Report issues or suggest enhancements via GitHub Issues

To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes and follow the existing coding style
4. Submit a pull request for review

Please ensure that all contributions maintain consistency with the script’s existing structure and are clearly documented.



## License 📄

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---
