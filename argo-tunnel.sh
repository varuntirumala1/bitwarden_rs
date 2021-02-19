  
#!/bin/bash
cloudflared --origincert /data/cert.pem --config /data/cargo.yml tunnel run bitwarden
