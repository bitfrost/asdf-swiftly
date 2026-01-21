#!/usr/bin/env bash

# Configuration
TOOL_NAME="swiftly"
DOWNLOAD_BASE_URL="https://download.swift.org/swiftly"

# Print error message and exit
fail() {
  echo -e "asdf-${TOOL_NAME}: $*" >&2
  exit 1
}

# Get the current platform (darwin or linux)
get_platform() {
  local platform
  platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

  case "$platform" in
    darwin)
      echo "darwin"
      ;;
    linux)
      echo "linux"
      ;;
    *)
      fail "Unsupported platform: $platform"
      ;;
  esac
}

# Get the current architecture
get_arch() {
  local arch
  arch="$(uname -m)"

  case "$arch" in
    x86_64)
      echo "x86_64"
      ;;
    aarch64 | arm64)
      echo "aarch64"
      ;;
    *)
      fail "Unsupported architecture: $arch"
      ;;
  esac
}

# Find executable files (cross-platform)
# macOS uses -perm +111, Linux uses -perm /111 or -executable
find_executable() {
  local dir="$1"
  local name="$2"

  # Try -executable first (GNU find), fall back to -perm /111, then -perm +111 (BSD)
  find "$dir" -name "$name" -type f -executable 2>/dev/null | head -1 ||
    find "$dir" -name "$name" -type f -perm /111 2>/dev/null | head -1 ||
    find "$dir" -name "$name" -type f -perm +111 2>/dev/null | head -1 ||
    echo ""
}

# Get the download URL for swiftly
# swift.org provides only the latest version at fixed URLs
get_download_url() {
  local platform arch

  platform="$(get_platform)"
  arch="$(get_arch)"

  case "$platform" in
    darwin)
      # macOS uses a universal .pkg file
      echo "${DOWNLOAD_BASE_URL}/darwin/swiftly.pkg"
      ;;
    linux)
      # Linux uses architecture-specific tarballs
      echo "${DOWNLOAD_BASE_URL}/linux/swiftly-${arch}.tar.gz"
      ;;
  esac
}

# Get the download filename
get_download_filename() {
  local platform arch

  platform="$(get_platform)"
  arch="$(get_arch)"

  case "$platform" in
    darwin)
      echo "swiftly.pkg"
      ;;
    linux)
      echo "swiftly-${arch}.tar.gz"
      ;;
  esac
}

# Download a file
download_file() {
  local url="$1"
  local output="$2"

  echo "Downloading ${TOOL_NAME} from ${url}..."

  if ! curl -fsSL --retry 3 --retry-delay 1 -o "$output" "$url"; then
    fail "Failed to download ${TOOL_NAME} from ${url}"
  fi
}

# List all available versions
# Since swift.org only provides the latest version, we just return "latest"
list_all_versions() {
  echo "latest"
}

# Get the latest stable version
get_latest_version() {
  echo "latest"
}

# Download swiftly to the specified path
download_swiftly() {
  local install_type="$1"
  local version="$2"
  local download_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-${TOOL_NAME} supports release installs only"
  fi

  local url filename

  url="$(get_download_url)"
  filename="$(get_download_filename)"

  mkdir -p "$download_path"
  download_file "$url" "${download_path}/${filename}"
}

# Install swiftly from the download path to the install path
install_swiftly() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"
  local download_path="$4"

  if [ "$install_type" != "version" ]; then
    fail "asdf-${TOOL_NAME} supports release installs only"
  fi

  local platform filename bin_path

  platform="$(get_platform)"
  filename="$(get_download_filename)"
  bin_path="${install_path}/bin"

  mkdir -p "$bin_path"

  case "$platform" in
    darwin)
      install_from_pkg "${download_path}/${filename}" "$bin_path"
      ;;
    linux)
      install_from_tarball "${download_path}/${filename}" "$bin_path"
      ;;
  esac

  # Verify installation
  if [ ! -x "${bin_path}/swiftly" ]; then
    fail "Installation failed: swiftly binary not found at ${bin_path}/swiftly"
  fi

  echo "${TOOL_NAME} ${version} installed successfully!"
}

# Install from macOS .pkg file
install_from_pkg() {
  local pkg_file="$1"
  local bin_path="$2"
  local temp_dir

  temp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$temp_dir'" EXIT

  echo "Extracting package..."

  # Expand the pkg to get the payload
  if ! pkgutil --expand "$pkg_file" "${temp_dir}/expanded"; then
    fail "Failed to expand package"
  fi

  # Find the payload (usually in a subfolder)
  local payload
  payload="$(find "${temp_dir}/expanded" -name 'Payload' -type f 2>/dev/null | head -1)"

  if [ -z "$payload" ]; then
    fail "Could not find Payload in package"
  fi

  # Extract the payload (it's a cpio archive, possibly gzipped)
  local payload_dir="${temp_dir}/payload"
  mkdir -p "$payload_dir"

  # Try to extract - the payload might be gzipped or plain cpio
  if file "$payload" | grep -q "gzip"; then
    if ! gunzip -c "$payload" | (cd "$payload_dir" && cpio -idm 2>/dev/null); then
      fail "Failed to extract gzipped payload"
    fi
  else
    if ! (cd "$payload_dir" && cpio -idm < "$payload" 2>/dev/null); then
      fail "Failed to extract payload"
    fi
  fi

  # Find the swiftly binary
  local swiftly_bin
  swiftly_bin="$(find_executable "$payload_dir" 'swiftly')"

  if [ -z "$swiftly_bin" ]; then
    # Try alternative search - may be in a different structure
    swiftly_bin="$(find "$payload_dir" -name 'swiftly' -type f 2>/dev/null | head -1)"
  fi

  if [ -z "$swiftly_bin" ]; then
    fail "Could not find swiftly binary in package"
  fi

  cp "$swiftly_bin" "${bin_path}/swiftly"
  chmod +x "${bin_path}/swiftly"

  trap - EXIT
  rm -rf "$temp_dir"
}

# Install from Linux tarball
install_from_tarball() {
  local tarball="$1"
  local bin_path="$2"
  local temp_dir

  temp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$temp_dir'" EXIT

  echo "Extracting tarball..."

  if ! tar -xzf "$tarball" -C "$temp_dir"; then
    fail "Failed to extract tarball"
  fi

  # Find the swiftly binary
  local swiftly_bin
  swiftly_bin="$(find_executable "$temp_dir" 'swiftly')"

  if [ -z "$swiftly_bin" ]; then
    # The tarball might just contain the binary directly
    swiftly_bin="$(find "$temp_dir" -name 'swiftly' -type f 2>/dev/null | head -1)"
  fi

  if [ -z "$swiftly_bin" ]; then
    fail "Could not find swiftly binary in tarball"
  fi

  cp "$swiftly_bin" "${bin_path}/swiftly"
  chmod +x "${bin_path}/swiftly"

  trap - EXIT
  rm -rf "$temp_dir"
}
