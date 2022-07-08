#Задаем базовый образ
FROM node:lts-buster
# создаем каталог в контейнере для нашего приложения
RUN mkdir -p /home/app
# задаем рабочию директорию 
WORKDIR /home/app
# копируем каталог с нашим приложением в контейнер
COPY . /home/app
RUN apt update -y && apt install -y net-tools lnav vim
# т.к. мы задали рабочию директорию выше валдиной будет запись 
# COPY . . (копируем файлы из текущего каталога в указанный рабочий)
#RUN npm install
# запускаем приложение
#CMD [ "node", "/home/app/server.js" ]

