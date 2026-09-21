<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project is a hardware-accelerated Regular Expression (Regex) Matcher. Unlike software regex engines that evaluate patterns sequentially and suffer from backtracking, this hardware design compiles the regex into a Non-deterministic Finite Automaton (NFA) where **every possible state is evaluated simultaneously in parallel**.

The matcher is hardcoded in silicon to detect a simplified email address format: `[a-z]+@[a-z]+\.com`. 

The design streams 8-bit ASCII characters (one per clock cycle) and uses simple combinational comparators to check for character classes (like `a-z`, `@`, and `.`). The progression through the regex is tracked by a series of Flip-Flops. Because the pattern is unanchored, the state machine actively searches for a valid substring match on every single clock cycle.

## How to test

1. Provide an active clock signal (`clk`) and hold `rst_n` low to reset the NFA state machine.
2. Set `rst_n` high to begin operation.
3. Stream an ASCII string into the 8 input pins (`ui_in`), providing exactly one character per clock cycle.
4. Monitor the `match` pin (`uo_out[0]`). It will pulse HIGH for exactly 1 clock cycle immediately after the final `m` in `.com` is received, indicating a successful match.

For example, streaming `hello@tapeout.com` will result in a match, while `hello@tapeoutcom` will not.

The remaining output pins (`uo_out[1:6]`) are connected directly to the internal state Flip-Flops, allowing you to visually debug the NFA's progression through the regex if hooked up to LEDs!

## External hardware

- Any microcontroller (like an Arduino or Raspberry Pi Pico) to stream the 8-bit parallel ASCII data into the `ui_in` pins at the desired clock rate.
- (Optional) LEDs connected to the `uo_out` pins to visualize the state machine progression and the final match.
