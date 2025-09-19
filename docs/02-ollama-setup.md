# 🦙 Ollama Setup Guide

This guide covers installing and configuring Ollama with multiple LLM models for the CNCF Pune demo environment.

## Overview

Ollama is a tool for running large language models locally. It provides a simple API that's compatible with OpenAI's format, making it perfect for integrating with K8sGPT for local, private AI-powered Kubernetes troubleshooting.

## Prerequisites

- **macOS**: This guide is tested on macOS Monterey and newer
- **Homebrew**: Package manager for macOS
- **10GB+ free disk space**: LLM models are large
- **8GB+ RAM**: Recommended for smooth model execution
- **Internet connection**: Required for downloading models

## Automatic Installation

Use the provided script for automated setup:

```bash
./scripts/install-ollama.sh
```

This script will:
- ✅ Install Ollama via Homebrew
- 🔧 Configure Ollama for external access
- 📥 Download multiple LLM models (Mistral, Llama2, Orca Mini)
- 🧪 Test model functionality
- ✅ Validate API endpoints

## Manual Installation Steps

If you prefer manual installation:

### 1. Install Ollama

```bash
# Install via Homebrew
brew install ollama

# Verify installation
ollama --version
```

### 2. Configure Ollama

Create configuration for external access:

```bash
# Create config directory
mkdir -p ~/.ollama

# Create config file
cat > ~/.ollama/config.json << EOF
{
    "host": "0.0.0.0:11434",
    "origins": ["*"],
    "models_path": "~/.ollama/models"
}
EOF
```

### 3. Start Ollama Service

```bash
# Set environment variable
export OLLAMA_HOST="0.0.0.0:11434"

# Start Ollama service in background
ollama serve &

# Verify service is running
curl http://localhost:11434/api/tags
```

### 4. Download Models

```bash
# Download Mistral 7B (fast, efficient)
ollama pull mistral:7b

# Download Llama2 13B (more capable)
ollama pull llama2:13b

# Download Orca Mini (lightweight)
ollama pull orca-mini:latest

# List downloaded models
ollama list
```

## Model Comparison

| Model | Size | Speed | Accuracy | Use Case |
|-------|------|-------|----------|----------|
| **Mistral 7B** | ~4GB | Fast | Good | Demos, quick analysis |
| **Llama2 13B** | ~7GB | Medium | Better | Detailed analysis |
| **Orca Mini** | ~2GB | Fastest | Basic | Testing, lightweight use |

## Testing Models

### Command Line Testing

```bash
# Test Mistral
ollama run mistral:7b "Explain what is a Kubernetes pod"

# Test Llama2
ollama run llama2:13b "How do I troubleshoot ImagePullBackOff?"

# Test Orca Mini
ollama run orca-mini:latest "What is Docker?"
```

### API Testing

```bash
# Test generation API
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral:7b",
    "prompt": "What is Kubernetes in one sentence?",
    "stream": false
  }'

# List available models
curl http://localhost:11434/api/tags

# Get model information
curl http://localhost:11434/api/show \
  -H "Content-Type: application/json" \
  -d '{"name": "mistral:7b"}'
```

## Configuration Options

### Environment Variables

```bash
# Ollama host configuration
export OLLAMA_HOST="0.0.0.0:11434"

# Ollama models directory
export OLLAMA_MODELS="~/.ollama/models"

# GPU settings (if available)
export OLLAMA_NUM_GPU=1
```

### Service Configuration

```json
{
  "host": "0.0.0.0:11434",
  "origins": ["*"],
  "models_path": "~/.ollama/models",
  "load_timeout": "5m",
  "keep_alive": "5m"
}
```

## API Endpoints

### Core Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/tags` | GET | List available models |
| `/api/generate` | POST | Generate text |
| `/api/chat` | POST | Chat completion |
| `/api/pull` | POST | Download model |
| `/api/show` | POST | Model information |

### Example API Calls

```bash
# Generate response
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral:7b",
    "prompt": "Explain Kubernetes networking",
    "stream": false,
    "options": {
      "temperature": 0.7,
      "top_p": 0.9
    }
  }'

# Chat format (recommended for K8sGPT)
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral:7b",
    "messages": [
      {
        "role": "user",
        "content": "Help me debug this Kubernetes issue"
      }
    ]
  }'
```

## Troubleshooting

### Common Issues

#### 1. Service Not Starting

```bash
Error: listen tcp 0.0.0.0:11434: bind: address already in use
```

**Solutions**:
```bash
# Check what's using the port
lsof -i :11434

# Kill existing Ollama processes
pkill ollama

# Restart service
ollama serve
```

#### 2. Model Download Fails

```bash
Error: failed to pull model
```

**Solutions**:
- Check internet connection
- Verify disk space (`df -h`)
- Try downloading a smaller model first
- Use VPN if geoblocked

#### 3. Out of Memory

```bash
Error: model failed to load
```

**Solutions**:
- Use a smaller model (orca-mini:latest)
- Increase system RAM
- Close other applications
- Use model with lower precision

#### 4. API Not Responding

```bash
curl: (7) Failed to connect to localhost port 11434
```

**Solutions**:
```bash
# Check service status
ps aux | grep ollama

# Verify configuration
cat ~/.ollama/config.json

# Restart service
ollama serve &

# Check logs
tail -f ~/.ollama/ollama.log
```

### Advanced Troubleshooting

#### Check System Resources

```bash
# Memory usage
top -o MEM

# Disk usage
du -h ~/.ollama/models/

# Process monitoring
htop
```

#### Model Management

```bash
# Remove model
ollama rm mistral:7b

# Update model
ollama pull mistral:7b

# Copy model
ollama cp mistral:7b my-mistral

# Show model details
ollama show mistral:7b
```

## Performance Optimization

### System Settings

**For Better Performance**:
- Close unnecessary applications
- Use SSD storage for models
- Increase system RAM if possible
- Use dedicated GPU if available

### Model Settings

```bash
# Optimize for speed
curl -X POST http://localhost:11434/api/generate \
  -d '{
    "model": "orca-mini:latest",
    "prompt": "Quick response needed",
    "options": {
      "num_predict": 50,
      "temperature": 0.1
    }
  }'

# Optimize for quality
curl -X POST http://localhost:11434/api/generate \
  -d '{
    "model": "llama2:13b",
    "prompt": "Detailed analysis needed",
    "options": {
      "num_predict": 200,
      "temperature": 0.7,
      "top_p": 0.9
    }
  }'
```

## Integration with K8sGPT

Once Ollama is running, configure K8sGPT:

```bash
# Add Ollama as backend
k8sgpt auth add --backend ollama --baseurl http://localhost:11434 --model mistral:7b

# Set as default provider
k8sgpt auth default --provider ollama

# Test integration
k8sgpt analyze --explain
```

## Model Switching

Use the provided script to switch between models:

```bash
# Switch to Llama2
~/.k8sgpt/switch-model.sh llama2:13b

# Switch to Orca Mini for speed
~/.k8sgpt/switch-model.sh orca-mini:latest

# Back to Mistral
~/.k8sgpt/switch-model.sh mistral:7b
```

## Security Considerations

### Network Security
- Ollama binds to `0.0.0.0:11434` for K8sGPT access
- Consider firewall rules in production
- Use VPN or private networks for remote access

### Data Privacy
- All processing happens locally
- No data sent to external services
- Models and conversations stay on your machine

### Resource Limits
- Monitor CPU and memory usage
- Set up process limits if needed
- Consider container deployment for isolation

## Monitoring and Maintenance

### Health Checks

```bash
# Service health
curl -f http://localhost:11434/api/tags || echo "Service down"

# Model availability
ollama list | grep -q mistral || echo "Model missing"

# Disk space
df -h ~/.ollama/models | tail -1
```

### Log Management

```bash
# View logs
tail -f ~/.ollama/ollama.log

# Rotate logs
logrotate ~/.ollama/ollama.log

# Clear old models
ollama list | grep -v "NAME" | awk '{print $1}' | head -n -3 | xargs -I {} ollama rm {}
```

## Next Steps

Once Ollama is set up:

1. **Install K8sGPT**: Run `./scripts/install-k8sgpt.sh`
2. **Deploy Demo App**: Run `./scripts/setup-demo.sh`
3. **Test Integration**: Run `k8sgpt analyze --explain`
4. **Validate Setup**: Run `./scripts/validate-setup.sh`

## Useful Commands Reference

```bash
# Service management
ollama serve                    # Start service
pkill ollama                   # Stop service
ollama --help                  # Show help

# Model management
ollama list                    # List models
ollama pull <model>           # Download model
ollama rm <model>             # Remove model
ollama run <model> "prompt"   # Test model

# API testing
curl http://localhost:11434/api/tags
curl -X POST http://localhost:11434/api/generate -d '{"model":"mistral:7b","prompt":"test"}'

# Configuration
cat ~/.ollama/config.json     # View config
ls -la ~/.ollama/models/      # List model files
```

## Resources

- [Ollama Documentation](https://ollama.ai/)
- [Ollama GitHub](https://github.com/ollama/ollama)
- [Model Library](https://ollama.ai/library)
- [API Reference](https://github.com/ollama/ollama/blob/main/docs/api.md)