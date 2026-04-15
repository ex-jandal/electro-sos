# electro_sos ⚡🆘

> "This project is just advanced stupidity!"

`electro_sos` is a "Static Electricity Warning System" that monitors your body's static electricity levels and warns you when they go out of range. Since I don't actually have a sensor, it just guesses the numbers. :)

## Features

- **Real-time Monitoring**: Tracks simulated static electricity measurements.
- **Audio Alerts**:
  - 🚨 **Danger**: Plays "Mmaaa" when levels are too high.
  - 📉 **Under the Rate**: Plays "Rizz" when levels are too low.
- **Configurable**: Set your own safe ranges and polling intervals.
- **Cross-Language**: Core logic in **Zig** with a **C**-based audio player.

## Visuals

```text
                            .ssSSSSss.
                          .ER'      `AM.
                        .ST'          `CS.
                       .E'  .S.    .S.  `S.
                      .L'   SSS    SSS   `S.
                      S'    `S'    `S'    `S
                      S                    S
                      S                    S
                      S.  s.          .s   S
                      `S. `"s.      .s"'  S'
                       `S.  `"ss..ss"'  .S'
                        `SS.    ~~    .SS'
                          `SS.      .SS'
                            `SSssssSS'
```

## Installation & Building

### Prerequisites

#### 1. Zig & C Compiler
- [Zig](https://ziglang.org/download/) (0.16.x-dev recommended)
- `gcc` or any C compiler for the audio player.

#### 2. Linux Audio Headers
To compile the audio player on Linux, you'll need the following development libraries:
The audio player depends on [miniaudio](https://miniaud.io/).
```bash
# For Ubuntu/Debian:
sudo apt-get install libminiaudio-dev

# For Arch BTW:
sudo pacman -S miniaudio
```

### Build

```bash
zig build
```

This will:
1. Compile the C audio player in `src/c/player`.
2. Build the main `electrosos` executable.
3. Install the artifact to `zig-out/bin/`.

## Usage

Run the application with optional range and time interval flags:

```bash
zig build run -- [options]
```

### Options

- `-f, --from <isize>`: Set the lower bound of the safe range (default: 10).
- `-t, --to <isize>`: Set the upper bound of the safe range (default: from + 5).
- `-i, --time <usize>`: Set the measurement interval in milliseconds (default: 1000).
- `-h, --help`: Display help and exit.
- `-v, --version`: Display the app version.

### Examples

Run with custom range (0 to 100) and 500ms updates:
```bash
./zig-out/bin/electrosos -f 0 -t 100 -i 500
```

## How it Works

The system runs two main asynchronous tasks:
1. **Income Stream**: Simulates "sensor data" by generating random numbers around your specified range.
2. **Radar**: Evaluates the current measurement and triggers sound alerts if the level is `Danger` or `UnderTheRate`.

To exit the application, press `q` or `Esc`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
