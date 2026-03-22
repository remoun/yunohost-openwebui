#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

OPENWEBUI_VERSION="0.6.5"

#=================================================
# COMMON HELPERS
#=================================================

# Detect ollama_ynh and return its domain, or empty string
detect_ollama_domain() {
    yunohost app setting ollama domain 2>/dev/null || echo ""
}

# Resolve the Ollama URL based on connection mode and detection
resolve_ollama_url() {
    local connection_mode="$1"
    local user_url="$2"

    if [ "$connection_mode" = "local" ]; then
        echo "http://localhost:11434"
    elif [ -n "$user_url" ] && [ "$user_url" != "http://localhost:11434" ]; then
        echo "$user_url"
    else
        local detected_domain
        detected_domain=$(detect_ollama_domain)
        if [ -n "$detected_domain" ]; then
            echo "https://${detected_domain}"
        else
            echo "http://localhost:11434"
        fi
    fi
}
