FROM alpine/git:latest
RUN git clone --single-branch --depth 1 \
   https://github.com/catwell/luajit-msgpack-pure.git \
   /luajit-msgpack-pure

FROM openresty/openresty:stretch
COPY --from=0 /luajit-msgpack-pure/luajit-msgpack-pure.lua /usr/local/share/lua/5.1/
ADD docker /
CMD ["/usr/local/sbin/startup.sh"]
