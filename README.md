# BackUpLab
В vagrant файле создаются 2 ВМ, одна из которых является клиентом для бэкапа своей директории etc для сервера backu.

* 1. В инлайн скриптах прописана установка боргбэкап на обе виртуалки.
* 2. Создаём пару ключей ssh-keygen на ВМ client и отправляем на сервер бэкапа командой ssh-copy-id 
* 3. Первоначально необходимо инициализировать репозиторий для бэкапа client
```
borg init -e none root@backup:/var/backup
```
* 4. После этого запускаем бэкап

**borg create --stats --list root@backup:/var/backup/::"Client-{now:%Y-%m-%d_%H:%M:%S}" /etc**
```
...
d /etc/audit
U /etc/sudoers.d/vagrant
d /etc/sudoers.d
d /etc
------------------------------------------------------------------------------
Archive name: Client-2020-09-21_10:00:45
Archive fingerprint: 15281da044383d1a31a4934ab28770ef023c5767bc2c2e531483d6af68ea576b
Time (start): Mon, 2020-09-21 10:00:47
Time (end):   Mon, 2020-09-21 10:00:48
Duration: 1.17 seconds
Number of files: 1711
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
Original size        Compressed size    Deduplicated size
This archive:               28.43 MB             13.43 MB             26.53 kB
All archives:              170.60 MB             80.56 MB             12.17 MB
                       Unique chunks         Total chunks
Chunk index:                    1309                10194
------------------------------------------------------------------------------
```
* 5. Просмотреть бэкапы можно с клиента командой borg list root@backup:/var/backup/
```
[root@client vagrant]# borg list root@backup:/var/backup/
Client-2020-09-20_20:19:46           Sun, 2020-09-20 20:19:50 [558fde8314c3123bc645725a61d5f381b3a2468714270f3e67d1ee6a46177c7b]
Client-2020-09-20_20:24:55           Sun, 2020-09-20 20:24:57 [2c5b43790c37e875486760edec2828d53d34cae0365139f478ed47132a8bb330]
Client-2020-09-20_20:26:16           Sun, 2020-09-20 20:26:17 [38f6fc7c52edae582ae820a775b84d0335314b706ff02c55444168512bb53f58]
Client-2020-09-21_09:24:04           Mon, 2020-09-21 09:24:17 [f648946d600061a358929dbd75dee471b1ee908064a066771086aafcd804922a]
Client-2020-09-21_09:24:54           Mon, 2020-09-21 09:24:59 [b97a59411455ded4c0cf9304ebc6167f21a19d07d50f738c52f2cd477cc6fbb4]
Client-2020-09-21_10:00:45           Mon, 2020-09-21 10:00:47 [15281da044383d1a31a4934ab28770ef023c5767bc2c2e531483d6af68ea576b]
```
* 6. Восстановление бэкапа по команде borg extract backup:/var/backup/::Client-2020-09-20_20:19:46
* 7. Автоматизировать можно создав скрипт и юнит с таймером в systemd. (в папке script)
* 8. В скрипте backup указаны правила хранения логов. Таймер отрабатывает запуск скрипта каждые 5min. Это логируется и логи ротируются через утилиту logrotate:
```
/var/backup/backup.log {
    missingok
    monthly
    create 0600 root utmp
    rotate 1
}
```
________________________________________________
```
[root@client client]# borg list $REPOSITORY
client-2020-09-21-15:49:57           Mon, 2020-09-21 15:49:58 [553b81a6ec4ce132800ba3f7df612075bcff762e6326a9b363a6705982ecdc7b]
client-2020-09-21-15:51:47           Mon, 2020-09-21 15:51:48 [671ad7e389aaaa6385015f31faeb0ddcc28da62822397ad462ea23347004ee42]
client-2020-09-21-15:52:57           Mon, 2020-09-21 15:52:58 [c8db489d9bdc5c75b8f25453166cc366487fd874d6a937faf7320b3c1432ca80]
client-2020-09-21-15:54:16           Mon, 2020-09-21 15:54:18 [766e36a26c1c7cc298269f52ae21726a3de403437c35f908f57443c1ce10d2b4]
client-2020-09-21-15:59:57           Mon, 2020-09-21 15:59:58 [cab77e0f79e40c9d329d1cadde22c77fc7e115bb2cabb0aa332dfbb8ce40a530]
...
```
Вывод journalctl
```
Sep 21 16:17:56 client systemd[1]: Started Borg Backup.
Sep 21 16:17:56 client backup.sh[2518]: Transfer files...
Sep 21 16:17:58 client backup.sh[2518]: Creating archive at "root@backup:/var/backup::{hostname}-{now:%Y-%m-%d-%H:%M:%S}"
Sep 21 16:17:59 client backup.sh[2518]: ------------------------------------------------------------------------------
Sep 21 16:17:59 client backup.sh[2518]: Archive name: client-2020-09-21-16:17:57
Sep 21 16:17:59 client backup.sh[2518]: Archive fingerprint: 00e7c7519969b3ccabea0b73a1e019ee10791456feef33abfd36160dd0d53b49
Sep 21 16:17:59 client backup.sh[2518]: Time (start): Mon, 2020-09-21 16:17:58
Sep 21 16:17:59 client backup.sh[2518]: Time (end):   Mon, 2020-09-21 16:17:59
Sep 21 16:17:59 client backup.sh[2518]: Duration: 0.71 seconds
Sep 21 16:17:59 client backup.sh[2518]: Number of files: 1726
Sep 21 16:17:59 client backup.sh[2518]: Utilization of max. archive size: 0%
Sep 21 16:17:59 client backup.sh[2518]: ------------------------------------------------------------------------------
Sep 21 16:17:59 client backup.sh[2518]: Original size      Compressed size    Deduplicated size
Sep 21 16:17:59 client backup.sh[2518]: This archive:               28.52 MB             13.47 MB                549 B
Sep 21 16:17:59 client backup.sh[2518]: All archives:              684.01 MB            322.99 MB             12.42 MB
Sep 21 16:17:59 client backup.sh[2518]: Unique chunks         Total chunks
Sep 21 16:17:59 client backup.sh[2518]: Chunk index:                    1351                41046
Sep 21 16:17:59 client backup.sh[2518]: ------------------------------------------------------------------------------
Sep 21 16:23:56 client systemd[1]: Started Borg Backup.
Sep 21 16:23:56 client backup.sh[2550]: Transfer files...
Sep 21 16:23:58 client backup.sh[2550]: Creating archive at "root@backup:/var/backup::{hostname}-{now:%Y-%m-%d-%H:%M:%S}"
Sep 21 16:23:59 client backup.sh[2550]: ------------------------------------------------------------------------------
Sep 21 16:23:59 client backup.sh[2550]: Archive name: client-2020-09-21-16:23:57
Sep 21 16:23:59 client backup.sh[2550]: Archive fingerprint: 50483348622dcae9738c94a75fdc36ba31bccc60d07d83c9e06d16bbdc1c7ab5
Sep 21 16:23:59 client backup.sh[2550]: Time (start): Mon, 2020-09-21 16:23:58
Sep 21 16:23:59 client backup.sh[2550]: Time (end):   Mon, 2020-09-21 16:23:59
Sep 21 16:23:59 client backup.sh[2550]: Duration: 0.60 seconds
Sep 21 16:23:59 client backup.sh[2550]: Number of files: 1726
Sep 21 16:23:59 client backup.sh[2550]: Utilization of max. archive size: 0%
Sep 21 16:23:59 client backup.sh[2550]: ------------------------------------------------------------------------------
Sep 21 16:23:59 client backup.sh[2550]: Original size      Compressed size    Deduplicated size
Sep 21 16:23:59 client backup.sh[2550]: This archive:               28.52 MB             13.47 MB                549 B
Sep 21 16:23:59 client backup.sh[2550]: All archives:              741.05 MB            349.93 MB             12.42 MB
Sep 21 16:23:59 client backup.sh[2550]: Unique chunks         Total chunks
Sep 21 16:23:59 client backup.sh[2550]: Chunk index:                    1353                44474
Sep 21 16:23:59 client backup.sh[2550]: ------------------------------------------------------------------------------
Sep 21 16:29:56 client systemd[1]: Started Borg Backup.
Sep 21 16:29:56 client backup.sh[2581]: Transfer files...
Sep 21 16:29:58 client backup.sh[2581]: Creating archive at "root@backup:/var/backup::{hostname}-{now:%Y-%m-%d-%H:%M:%S}"
Sep 21 16:29:59 client backup.sh[2581]: ------------------------------------------------------------------------------
Sep 21 16:29:59 client backup.sh[2581]: Archive name: client-2020-09-21-16:29:57
Sep 21 16:29:59 client backup.sh[2581]: Archive fingerprint: 3af96e7c8434cf0d1f03aa8832388ae93c020fe9cddc445dcacb0474568af40a
Sep 21 16:29:59 client backup.sh[2581]: Time (start): Mon, 2020-09-21 16:29:58
Sep 21 16:29:59 client backup.sh[2581]: Time (end):   Mon, 2020-09-21 16:29:59
Sep 21 16:29:59 client backup.sh[2581]: Duration: 0.69 seconds
Sep 21 16:29:59 client backup.sh[2581]: Number of files: 1726
Sep 21 16:29:59 client backup.sh[2581]: Utilization of max. archive size: 0%
Sep 21 16:29:59 client backup.sh[2581]: ------------------------------------------------------------------------------
Sep 21 16:29:59 client backup.sh[2581]: Original size      Compressed size    Deduplicated size
Sep 21 16:29:59 client backup.sh[2581]: This archive:               28.52 MB             13.47 MB                549 B
Sep 21 16:29:59 client backup.sh[2581]: All archives:              769.58 MB            363.40 MB             12.42 MB
Sep 21 16:29:59 client backup.sh[2581]: Unique chunks         Total chunks
Sep 21 16:29:59 client backup.sh[2581]: Chunk index:                    1354                46188
Sep 21 16:29:59 client backup.sh[2581]: ------------------------------------------------------------------------------
```
* 9. После запуска "vagrant up" заходим в ВМ клиента "vagrant ssh client", созадём ключ "ssh-keygen" и сразу же отправляем на сервер бэкапа "ssh-copy-id root@backup", 
соглашаемся на запрос и вводим пароль от рута сервера бэкапов. После этого на клиенте инициализируем репу для бэкапов этого клиента. Смотрим, как заполняется лог
"cat /var/log/backup/backup.log" каждые 5 минут.
