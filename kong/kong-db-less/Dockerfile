FROM kong/kong-gateway:3.1.1.1
USER 0
RUN mkdir -p /kong/declarative/
COPY declarative/kong.yml /kong/declarative/
RUN cp /etc/kong/kong.conf.default /etc/kong/kong.conf
USER kong
