FROM l3iggs/archlinux
CMD /usr/sbin/nginx -c /artlist.nginx.conf
EXPOSE 80
EXPOSE 443
MAINTAINER girafe en bois

RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
RUN pacman-db-upgrade
RUN pacman --refresh --refresh --sync --sysupgrade --noconfirm
RUN pacman --sync nginx --noconfirm

ADD artlist.nginx.conf /artlist.nginx.conf
ADD artlist.website.secret.key /artlist.website.secret.key
ADD artlist.website.certificates.pem /artlist.website.certificates.pem
