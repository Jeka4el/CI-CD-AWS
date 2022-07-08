#Задаем базовый образ
FROM node:current-alpine3.16
# MAINTAINER Actpro  <actpro@actpro.com.ua>
# задаем переменные
ENV TZ=Europe/Kiev
# создаем каталог в контейнере для нашего приложения
RUN mkdir -p /home/app
# задаем рабочию директорию 
WORKDIR /home/app
# копируем каталог с нашим приложением в контейнер
COPY . /home/app
# т.к. мы задали рабочию директорию выше валдиной будет запись 
# COPY . . (копируем файлы из текущего каталога в указанный рабочий)
RUN npm install
# запускаем приложение
CMD [ "node", "/home/app/index.js" ]
# FROM nginx
# COPY ./default.conf /etc/nginx/conf.d/