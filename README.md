# toolbox



# Services
## Plex
### Cron job to clear photo transcoder cache folder
Created a cron job that clears the stupid photo transcoder cache files to keep the plex folder size low
```bash
curl -sSL https://raw.githubusercontent.com/greirson/toolbox/main/service/plex/plex-cron-cache-clear.sh | bash
```
