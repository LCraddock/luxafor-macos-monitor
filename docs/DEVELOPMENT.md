# Development Notes

## Repository Structure

```
luxafor-macos-monitor/
├── install.sh              # Main installer script
├── uninstall.sh           # Uninstaller
├── luxafor-notify.sh      # Main monitoring script
├── luxafor-control.sh     # Service control script
├── luxafor-config.conf    # Default configuration
├── luxafor-toggle.1s.sh   # SwiftBar plugin
├── luxafor-test.sh        # LED test scripts
├── luxafor-quick-test.sh
├── com.luxafor.notify.plist # Launch agent definition
├── setup-launch-agent.sh  # Launch agent installer
├── README.md              # This file
├── LICENSE               # MIT License
└── .gitignore
```

## Handling luxafor-cli Dependency

We have several options for including the modified luxafor-cli:

### Option 1: Git Submodule (Recommended)
```bash
# Add as submodule
git submodule add https://github.com/mike-rogers/luxafor-cli.git
cd luxafor-cli
git checkout -b enhanced-colors
# Apply your modifications
git commit -am "Add enhanced color support"
```

Then update install.sh to use the submodule.

### Option 2: Fork and Reference
1. Fork https://github.com/mike-rogers/luxafor-cli to your GitHub
2. Apply your enhancements
3. Update install.sh to clone from your fork

### Option 3: Build from Source
Include build instructions and patches in the installer.

### Option 4: Pre-built Binary
- Build for common architectures (Intel/Apple Silicon)
- Include binaries in repo (larger repo size)
- Add binary selection logic to installer

## Publishing to GitHub

1. Create new repository on GitHub
2. Add all files except luxafor-cli (initially)
3. Choose luxafor-cli strategy from above
4. Add appropriate LICENSE file
5. Tag a release (e.g., v1.0.0)

## Making it Homebrew-Compatible

Create a Formula:
```ruby
class LuxaforMonitor < Formula
  desc "macOS notification monitor for Luxafor LED devices"
  homepage "https://github.com/yourusername/luxafor-macos-monitor"
  url "https://github.com/yourusername/luxafor-macos-monitor/archive/v1.0.0.tar.gz"
  sha256 "..."
  
  depends_on "cmake" => :build
  depends_on "hidapi"
  depends_on "swiftbar" => :cask
  
  def install
    system "./install.sh", "--prefix", prefix
  end
end
```

## Enhanced Installer Features

Could add to install.sh:
- Architecture detection (Intel vs Apple Silicon)
- Version checking and updates
- Backup existing config during updates
- Interactive setup wizard
- Custom installation paths
- System requirements validation