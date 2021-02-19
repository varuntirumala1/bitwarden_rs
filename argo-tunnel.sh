#!/bin/bash
cloudflared --origincert /data/cert.pem --config /data/argo.yml tunnel run bitwarden
