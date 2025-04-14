
## How to use this image

```
docker compose up [--detach]
docker compose logs --follow
docker compose stop
docker compose down
tail -f logs/atlassian-${APP}.log
```

## Database URL

```
From IntelliJ: jdbc:postgresql://localhost:${PORT_DB}/${APP}
                                 ^ This time, it's 'localhost'
In Confluence: jdbc:postgresql://postgres:${PORT_DB}/${APP}
                                 ^ This time, it's 'postgres', it's the docker container name (seen from ${APP})
                                 ^ Not 'postgresql'. Just 'postgres'.
- Username: ${APP}
- Password: ${APP}
```

## Application URL

${PROXY_SCHEME}://${PROXY_DOMAIN}:${PROXY_PORT}${CONTEXT_PATH}

But that only works if you've written this in your `/etc/hosts`:
```
127.0.0.1 ${LETTER}${APP_VERSION}.local
```

## License keys for "${APP}"

- If you work at Requirement Yogi: https://requirementyogi.atlassian.net/wiki/spaces/TEAM/pages/1844413025/License+keys
- In other cases: https://developer.atlassian.com/platform/marketplace/timebomb-licenses-for-testing-server-apps/

## Upload the plugin:
- Place your jars in `quickreload/` to be reloaded
- And watch the logs using `tail -f logs/atlassian-${APP}.log`
