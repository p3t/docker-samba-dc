FROM alpine:3.11

LABEL org.label-schema.name="Samba AD DC" \
      org.label-schema.description="Docker image for Samba 4 DC on Alpine Linux." \
      org.label-schema.schema-version="1.0"

VOLUME ["/samba"]

COPY . /

# samba-winbind samba-libnss-winbind
ENV SAMBA_PACKAGES="samba-dc krb5 chrony"

RUN apk add --no-cache ${SAMBA_PACKAGES} \
 && mv /etc/samba /etc/samba.orig \
 && rm -rf /var/lib/samba \
 && ln -s /samba /var/lib/samba \
 && chmod a+x entrypoint.sh

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


ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "start" ]
