<p><img src="https://static.tildacdn.com/tild3733-3430-4331-a637-336233396534/logo.svg" alt="NGRSOFTLAB logo" title="NGR" align="right" height="60" /></p>

# Image builder

[![Image builder](https://img.shields.io/badge/image-builder-blue.svg)](https://gitlab.ngrsoftlab.ru/multicheck/infra/autoinstall)

## Description

Cкрипт по сборке образов Astra Linux. Взяты за основу [статья по сборке на докера на Astra](https://wiki.astralinux.ru/pages/viewpage.action?pageId=137563067), [minideb](https://github.com/bitnami/minideb) от Bitnami и скрипт от [@g.sorokin](https://gitlab.ngrsoftlab.ru/ngr-service/docker-images/astra/-/blob/master/astra-debootstrap/build-image.sh?ref_type=heads)

## Contents

- [Image builder](#image-builder)
  - [Description](#description)
  - [Contents](#contents)
  - [Requirements](#requirements)
  - [What it is](#what-it-is)
  - [Why use product?](#why-use-product)
  - [Project variables](#project-variables)
  - [How work with](#how-work-with)
  - [Issues and solutions](#issues-and-solutions)

## [Requirements](#contents)

- Astra Linux
- bash
- docker.io
- debootstrap

## [What it is](#contents)

Скрипт по сборке образов на основе Astra Linux. Что умеет:

- [x] Собирать образы на основе  1.7.3, 1.7.4, 1.7.5, 1.7.x (latest updated version), 1.8.1, 1.8.x (latest updated version)
- [x] Собирать образы на основе архитектуры
- [x] Собирать образы на основе прокси и вшивать прокси внуть образа (аля Nexus)
- [x] Собирать образы с произвольным тегом + именем
- [x] Проводить синтетические тесты

## [Why use product?](#contents)

- Этот образ призван обеспечить хороший баланс между небольшими образами и наличием множества базовых пакетов для легкой интеграции.
- Образ основан на `glibc` для широкой совместимости и подходит для доступа к большому количеству пакетов. Чтобы уменьшить размер образа, удалены некоторые вещи, которые не требуются в контейнерах:
  - Пакеты, которые не часто используются в контейнерах (аппаратные, системы инициализации и т.д.).
  - Некоторые файлы, которые обычно не требуются (документы, страницы руководства, локали, кэши)
- Эти образы также включают команду `install_packages`, которую можно использовать вместо `apt`. Скрипт позаботится о некоторых вещах:
  - Установить названные пакеты, пропуская подсказки и т.д.
  - После этого очистите метаданные `apt`, чтобы образ оставался маленьким.
  - Повторная попытка установка пакета в случае сбоя `apt`. Иногда пакет не удается загрузить из-за проблем с сетью, и это может исправить ситуацию, что особенно полезно в автоматизированном конвейере сборки.

Пример:

```bash
$ install_packages apache2 memcached
...
```

## [Project variables](#contents)

|     Имя     | Значение по умолчанию | Тип | Описание |
|     :---    |         :----:        |  :----:  |   ---:   |
| `DOCKER_SAVE_ACTION` | import | string | Тип загрузки образа(может быть `load/import`). |
| `CODENAME` | stable | string | Имя сборки(для астры можно использовать `1.7_x86-64/1.8_x86-64`). |
| `REPO_URL` | `https://pr.ngrsoftlab.ru/repository/astra-cache` | string | Путь до прокси реджестри/репозитория с которым будет работать образ. |
| `PLATFORM` | `$(dpkg --print-architecture)` | string | Архитектура системы. |
| `IMAGE_NAME` | astra | string | Имя образа. |
| `DEBUG` | OFF | string | Параметр включения/отключения отладки. |
| `TAG` | "" | string | Тэг задаваемого образа. |

## [How work with](#contents)

```shell
## Вызов справки
./build-astra-image.sh -h

## Посмотреть версию
./build-astra-image.sh -v

## Собрать образ с минимальными параметрами
./build-astra-image.sh -t 1.7.5 \
                      -c 1.7_x86-64

## Cобрать образ с отладкой(дебагом)
./build-astra-image.sh -t 1.8.1 \
                      -c 1.8_x86-64 \
                      -d

## Для загрузки образа можно использовать 2 метода - load и import
## По умолчанию используется import, но можно переопределить
## Чем отличаются
export DOCKER_SAVE_ACTION=load
./build-astra-image.sh -t 1.8.1 \
                      -c 1.8_x86-64
```

- `md5sum` проверка файла

```shell
echo "0f68fb660356c3f176dffd50e268778f  build-deb-image.sh" | md5sum -c -
```

## [Issues and solutions](#contents)

- При появлении подобного сообщения об ошибке:

```text
Error response from daemon: directory '/var/lib/docker/overlay2/84dd6d8ea4091978616b1c933aaeb9e45ff729207a0028030a595e3ce69a6238/diff' contains vulnerabilities! [{oval:ru.altx-soft.nix:def
:188464 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188463 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.a
ltx-soft.nix:def:188462 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188460 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE
17) } {oval:ru.altx-soft.nix:def:188459 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188457 true Astra Linux -- уязвимость в cyrus-sasl2, 
ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188451 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188447 true Astra Linux -- уязв
имость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188444 true Astra Linux -- уязвимость в glibc (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188442 true Astra Linux --
уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188441 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188440 tru
e Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188439 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.ni
x:def:188438 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188437 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval
:ru.altx-soft.nix:def:188415 true Astra Linux -- уязвимость в ia32-libs, OpenSSL (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188393 true Astra Linux -- уязвимость в ia32-libs, OpenSSL (20
22-0819SE17) } {oval:ru.altx-soft.nix:def:188392 true Astra Linux -- уязвимость в gzip, xz-utils (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188262 true Astra Linux -- уязвимость в expat,
ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188259 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188228 true Astra Linux -- уяз
вимость в python2.7, python3.7 (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188192 true Astra Linux -- уязвимость в glibc (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188135 true Astra Lin
ux -- уязвимость в glibc (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188121 true Astra Linux -- уязвимость в python3.7 (2022-0819SE17) } {oval:ru.altx-soft.nix:def:188115 true Astra Linux}
```

- Выхода 2 - использовать актуальный образ или отключить встроенную проверку уязвимости
  - Отключить встроенную проверку уязвимостей (не рекомендуется) можно следующим образом
    - Порядок проверки уязвимостей в образах определяется значением параметра astra-sec-level службы dockerd. Значением параметра может быть от 1 до 6 включительно, определяющее класс защиты:

```text
Классы защиты 1 — 5: при обнаружении уязвимости в контейнере его запуск блокируется;
Класс защиты 6: отладочный режим, при обнаружении уязвимости в контейнере выводится соответствующее предупреждение, при этом запуск контейнера не блокируется.
```

- Задать значение параметра можно:
  - c помощью конфигурационного файла;
  - c помощью параметров запуска службы

- Конфигурационный файл

```bash
## Установить jq для удобства работы
apt update && apt install -y jq

## Создать конфигурационный файл /etc/docker/daemon.json если он не был создан ранее и указать в нем параметры
DOCKER_DAEMON_FILE='/etc/docker/daemon.json'
[[ ! -f ${DOCKER_DAEMON_FILE} ]] || echo "$(jq '. += {"debug" : true, "astra-sec-level" : 6}' ${DOCKER_DAEMON_FILE})" >"${DOCKER_DAEMON_FILE}"
[[ -f ${DOCKER_DAEMON_FILE} ]] || {
  mkdir -p "${DOCKER_DAEMON_FILE%/*}"
  echo "{}" >"${DOCKER_DAEMON_FILE}"
  echo "$(jq '. += {"debug" : true, "astra-sec-level" : 6}' ${DOCKER_DAEMON_FILE})" >"${DOCKER_DAEMON_FILE}"
}
```

- Параметры запуска службы

```bash
## Выполнить команду
systemctl edit docker

## Ввести и сохранить данные
[Service]
Environment="DOCKER_OPTS=--astra-sec-level 6"
```

- Независимо от использованного способа перезапустить службу docker: `systemctl restart docker`
