# Statische Seite (Original-HTML von 2013) via nginx. Kamal baut dieses Image
# und laesst es als Hauptservice hinter kamal-proxy auf dem X1 laufen.
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY *.html check_cs6.css /usr/share/nginx/html/
COPY images/           /usr/share/nginx/html/images/
COPY images_slideshow/ /usr/share/nginx/html/images_slideshow/
COPY Spry-UI-1.7/      /usr/share/nginx/html/Spry-UI-1.7/

EXPOSE 80
