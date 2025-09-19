# 🚀 Quick Reference Card

## One-Command Setup
```bash
./scripts/setup-demo.sh
```

## Demo Flow
1. **Setup**: `./scripts/validate-setup.sh`
2. **Scenario**: `./scenarios/run-scenario.sh 1`
3. **Analyze**: `k8sgpt analyze --namespace demo --explain`
4. **Fix**: `./scenarios/run-scenario.sh 1 fix`

## Key URLs
- **Demo App**: http://cncf.vg.local
- **Ollama API**: http://localhost:11434
- **Cluster**: https://127.0.0.1:6443

## Emergency Commands
```bash
# Restart everything
./scripts/setup-demo.sh

# Check status
./scripts/validate-setup.sh

# Clean slate
k3d cluster delete cncf-pune-k3d-demo
./scripts/install-k3d.sh
```
