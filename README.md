<!-- markdownlint-disable MD033 MD041 MD044 -->

<!-- Not work in GitLab <link href=".gitlab/style.css" rel="stylesheet"></link> -->

<p><img src="https://static.tildacdn.com/tild3733-3430-4331-a637-336233396534/logo.svg" alt="NGRSOFTLAB logo" title="NGR" align="right" height="60" /></p>
<!-- markdownlint-enable MD033 MD041 MD044 -->

# Image builder

<!-- markdownlint-disable MD033 -->
<div class="badges-row">
  <h4 align="center">
    <img src="https://img.shields.io/badge/Image-Builder-blue.svg?logo=curseforge&style=plastic" alt="Image builder"/>
    <img src="https://img.shields.io/badge/Dive%20efficiency-100%25-brightgreen.svg?logo=Docker&style=plastic" alt="Dive efficiency"/>
    <img src="https://img.shields.io/badge/Made%20with-%E2%9D%A4%EF%B8%8F-9cf?style=plastic" alt="Made with love"/>
  </h4>
</div>

<div align="center">

![Forge image](docs/images/logo.svg)
</div>

<div align="center"> <sub> Blacksmith anvil hammer под авторством <a href="https://en.wikipedia.org/wiki/File%3ABlacksmith_anvil_hammer.svg">Midnightcomm</a>. </sub> </div>

<!-- markdownlint-enable MD033 -->

## Description

Скрипт по сборке образов Astra Linux. Взяты за основу [статья по сборке на докера на Astra](https://wiki.astralinux.ru/pages/viewpage.action?pageId=137563067), [minideb](https://github.com/bitnami/minideb) от Bitnami, проекта [Tianon Gravi](https://github.com/debuerreotype/debuerreotype) и скрипты от команды NGRSoftlab

Аффикс, для переменных, был выбран как `SCF_` - акроним от `Script that Creates a Form` - скрипт создающий форму. Игра слов, связанная с тем, что данный скрипт создаёт из минимального наборка компонентов базовый образ для контейнерных сред

Присоединяйтесь к нашим социальным сетям:

<!-- markdownlint-disable MD033 -->

<div class="badges-row-public">
  <h4 align="center">
    <a href="https://t.me/NGR_Softlab">
      <img src="https://shields.io/badge/ngr-telegram-blue?logo=telegram&style=for-the-badge" alt="NGR Social Telegram" height="40" />
    </a>
    &emsp; &emsp; &emsp;
    <a href="https://www.ngrsoftlab.ru/?utm_source=tg&utm_medium=start" >
      <img src="https://shields.io/badge/ngr-web--page-yellow?style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGZpbGw9Im5vbmUiIHZpZXdCb3g9IjIyLjcgMCA1MS45IDUxLjciPjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNNzQuNSAwSDYzLjhsMy42IDMuNWMuNy43LjcgMS45IDAgMi43LS43LjctMS45LjctMi42IDBMNTguOSAwSDUzbDE0LjUgMTMuOWMuNy43LjcgMS45IDAgMi43LS43LjctMS45LjctMi42IDBMNDkgMGgtNi44bDI1LjMgMjQuM2MuNy43LjcgMS45IDAgMi43LS43LjctMS45LjctMi42IDBMMzkgMGgtNy43bDM2LjEgMzQuN2MuNy43LjcgMS45IDAgMi42cy0xLjkuNy0yLjYgMEwyOSAwYy0zLjUuNC02LjMgMy40LTYuMyA3djQ0LjdoMTAuNmwtMy42LTMuNGMtLjctLjctLjctMS45IDAtMi42czEuOS0uNyAyLjcgMGw1LjggNmg1LjlMMjkuNyAzNy45Yy0uNy0uNy0uNy0xLjkgMC0yLjcuNy0uNyAxLjktLjcgMi43IDBsMTUuOCAxNi40SDU1TDI5LjggMjcuNGMtLjctLjctLjctMS45IDAtMi43LjctLjcgMS45LS43IDIuNyAwbDI1LjggMjYuOEg2NkwyOS45IDE2LjljLS43LS43LS43LTEuOSAwLTIuNnMxLjktLjcgMi43IDBsMzUuNyAzNy4yYzMuNS0uMyA2LjMtMy4zIDYuMy03VjB6IiBmaWxsPSIjRjhBRDAwIi8+PC9zdmc+" alt="NGR Social Media" height="40" />
    </a>
  </h4>
</div>

<!-- markdownlint-enable MD033 -->

## Contents

- [Image builder](#image-builder)
  - [Description](#description)
  - [Contents](#contents)
  - [Requirements](#requirements)
  - [What is it](#what-is-it)
  - [Why to use this product?](#why-to-use-this-product)
  - [Supported version](#supported-version)
    - [Compare versions](#compare-versions)
  - [How to work with](#how-to-work-with)
    - [Project variables](#project-variables)
  - [Certification process](#certification-process)
  - [Assembling a compact image](#assembling-a-compact-image)
    - [Compact image variables](#compact-image-variables)
      - [Advantages and Disadvantages](#advantages-and-disadvantages)
  - [How use in CI/CD](#how-use-in-cicd)
  - [Issues and solutions](#issues-and-solutions)
  - [Contributing](#contributing)
    - [Cya!](#cya)

## [Requirements](#contents)

- Astra Linux
- bash >= 5.0.3(1)-release;
- Docker.io ~= 25.0.5.astra2
- debootstrap ~= 1.0.132
- coreutils ~= 9.1-1

## [What is it](#contents)

Скрипт по сборке образов на основе Astra Linux. Что умеет:

- [x] Собирать образы на основе 1.7.2 - 1.7.x (latest updated version), 1.8.1 - 1.8.x (latest updated version)
- [x] Собирать образы на основе архитектуры
- [x] Собирать образы на основе прокси и вшивать прокси внутрь образа (аля Nexus)
- [x] Собирать образы с произвольным тегом + именем
- [x] Проводить синтетические тесты

## [Why to use this product?](#contents)

- Этот образ призван обеспечить хороший баланс между небольшими образами и наличием множества базовых пакетов для легкой интеграции
- Образ основан на `glibc` для широкой совместимости и подходит для доступа к большому количеству пакетов. Чтобы уменьшить размер образа, удалены некоторые вещи, которые не требуются в контейнерах:
  - Пакеты, которые не часто используются в контейнерах (аппаратные, системы инициализации и т.д.)
  - Некоторые файлы, которые обычно не требуются (документы, страницы руководства, локали, кэши)
- Эти образы также включают команду `install_packages`, которую можно использовать вместо `apt`. Скрипт позаботится о некоторых вещах:
  - Установит названные пакеты, пропуская подсказки и т.д.
  - После этого очистит метаданные `apt`, чтобы образ оставался маленьким
  - Повторная попытка установка пакета в случае сбоя `apt`. Иногда пакет не удается загрузить из-за проблем с сетью, и это может исправить ситуацию, что особенно полезно в автоматизированном конвейере сборки

Пример:

```console
$ install_packages apache2 memcached

...install process...
```

## [Supported version](#contents)

<!-- markdownlint-disable MD033 -->
<div align="center" class="table-double">

|                                                   Кодовое имя                                                    |    Версия     | Status             |
| :--------------------------------------------------------------------------------------------------------------: | :-----------: | :----------------- |
| ![Astra 1.7_x86-64](https://img.shields.io/badge/Astra-1.7_x86--64-00ADD8?style=flat&logo=astra&logoColor=white) | 1.7.x - 1.7.9 | ✅ Fully supported |
| ![Astra 1.7_x86-64](https://img.shields.io/badge/Astra-1.8_x86--64-00ADD8?style=flat&logo=astra&logoColor=white) | 1.8.x - 1.8.4 | ✅ Fully supported |

</div>

<div align="center"> <sub> Таблица 1. Поддерживаемые версии Astra Linux. </sub> </div>
<p>&nbsp;</p>
<!-- markdownlint-enable MD033 -->

### [Compare versions](#contents)

Так как `AstraLinux` это детище `Debian` необходимо знать о их соотношении версий, чтобы понимать на чём основана [база](https://wiki.astralinux.ru/pages/viewpage.action?pageId=53646577)

<!-- markdownlint-disable MD033 -->
<div align="center" class="table-double">

|                                           Версия Astra                                            |                                               Версия Debian                                                |
| :-----------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------: |
| ![Astra 1.6](https://img.shields.io/badge/Astra-1.6-00ADD8?style=flat&logo=astra&logoColor=white) |  ![Debian](https://img.shields.io/badge/Debian-9-D70A53?style=flat&logo=debian&logoColor=white) (Stretch)  |
| ![Astra 1.7](https://img.shields.io/badge/Astra-1.7-00ADD8?style=flat&logo=astra&logoColor=white) |  ![Debian](https://img.shields.io/badge/Debian-10-D70A53?style=flat&logo=debian&logoColor=white) (Buster)  |
| ![Astra 1.8](https://img.shields.io/badge/Astra-1.8-00ADD8?style=flat&logo=astra&logoColor=white) | ![Debian](https://img.shields.io/badge/Debian-12-D70A53?style=flat&logo=debian&logoColor=white) (Bookworm) |

</div>

<div align="center"> <sub> Таблица 2. Соотношений Astra Linux и Debian. </sub> </div>
<p>&nbsp;</p>
<!-- markdownlint-enable MD033 -->

## [How to work with](#contents)

Для начала работы необходимо установить [pre-commit](https://pre-commit.com/) и хуки

```console
$ pip install pre-commit
$ pre-commit --version

pre-commit 4.2.0

$ pre-commit install

pre-commit installed at .git/hooks/pre-commit
pre-commit installed at .git/hooks/commit-msg
pre-commit installed at .git/hooks/pre-push
```

> [!warning]
> Чтобы проверить свои изменения, воспользуйтесь командой `pre-commit run --all-files`.
> Чтобы проверить конкретную задачу, воспользуетесь командой `pre-commit run <target> --all-files`.
> Если Вы понимаете что творите и хотите пропустить проверку `pre-commit`-ом воспользуйтесь `--no-verify`, пример `git commit -m "Добавил изменения и не хочу проверки" --no-verify`

При работе с хуками, есть некоторые моменты:

> [!note]
> Подготовка среды для работы с `vale` берёт из `StylesPath` в `.vale.ini` конфигурационном файле.
> Если необходимо пересоздать настройку окружения для `vale`, то нужно предварительно очистить полностью данную директорию

Примеры работы со скриптом:

1. Вызов справки

    ```console
    $ ./build-astra-image.sh -h

    NAME:
      build-astra-image.sh - Create Docker image IMAGE_NAME based on REPOSITORY with CODENAME.

    SYNOPSIS:
      build-astra-image.sh {-t TAG NAME} {-r REPOSITORY} [-i IMAGE NAME] [-c CODENAME] [-p PLATFORM] [-v] [-h] [-d] [-s]

    DESCRIPTION:
      Script can create astra docker image v1.7.x and v1.8.x.

    ARGUMENTS LIST:
      -h             help menu
      -v             print version
      -d             set debug, to enable pass '-d'
      -s             call only synthetic test for image
      -t TAG NAME    image tag, such as 1.8.1 and etc.
      -c CODENAME    codename (specified in '/etc/os-release' VERSION_CODENAME variable. For this OS it is: 1.8_x86-64)
      -r REPOSITORY  address of the repository, such as '-r https://download.astralinux.ru/astra/stable/1.7_x86-64/repository' or '-r https://download.astralinux.ru/astra/frozen/1.7_x86-64/1.7.5/repository' and in the same vein
      -i IMAGE NAME  name of the image being created
      -p PLATFORM    platform (based on dpkg --print-architecture command)
      -z             enable certification image

    AUTHOR:
      Written by NGRSoftlab.
    ```

2. Посмотреть версию

    ```console
    $ ./build-astra-image.sh -v

    build-astra-image.sh (NGRSoftlab) v2.0.0
    ```

3. Собрать образ с минимальными параметрами для 1.7.5

    ```console
    $ ./build-astra-image.sh -t 1.7.5 \
                          -c 1.7_x86-64 \
                          -r https://download.astralinux.ru/astra/frozen/1.7_x86-64/1.7.5/repository

    ..build process..
    ```

4. Собрать образ с отладкой(дебагом) для 1.8.1

    ```console
    $ ./build-astra-image.sh -t 1.8.1 \
                          -c 1.8_x86-64 \
                          -r https://dl.astralinux.ru/astra/frozen/1.8_x86-64/1.8.1/repository \
                          -d

    ..build process..
    ```

5. Собрать образ с минимальными параметрами для 1.8.1 rolling release и переопределенным методом импорта на 'load'

    ```console
    $ SCF_DOCKER_SAVE_ACTION=load ./build-astra-image.sh -t 1.8.1 \
                          -c 1.8_x86-64 \
                          -r https://download.astralinux.ru/astra/stable/1.8_x86-64/repository

    ..build process..
    ```

6. Собрать сертифицированный образ

    ```console
    $ ./build-astra-image.sh -t 1.8.x \
                          -c 1.8_x86-64 \
                          -r https://download.astralinux.ru/astra/stable/1.8_x86-64/repository \
                          -z
    ```

7. Протестировать образ без сборки. Может быть полезен в тех случаях, когда необходимо произвести синтетические тесты в уже подготовленном образе

    ```console
    $ ./build-astra-image.sh -t 1.7.7 -s

    ..test process..
    ```

8. `md5sum` проверка контрольных сумм

    ```shell
    cat MD5SUM | md5sum -c -
    ```

### [Project variables](#contents)

<!-- markdownlint-disable MD033 -->
<div align="center" class="table-quadro">

| Имя                      |     Значение по умолчанию      |    Тип     |                                                                    Описание |
| :----------------------- | :----------------------------: | :--------: | --------------------------------------------------------------------------: |
| `SCF_CODENAME`           |             stable             |   string   | Кодовое имя дистрибутива[^1](для астры: `1.7_x86-64` или `1.8_x86-64`)[^2]. |
| `SCF_DEBUG`              |              OFF               |   string   |                                      Параметр включения/отключения отладки. |
| `SCF_DOCKER_SAVE_ACTION` |             import             |   string   |                              Тип загрузки образа(может быть `load/import`). |
| `SCF_IMAGE_NAME`         |             astra              |   string   |                                                                 Имя образа. |
| `SCF_INCLUDE_DEV`        |               0                |  integer   |                                     Включить в образ содержимое `/dev`[^3]. |
| `SCF_PLATFORM`           | `$(dpkg --print-architecture)` | stringspec |                                                        Архитектура системы. |
| `SCF_REPO_URL`           |               ""               |   string   |          Путь до прокси реестра/репозитория с которым будет работать образ. |
| `SCF_TAG_NAME`           |               ""               |   string   |                                                     Тег задаваемого образа. |

</div>

<div align="center"> <sub> Таблица 3. Переопределяемые аргументы для скрипта сборки. </sub> </div>
<p>&nbsp;</p>
<!-- markdownlint-enable MD033 -->

## [Certification process](#contents)

Процесс сертификации выглядит весьма не однозначным, поэтому для этого будет посвящен целый раздел тут. Пообщавшись с технической поддержкой, предоставляю краткую выжимку ответов из серии **В**опрос - **О**твет. Данные ответов приведены за *17 марта 2026*. Текст вопросов будет слегка изменён, но отражает туже суть

1. Про [реестр образов](https://registry.astralinux.ru/latest/descriptions/local/containers/)

    - В: Является ли Ваш реестр образов сертифицируемым?
    - О: Эти образы не являются сертифицированным изделием и в поставку с Astra Linux Special Edition не входят.

2. Про самосборки образов из [официальных статей](https://wiki.astralinux.ru/pages/viewpage.action?pageId=137563067)

    - В: Считаются ли образы, которые собраны посредством статьи приемлемыми для прохождения сертификации в ФСТЭК и могут ли они соответствовать формуляру ОС Астра Linux?
    - О: Сборка образов, реализованная за счёт эксплуатационной документации и базы знаний, способствует прохождению сертификации и обеспечит реализацию необходимых требований. Среди них, в том числе, требования об использовании сертифицированной среды контейнеризации.

3. Про официальные сертифицированные образы ОС Астра Linux

    - В: Есть ли официальные образы от ОС Астра Linux, которые прошли сертификацию? где взять?
    - О: Образов, прошедших сертификацию, нет. Требования документа «Требования по безопасности информации. Утверждены приказом ФСТЭК России от 4 июля 2022 г. № 118» относятся к средству контейнеризации, а не к UBI-образам. Для операционной системы Astra Linux Special Edition выполнение приказа ФСТЭК России № 118 выполняется и подтверждается сертификатом ФСТЭК России № 2557. Сервисные пакеты, используемые при сборке, берутся из репозиториев операционной системы Astra Linux, которые проходят соответствующие проверки. Более подробно о репозиториях и их проверках Вы можете узнать на ресурсах: [для 1.7](https://wiki.astralinux.ru/pages/viewpage.action?pageId=149062354) и [для 1.8](https://wiki.astralinux.ru/pages/viewpage.action?pageId=302028564)

4. Про самосборки образов и их модификации для прохождения сертификации

    - В: Тех инструкций, что вы поставляете на вики, хватит для сборки такого? если нет, то как осуществить их соответствие сертифицируемому изделию? если собирать на сертифицируемой ОС Астра Linux, то это равно собрать сертифицируемый образ? формуляр можно использовать от сертифицируемой ОС Астра Linux как сравнение с референс? какие-то особенности сборки на сертифицируемой ОС Астра Linux есть для образов? если мы вносим изменения в сертифицируемый образ, то сертификация остается(вырезаем пакеты, правим конфиги)?
    - О: При проведении разработки СрЗИ с использованием контейнеров сертифицированной ОС необходимо учитывать следующие важные ресурсы:
    - О: 1. Разработка приложения должна осуществляться с учетом документа "Методические рекомендации по исключению влияния на функции безопасности операционной системы специального назначения «Astra Linux Special Edition» при проектировании, разработке и эксплуатации программного обеспечения". Дополнительная информация о технический ограничениях и пакетах реализующих функции безопасности представлена в Справочном центре: [Использование стороннего программного обеспечения в аттестованных информационных системах, функционирующих под управлением Astra Linux Special Edition 1.8.](https://wiki.astralinux.ru/pages/viewpage.action?pageId=323682032)
    - О: 2. Сборка осуществляется в строгом в соответствии с эксплуатационной документацией. Основные положения сборки выделены в документах: "Руководство администратора. Часть 1. РУСБ.10015-01 95 01-1" (10.1.2.1. Создание образа Docker) и "Руководство по КСЗ. Часть 1. РУСБ.10015-01 97 01-1"(создание и защиты изолированных программных сред (контейнеров)). Кроме того, разрабатываемое СЗИ рекомендуется разрабатывать таким образом, чтобы они были интернированы во встроенные СрЗИ ОС Astra Linux. Разрабатываемому ПО рекомендуется функционировать в условиях ограничения программной среды ОС (в «режиме замкнутой программной среды»), а также функционировать в условиях мандатного контроля целостности (МКЦ) ОС.
    - О: 3.Для обеспечения гарантированной совместимости с экосистемой «Группы Астра» рекомендуется провести тестирование приложения по программе [Ready for Astra](https://docs.astralinux.ru/latest/rfa/).
    - О: Дополнительные ресурсы:
    - О: - [База знаний](https://wiki.astralinux.ru/kb/docker-153490263.html);
    - О: - Информационное письмо ФСТЭК. "О повышении безопасности средств защиты информации, в состав которых разработчики включают средства контейнеризации или образы контейнеров" от 13 января 2025 г. N 240/24/38: [Информационное сообщение ФСТЭК России от 13 января 2025 г. N 240/24/38](https://fstec.ru/dokumenty/vse-dokumenty/informatsionnye-i-analiticheskie-materialy/informatsionnoe-soobshchenie-fstek-rossii-ot-13-yanvarya-2025-g-n-240-24-38);
    - О: - [Использование стороннего программного обеспечения в аттестованных информационных системах, функционирующих под управлением Astra Linux Special Edition 1.8](https://wiki.astralinux.ru/pages/viewpage.action?pageId=323682032).

Также прикрепляю полезную информацию о:

- [Состав репозиториев ОС Астра Linux](https://wiki.astralinux.ru/pages/viewpage.action?pageId=3276917#id-СписокпакетовОСAstraLinuxSpecialEdition-Основнойрепозиторий)
- [Патч репозитории для устранения уязвимостей ОС Астра Linux](https://wiki.astralinux.ru/pages/viewpage.action?pageId=461742397)

После генерации образа:

- Остаётся только репозиторий, который проходит сертификацию + репозиторий с механизмом оперативного предоставления пользователям критических обновлений для ОС Астра Linux
- Генерируется псевдо-SBOM файл по пути `/usr/share/rocks/sbom-cert.json`
- Генерируется описание пакетов и контрольные суммы библиотек `/usr/share/rocks/dpkg.query`

## [Assembling a compact image](#contents)

Есть возможность сборки более компактной версии образа, можно сказать, что это аналог **slim** версии. Для этого необходимо использовать [Dockerfile-astra-slim](Dockerfile-astra-slim). Для сборки необходим пакет `docker-buildx`

*Slim-образ не рекомендуется для использования в режиме расширенного МКЦ без дополнительной проверки совместимости*

```console
$ DOCKER_BUILDKIT=1 docker build \
    --progress=plain \
    -f Dockerfile-astra-slim \
    -t astra:1.8.1-slim \
    .
```

### [Compact image variables](#contents)

<!-- markdownlint-disable MD033 -->
<div align="center" class="table-quadro">

| Имя                        | Значение по умолчанию |  Тип   |                                                                                                                                                Описание |
| :------------------------- | :-------------------: | :----: | ------------------------------------------------------------------------------------------------------------------------------------------------------: |
| `image_name`               |         astra         | string |                                                                                                                                             Имя образа. |
| `image_registry`           |          ''           | string |                                                            Адрес до реестра образа. Например: `--build-arg image_registry=my-container-registry:1111/`. |
| `image_version`            |         1.8.1         | string |                                                                                                                                          Версия образа. |
| `version`                  |         1.0.0         | float  |                                                                                                                 Версия выпуска минимального контейнера. |
| `install_additional_tools` |          ''           | string |           Дополнительные компоненты ОС, которые необходимо установить. Разделителем между компонентами должен быть строчный пробел: `ldap-utils slapd`. |
| `remove_additional_binary` |          ''           | string | Дополнительные компоненты ОС, которые необходимо удалить из итогового образа. Разделителем между компонентами должен быть строчный пробел: `sh numfmt`. |
| `locale_list_enable`       |          ''           | string |      Дополнительная локаль, которую необходимо установить в ОС. Разделителем между компонентами должен быть строчный пробел: `en_US.UTF-8 ru_RU.UTF-8`. |

</div>

<div align="center"> <sub> Таблица 4. Переопределяемые аргументы для сборки образа. </sub> </div>
<p>&nbsp;</p>
<!-- markdownlint-enable MD033 -->

#### [Advantages and Disadvantages](#contents)

<!-- markdownlint-disable MD033 -->
<div align="center" class="table-triple">

|         Категория          | Преимущества                                                                | Недостатки                                                                      |
| :------------------------: | :-------------------------------------------------------------------------- | :------------------------------------------------------------------------------ |
|         **Размер**         | Уменьшение размера на 10-15% за счёт удаления ненужных компонентов          | Возможна потеря совместимости с пакетами, требующими удалённых компонентов      |
|        **Отладка**         | Отсутствует отладочные пакеты, для оптимизации образа                       | Для анализа проблем потребуется добавление утилит вручную (например, `busybox`) |
|       **PAM-модули**       | Контейнеры редко используют PAM                                             | Ошибки при работе с пакетами, использующими PAM (например, `sshd`, `sudo`)      |
|      **Безопасность**      | Удаление потенциально опасных утилит (например, `agetty`, `su`, `mount`)    | Ограниченная отладка из-за отсутствия диагностических утилит (`fsck`, `dmesg`)  |
|      **Локализация**       | Сохранение только базовых локалей (`en_US`, `ru_RU`)                        | Проблемы с приложениями, требующими специфичных локалей                         |
|    **Упрощение образа**    | Удаление 200+ утилит снижает поверхность атаки (CVE)                        | -                                                                               |
|   **Производительность**   | Оптимизация памяти через `MALLOC_ARENA_MAX=2` и дедупликацию с `jdupes`     | -                                                                               |
| **Динамические бинарники** | Большинство сохраняет работоспособность                                     | Некоторые пакеты могут требовать PAM или `glibc`-модули, отсутствующие в образе |
| **Совместимость с Docker** | Использование `dumb-init` корректно обрабатывает сигналы (SIGTERM, SIGKILL) | -                                                                               |
| **Управление процессами**  | Блокировка сервисных команд через перенаправление на `/bin/true`            | Невозможность запуска `systemd` и зависимых от него сервисов                    |
| **Устаревшие компоненты**  | Удалены `expect`, `tcl8.6`, `bsd-write`                                     | Не используются в современных workloads                                         |

</div>

<div align="center"> <sub> Таблица 5. Сравнение преимуществ и недостатков в модернизации образа. </sub> </div>
<p>&nbsp;</p>

Пояснение удаления системных компонентов:

<div align="center" class="table-triple">

| Бинарный файл | Назначение                               |                             Причина удаления |
| :-----------: | :--------------------------------------- | -------------------------------------------: |
|    `blkid`    | Определение UUID и типов файловых систем | Доступ к блочным устройствам обычно запрещён |
|    `partx`    | Работа с таблицей разделов               |                  Только для хостовой системы |
|   `addpart`   | Добавление разделов на диске             |  Контейнеры не управляют физическими дисками |
|   `delpart`   | Удаление разделов                        |                                   Аналогично |
|   `losetup`   | Настройка loop-устройств                 |             Редко используется в контейнерах |
|  `blockdev`   | Управление параметрами блочных устройств |                    Избыточно для контейнеров |
| `blkdiscard`  | Очистка блоков на устройстве (SSD/HDD)   |                    Не требуется в контейнере |

</div>

<div align="center"> <sub> Таблица 6. Компоненты управления дисками и разделами. </sub> </div>
<p>&nbsp;</p>

<div align="center" class="table-triple">

|  Бинарный файл   | Назначение                                     |                                          Причина удаления |
| :--------------: | :--------------------------------------------- | --------------------------------------------------------: |
|     `e2fsck`     | Проверка `ext2`/`ext3`/`ext4` ФС               | Контейнеры используют volumes, проверка ФС - задача хоста |
|     `fstrim`     | Оптимизация SSD (TRIM)                         |                               Обычно выполняется на хосте |
|     `mkfs.*`     | Создание файловых систем (`ext4`, `xfs` и др.) |                           Контейнеры монтируют готовые ФС |
|    `tune2fs`     | Настройка параметров ext-ФС                    |                                              Не требуется |
|   `resize2fs`    | Изменение размера ext-разделов                 |                                               Неприменимо |
| `fsck`, `fsck.*` | Проверка и ремонт ФС                           |                                                 Избыточно |

</div>

<div align="center"> <sub> Таблица 7. Компоненты файловой системы. </sub> </div>
<p>&nbsp;</p>

<div align="center" class="table-triple">

| Бинарный файл | Назначение                     |                                        Причина удаления |
| :-----------: | :----------------------------- | ------------------------------------------------------: |
|    `cron`     | Планировщик задач              | Альтернатива: внешний планировщик (Kubernetes CronJobs) |
|    `pam-*`    | Модули PAM для аутентификации  |                         Контейнеры редко используют PAM |
|   `agetty`    | Управление TTY-терминалами     |                     Контейнеры используют stdout/stderr |
|   `hwclock`   | Управление аппаратными часами  |                       Контейнеры используют время хоста |
|   `rtcwake`   | Пробуждение системы по таймеру |                               Бессмысленно в контейнере |

</div>

<div align="center"> <sub> Таблица 8. Компоненты системных сервисов и демонов. </sub> </div>
<p>&nbsp;</p>

<div align="center" class="table-triple">

| Бинарный файл  | Назначение                                  |                                                   Причина удаления |
| :------------: | :------------------------------------------ | -----------------------------------------------------------------: |
|   `chpasswd`   | Изменение паролей пользователей             |                       Stateless-контейнеры не хранят пользователей |
|   `gpasswd`    | Управление группами                         |                                                          Избыточно |
|   `newusers`   | Пакетное создание пользователей             | Пользователи обычно задаются при запуске (via `docker run --user`) |
| `vipw`, `vigr` | Редактирование `/etc/passwd` и `/etc/group` |                        Контейнеры используют read-only корневую ФС |

</div>

<div align="center"> <sub> Таблица 9. Компоненты аутентификации и пользователей. </sub> </div>
<p>&nbsp;</p>

<div align="center" class="table-triple">

| Бинарный файл | Назначение                            |                        Причина удаления |
| :-----------: | :------------------------------------ | --------------------------------------: |
|    `mesg`     | Управление доступом к TTY             |                             Неактуально |
|    `wall`     | Отправка сообщений всем пользователям |                  Контейнеры изолированы |
|  `ldattach`   | Настройка line discipline для TTY     | Устарело, не используется в контейнерах |

</div>

<div align="center"> <sub> Таблица 10. Сетевые и низкоуровневые утилиты. </sub> </div>
<p>&nbsp;</p>

<div align="center" class="table-triple">

| Бинарный файл | Назначение                                                         |                   Причина удаления |
| :-----------: | :----------------------------------------------------------------- | ---------------------------------: |
|   `sulogin`   | Single-user mode login                                             |                        Неприменимо |
|   `zramctl`   | Управление `zram`-устройствами                                     |      Обычно настраивается на хосте |
|  `bsd-write`  | Отправка сообщений между пользователями                            | Устарело, потенциальная уязвимость |
| `ctrlaltdel`  | Настройка реакции на <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>Del</kbd> |          Бессмысленно в контейнере |

</div>

<div align="center"> <sub> Таблица 11. Устаревшие и опасные утилиты. </sub> </div>
<p>&nbsp;</p>

<div align="center" class="table-triple">

|  Бинарный файл  | Назначение                  |                         Причина удаления |
| :-------------: | :-------------------------- | ---------------------------------------: |
|     `dmesg`     | Чтение ядерных логов        | Контейнеры не имеют доступа к логам ядра |
|     `lsblk`     | Просмотр блочных устройств  |                                Избыточно |
|     `wdctl`     | Мониторинг watchdog-таймера |                             Не требуется |
| `last`, `lastb` | История входа пользователей |    Неактуально для ephemeral-контейнеров |

</div>

<div align="center"> <sub> Таблица 12. Отладочные и диагностические утилиты. </sub> </div>
<p>&nbsp;</p>
<!-- markdownlint-enable MD033 -->

Ключевые принципы удаления:

1. **Изоляция контейнера**: Удалено всё, что взаимодействует с железом (`hwclock`, `blkid`)
2. **Минимизация атакующей поверхности**: Убраны утилиты с потенциальными уязвимостями (`chpasswd`, `wall`)
3. **Stateless-принцип**: Удалены компоненты, хранящие состояние (`cron`, `utmpdump`)
4. **Ограничение debug-возможностей**: Диагностика должна проводиться на хосте или через логи

Рекомендации:

```dockerfile
## Для отладки можно добавить временный слой
FROM optimized-image AS debug
RUN apt-install.sh strace procps
```

Сравнительный размер образов:

```console
$ docker images

REPOSITORY                                   TAG                 IMAGE ID       CREATED              SIZE
astra                                        1.7.5-slim          cccccccccccc   5 minutes ago        88.1MB
astra                                        1.7.5               cccccccccccc   5 minutes ago        89.4MB
astra                                        1.7.6-slim          cccccccccccc   5 minutes ago        88.4MB
astra                                        1.7.6               cccccccccccc   5 minutes ago        89.8MB
astra                                        1.7.7-slim          cccccccccccc   5 minutes ago        88.5MB
astra                                        1.7.7               cccccccccccc   5 minutes ago        90.4MB
astra                                        1.8.1-slim          cccccccccccc   5 minutes ago        96.5MB
astra                                        1.8.1               cccccccccccc   5 minutes ago        99.0MB
astra                                        1.8.2-slim          cccccccccccc   5 minutes ago        97.9MB
astra                                        1.8.2               cccccccccccc   5 minutes ago        100MB
... etc
```

## [How use in CI/CD](#contents)

Можно воспользоваться [шаблоном](configuration/Makefile.default.mk) при помощи которого реализуется сборка в CI/CD конвейере. Далее необходимо установить на хост-систему GitLab-runner. В качестве хост-системы необходимо использовать Astra Linux последней, из доступных, версий

<!-- markdownlint-disable MD033 MD044 -->
<div align="center" class="table-triple">

|         Имя          | Значение по умолчанию                                                                                      |                                                                                                                                                                   Описание |
| :------------------: | :--------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
|        SHELL         | /bin/bash                                                                                                  |                                                                                                                                           Стартовая оболочка для Makefile. |
|  MAKEFILE_LOCATION   | [тут](configuration/Makefile.default.mk#L2)                                                                |                                                                                                                  Определение точного местоположения запускаемого Makefile. |
|      BUILD_TAG       | переопределяемое значение на основе переменной CONTAINER_BUILD_TAG                                         |                                                                                                                                           Указывает на версию Astra Linux. |
|       REGISTRY       | переопределяемое значение на основе переменной CONTAINER_PUBLISH_REGISTRY                                  |                                                                                                 Пользовательский реестр образов, куда будет отправлен образ с Astra Linux. |
|   REPOSITORY_BASE    | переопределяемое значение на основе переменной CONTAINER_BASE_REPOSITORY                                   |                                                                                Пользовательский кеширующий/хостирующий репозиторий, откуда будет брать пакеты Astra Linux. |
|   IMAGE_TAG_SUFFIX   | переопределяемое значение на основе переменной IMAGE_TAG_SUFFIX, иначе `slim`                              |                                                                                                                          Переопределение тега для slim версии Astra Linux. |
|     SCRIPT_FILE      | переопределяемое значение на основе переменной SCRIPT_FILE_EXEC, иначе `./build-astra-image.sh`            |                                                                                                                Имя пользовательского скрипта для создания базового образа. |
|     SCRIPT_ARGS      | переопределяемое значение на основе переменной SCRIPT_ADDITIONAL_ARGS                                      |                                                                                                               Дополнительные аргументы для скрипта `build-astra-image.sh`. |
|      DOCKER_BIN      | переопределяемое значение на основе переменной CONTAINER_BIN, иначе `docker`                               |                                                                                         Обозначение бинарного файла, который отвечает за запуск CLI способа сборки образа. |
|      IMAGE_ARGS      | переопределяемое значение на основе переменной CONTAINER_ADDITIONAL_ARGS                                   | Дополнительные аргументы для slim версии. Используются как [подстановочные аргументы](https://docs.docker.com/reference/cli/docker/buildx/build/#build-arg) сборки образа. |
|      IMAGE_NAME      | переопределяемое значение на основе переменной CONTAINER_IMAGE_NAME, иначе `astra`                         |                                                                                                                                                  Обозначение имени образа. |
|  IMAGE_BUILDER_FILE  | переопределяемое значение на основе переменной CONTAINER_IMAGE_BUILDER_FILE, иначе `Dockerfile-astra-slim` |                                                                                                                       Обозначение имени Dockerfile для сборки slim образа. |
| CONTAINER_SKIP_SLIM  | ''                                                                                                         |                                                                                                               При значении `TRUE` будет дополнительно собрана slim версия. |
|  CERTIFICATION_ARG   | переопределяемое значение на основе переменной ALLOW_CERTIFICATION, иначе `''`                             |                                                                                              При объявлении переменной подставляет в аргумент сборки базового образа `-z`. |
| CERTIFICATION_SUFFIX | переопределяемое значение на основе переменной ALLOW_CERTIFICATION, иначе `''`                             |                                                                                                  При объявлении переменной подставляет в суффикс тега образа `-certified`. |

</div>

<div align="center"> <sub> Таблица 13. Переопределяемые аргументы для сборки в управлении Makefile. </sub> </div>
<p>&nbsp;</p>
<!-- markdownlint-enable MD033 MD044 -->

Более подробно почитать [про Makefile](https://microsin.net/programming/arm/learning-makefile-with-simple-examples.html#StaticPatternRules), [переменные Makefile](https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html)

```console
# Download gitlab-runner
$ curl -LJO "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/deb/gitlab-runner-helper-images.deb"
$ curl -LJO "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/deb/gitlab-runner_$(dpkg --print-architecture).deb"

...download process...
```

После последовательной установки `deb` пакетов необходимо отредактировать daemon unit файл

```console
$ nano /etc/systemd/system/gitlab-runner.service

[Unit]
Description=GitLab Runner
ConditionFileIsExecutable=/usr/bin/gitlab-runner

After=network.target

[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/bin/gitlab-runner "run" "--config" "/etc/gitlab-runner/config.toml" "--working-directory" "/root" "--service" "gitlab-runner" "--user" "root"

User=root
Group=root


Restart=always

RestartSec=120
EnvironmentFile=-/etc/sysconfig/gitlab-runner

[Install]
WantedBy=multi-user.target

$ systemctl daemon-reload
$ systemctl restart gitlab-runner
```

После, при помощи GitLab веб-интерфейса настройте сопряжение между Astra Linux и сервером GitLab. После всех проделанных манипуляций можно использовать конвейер для выполнения сборки образа Astra Linux

## [Issues and solutions](#contents)

При появлении подобного сообщения об ошибке, как в примере ниже, необходимо использовать актуальный образ или отключить встроенную проверку уязвимости

```plaintext
Error response from daemon: directory '/var/lib/docker/overlay2/84dd6d8ea4091978616b1c933aaeb9e45ff729207a0028030a595e3ce69a6238/diff' contains vulnerabilities!
{oval:ru.altx-soft.nix:def:188464 true Astra Linux -- уязвимость в expat, ia32-libs (2022-0819SE17) }
{oval:ru.altx-soft.nix:def:188228 true Astra Linux -- уязвимость в python2.7, python3.7 (2022-0819SE17) }
{oval:ru.altx-soft.nix:def:188192 true Astra Linux -- уязвимость в glibc (2022-0819SE17) }
{oval:ru.altx-soft.nix:def:188121 true Astra Linux -- уязвимость в python3.7 (2022-0819SE17) }
...
```

Отключить встроенную проверку уязвимостей (не рекомендуется) можно следующим образом:

Порядок проверки уязвимостей в образах определяется значением параметра astra-sec-level службы dockerd. Значением параметра может быть от 1 до 6 включительно, определяющее класс защиты:

- Классы защиты 1 - 5: при обнаружении уязвимости в контейнере его запуск блокируется
- Класс защиты 6: отладочный режим, при обнаружении уязвимости в контейнере выводится соответствующее предупреждение, при этом запуск контейнера не блокируется

Задать значение параметра можно:

- С помощью конфигурационного файла
- С помощью параметров запуска службы

Конфигурационный файл:

```shell
## Установить jq для удобства работы
apt update && apt install -y jq

## Для версий 1.7.4-1.7.7 и 1.8.1-1.8.2
## Создать конфигурационный файл /etc/docker/daemon.json если он не был создан ранее и указать в нем параметры
DOCKER_DAEMON_FILE='/etc/docker/daemon.json'
[[ ! -f ${DOCKER_DAEMON_FILE} ]] || echo "$(jq '. += {"debug" : true, "astra-sec-level" : 6}' ${DOCKER_DAEMON_FILE})" >"${DOCKER_DAEMON_FILE}"
[[ -f ${DOCKER_DAEMON_FILE} ]] || {
  mkdir -p "${DOCKER_DAEMON_FILE%/*}"
  echo "{}" >"${DOCKER_DAEMON_FILE}"
  echo "$(jq '. += {"debug" : true, "astra-sec-level" : 6}' ${DOCKER_DAEMON_FILE})" >"${DOCKER_DAEMON_FILE}"
}

## Для версий >=1.7.8 и >=1.8.3
## Создать конфигурационный файл /etc/docker/daemon.json если он не был создан ранее и указать в нем параметры
DOCKER_DAEMON_FILE='/etc/docker/daemon.json'
[[ ! -f ${DOCKER_DAEMON_FILE} ]] || echo "$(jq '. += {"debug" : true, "scan-on-image-create" : false, "scan-on-container-start": false, "periodic-scan-time-in-hours": 0}' ${DOCKER_DAEMON_FILE})" >"${DOCKER_DAEMON_FILE}"
[[ -f ${DOCKER_DAEMON_FILE} ]] || {
  mkdir -p "${DOCKER_DAEMON_FILE%/*}"
  echo "{}" >"${DOCKER_DAEMON_FILE}"
  echo "$(jq '. += {"debug" : true, "scan-on-image-create" : false, "scan-on-container-start": false, "periodic-scan-time-in-hours": 0}' ${DOCKER_DAEMON_FILE})" >"${DOCKER_DAEMON_FILE}"
}
```

Параметры запуска службы:

```shell
## Выполнить команду
systemctl edit docker

## Для версий 1.7.4-1.7.7 и 1.8.1-1.8.2
## Ввести и сохранить данные
[Service]
Environment="DOCKER_OPTS=--astra-sec-level 6"
```

> [!warning]
> Независимо от использованного способа перезапустить службу Docker: `systemctl restart docker`

## [Contributing](#contents)

По всем вопросам о сотрудничестве - [сюда](CONTRIBUTING.md)

<!-- markdownlint-disable MD033 MD041 MD051 -->

<table align="center"><tr><td align="center" width="9999">
<img src="docs/images/cya.gif" align="center"  alt="Billy Herrington gif">

<div align="center"> <sub> Billy Herrington in the forge of Skyrim. </sub> </div>

### [Cya!](#contents)

</td></tr></table>
<!-- markdownlint-enable MD033 MD041 MD051 -->

---

[^1]: 🛠️ Подробнее об релизе [Astra Linux](https://wiki.astralinux.ru/pages/viewpage.action?pageId=137563146)
[^2]: 🛠️ В качестве проверки можно использовать эту команду `awk -F'=' '$1=="VERSION_CODENAME" { print $2 ;}' /etc/os-release`
[^3]: 🛠️ По умолчанию выключено включение, если необходимо включить, то перед запуском скрипта передайте как значение `1`. Пример: `export SCF_INCLUDE_DEV=1`
