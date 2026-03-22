### Ollama for local AI models

Open WebUI works best with [Ollama](https://ollama.com) for running AI models locally. You can install Ollama on your YunoHost server using the **ollama_ynh** package:

```bash
yunohost app install ollama
```

This is **optional** — Open WebUI can also connect to:

- A remote Ollama instance on another server
- OpenAI or any OpenAI-compatible API (Anthropic, Mistral, etc.)

### Resource requirements

Open WebUI itself is relatively lightweight, but running local AI models via Ollama requires significant resources (RAM, GPU). If you only plan to use remote APIs, the server requirements are modest.
