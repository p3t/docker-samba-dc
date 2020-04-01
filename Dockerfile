FROM alpine:edge

LABEL org.label-schema.name="Samba AD DC" \
      org.label-schema.description="Docker image for Samba 4 DC on Alpine Linux." \
      org.label-schema.schema-version="1.0"

COPY . /

# samba-winbind samba-libnss-winbind
ENV SAMBA_PACKAGES="samba-dc supervisor krb5 chrony"
ENV WEBMIN_PACKAGES="nginx"

RUN apk add --no-cache ${SAMBA_PACKAGES} \
    && mv /etc/samba/smb.conf /etc/samba/smb.conf.orig \
    chmod a+x entrypoint.sh

# RUN curl -o webmin.tgz https://downloads.sourceforge.net/project/webadmin/webmin/1.941/webmin-1.941.tar.gz

EXPOSE 37/udp \
       53 \
       88 \
       135/tcp \
       137/udp \
       138/udp \
       139 \
       389 \
       445 \
       464 \
       636/tcp \
       1024-5000/tcp \
       3268/tcp \
       3269/tcp

VOLUME ["/samba"]

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "start" ]
