#!/bin/bash
cloudflared --origincert /data/cert.pem --config /data/argo.yml tunnel run -p http2 bitwarden
