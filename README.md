#### Реализовать обмен данными  

##### Общее описание:  
Нужно сделать двусторонний обмен данными пользователя между двумя системами. Пользователь может быть создан в одной из систем, а также может изменять свои данные, после каких-либо манипуляций, данные пользователя должны быть одинаковы в обоих системах.  
Задача:  
Сделать две системы у каждой своя БД и свои скрипты для отправки и приёма запросов.  
Создаём сущность пользователь с набором полей: логин, пароль, email, имя и фамилия. Также известно, что сейчас будет использоваться для обмена формат JSON, но в планах использовать ещё XML, необходимо сделать проверку по токену в заголовке для обработки запросов. Все запросы передавать методом POST.   
Предусмотреть проверку на уникальность поля логин и Email. При создании/редактирования выдавать сообщение об ошибке о существующем логине/Email.  
Пароль должен содержать хотя бы одну цифру, большую и маленькую букву.  
Внешне, выводим форму для создания записи, список существующих записей, открытие записи на редактирование. Стили можно использовать любые на усмотрение.  

----------

#### Запуск проекта после клонирования. 

##### Общие требования
- В системе должен быть установлен docker-compose
- Из-за использования sudo и mount, предназначен для запуска на unix-based системах    
- Потребуется ввести пароль для выполнения sudo mount

##### Как запустить
вариант 1) полный автомат. Будут зяняты порты 8011/8012 на nginx, 3321/3322 на mysql, 3331/3332 на pma. 
```
make full_setup
```

Состоит из сценариев
- both_setup_unv: создаст .env файлы в папках инстансов, пропишет в них вышеуказанные порты и стандартные доступы к БД.  
- mount: примаунтит две директории внутри instance2 к таким же в instance1
- both_docker_up: запустит два docker-compose для инстенсов
- both_db_composer_ins выполнит composer install в проекте
- both_db_init - создаст ДБ в контейнерах, если их еще нет, и запустит миграции

Можно запускать повторно, все операции не затирают результат предыдущих запусков

----------

Вариант 2) Если нужно заменить порты на кастомные.   
это создаст файлы настроек .env в директориях instance1 и instance2
```
make both_setup_unv
```
после чего их можно поменять и запустить всю систему уже с ними. При замене нужно учесть, чтобы порты не пересекались у двух инстансов, а REMOTE_API_UPL вели друг на друга
```
make full_setup
```

##### Как посмотреть что получилось
После запуска укружения в браузере можно открыть отдельно два инстанса сайта и два pma. Если .env файлы создавались автоматом, то запустить можно через make 
```
make open_brouser_all
```
что, в свою очередь, состоит из open_browser_sites + open_browser_pma

Доступы в pma root/root  
пользователей в БД нет, нужно идти на /register и создавать

#### Организация docker-окружения:

Для интересующихся, как оно все устроено  

Обмен требует запуска двух инстансов приложения. Для простоты, код используется общий, расположен в instance1/project, docker-файлы образов также общие, расположены в instance1/docker.  
Второе окружение имеет свой собственный docker-compose.yml, чтобы разделить network на instance1 и instance2. Так странно, потому что пока что не удалось вынести имя сет в переменную в .env. А также из-за того, что docker-compose не подставляет переменные из кастомных файлов, заданных в env-file, а только .env, лежащий непосредственно рядом с docker-compose.yml    
В файлах .env вынесены переменные, которыми отличаются два инстанса. По сути, это порты nginx, mysql и pma, чтобы можно было запустить два compose параллельно и они могли общаться между собой. Там же в файлах расположен путь до второго инстанса, перекрестно (REMOTE_API_UPL). Этот путь из .env будет использоваться для отправки запросов к api в момент обновления пользователя для синхронизации.   
так что, после клонирования репа нужно выполнить 
```
cp instance1/.env.dist instance1/.env
cp instance1/.env.dist instance2/.env
``` 
При установке переменных главное сделать оличающимися значения *_PORT, доступы и имя БД можно оставить одинаковыми, они будут в разных контейнерах.

Далее, чтобы реиспользовать код из первого инстанса во втором, но не копировать его, следует примаунтить две директории, docker и project. Симлинки не подходят, потому как docker-compose их не обрабатывает. Есть хаки, но проще уж так. 
```
cd instance2
mkdir docker
sudo mount --bind ../instance1/docker docker/
mkdir project
sudo mount --bind ../instance1/project project/
```
что вынесено в make
```
make mount
```
Затем, можно запускать инстанс приложения, обновить зависимости композера, которые не в репе, и мигрировать БД 
```
make both_docker_up
make both_db_composer_ins
make both_db_init
```

