# 📁 Project Structure Guide

This document explains the complete structure of the CNCF Pune K8sGPT Demo repository.

## 🗂️ Directory Layout

```
📦 cncf-pune-k8sgpt-demo/
├── 🚀 setup.sh                    # Main one-command setup script
├── 📖 README.md                   # Project overview and quick start
├── 📋 PROJECT_STRUCTURE.md        # This file - project structure guide
├── 🙈 .gitignore                  # Git ignore patterns
│
├── 🛠️ scripts/                    # Installation and setup scripts
│   ├── install-k3d.sh            # K3D cluster setup
│   ├── install-ollama.sh          # Ollama + LLM models installation
│   ├── install-k8sgpt.sh          # K8sGPT installation & configuration
│   ├── setup-demo.sh              # Demo environment setup
│   └── validate-setup.sh          # Complete environment validation
│
├── 📚 docs/                       # Detailed documentation
│   ├── 01-k3d-setup.md            # K3D cluster setup guide
│   └── 02-ollama-setup.md         # Ollama installation guide
│
├── 🎮 demo-app/                   # Demo web application
│   ├── src/                       # Application source files
│   │   ├── index.html             # Main web page
│   │   ├── helloworld.png         # Demo images
│   │   └── pune-cncf.png          # CNCF Pune branding
│   ├── k8s/                       # Kubernetes manifests
│   │   └── deployment.yaml        # App deployment config
│   ├── Dockerfile                 # Container definition
│   ├── deploy.sh                  # Build and deploy script
│   └── README.md                  # App-specific documentation
│
├── 💥 scenarios/                  # Failure demonstration scenarios
│   ├── scenario-1/k8s/            # ImagePullBackOff demo
│   │   ├── error_1.yaml           # Broken configuration
│   │   └── fix_1.yaml             # Fixed configuration
│   ├── scenario-2/k8s/            # Service selector mismatch
│   │   ├── error_2.yaml           # Broken service config
│   │   └── fix_2.yaml             # Fixed service config
│   ├── scenario-3/k8s/            # Resource constraints
│   │   ├── error_3.yaml           # Resource limit issues
│   │   └── fix_3.yaml             # Fixed resource config
│   └── run-scenario.sh            # Scenario execution script
│
└── ⚙️ k8s/                        # Kubernetes configuration
    └── k3d-cluster.yaml           # K3D cluster definition
```

## 🚀 Main Entry Points

### For End Users
- **`./setup.sh`** - One-command complete setup
- **`README.md`** - Start here for overview

### For Developers
- **`scripts/`** - Individual installation scripts
- **`PROJECT_STRUCTURE.md`** - This guide for project structure

### For Speakers
- **`scenarios/`** - Failure scenarios for demos
- **Generated guides** - DEMO_GUIDE.md created during setup

## 📋 File Categories

### 🔧 Executable Scripts
All scripts are executable and include proper error handling:
- `setup.sh` - Main setup orchestrator
- `scripts/*.sh` - Individual component installers
- `demo-app/deploy.sh` - Application deployment

### 📖 Documentation
- `README.md` - Project overview
- `PROJECT_STRUCTURE.md` - This project structure guide
- `docs/*.md` - Detailed setup guides
- `demo-app/README.md` - App-specific docs

### ⚙️ Configuration Files
- `k8s/*.yaml` - Kubernetes configurations
- `scenarios/*/k8s/*.yaml` - Demo scenario configs
- `.gitignore` - Git ignore patterns

### 🎨 Assets
- `demo-app/src/*.png` - Demo application images
- `demo-app/src/index.html` - Web interface

## 🏗️ Generated Files (Not in Repo)

These files are created during setup and are ignored by Git:
- `DEMO_GUIDE.md` - Generated demo walkthrough
- `QUICK_REFERENCE.md` - Generated quick reference
- `k8sgpt-usage-guide.md` - Generated K8sGPT guide
- `ollama-service-info.txt` - Generated Ollama info
- Various log files

## 🎯 Usage Patterns

### First-Time Users
1. Clone repository
2. Run `./setup.sh`
3. Follow generated guides

### Demo Presenters
1. Run `./setup.sh --validate` before session
2. Use generated `DEMO_GUIDE.md` for timing and walkthrough
3. Execute scenarios with `scenarios/run-scenario.sh`

### Contributors
1. Read the project documentation in `docs/`
2. Test changes with `scripts/validate-setup.sh`
3. Follow the existing code patterns

### Troubleshooters
1. Check `docs/` for detailed guides
2. Run `./setup.sh --validate` for diagnostics
3. Use generated guides like `DEMO_GUIDE.md` for help

## 🔍 Key Design Decisions

### Structure Philosophy
- **Simplicity**: One main entry point (`setup.sh`)
- **Modularity**: Individual scripts for each component
- **Validation**: Comprehensive testing at every level
- **Documentation**: Multiple levels from quick-start to deep-dive

### User Experience
- **Progressive disclosure**: Simple start, detailed docs available
- **Error handling**: Clear messages and recovery suggestions
- **Automation**: Minimal manual intervention required
- **Validation**: Continuous verification of setup state

### Maintainability
- **Testing**: Built-in validation scripts
- **Documentation**: Generated guides that stay current
- **Modularity**: Easy to update individual components
- **Simplicity**: Clear separation of concerns

This structure supports multiple user types while maintaining simplicity for the primary use case: getting a working demo environment quickly.