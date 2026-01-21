# asdf-swiftly

[Swiftly](https://github.com/swiftlang/swiftly) plugin for the [asdf version manager](https://asdf-vm.com).

Swiftly is a Swift toolchain installer and manager, written in Swift. It allows you to easily install, manage, and switch between different Swift toolchains on Linux and macOS.

## Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Dependencies

- `bash`, `curl`, `tar`: generic POSIX utilities
- macOS: `pkgutil` (included with macOS)

## Install

Plugin:

```shell
asdf plugin add swiftly https://github.com/YOUR_USERNAME/asdf-swiftly.git
```

Or for local development:

```shell
asdf plugin add swiftly /path/to/asdf-swiftly
```

swiftly:

```shell
# Show all installable versions (currently only "latest" is available)
asdf list-all swiftly

# Install the latest version
asdf install swiftly latest

# Set a version globally (in your ~/.tool-versions file)
asdf global swiftly latest

# Now swiftly commands are available
swiftly --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to install & manage versions.

## Usage

After installing swiftly via asdf, you can use it to manage Swift toolchains:

```shell
# Install the latest Swift toolchain
swiftly install latest

# List installed toolchains
swiftly list

# Use a specific toolchain
swiftly use 6.0.3

# Check Swift version
swift --version
```

For more detailed usage, see the [Swiftly documentation](https://www.swift.org/swiftly).

## Version Note

This plugin installs the latest version of Swiftly from [swift.org](https://swift.org/install). Swift.org distributes only the current version of Swiftly without version-specific URLs, so this plugin supports `latest` as the only installable version.

To update to a newer version of Swiftly when one is released:

```shell
asdf uninstall swiftly latest
asdf install swiftly latest
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See [LICENSE](LICENSE) - MIT
