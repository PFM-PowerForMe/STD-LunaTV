FROM ghcr.io/pfm-powerforme/s6:latest AS s6
FROM ghcr.io/pfm-powerforme/s6-box:latest AS s6-box
FROM ghcr.io/pfm-powerforme/base-kvrocks:latest AS kvrocks
FROM ghcr.io/mtvpls/moontvplus:latest AS fetch

FROM scratch AS runtime
COPY --from=fetch / /
COPY --from=s6 / /
COPY --from=s6-box /etc/s6-overlay /etc/s6-overlay
COPY --from=s6-box /pfm /pfm
COPY --from=kvrocks / /
COPY rootfs/ /

RUN mkdir -pv /etc/s6-overlay/init-data/ && mkdir -pv /etc/s6-overlay/scripts

ENV PATH="/command:/pfm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
     S6_LOGGING_SCRIPT="n2 s1000000 T" \
     LC_ALL="C.UTF-8" \
     LANG="C.UTF-8" \
     TERM="xterm-256color" \
     COLORTERM="truecolor" \
     MALLOC_CONF="prof:true,prof_active:false,background_thread:true" \
     DOCKER_ENV=true \
     NODE_ENV=production \
     HOSTNAME=0.0.0.0 \
     PORT=8080 \
     NEXT_PUBLIC_STORAGE_TYPE=kvrocks \
     KVROCKS_URL="redis://127.0.0.1:6379" \
     NEXT_PUBLIC_SEARCH_MAX_PAGE=50 \
     MAX_PLAY_RECORDS_PER_USER=200 \
     NEXT_PUBLIC_DISABLE_YELLOW_FILTER=true \
     NEXT_PUBLIC_DOUBAN_IMAGE_PROXY_TYPE=server \
     NEXT_PUBLIC_DOUBAN_PROXY_TYPE=direct \
     NEXT_PUBLIC_ENABLE_OFFLINE_DOWNLOAD=true \
     NEXT_PUBLIC_FLUID_SEARCH=true \
     WATCH_ROOM_SERVER_TYPE=internal \
     WATCH_ROOM_ENABLED=true \
     NEXT_PUBLIC_DANMAKU_CACHE_EXPIRE_MINUTES=0 \
     OFFLINE_DOWNLOAD_DIR=/data \
     NEXT_PUBLIC_ENABLE_SOURCE_SEARCH=true

RUN addgroup -g 999 -S kvrocks && adduser -u 999 -S kvrocks -G kvrocks
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nextjs -G nodejs
RUN mkdir -pv /run/kvrocks && \
    chown -R kvrocks:kvrocks /run/kvrocks /var/lib/kvrocks
RUN chown -R nextjs:nodejs /app

VOLUME /var/lib/kvrocks/db
VOLUME /data

WORKDIR /app

EXPOSE 8080

RUN /pfm/bin/fix_env
ENTRYPOINT ["/init"]