# 내 컴퓨터에 개발자용 '작업실' 꾸미기 — Dev Workstation

Codyssey 입학연수(Pre-course) 미션 수행 기록입니다. Windows 11 PC에 **WSL2(Ubuntu) + Docker Engine + Git/VS Code** 개발 환경을 세팅하고, 터미널·권한·컨테이너·포트·바인드 마운트·볼륨·Git 연동이 실제로 동작하는지 **명령어와 출력 결과(로그·스크린샷)로 검증**했습니다.

- 저장소(공개): https://github.com/timmy518/Codyssey_E_1-1
- Ubuntu(WSL) 안에서 실행한 명령과 출력은 [`logs/`](logs/)에 단계별 파일로 저장했고, 이 문서에는 핵심 부분을 발췌했습니다. Windows PowerShell에서 실행한 명령은 `PS>` 표시를 붙여 [`logs/00_environment.log`](logs/00_environment.log)(실행 환경), [`logs/08_ports.log`](logs/08_ports.log) 끝부분(Windows에서 `localhost` 접속 확인), [`logs/12_troubleshooting.log`](logs/12_troubleshooting.log) 끝부분(7-6 원인 확인 실험)에 함께 기록했습니다.
- WSL 설치 과정([7-1](#7-1-wsl-설치-명령이-설치를-하지-않음), [7-2](#7-2-설치-직후-wsl2가-시작되지-않음))은 Ubuntu가 아직 없을 때 Windows에서 진행해서 로그 파일이 없습니다. 당시 출력된 메시지를 옮겨 적었습니다. (브라우저·VS Code 화면에서 일어난 [7-5](#7-5-vs-code의-github-로그인이-브라우저에서-멈춤)와 PowerShell 쪽 문제인 [7-6](#7-6-powershell에서-wsl로-명령을-넘길-때-변수와-따옴표가-깨짐)의 당시 출력도 같은 방식입니다.)
- 스크린샷 6장(브라우저 접속, 바인드 마운트 전/후, VS Code·GitHub 연동)은 [`docs/images/`](docs/images/)에 있습니다.

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [실행 환경](#2-실행-환경)
3. [수행 항목 체크리스트](#3-수행-항목-체크리스트)
4. [저장소 구조](#4-저장소-구조)
5. [수행 기록 (명령 + 결과)](#5-수행-기록-명령--결과)
   - [5.1 터미널 기본 조작](#51-터미널-기본-조작)
   - [5.2 권한 실습](#52-권한-실습)
   - [5.3 Docker 설치](#53-docker-설치)
   - [5.4 Docker 설치 점검](#54-docker-설치-점검)
   - [5.5 Docker 기본 운영 명령](#55-docker-기본-운영-명령)
   - [5.6 컨테이너 실행 실습](#56-컨테이너-실행-실습)
   - [5.7 Dockerfile 커스텀 이미지](#57-dockerfile-커스텀-이미지)
   - [5.8 포트 매핑과 접속 증거](#58-포트-매핑과-접속-증거)
   - [5.9 바인드 마운트 반영](#59-바인드-마운트-반영)
   - [5.10 Docker 볼륨 영속성](#510-docker-볼륨-영속성)
   - [5.11 Git 설정과 GitHub / VS Code 연동](#511-git-설정과-github--vs-code-연동)
6. [검증 방법 요약](#6-검증-방법-요약)
7. [트러블슈팅](#7-트러블슈팅)
8. [보안·개인정보 처리](#8-보안개인정보-처리)
9. [개념 정리 (과제 목표)](#9-개념-정리-과제-목표)
10. [재현 방법](#10-재현-방법)
11. [로그 기록 방식](#11-로그-기록-방식)

---

## 1. 프로젝트 개요

**미션 목표 요약**

- 터미널(CLI)로 작업 디렉토리를 만들고 파일을 다루며, 파일·디렉토리 권한을 바꿔 봅니다.
- Docker를 설치·점검하고 이미지와 컨테이너를 실행·관리합니다.
- 기존 이미지(NGINX)를 바탕으로 Dockerfile을 작성해 커스텀 웹 서버 이미지를 만듭니다.
- 포트 매핑으로 접속을 확인하고, 바인드 마운트(변경 반영)와 볼륨(데이터 영속성)을 검증합니다.
- Git을 설정하고 VS Code에서 GitHub에 연동해, 이 저장소로 결과를 제출합니다.

**결과 한눈에 보기**

| 확인한 것 | 결과 | 증거 |
|---|---|---|
| [리눅스 환경](#2-실행-환경) | WSL2(`wsl -l -v`의 VERSION 2) 위 Ubuntu 24.04.5 LTS, bash 5.2.21, PID 1 = systemd | [00](logs/00_environment.log) |
| [터미널 조작](#51-터미널-기본-조작) | 숨김 파일 `.hidden_config`는 `ls -la`에서만 보임, 빈 파일 0바이트(`wc -c`), 절대·상대 경로로 이동하고 `pwd`로 확인 | [01](logs/01_terminal.log) |
| [권한](#52-권한-실습) | `hello.sh` 644에서는 `Permission denied`(exit 126) → 755로 바꾸자 실행, `perm_dir`에서 `x`를 빼자(755 → 644) `cd`·파일 읽기 거부 | [02](logs/02_permissions.log) |
| [Docker 설치·점검](#53-docker-설치) | Docker Engine 29.9.2(공식 apt 저장소) 설치, 서비스 `enabled`·`active`, `docker version`에 Server(데몬) 정보 출력 | [03](logs/03_docker_install.log), [04](logs/04_docker_check.log) |
| [Docker 운영](#55-docker-기본-운영-명령) | `images`·`ps`·`ps -a`·`logs`·`stats` 실행, `stop` 후 `Exited (0)` → `start` 후 다시 `Up` | [05](logs/05_docker_ops.log) |
| [컨테이너 실행](#56-컨테이너-실행-실습) | `hello-world` 성공, ubuntu 안에서 `ls`·`echo` 실행 / `exec`는 새 bash(PID 9, 나와도 `Up`), `attach`는 PID 1(Ctrl+P→Ctrl+Q면 `Up`, `exit`하면 `Exited`) | [06](logs/06_containers.log) |
| [커스텀 이미지](#57-dockerfile-커스텀-이미지) | `my-web:1.0`(베이스 `nginx:1.30.6-alpine`) 빌드 성공, 실행하면 `(healthy)` | [07](logs/07_build.log), [08](logs/08_ports.log) |
| [포트 매핑](#58-포트-매핑과-접속-증거) | 매핑 없이는 `localhost:80` 연결 실패(curl 7) → `-p 8080:80`, `-p 8081:80`은 둘 다 HTTP 200, Windows `curl.exe`·브라우저에서도 접속 | [08](logs/08_ports.log), [캡처 1](docs/images/08_port_8080.png)·[2](docs/images/08_port_8081_info.png) |
| [바인드 마운트](#59-바인드-마운트-반영) | 호스트 파일 수정(v1 → v2)이 컨테이너 재시작 없이 바로 반영 | [09](logs/09_bind_mount.log), [전](docs/images/09_bind_before.png)·[후](docs/images/09_bind_after.png) |
| [볼륨](#510-docker-볼륨-영속성) | `vol-writer`를 지운 뒤 새 컨테이너 `vol-reader`에서 `note.txt`가 그대로 읽힘 (볼륨 없이 쓴 파일은 컨테이너 삭제와 함께 사라짐) | [10](logs/10_volume.log) |
| [Git / GitHub](#511-git-설정과-github--vs-code-연동) | `user.name`·`user.email`·`init.defaultBranch=main` 설정, VS Code에서 공개 저장소로 게시 (첫 게시 때 원격 `main` = 로컬 커밋 `f642393`, 이후 정리 커밋으로 다시 올림) | [11](logs/11_git.log), [캡처 1](docs/images/11_vscode_github_login.png)·[2](docs/images/11_vscode_window.png) |

---

## 2. 실행 환경

| 항목 | 값 | 확인 방법 |
|---|---|---|
| 호스트 OS | Microsoft Windows 11 Home Single Language 25H2 (빌드 10.0.26200.9711) | `(Get-CimInstance Win32_OperatingSystem).Caption`, `Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' DisplayVersion`, `wsl --version`의 `Windows 버전` |
| WSL | WSL 3.0.3.0, 배포판 `Ubuntu-24.04`가 VERSION 2(= WSL2)로 실행 중 | `wsl --version`, `wsl -l -v` |
| WSL 네트워크 모드 | `nat` | `wslinfo --networking-mode` |
| 리눅스 커널 | 6.18.54.1-microsoft-standard-WSL2 | `uname -r` |
| 배포판 | Ubuntu 24.04.5 LTS (noble) | `grep -E "^(PRETTY_NAME\|VERSION_CODENAME)=" /etc/os-release` |
| init (PID 1) | systemd — `systemctl`로 Docker 서비스 관리 | `ps -p 1 -o comm=` |
| 셸 | GNU bash 5.2.21(1)-release | `echo $BASH_VERSION` |
| 터미널 | 대화형 사용: Windows Terminal 1.24.12741.0, VS Code 통합 터미널<br>로그 기록: Windows PowerShell 5.1 → `wsl -- bash <스크립트>` ([11장](#11-로그-기록-방식)) | `(Get-AppxPackage Microsoft.WindowsTerminal).Version` |
| Docker | Docker Engine - Community 29.9.2 (Client·Server, API 1.56) — Docker Desktop이 아니라 Ubuntu 안에 Docker 공식 apt 저장소로 설치<br>containerd v2.4.2, runc 1.5.2, Buildx v0.38.1, Compose v5.6.1 | `docker --version`, `docker version`, `docker info`, `docker compose version` ([04 로그](logs/04_docker_check.log)) |
| Git | 2.43.0 | `git --version` |
| 에디터 | VS Code 1.143.1 (x64), WSL 모드로 Ubuntu에 연결 (상태 표시줄 `WSL: Ubuntu-24.04`) | `code --version`, [5.11 캡처](#511-git-설정과-github--vs-code-연동) |

<details>
<summary>환경 확인 명령과 출력 보기 (logs/00_environment.log의 [1]·[2])</summary>

```text
# [1] Windows 쪽 — PowerShell 에서 확인 (PS> 뒤가 명령, 그 아래가 출력)
PS> (Get-CimInstance Win32_OperatingSystem).Caption
Microsoft Windows 11 Home Single Language
PS> Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' DisplayVersion
25H2
PS> wsl --version
WSL 버전: 3.0.3.0
커널 버전: 6.18.54.1-1
WSLg 버전: 1.0.79
MSRDC 버전: 1.2.7391
Direct3D 버전: 1.611.1-81528511
DXCore 버전: 10.0.26100.1-240331-1435.ge-release
Windows 버전: 10.0.26200.9711
PS> wsl -l -v
  NAME            STATE           VERSION
* Ubuntu-24.04    Running         2
PS> (Get-AppxPackage Microsoft.WindowsTerminal).Version
1.24.12741.0
PS> code --version
1.143.1
e646868227c3e3a9e3f24277c8c7220be42c0be7
x64

# [2] Ubuntu(WSL) 쪽 — bash 에서 확인
timmy518@AISiLa:~$ grep -E "^(PRETTY_NAME|VERSION_CODENAME)=" /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
VERSION_CODENAME=noble
timmy518@AISiLa:~$ uname -r
6.18.54.1-microsoft-standard-WSL2
timmy518@AISiLa:~$ echo $BASH_VERSION
5.2.21(1)-release
timmy518@AISiLa:~$ wslinfo --networking-mode
nat
timmy518@AISiLa:~$ ps -p 1 -o comm=
systemd
timmy518@AISiLa:~$ docker --version
Docker version 29.9.2, build a82e528
timmy518@AISiLa:~$ git --version
git version 2.43.0
```

</details>

전체 출력은 [`logs/00_environment.log`](logs/00_environment.log)에 있습니다 (Docker 상세: [`logs/04_docker_check.log`](logs/04_docker_check.log)). 같은 로그의 `[3]`은 02, 04~10, 12를 다시 기록하기 직전에 컨테이너·이미지·볼륨·빌드 캐시와 02·09의 실습 파일을 지운 기록입니다(마지막 `docker system df`가 모두 0). 01·03과 11의 앞부분은 1차 기록을 그대로 썼습니다([11장](#11-로그-기록-방식)).

> **PC 환경에 따른 차이 (재현 시 주의)**
>
> 미션 안내의 OrbStack은 macOS 전용 앱입니다. 이 PC는 Windows라서 WSL2로 Ubuntu를 띄우고, 그 안에 Docker Engine을 설치했습니다. 그래서 `docker` 명령은 모두 Ubuntu 터미널(bash)에서 실행했습니다.
>
> - Windows: WSL2 + Ubuntu + Docker Engine(이 문서의 방법) 또는 Docker Desktop. Ubuntu 안에 Docker Engine을 설치하는 단계는 관리자(root) 권한이 필요합니다 ([5.3](#53-docker-설치)).
> - macOS: OrbStack 또는 Docker Desktop을 쓰고 WSL 단계는 건너뜁니다. 그 뒤의 `docker` 명령은 같습니다.
> - Windows에서 WSL2(가상 머신 플랫폼)를 처음 켜면 재부팅이 한 번 필요합니다. 이 PC도 재부팅 전에는 WSL2가 시작되지 않았습니다 ([7-2](#7-2-설치-직후-wsl2가-시작되지-않음)).
> - 로그에 나오는 `timmy518`(리눅스 사용자명), `AISiLa`(PC 이름), `/home/timmy518`은 이 PC 기준입니다. 따라 할 때는 `~`, `$HOME`, `$USER`로 바꿔 쓰세요 (예: `cd ~/codyssey/practice/docs`, `sudo usermod -aG docker $USER`, `id $USER`).

---

## 3. 수행 항목 체크리스트

- [x] 터미널 기본 조작 — 현재 위치 확인(`pwd`), 숨김 파일 포함 목록(`ls -la`), 이동(절대·상대 경로 `cd`), 생성(`mkdir`, `echo >`), 복사(`cp`, `cp -r`), 이동/이름 변경(`mv`), 삭제(`rm`, `rmdir`, `rm -r`), 내용 확인(`cat`), 빈 파일 생성(`touch`) → [5.1](#51-터미널-기본-조작)
- [x] 권한 실습 — 파일 2개(`hello.sh`, `perm_file.txt`) + 디렉토리 1개(`perm_dir`)의 권한 변경 전/후 비교 (숫자 방식 `755`·`644`·`600`, 기호 방식 `u=rwx,g=rx,o=`) → [5.2](#52-권한-실습)
- [x] Docker 설치 및 점검 — Docker 공식 apt 저장소로 Docker Engine 설치, `docker --version`, `docker version`(Client·Server), `docker info` → [5.3](#53-docker-설치), [5.4](#54-docker-설치-점검)
- [x] Docker 기본 운영 — `docker pull`, `docker images`, `docker run -d`, `docker ps`, `docker ps -a`, `docker logs`, `docker stats`, `docker stop`/`start`/`rm` → [5.5](#55-docker-기본-운영-명령)
- [x] 컨테이너 실행 — `hello-world` 실행 성공, ubuntu 컨테이너 내부 진입 후 `ls`·`echo`, attach/exec 차이 관찰·정리 → [5.6](#56-컨테이너-실행-실습)
- [x] Dockerfile 커스텀 이미지 — 기존 베이스 `nginx:1.30.6-alpine` + 정적 콘텐츠·설정 교체로 `my-web:1.0` 빌드·실행, 커스텀 포인트별 목적 정리 → [5.7](#57-dockerfile-커스텀-이미지)
- [x] 포트 매핑 — 같은 이미지를 `-p 8080:80`, `-p 8081:80`으로 두 번 실행해 접속 (Ubuntu `curl`, Windows `curl.exe`, 주소창이 보이는 브라우저 캡처 2장) → [5.8](#58-포트-매핑과-접속-증거)
- [x] 바인드 마운트 — `-v "$PWD/bind-site":/usr/share/nginx/html`로 실행하고 호스트 파일 변경 전/후 비교 (`curl` + 캡처 2장) → [5.9](#59-바인드-마운트-반영)
- [x] Docker 볼륨 — `docker volume create` → `-v web-data:/data` 연결 → 데이터 쓰기·읽기, 컨테이너 삭제 전/후 비교 → [5.10](#510-docker-볼륨-영속성)
- [x] Git 설정 — `user.name`, `user.email`, `init.defaultBranch main` 설정 후 `git config --list` → [5.11](#511-git-설정과-github--vs-code-연동)
- [x] GitHub / VS Code 연동 — VS Code(WSL 모드)에서 GitHub 로그인 → Publish Branch로 공개 저장소 게시, 연동 캡처 2장 + `git remote -v`·`git ls-remote` → [5.11](#511-git-설정과-github--vs-code-연동)
- [x] 실행 환경 기록 — Windows(PowerShell)·Ubuntu(bash) 양쪽에서 OS·WSL·셸·Docker·Git·VS Code 버전 확인 → [2](#2-실행-환경), [`logs/00_environment.log`](logs/00_environment.log)
- [x] 트러블슈팅 6건 (문제 → 원인 가설 → 확인 → 해결/대안) — [7-1](#7-1-wsl-설치-명령이-설치를-하지-않음) WSL 설치, [7-2](#7-2-설치-직후-wsl2가-시작되지-않음) WSL2 시작, [7-3](#7-3-windows-드라이브에서-가져온-파일에-실행-권한이-붙음) 파일 실행 권한, [7-4](#7-4-포트-충돌-의도적으로-재현) 포트 충돌, [7-5](#7-5-vs-code의-github-로그인이-브라우저에서-멈춤) VS Code 로그인, [7-6](#7-6-powershell에서-wsl로-명령을-넘길-때-변수와-따옴표가-깨짐) PowerShell → WSL 명령 전달 → [7](#7-트러블슈팅)
- [x] 민감정보 점검 — 실제 비밀값 형식(GitHub 토큰·개인키·AWS 키·URL 속 계정 정보) 검색을 README 포함 모든 파일과 커밋 히스토리 전체에 실행(0건), README를 뺀 텍스트 파일의 키워드 검색(실습 파일 내용 같은 설명 문구만 걸림), `git remote -v`에 토큰 없음·`credential.helper` 설정 없음, 스크린샷 6장의 메타데이터·화면 확인 → [8](#8-보안개인정보-처리), [`logs/13_secret_check.log`](logs/13_secret_check.log)

---

## 4. 저장소 구조

```text
dev-workstation/
├── README.md                           # 기술 문서 (이 파일)
├── Dockerfile                          # 커스텀 웹 서버 이미지 정의 (베이스 nginx:1.30.6-alpine)
├── .dockerignore                       # 빌드 컨텍스트에서 뺄 파일 (.git·문서·로그·비밀 파일 패턴)
├── .gitignore                          # 커밋하지 않을 파일 (OS·에디터 파일, .env·키 파일)
├── app/
│   └── index.html                      # 웹 서버가 보여 줄 정적 페이지 (웹 서버 소스)
├── nginx/
│   └── default.conf.template           # NGINX 설정 템플릿 (/health, /info, 응답 헤더)
├── logs/                               # 단계별 터미널 로그 (명령 + 출력)
│   ├── 00_environment.log              # 실행 환경(Windows PS> + Ubuntu), 재기록 전 실습 환경 초기화
│   ├── 01_terminal.log                 # 5.1 터미널 기본 조작
│   ├── 02_permissions.log              # 5.2 권한 실습
│   ├── 03_docker_install.log           # 5.3 Docker Engine 설치
│   ├── 04_docker_check.log             # 5.4 docker --version / version / info
│   ├── 05_docker_ops.log               # 5.5 pull, images, ps, logs, stats, stop/start/rm
│   ├── 06_containers.log               # 5.6 hello-world, ubuntu 내부 진입, attach/exec
│   ├── 07_build.log                    # 5.7 커스텀 이미지 빌드와 점검
│   ├── 08_ports.log                    # 5.8 포트 매핑, 7-4 포트 충돌, 끝부분 Windows(PS>) 접속 확인
│   ├── 09_bind_mount.log               # 5.9 바인드 마운트 변경 전/후
│   ├── 10_volume.log                   # 5.10 볼륨 영속성, 볼륨 없는 쓰기 층과 비교
│   ├── 11_git.log                      # 5.11 Git 설정, GitHub 연동 확인
│   ├── 12_troubleshooting.log          # 7-3 Windows 드라이브 파일의 실행 권한 재현, 끝부분 7-6 원인 확인 실험(PS>)
│   └── 13_secret_check.log             # 8장 민감정보 점검 결과
└── docs/images/                        # 스크린샷 6장
    ├── 08_port_8080.png                # 브라우저 localhost:8080 (주소창 포함)
    ├── 08_port_8081_info.png           # 브라우저 localhost:8081/info ("env":"prod")
    ├── 09_bind_before.png              # 바인드 마운트 변경 전 (v1)
    ├── 09_bind_after.png               # 바인드 마운트 변경 후 (v2)
    ├── 11_vscode_github_login.png      # VS Code 계정 메뉴 "timmy518 (GitHub)"
    └── 11_vscode_window.png            # VS Code(WSL) 게시 성공 알림
```

실습용 폴더 `~/codyssey/practice`(터미널·권한·바인드 마운트 실습)는 저장소 밖에 따로 두어 커밋하지 않았습니다. 이 저장소는 `~/codyssey/dev-workstation`에 있습니다.

## 5. 수행 기록 (명령 + 결과)

각 절은 **한 일 → 명령과 출력 → 확인 포인트 → 전체 로그 링크** 순서로 정리했습니다.

**로그 읽는 법**

- `timmy518@AISiLa:~/codyssey/practice$ pwd`처럼 프롬프트(`사용자@호스트:현재 위치$`) 뒤에 있는 것이 실행한 명령이고, 다음 프롬프트 전까지가 그 출력입니다. `root@AISiLa:~#`처럼 `#`으로 끝나는 프롬프트는 관리자(root) 셸, `PS>`는 Windows PowerShell입니다.
- `#`으로 시작하는 줄은 설명이고, 명령 줄 끝의 `# ...`는 이 문서에서 덧붙인 설명입니다. 길거나 반복되는 출력은 `...`로 줄였고, 전체는 [`logs/`](logs/)의 로그 파일에 있습니다.
- `[exit code: N]`은 바로 위 명령이 실패했고 종료 코드가 N이라는 표시입니다(예: 126 = 실행 권한 없음, 1 = 일반 오류). 기록용 함수가 각 명령을 `bash -c`로 실행해서 오류 메시지가 `bash: line 1: ...` 형태로 보이며, 터미널에 직접 입력하면 `bash: ...`로 나옵니다.
- `timmy518`(리눅스 사용자명), `AISiLa`(PC 이름), `/home/timmy518`(홈 디렉토리)는 이 PC의 값입니다. 따라 할 때는 `/home/timmy518`을 `~` 또는 `$HOME`으로, `timmy518`을 `$USER`로 바꿔 입력하세요. 예: `cd $HOME/codyssey/practice/docs`, `id $USER`.
- 출력 속 시각은 종류마다 뜻이 다릅니다. 컨테이너 로그(`+0000`)와 `date`의 시각은 그 명령을 실행한 때, `docker volume inspect`의 `CreatedAt`은 볼륨을 만든 때, `ls -l`의 시각은 파일이 마지막으로 바뀐 때입니다(예: 5.4의 `docker.sock` `13:41`은 Docker 설치 때 소켓이 만들어진 시각). 컨테이너 안에서 찍힌 시각은 UTC라서 9시간을 더하면 한국 시간입니다(예: 05:50 UTC = 14:50 KST).
- 로그는 두 차례에 나눠 기록해서 절마다 시각이 다를 수 있습니다(예: 5.1에서 만든 파일은 `13:46`, 5.2에서 만든 파일은 `14:49`). 자세한 기록 방식은 [11. 로그 기록 방식](#11-로그-기록-방식)에 있습니다.

### 5.1 터미널 기본 조작

홈 디렉토리 아래에 실습 폴더 `~/codyssey/practice`를 만들고, 미션이 요구한 기본 조작을 모두 터미널 명령으로 수행했습니다. 아래 블록에는 로그의 모든 명령을 순서대로 옮겼습니다.

| 미션 요구 | 사용한 명령 |
|---|---|
| 현재 위치 확인 | `pwd` |
| 목록 확인 (숨김 파일 포함) | `ls`, `ls -la`, `find . \| sort` |
| 이동 | `cd` — 상대 경로(`codyssey/practice`, `..`, `./docs`), 절대 경로(`/home/timmy518/...`), 홈 기준(`~/...`) |
| 생성 | `mkdir -p`, `mkdir` (디렉토리), `echo "..." > hello.txt` (내용 있는 파일), `touch .hidden_config` (숨김 파일) |
| 빈 파일 생성 | `touch empty.txt` |
| 복사 | `cp` (파일), `cp -r` (디렉토리째) |
| 이동 / 이름 변경 | `mv hello.txt docs/` (이동), `mv docs/hello.txt docs/greeting.txt` (이름 변경) |
| 삭제 | `rm` (파일), `rmdir` (빈 디렉토리), `rm -r` (내용이 있는 디렉토리) |
| 파일 내용 확인 | `cat`, `wc -c` (바이트 수) |

```bash
# 1) 현재 위치 확인 — 터미널을 열면 홈 디렉토리(~)에서 시작한다
timmy518@AISiLa:~$ pwd
/home/timmy518

# 2) 실습용 작업 디렉토리 만들기 (-p: 중간 경로(codyssey)까지 한 번에 생성)
timmy518@AISiLa:~$ mkdir -p ~/codyssey/practice

# 3) 상대 경로로 이동 (현재 위치 기준)
timmy518@AISiLa:~$ cd codyssey/practice
timmy518@AISiLa:~/codyssey/practice$ pwd
/home/timmy518/codyssey/practice

# 4) 빈 파일 만들기(touch) / 내용 있는 파일 만들기(echo + > 리다이렉션) / 숨김 파일(.으로 시작)
timmy518@AISiLa:~/codyssey/practice$ touch empty.txt
timmy518@AISiLa:~/codyssey/practice$ echo "Hello, Codyssey!" > hello.txt
timmy518@AISiLa:~/codyssey/practice$ touch .hidden_config

# 5) 목록 확인 — ls 는 숨김 파일을 안 보여주고, ls -la 는 숨김 파일(., .., .hidden_config)까지 보여준다
timmy518@AISiLa:~/codyssey/practice$ ls
empty.txt
hello.txt
timmy518@AISiLa:~/codyssey/practice$ ls -la
total 12
drwxr-xr-x 2 timmy518 timmy518 4096 Nov  2 13:46 .
drwxr-xr-x 4 timmy518 timmy518 4096 Nov  2 13:46 ..
-rw-r--r-- 1 timmy518 timmy518    0 Nov  2 13:46 .hidden_config
-rw-r--r-- 1 timmy518 timmy518    0 Nov  2 13:46 empty.txt
-rw-r--r-- 1 timmy518 timmy518   17 Nov  2 13:46 hello.txt

# 6) 파일 내용 확인 — 빈 파일은 아무것도 출력되지 않는다 (크기 0 바이트)
timmy518@AISiLa:~/codyssey/practice$ cat hello.txt
Hello, Codyssey!
timmy518@AISiLa:~/codyssey/practice$ cat empty.txt   # 빈 파일이라 출력 없음
timmy518@AISiLa:~/codyssey/practice$ wc -c empty.txt hello.txt
 0 empty.txt
17 hello.txt
17 total

# 7) 디렉토리 만들기 + 복사 (cp: 파일 복사 / cp -r: 디렉토리째 복사)
timmy518@AISiLa:~/codyssey/practice$ mkdir docs backup
timmy518@AISiLa:~/codyssey/practice$ cp hello.txt backup/hello_copy.txt
timmy518@AISiLa:~/codyssey/practice$ cp -r backup backup_copy
timmy518@AISiLa:~/codyssey/practice$ ls -la backup backup_copy
backup:
total 12
drwxr-xr-x 2 timmy518 timmy518 4096 Nov  2 13:46 .
drwxr-xr-x 5 timmy518 timmy518 4096 Nov  2 13:46 ..
-rw-r--r-- 1 timmy518 timmy518   17 Nov  2 13:46 hello_copy.txt

backup_copy:
total 12
drwxr-xr-x 2 timmy518 timmy518 4096 Nov  2 13:46 .
drwxr-xr-x 5 timmy518 timmy518 4096 Nov  2 13:46 ..
-rw-r--r-- 1 timmy518 timmy518   17 Nov  2 13:46 hello_copy.txt

# 8) 이동과 이름 변경 — 둘 다 mv 명령 (목적지가 디렉토리면 이동, 새 이름이면 이름 변경)
timmy518@AISiLa:~/codyssey/practice$ mv hello.txt docs/
timmy518@AISiLa:~/codyssey/practice$ mv docs/hello.txt docs/greeting.txt
timmy518@AISiLa:~/codyssey/practice$ ls -la docs
total 12
drwxr-xr-x 2 timmy518 timmy518 4096 Nov  2 13:46 .
drwxr-xr-x 5 timmy518 timmy518 4096 Nov  2 13:46 ..
-rw-r--r-- 1 timmy518 timmy518   17 Nov  2 13:46 greeting.txt
timmy518@AISiLa:~/codyssey/practice$ cat docs/greeting.txt
Hello, Codyssey!

# 9) 절대 경로 vs 상대 경로
timmy518@AISiLa:~/codyssey/practice$ cd /home/timmy518/codyssey/practice/docs   # 절대 경로
timmy518@AISiLa:~/codyssey/practice/docs$ pwd
/home/timmy518/codyssey/practice/docs
timmy518@AISiLa:~/codyssey/practice/docs$ cd ..   # 상대 경로 (.. = 상위 디렉토리)
timmy518@AISiLa:~/codyssey/practice$ pwd
/home/timmy518/codyssey/practice
timmy518@AISiLa:~/codyssey/practice$ cd ./docs   # 상대 경로 (. = 현재 디렉토리)
timmy518@AISiLa:~/codyssey/practice/docs$ pwd
/home/timmy518/codyssey/practice/docs
timmy518@AISiLa:~/codyssey/practice/docs$ cd ~/codyssey/practice   # ~ = 홈 디렉토리
timmy518@AISiLa:~/codyssey/practice$ pwd
/home/timmy518/codyssey/practice

# 10) 삭제 — rm: 파일 / rmdir: 빈 디렉토리 / rm -r: 내용이 있는 디렉토리
timmy518@AISiLa:~/codyssey/practice$ rm backup/hello_copy.txt
timmy518@AISiLa:~/codyssey/practice$ rmdir backup
timmy518@AISiLa:~/codyssey/practice$ rm -r backup_copy
timmy518@AISiLa:~/codyssey/practice$ rm empty.txt
timmy518@AISiLa:~/codyssey/practice$ ls -la
total 12
drwxr-xr-x 3 timmy518 timmy518 4096 Nov  2 13:46 .
drwxr-xr-x 4 timmy518 timmy518 4096 Nov  2 13:46 ..
-rw-r--r-- 1 timmy518 timmy518    0 Nov  2 13:46 .hidden_config
drwxr-xr-x 2 timmy518 timmy518 4096 Nov  2 13:46 docs

# 최종 구조 확인
timmy518@AISiLa:~/codyssey/practice$ find . | sort
.
./.hidden_config
./docs
./docs/greeting.txt
```

**확인 포인트**

- **숨김 파일**: `ls`에는 `empty.txt`, `hello.txt`만 나오고, `ls -la`에는 `.`(현재 디렉토리), `..`(상위 디렉토리), `.hidden_config`까지 나옵니다. 이름이 `.`으로 시작하는 파일은 숨김 파일이라 `-a` 옵션을 줘야 보입니다.
- **빈 파일(0바이트)**: `touch`로 만든 `empty.txt`는 `ls -la`의 크기 칸이 `0`이고, `cat`은 아무것도 출력하지 않았으며, `wc -c`도 `0 empty.txt`입니다. 참고로 `hello.txt`가 17바이트인 것은 `Hello, Codyssey!` 16글자에 `echo`가 붙인 줄바꿈 1바이트가 더해졌기 때문입니다.
- **복사·이동·삭제**: `cp -r`로 복사한 `backup_copy` 안에도 `hello_copy.txt`가 있어 디렉토리가 내용째 복사되었습니다. `mv` 두 번으로 `hello.txt`가 `docs/greeting.txt`가 되었고 내용은 그대로입니다. `rmdir`는 빈 디렉토리만 지울 수 있어서 `backup` 안의 파일을 먼저 지웠습니다. 마지막 `ls -la`와 `find` 결과에는 `.hidden_config`와 `docs/greeting.txt`만 남았습니다.
- **절대 경로 vs 상대 경로**: 같은 `docs` 디렉토리에 두 방법으로 이동해 `pwd` 결과가 똑같은 것을 확인했습니다. 프롬프트의 현재 위치 표시도 `~/codyssey/practice$`에서 `~/codyssey/practice/docs$`로 함께 바뀝니다.

| 명령 | 경로 종류 | 실행한 위치 | 이동 후 `pwd` |
|---|---|---|---|
| `cd codyssey/practice` | 상대 경로 (현재 위치 기준) | `~` | `/home/timmy518/codyssey/practice` |
| `cd /home/timmy518/codyssey/practice/docs` | 절대 경로 (`/`부터 시작하는 전체 주소) | `~/codyssey/practice` | `/home/timmy518/codyssey/practice/docs` |
| `cd ..` | 상대 경로 (`..` = 상위 디렉토리) | `~/codyssey/practice/docs` | `/home/timmy518/codyssey/practice` |
| `cd ./docs` | 상대 경로 (`.` = 현재 디렉토리) | `~/codyssey/practice` | `/home/timmy518/codyssey/practice/docs` |
| `cd ~/codyssey/practice` | 홈 기준 (셸이 `~`를 홈 경로로 바꿔 절대 경로가 됨) | `~/codyssey/practice/docs` | `/home/timmy518/codyssey/practice` |

절대 경로는 어디서 실행해도 같은 곳을 가리키고, 상대 경로 `./docs`는 `~/codyssey/practice`에 있을 때만 이 디렉토리를 가리킵니다.

전체 로그: [`logs/01_terminal.log`](logs/01_terminal.log)

### 5.2 권한 실습

파일 2개(`hello.sh`, `perm_file.txt`)와 디렉토리 1개(`perm_dir`)를 새로 만들어 권한을 바꾸고, 바꾸기 전/후에 무엇이 되고 무엇이 막히는지 확인했습니다. 권한은 `stat -c '%A (%a) %n'`으로 기호(`-rw-r--r--`)와 숫자(`644`)를 함께 출력해 비교했습니다. 아래 네 블록에 로그의 모든 명령을 순서대로 나눠 옮겼습니다.

**준비 — 기본 권한(umask) 확인과 실습 재료 만들기**

```bash
# 권한 읽는 법: ls -l 첫 10글자 = 종류(1) + 소유자 u(3) + 그룹 g(3) + 기타 o(3)
# 숫자 표기: r=4, w=2, x=1 을 더한다 → rwx=7, r-x=5, rw-=6, r--=4  (예: 755 = rwx r-x r-x)
# umask 0022: 새 파일 기본값 666, 새 디렉토리 기본값 777 에서 022(그룹·기타의 w) 비트를 끈다 → 644 / 755 (빼기가 아니라 비트 끄기)
timmy518@AISiLa:~/codyssey/practice$ umask
0022

# 실습 재료 만들기: 파일 2개(perm_file.txt, hello.sh) + 디렉토리 1개(perm_dir, 안에 inside.txt)
timmy518@AISiLa:~/codyssey/practice$ touch perm_file.txt && mkdir perm_dir
timmy518@AISiLa:~/codyssey/practice$ printf '#!/bin/bash\necho "hello.sh is running!"\n' > hello.sh
timmy518@AISiLa:~/codyssey/practice$ echo "secret inside" > perm_dir/inside.txt
timmy518@AISiLa:~/codyssey/practice$ ls -l perm_file.txt hello.sh && ls -ld perm_dir
-rw-r--r-- 1 timmy518 timmy518 40 Nov  2 14:49 hello.sh
-rw-r--r-- 1 timmy518 timmy518  0 Nov  2 14:49 perm_file.txt
drwxr-xr-x 2 timmy518 timmy518 4096 Nov  2 14:49 perm_dir
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %U:%G %n' perm_file.txt hello.sh perm_dir
-rw-r--r-- (644) timmy518:timmy518 perm_file.txt
-rw-r--r-- (644) timmy518:timmy518 hello.sh
drwxr-xr-x (755) timmy518:timmy518 perm_dir
```

**umask는 빼기가 아니라 비트 끄기입니다.** 프로그램이 새 파일은 보통 666(`rw-rw-rw-`), 새 디렉토리는 777(`rwxrwxrwx`)로 만들어 달라고 요청하면, 커널이 umask에 켜져 있는 비트를 끈 값으로 만듭니다(`요청값 AND (NOT umask)`). `0022`의 맨 앞 `0`은 특수 권한(setuid·setgid·sticky) 자리입니다.

| 대상 | 요청값 | umask `022`가 끄는 비트 | 결과 |
|---|---|---|---|
| 새 파일 | 666 = `110 110 110` (`rw-rw-rw-`) | `000 010 010` (그룹·기타의 `w`) | `110 100 100` = **644** (`rw-r--r--`) |
| 새 디렉토리 | 777 = `111 111 111` (`rwxrwxrwx`) | `000 010 010` (그룹·기타의 `w`) | `111 101 101` = **755** (`rwxr-xr-x`) |

022에서는 빼기(666 − 022)와 결과가 우연히 같을 뿐입니다. 예를 들어 umask가 033이라면 빼기로는 633(`rw--wx-wx`)이 나오지만 실제 새 파일은 **644**입니다. 666에는 `x` 비트가 처음부터 없어서 끌 것이 없기 때문입니다. 새로 만든 `hello.sh`가 실행 권한 없이 644로 시작한 것도 파일은 처음부터 `x`를 요청하지 않기 때문입니다.

**[실험 1·2] 파일 — 실행(`x`)과 읽기(`r`)**

```bash
# [실험 1] 파일: 실행 권한(x)이 없으면 스크립트를 실행할 수 없다 → chmod 755 후 실행 가능
timmy518@AISiLa:~/codyssey/practice$ cat hello.sh   # 아래 2줄은 출력(스크립트 내용)
#!/bin/bash
echo "hello.sh is running!"
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' hello.sh
-rw-r--r-- (644) hello.sh
timmy518@AISiLa:~/codyssey/practice$ ./hello.sh
bash: line 1: ./hello.sh: Permission denied
[exit code: 126]
timmy518@AISiLa:~/codyssey/practice$ chmod 755 hello.sh
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' hello.sh
-rwxr-xr-x (755) hello.sh
timmy518@AISiLa:~/codyssey/practice$ ./hello.sh
hello.sh is running!

# [실험 2] 파일: 644 → 600 (그룹/기타 사용자의 읽기 권한 제거, 비밀 파일에 쓰는 권한) → 다시 644
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' perm_file.txt
-rw-r--r-- (644) perm_file.txt
timmy518@AISiLa:~/codyssey/practice$ chmod 600 perm_file.txt
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' perm_file.txt
-rw------- (600) perm_file.txt
timmy518@AISiLa:~/codyssey/practice$ chmod 644 perm_file.txt
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' perm_file.txt
-rw-r--r-- (644) perm_file.txt
```

**[실험 3] 디렉토리 — `x`는 '안으로 들어가기(통과)' 권한**

```bash
# [실험 3] 디렉토리: x 권한은 '안으로 들어가기(통과)' 권한이다 → x 를 빼면 cd 와 안의 파일 읽기가 막힌다
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' perm_dir
drwxr-xr-x (755) perm_dir
timmy518@AISiLa:~/codyssey/practice$ chmod 644 perm_dir
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' perm_dir
drw-r--r-- (644) perm_dir
timmy518@AISiLa:~/codyssey/practice$ cd perm_dir
bash: line 1: cd: perm_dir: Permission denied
[exit code: 1]
timmy518@AISiLa:~/codyssey/practice$ cat perm_dir/inside.txt
cat: perm_dir/inside.txt: Permission denied
[exit code: 1]
#    r 은 있어서 안에 있는 이름(inside.txt)은 읽히지만, x 가 없어 파일의 상세 정보는 읽지 못해 ? 로 보인다
timmy518@AISiLa:~/codyssey/practice$ ls -l perm_dir
ls: cannot access 'perm_dir/inside.txt': Permission denied
total 0
-????????? ? ? ? ?            ? inside.txt
[exit code: 1]
timmy518@AISiLa:~/codyssey/practice$ chmod 755 perm_dir
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' perm_dir
drwxr-xr-x (755) perm_dir
timmy518@AISiLa:~/codyssey/practice$ cat perm_dir/inside.txt
secret inside
```

**`ls -l perm_dir`에 `?`가 보인 이유** — 디렉토리는 안에 든 파일들의 **이름 목록**을 담은 특별한 파일입니다. 디렉토리의 `r`은 이 목록을 **읽는** 권한이고, `x`는 목록의 이름을 따라 **안의 파일에 접근하는(통과하는)** 권한입니다. `ls -l`은 먼저 목록에서 이름을 읽고(`r` 필요), 그다음 이름마다 파일의 상세 정보(권한·링크 수·소유자·그룹·크기·시각, inode에 저장됨)를 읽습니다(`x` 필요). 644(`drw-r--r--`)는 소유자에게도 `x`가 없어서, 이름 `inside.txt`는 보였지만(`r`) 상세 정보는 읽지 못해 모두 `?`로 표시되고 `cannot access ... Permission denied`와 함께 실패(exit 1)했습니다. 맨 앞의 `-`(일반 파일)만 보인 것은 파일 종류가 디렉토리 목록에 이름과 함께 기록되어 있기 때문입니다. `cd`와 `cat perm_dir/inside.txt`가 거부된 것도 `x`가 없어서이고, 755로 되돌리자 같은 `cat`이 `secret inside`를 출력했습니다.

**[실험 4] 기호 방식, 그리고 원래대로 되돌리기**

```bash
# [실험 4] 기호 방식: u(소유자) g(그룹) o(기타) a(모두) + 더하기/빼기/지정 r w x
timmy518@AISiLa:~/codyssey/practice$ chmod u=rwx,g=rx,o= perm_dir
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' perm_dir
drwxr-x--- (750) perm_dir
timmy518@AISiLa:~/codyssey/practice$ chmod o+r,g+w perm_file.txt
timmy518@AISiLa:~/codyssey/practice$ stat -c '%A (%a) %n' perm_file.txt
-rw-rw-r-- (664) perm_file.txt
timmy518@AISiLa:~/codyssey/practice$ chmod 755 perm_dir && chmod 644 perm_file.txt

# 최종 상태 (기본값으로 되돌림, hello.sh 는 실행 파일이므로 755 유지)
timmy518@AISiLa:~/codyssey/practice$ ls -l perm_file.txt hello.sh && ls -ld perm_dir
-rwxr-xr-x 1 timmy518 timmy518 40 Nov  2 14:49 hello.sh
-rw-r--r-- 1 timmy518 timmy518  0 Nov  2 14:49 perm_file.txt
drwxr-xr-x 2 timmy518 timmy518 4096 Nov  2 14:49 perm_dir
```

기호 방식은 **누구**(`u` 소유자, `g` 그룹, `o` 기타, `a` 모두) + **연산**(`+` 더하기, `-` 빼기, `=` 지정) + **권한**(`r`, `w`, `x`)으로 씁니다. `=`는 그 자리를 통째로 정하고(`o=` → 기타는 권한 없음), `+`는 기존 권한에 더합니다.

**확인 포인트 — 변경 전/후 비교**

| 대상 | 변경 전 | 명령 | 변경 후 | 관찰한 결과 |
|---|---|---|---|---|
| `hello.sh` (파일) | `-rw-r--r--` (644) | `chmod 755 hello.sh` | `-rwxr-xr-x` (755) | 변경 전 `./hello.sh` → `Permission denied` (exit 126), 변경 후 `hello.sh is running!` 출력 |
| `perm_file.txt` (파일) | `-rw-r--r--` (644) | `chmod 600 perm_file.txt` | `-rw-------` (600) | 그룹·기타 자리가 `---`가 되어 소유자만 읽고 쓰는 설정(비밀 파일용) → `chmod 644`로 복구 |
| `perm_dir` (디렉토리) | `drwxr-xr-x` (755) | `chmod 644 perm_dir` | `drw-r--r--` (644) | `cd`, `cat perm_dir/inside.txt` 거부 (exit 1), `ls -l`은 이름만 보이고 나머지는 `?` → `chmod 755`로 복구하자 `secret inside` 읽힘 |
| `perm_dir` (기호 방식) | `drwxr-xr-x` (755) | `chmod u=rwx,g=rx,o= perm_dir` | `drwxr-x---` (750) | 기타(o)의 `r`·`x`만 꺼짐 |
| `perm_file.txt` (기호 방식) | `-rw-r--r--` (644) | `chmod o+r,g+w perm_file.txt` | `-rw-rw-r--` (664) | 그룹에 `w`가 더해짐 (기타는 이미 `r`이 있어 그대로) |

마지막에 `perm_dir`는 755, `perm_file.txt`는 644로 되돌렸고, `hello.sh`는 실행 파일이라 755로 두었습니다(마지막 `ls -l` 출력).

- `126`은 bash가 "파일은 찾았지만 실행할 수 없음"일 때 돌려주는 종료 코드입니다. 디렉토리 실험의 실패(`cd`, `cat`, `ls`)는 일반 오류 `1`입니다.
- [실험 4]의 664는 [실험 2]에서 644로 되돌린 상태에 `g+w`가 더해진 결과입니다(600 상태였다면 `-rw--w-r--`, 624).
- 같은 umask 계산(777에서 022 비트를 끄면 755)이 Windows 드라이브에서 복사한 파일에 실행 권한이 붙는 문제([7-3](#7-3-windows-드라이브에서-가져온-파일에-실행-권한이-붙음))의 원인입니다.

전체 로그: [`logs/02_permissions.log`](logs/02_permissions.log)

### 5.3 Docker 설치

Ubuntu(WSL2) 안에 [Docker 공식 문서](https://docs.docker.com/engine/install/ubuntu/)의 **apt 저장소 방식**으로 Docker Engine을 설치했습니다. 아래 기록은 **관리자(root) 셸**에서 실행한 것이라 프롬프트가 `root@AISiLa:~#`이고, 명령 앞에 `sudo`가 없습니다. 일반 사용자 계정으로 따라 할 때는 이 절 뒷부분의 **일반 사용자로 따라 하기**를 쓰세요.

```bash
# OS 확인 + systemd 동작 확인 (PID 1 이 systemd 여야 docker 서비스가 자동 시작된다)
root@AISiLa:~# grep -E "^(PRETTY_NAME|VERSION_CODENAME)=" /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
VERSION_CODENAME=noble
root@AISiLa:~# ps -p 1 -o comm=
systemd

# 1) Docker 공식 GPG 키 등록 (다운로드한 패키지가 진짜 Docker 것인지 검증하는 용도)
root@AISiLa:~# apt-get update -qq
root@AISiLa:~# apt-get install -y -qq ca-certificates curl > /dev/null && echo "ca-certificates, curl: OK"
ca-certificates, curl: OK
root@AISiLa:~# install -m 0755 -d /etc/apt/keyrings
root@AISiLa:~# curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
root@AISiLa:~# chmod a+r /etc/apt/keyrings/docker.asc
root@AISiLa:~# ls -l /etc/apt/keyrings/docker.asc
-rw-r--r-- 1 root root 3817 Nov  2 13:41 /etc/apt/keyrings/docker.asc

# 2) Docker apt 저장소 추가
root@AISiLa:~# printf "Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nSigned-By: /etc/apt/keyrings/docker.asc\n" "$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")" > /etc/apt/sources.list.d/docker.sources
root@AISiLa:~# cat /etc/apt/sources.list.d/docker.sources
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
root@AISiLa:~# apt-get update -qq

# 3) Docker Engine + CLI + containerd + buildx + compose 플러그인 설치 (긴 설치 출력은 /tmp/docker-apt.log 로 보내고 종료 코드와 Setting up 줄만 표시)
root@AISiLa:~# DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /tmp/docker-apt.log 2>&1; echo "apt-get exit code: $?"; grep -E "^Setting up (docker|containerd)" /tmp/docker-apt.log
apt-get exit code: 0
Setting up docker-buildx-plugin (0.38.1-1~ubuntu.24.04~noble) ...
Setting up containerd.io (2.4.2-3~ubuntu.24.04~noble) ...
Setting up docker-compose-plugin (5.6.1-1~ubuntu.24.04~noble) ...
Setting up docker-ce-cli (5:29.9.2-1~ubuntu.24.04~noble) ...
Setting up docker-ce-rootless-extras (5:29.9.2-1~ubuntu.24.04~noble) ...
Setting up docker-ce (5:29.9.2-1~ubuntu.24.04~noble) ...

# 4) 서비스 상태 확인 (enabled = 부팅 시 자동 시작, active = 지금 실행 중)
root@AISiLa:~# systemctl is-enabled docker
enabled
root@AISiLa:~# systemctl is-active docker
active

# 5) sudo 없이 docker 를 쓰도록 사용자를 docker 그룹에 추가 (새 터미널부터 적용)
root@AISiLa:~# usermod -aG docker timmy518      # 주의: root와 같은 권한 (아래 주의 참고)
root@AISiLa:~# id timmy518
uid=1000(timmy518) gid=1000(timmy518) groups=1000(timmy518),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),989(docker)
```

**확인 포인트**

| 단계 | 출력 | 의미 |
|---|---|---|
| 사전 확인 | `VERSION_CODENAME=noble`, `systemd` | 코드네임 `noble`이 2)의 저장소 설정에서 `Suites` 값이 됩니다. PID 1이 `systemd`라서 docker 서비스를 `systemctl`로 관리하고 부팅 때 자동으로 시작할 수 있습니다. |
| 1) GPG 키 | `ca-certificates, curl: OK`, `-rw-r--r-- 1 root root 3817 ... docker.asc` | HTTPS 인증서 묶음(ca-certificates)과 curl을 준비하고, 키 보관 폴더 `/etc/apt/keyrings`(755)에 Docker 공식 공개키를 내려받아 모든 사용자가 읽을 수 있게(`a+r`) 했습니다. |
| 2) 저장소 | `Suites: noble`, `Signed-By: /etc/apt/keyrings/docker.asc` | apt가 Docker 저장소를 알게 되고, 이 저장소의 서명은 1)의 키로만 검증합니다. 이어서 `apt-get update`로 Docker 패키지 목록을 받아 왔습니다. |
| 3) 설치 | `apt-get exit code: 0`, `Setting up ...` 6줄 | 설치 성공입니다. Engine·CLI 29.9.2, containerd 2.4.2, Buildx 0.38.1, Compose 5.6.1이 설치됐고, 명령에 적지 않은 `docker-ce-rootless-extras`(rootless 모드용)도 `docker-ce`의 추천 패키지로 함께 설치됐습니다. 긴 설치 출력은 `/tmp/docker-apt.log`로 보내고, 화면에는 종료 코드와 docker·containerd 패키지의 `Setting up` 줄만 골라 표시했습니다. |
| 4) 서비스 | `enabled`, `active` | `systemctl enable`을 따로 실행하지 않았는데도 패키지 설치만으로 서비스가 등록(부팅 시 자동 시작)되고 지금 실행 중입니다. |
| 5) 그룹 | `989(docker)` | `timmy518`이 docker 그룹에 들어갔습니다. 이미 열려 있는 터미널에는 적용되지 않고 새 터미널부터 적용됩니다(5.4의 `id -nG`에서 확인). |

전체 로그: [`logs/03_docker_install.log`](logs/03_docker_install.log)

**일반 사용자로 따라 하기 (로그 아님, 참고용)**

일반 사용자 터미널에서는 관리자 권한이 필요한 명령 앞에 `sudo`를 붙입니다. 기록용으로 넣은 옵션(`-qq`, `DEBIAN_FRONTEND=noninteractive`, 설치 출력을 `/tmp/docker-apt.log`로 보내기)은 뺐습니다.

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
printf "Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nSigned-By: /etc/apt/keyrings/docker.asc\n" "$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")" | sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl is-active docker           # active가 나오면 데몬 실행 중
sudo usermod -aG docker $USER        # $USER = 지금 로그인한 내 사용자명
```

- **저장소 파일을 만드는 줄만 `sudo tee`를 씁니다.** `sudo printf ... > /etc/apt/sources.list.d/docker.sources`처럼 쓰면 `Permission denied`로 실패합니다. `>`(출력을 파일로 보내기)는 `sudo`가 실행되기 **전에** 지금 셸이 처리하는데, 이 셸은 일반 사용자 권한이라 `/etc/apt/sources.list.d/` 안에 파일을 만들 수 없기 때문입니다. `| sudo tee 파일`로 바꾸면 root 권한으로 실행되는 `tee`가 파일을 씁니다. 끝의 `> /dev/null`은 `tee`가 같은 내용을 화면에도 찍는 것을 숨길 뿐입니다.
- **그룹 변경은 새 터미널부터 적용됩니다.** 이미 열려 있는 터미널은 예전 그룹 정보를 그대로 쓰므로, 터미널을 새로 연 뒤 `id -nG`에 `docker`가 보이는지 확인하세요. 그래도 보이지 않으면 Windows PowerShell에서 `wsl --shutdown`을 실행하고 Ubuntu를 다시 엽니다. 적용 전에 `docker ps`를 실행하면 `/var/run/docker.sock`에 대한 permission denied 오류가 납니다.
- `ps -p 1 -o comm=`의 결과가 `systemd`가 아니면 docker 서비스가 자동으로 시작되지 않습니다. 이때는 Ubuntu의 `/etc/wsl.conf`에 `[boot]` 섹션과 `systemd=true`를 넣고 `wsl --shutdown` 후 다시 엽니다(이 PC는 위 기록처럼 이미 `systemd`였습니다).

> **주의 — `docker` 그룹은 사실상 root 권한입니다**
>
> Docker 데몬은 root로 실행되고, `docker` 그룹 사용자는 소켓(`/var/run/docker.sock`)을 통해 이 데몬에 무엇이든 시킬 수 있습니다. 예를 들어 `docker run -v /:/host ...`처럼 호스트의 `/` 전체를 컨테이너에 연결하면 sudo 비밀번호 없이 호스트의 모든 파일을 읽고 고칠 수 있습니다. Docker 공식 문서([Linux post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/))도 docker 그룹이 root 수준 권한을 준다고 경고합니다.
>
> 이 PC는 혼자 쓰는 개인 WSL 개발 환경이라 편의를 위해 그룹에 추가했습니다. 여러 사람이 함께 쓰는 서버나 공용 PC라면 그룹에 넣지 말고 필요할 때 `sudo docker ...`로 실행하거나, 데몬을 일반 사용자 권한으로 실행하는 [rootless 모드](https://docs.docker.com/engine/security/rootless/)를 검토해야 합니다. rootless 모드에 필요한 `docker-ce-rootless-extras` 패키지는 위 3) 설치 때 이미 함께 설치되었습니다.

### 5.4 Docker 설치 점검

설치가 끝난 뒤 **일반 사용자(`timmy518`) 터미널에서 `sudo` 없이** 버전, 데몬 동작, 시스템 정보, 권한을 점검했습니다. 미션의 "Docker 버전 확인(`docker --version`)"과 "데몬 동작 여부 확인(`docker info` 또는 동등 점검)"에 해당합니다. 출력이 긴 `docker version`과 `docker info`는 핵심 줄만 남기고 `...`로 줄였습니다.

```bash
# 1) Docker 버전 확인 (클라이언트 CLI)
timmy518@AISiLa:~$ docker --version
Docker version 29.9.2, build a82e528
timmy518@AISiLa:~$ docker compose version
Docker Compose version v5.6.1

# 2) 데몬 동작 확인 — docker version 은 Client 와 Server(=데몬) 정보를 함께 보여준다. Server 부분이 나오면 데몬이 살아 있다
timmy518@AISiLa:~$ docker version
Client: Docker Engine - Community
 Version:           29.9.2
 API version:       1.56
...
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          29.9.2
  API version:      1.56 (minimum version 1.40)
...
 containerd:
  Version:          v2.4.2
...
 runc:
  Version:          1.5.2
...

# 3) docker info — 데몬 상태, 컨테이너/이미지 개수, 스토리지 드라이버, cgroup, 커널 등 상세 점검
timmy518@AISiLa:~$ docker info
Client: Docker Engine - Community
 Version:    29.9.2
 Context:    default
...

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 29.9.2
 Storage Driver: overlayfs
  driver-type: io.containerd.snapshotter.v1
 Logging Driver: json-file
 Cgroup Driver: systemd
 Cgroup Version: 2
...
 Kernel Version: 6.18.54.1-microsoft-standard-WSL2
 Operating System: Ubuntu 24.04.5 LTS
 OSType: linux
 Architecture: x86_64
 CPUs: 12
 Total Memory: 7.602GiB
...
 Docker Root Dir: /var/lib/docker
...

# 4) systemd 서비스 상태 + sudo 없이 쓸 수 있는 이유(docker 그룹 + 소켓 권한)
timmy518@AISiLa:~$ systemctl is-active docker containerd
active
active
timmy518@AISiLa:~$ id -nG
timmy518 adm cdrom sudo dip plugdev users docker
timmy518@AISiLa:~$ ls -l /var/run/docker.sock
srw-rw---- 1 root docker 0 Nov  2 13:41 /var/run/docker.sock
```

**확인 포인트**

| 확인한 출력 | 의미 |
|---|---|
| `Docker version 29.9.2`, `Docker Compose version v5.6.1` | CLI와 Compose 플러그인이 설치되어 실행됩니다. 5.3의 `Setting up` 줄과 버전이 같습니다. |
| `docker version`의 `Server: Docker Engine - Community` 부분 | CLI가 소켓을 통해 데몬에 접속해 응답을 받았다는 뜻입니다 = **데몬 동작 중**. 데몬이 꺼져 있으면 이 자리에 `Cannot connect to the Docker daemon ...` 오류가 나옵니다. |
| `API version: 1.56 (minimum version 1.40)`, containerd `v2.4.2`, runc `1.5.2` | 클라이언트와 데몬의 API 버전(1.56)이 맞습니다. 데몬 아래에서 실제로 컨테이너를 만들고 실행하는 containerd·runc도 응답합니다. |
| `Containers: 0`, `Images: 0` | 빈 상태에서 시작했습니다. [`logs/00_environment.log`](logs/00_environment.log)의 `[3] 실습 환경 초기화`에서 앞선 실습의 컨테이너·이미지를 정리한 뒤 다시 기록했기 때문입니다. |
| `Storage Driver: overlayfs` (`io.containerd.snapshotter.v1`), `Docker Root Dir: /var/lib/docker` | 이미지 레이어를 겹쳐(overlay) 하나의 파일 시스템처럼 보여 주는 방식이고, 이미지 저장·관리는 containerd가 맡습니다. containerd 이미지 저장소(`io.containerd.snapshotter.v1`)를 쓰므로 이미지 레이어와 컨테이너 쓰기 층(스냅샷)은 containerd의 저장 위치(기본 `/var/lib/containerd`)에 있고, `Docker Root Dir`인 `/var/lib/docker`에는 볼륨(`volumes/`, 5.10의 `web-data`도 여기)과 컨테이너 설정·로그(`containers/`) 등이 저장됩니다. |
| `Logging Driver: json-file` | 컨테이너의 표준 출력·에러가 JSON 파일로 저장되고, `docker logs`(5.5)가 이 파일을 읽어 보여 줍니다. |
| `Cgroup Driver: systemd`, `Cgroup Version: 2` | 컨테이너의 CPU·메모리 사용은 리눅스 cgroup v2로 제한·측정하고, cgroup 관리는 systemd가 맡습니다. |
| `Kernel Version: 6.18.54.1-microsoft-standard-WSL2`, `Operating System: Ubuntu 24.04.5 LTS` | 엔진이 WSL2 커널 위의 Ubuntu 안에서 돌고 있습니다(Docker Desktop이 아니라 Ubuntu 안에 설치한 Docker Engine). |
| `CPUs: 12`, `Total Memory: 7.602GiB` | WSL2 가상 머신에 잡힌 자원입니다. 컨테이너에 따로 제한을 주지 않으면 이것이 상한이라, 5.5 `docker stats`의 메모리 LIMIT도 `7.602GiB`로 나옵니다. |
| `active` / `active` | docker와 containerd 서비스가 모두 실행 중입니다. |
| `id -nG`의 `docker`, `srw-rw---- 1 root docker ... docker.sock` | 5.3에서 추가한 docker 그룹이 새 터미널에 적용됐습니다. 소켓 파일(`s`)은 root와 **docker 그룹**만 읽기·쓰기(rw)할 수 있으므로, docker 그룹인 `timmy518`은 `sudo` 없이 데몬에 명령을 보낼 수 있습니다. 같은 이유로 docker 그룹은 사실상 root 권한입니다([5.3의 주의](#53-docker-설치)). |

전체 로그: [`logs/04_docker_check.log`](logs/04_docker_check.log)

### 5.5 Docker 기본 운영 명령

`ubuntu:24.04`와 `nginx:stable-alpine` 이미지를 받고, nginx 이미지로 `ops-web` 컨테이너를 만들어 실행 → 로그·자원 확인 → 중지 → 재시작 → 삭제까지 한 흐름으로 실행했습니다. 미션의 이미지(다운로드·목록), 컨테이너(실행·중지·목록), 운영(로그·리소스) 항목에 해당합니다. 긴 `pull` 진행 표시는 `...`로 줄였습니다.

```bash
# 1) 이미지 다운로드(pull) 와 목록 확인(images)
timmy518@AISiLa:~$ docker pull ubuntu:24.04
24.04: Pulling from library/ubuntu
...
Digest: sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852
Status: Downloaded newer image for ubuntu:24.04
docker.io/library/ubuntu:24.04
timmy518@AISiLa:~$ docker pull nginx:stable-alpine
stable-alpine: Pulling from library/nginx
...
Digest: sha256:0e52bd054126cdc040b1276c0af347aeb02a41b9cfe305d6094767ac30e97949
Status: Downloaded newer image for nginx:stable-alpine
docker.io/library/nginx:stable-alpine
timmy518@AISiLa:~$ docker images
IMAGE                 ID             DISK USAGE   CONTENT SIZE   EXTRA
nginx:stable-alpine   0e52bd054126       93.5MB           27MB        
ubuntu:24.04          fe81560990fa        119MB         31.7MB        

# 2) 컨테이너 목록 — docker ps 는 실행 중인 것만, docker ps -a 는 종료된 것까지 전부
timmy518@AISiLa:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
timmy518@AISiLa:~$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

# 3) 컨테이너 실행(-d: 백그라운드) → 목록 확인
timmy518@AISiLa:~$ docker run -d --name ops-web nginx:stable-alpine
059b738907b42f62670a9c125ad58a7849873d0a62d709ef722ee0f0b146c59f
timmy518@AISiLa:~$ docker ps
CONTAINER ID   IMAGE                 COMMAND                  CREATED        STATUS                  PORTS     NAMES
059b738907b4   nginx:stable-alpine   "/docker-entrypoint.…"   1 second ago   Up Less than a second   80/tcp    ops-web

# 4) 로그 확인 — 요청을 하나 보내고(컨테이너 안에서 wget) 접근 로그가 찍히는지 본다
timmy518@AISiLa:~$ docker exec ops-web wget -qO- http://127.0.0.1 | grep -o "<title>.*</title>"
<title>Welcome to nginx!</title>
timmy518@AISiLa:~$ docker logs --tail 5 ops-web
2026/11/02 05:49:27 [notice] 1#1: start worker process 38
2026/11/02 05:49:27 [notice] 1#1: start worker process 39
2026/11/02 05:49:27 [notice] 1#1: start worker process 40
2026/11/02 05:49:27 [notice] 1#1: start worker process 41
127.0.0.1 - - [02/Nov/2026:05:49:27 +0000] "GET / HTTP/1.1" 200 896 "-" "Wget" "-"

# 5) 리소스 사용량 확인 (--no-stream: 한 번만 찍고 종료)
timmy518@AISiLa:~$ docker stats --no-stream ops-web
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O      BLOCK I/O     PIDS
059b738907b4   ops-web   0.00%     11.35MiB / 7.602GiB   0.15%     486B / 84B   0B / 8.19kB   13

# 6) 중지(stop) → ps 에서는 사라지고 ps -a 에서는 Exited 로 보인다 → 다시 시작(start)
timmy518@AISiLa:~$ docker stop ops-web
ops-web
timmy518@AISiLa:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
timmy518@AISiLa:~$ docker ps -a
CONTAINER ID   IMAGE                 COMMAND                  CREATED         STATUS                              PORTS     NAMES
059b738907b4   nginx:stable-alpine   "/docker-entrypoint.…"   2 seconds ago   Exited (0) Less than a second ago             ops-web
timmy518@AISiLa:~$ docker start ops-web
ops-web
timmy518@AISiLa:~$ docker ps
CONTAINER ID   IMAGE                 COMMAND                  CREATED         STATUS                  PORTS     NAMES
059b738907b4   nginx:stable-alpine   "/docker-entrypoint.…"   2 seconds ago   Up Less than a second   80/tcp    ops-web

# 7) 정리 (rm -f: 실행 중이어도 강제로 중지 후 삭제)
timmy518@AISiLa:~$ docker rm -f ops-web
ops-web
timmy518@AISiLa:~$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**확인 포인트**

| 명령 | 관찰한 결과 | 의미 |
|---|---|---|
| `docker pull` (2회) | `Status: Downloaded newer image for ...` | Docker Hub에서 이미지를 받았습니다. 00 로그 [3]에서 이미지를 모두 지운 뒤라 둘 다 새로 받았습니다. |
| `docker images` | `nginx:stable-alpine` 93.5MB, `ubuntu:24.04` 119MB | 로컬에 저장된 이미지 목록입니다. ID(`0e52bd054126`, `fe81560990fa`)는 pull 때 나온 `Digest`의 앞부분과 같습니다. |
| `docker ps`, `docker ps -a` (실행 전) | 둘 다 빈 목록 | 이미지는 있어도 컨테이너는 아직 없습니다. 이미지(틀)와 컨테이너(그 틀로 실행한 것)는 별개입니다. |
| `docker run -d` → `docker ps` | `Up Less than a second`, PORTS `80/tcp` | 백그라운드에서 실행 중입니다. `80/tcp`는 nginx 이미지에 `EXPOSE 80`으로 선언된 포트를 보여 줄 뿐(실제로 듣는지 검사한 값이 아님) 호스트에는 공개되지 않았습니다(포트 매핑은 [5.8](#58-포트-매핑과-접속-증거)). |
| `docker exec ... wget` → `docker logs --tail 5` | `<title>Welcome to nginx!</title>`, 마지막 줄 `"GET / HTTP/1.1" 200 896 "-" "Wget"` | 컨테이너 안에서 보낸 요청이 nginx 접근 로그에 찍혔습니다. nginx 공식 이미지는 접근 로그를 표준 출력(`/dev/stdout`), 에러 로그를 표준 에러(`/dev/stderr`)로 연결해 두어 `docker logs`로 둘 다 볼 수 있습니다(위 `[notice]` 줄은 에러 로그). 로그 시각 `05:49:27 +0000`은 UTC라 한국 시간으로 14:49입니다. |
| `docker stats --no-stream` | CPU `0.00%`, MEM `11.35MiB / 7.602GiB`, PIDS `13` | 대기 중인 nginx라 CPU는 거의 쓰지 않고 메모리는 약 11MiB입니다. LIMIT `7.602GiB`는 5.4의 `Total Memory`와 같습니다. PIDS 13은 nginx 마스터 1개 + 워커 12개(CPU 12개에 맞춰 자동 생성)입니다. |
| `docker stop` → `docker ps`, `docker ps -a` | `ps`에서는 사라지고 `ps -a`에는 `Exited (0)` | 중지는 삭제가 아닙니다. 컨테이너는 정상 종료(코드 0) 상태로 남아 있습니다. |
| `docker start` → `docker ps` | 같은 ID `059b738907b4`가 다시 `Up` | 멈춘 컨테이너를 그대로 다시 실행했습니다(새로 만든 것이 아님). |
| `docker rm -f` → `docker ps -a` | 빈 목록 | 컨테이너가 삭제됐습니다. 이미지는 남아 있어 `ubuntu:24.04`는 [5.6](#56-컨테이너-실행-실습)·[5.10](#510-docker-볼륨-영속성)에서 다시 씁니다. |

전체 로그: [`logs/05_docker_ops.log`](logs/05_docker_ops.log)

### 5.6 컨테이너 실행 실습

`hello-world`를 실행하고, ubuntu 컨테이너 안에 들어가 간단한 명령을 실행했습니다. 그다음 같은 조건의 컨테이너 3개로 `exec`와 `attach`의 차이(빠져나온 뒤 컨테이너가 종료되는지, 유지되는지)를 관찰했습니다. 명령은 홈 폴더(`~`)에서 실행했습니다.

**① hello-world 실행**

로컬에 없는 이미지를 `docker run`으로 바로 실행해, 이미지 받기 → 컨테이너 생성 → 실행 → 종료를 한 번에 확인했습니다.

```bash
timmy518@AISiLa:~$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
...
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
...
timmy518@AISiLa:~$ docker ps -a --filter ancestor=hello-world
CONTAINER ID   IMAGE         COMMAND    CREATED                  STATUS                              PORTS     NAMES
3dd0e96bc679   hello-world   "/hello"   Less than a second ago   Exited (0) Less than a second ago             dazzling_brahmagupta
```

**확인 포인트**

- `Unable to find image ... locally` → `Pulling from library/hello-world` → `Status: Downloaded newer image`: 로컬에 이미지가 없으면 `docker run`이 Docker Hub에서 먼저 받아(pull) 실행합니다.
- `Hello from Docker!`: Docker 클라이언트가 데몬에 요청하고, 데몬이 이미지로 컨테이너를 만들어 실행한 결과가 터미널까지 전달되었습니다(출력의 1~4단계 설명은 전체 로그 참고). 설치가 정상이라는 뜻입니다.
- `docker ps -a`의 `Exited (0)`: 메시지를 출력한 `/hello` 프로그램이 끝나자 컨테이너도 바로 정상 종료(종료 코드 0)했습니다. `--name`을 주지 않아서 이름 `dazzling_brahmagupta`는 Docker가 자동으로 붙였습니다.

**② ubuntu 컨테이너 안에서 명령 실행 (`-it`)**

`-i`(입력 유지)와 `-t`(터미널 연결)로 ubuntu 컨테이너의 bash에 들어가 `ls`, `echo`, `cat`을 실행하고 `exit`로 나왔습니다. `ubuntu:24.04`는 [5.5](#55-docker-기본-운영-명령)에서 받아 두어서 다시 받지 않고 바로 실행됩니다.

```bash
timmy518@AISiLa:~$ docker run -it --name ubuntu-shell ubuntu:24.04 bash
root@5392105b2b32:/# ls
bin   dev  home  lib64  mnt  proc  run   srv  tmp  var
boot  etc  lib   media  opt  root  sbin  sys  usr
root@5392105b2b32:/# echo "Hello from inside the container"
Hello from inside the container
root@5392105b2b32:/# cat /etc/os-release | head -2
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
root@5392105b2b32:/# exit
exit
timmy518@AISiLa:~$ docker ps -a --filter name=ubuntu-shell --format "table {{.Names}}\t{{.Status}}"
NAMES          STATUS
ubuntu-shell   Exited (0) 2 seconds ago
```

**확인 포인트**

- 프롬프트가 `timmy518@AISiLa:~$`에서 `root@5392105b2b32:/#`로 바뀌었습니다. 컨테이너 안의 root 셸이고, `5392105b2b32`는 컨테이너의 호스트 이름(기본값: 컨테이너 ID 앞 12자리)입니다.
- `ls`는 컨테이너의 루트(`/`) 목록을, `cat /etc/os-release`는 `ubuntu:24.04` 이미지의 배포판 정보를 보여 줍니다.
- 메인 프로세스인 bash에서 `exit`하자 컨테이너가 `Exited (0)`이 되었습니다. 컨테이너는 메인 프로세스가 끝나면 함께 끝납니다.

**③ 비교 준비 — `-d`·`-i`·`-t`의 역할**

먼저 `-i`·`-t` 없이 `-d`만으로 bash를 띄워 봤습니다(`no-it-demo`). 그다음 비교용 컨테이너 3개를 `-dit`로 띄웠습니다. 세 컨테이너 모두 메인 프로세스는 `bash`입니다.

```bash
timmy518@AISiLa:~$ docker run -d --name no-it-demo ubuntu:24.04 bash  # -i·-t 없이 -d만
8c002cd8aebf84055dce0206a318a97457b28c3b9c8f1cad887716c819f49d25
timmy518@AISiLa:~$ docker ps -a --filter name=no-it-demo --format "table {{.Names}}\t{{.Status}}"  # 시작 직후 조회
NAMES        STATUS
no-it-demo   Up Less than a second
timmy518@AISiLa:~$ docker rm no-it-demo  # -f 없이 삭제
no-it-demo
timmy518@AISiLa:~$ docker run -dit --name exec-demo ubuntu:24.04 bash  # exec 실험용
8bd3bd2d3e64d2802ec7cffe5e5f9e5fdf8d0a66749175f8bb4fb8dd6079a024
timmy518@AISiLa:~$ docker run -dit --name attach-demo ubuntu:24.04 bash  # attach → Ctrl+P, Ctrl+Q 실험용
8d80de17ddf5254c532d5c916a7d3d5dbc9724551edd74afefb20aebe0f4de12
timmy518@AISiLa:~$ docker run -dit --name attach-exit-demo ubuntu:24.04 bash  # attach → exit 실험용
e347a361127691a761d7f519efe879ab1e0bd4823e14fd2e7f9aebddb3ef2533
timmy518@AISiLa:~$ docker ps --format "table {{.Names}}\t{{.Status}}"
NAMES              STATUS
attach-exit-demo   Up Less than a second
attach-demo        Up Less than a second
exec-demo          Up Less than a second
```

| 옵션 | 뜻 | 이 실습에서의 역할 |
|---|---|---|
| `-d` (`--detach`) | 백그라운드에서 실행하고 컨테이너 ID만 출력 | 컨테이너를 띄워 둔 채 터미널을 돌려받아 다음 명령(exec/attach)을 실행 |
| `-i` (`--interactive`) | 컨테이너의 표준 입력(STDIN)을 열어 둠 | bash가 입력을 기다리며 계속 실행됨 |
| `-t` (`--tty`) | 가상 터미널(TTY)을 붙임 | 프롬프트가 보이는 대화형 셸이 됨. attach 뒤 `Ctrl+P` → `Ctrl+Q`로 빠져나오려면 `-i`와 함께 필요 |

**③-1 보충 실험 (검토 후 추가 — 로그 맨 끝부분)** — 위 `no-it-demo`는 컨테이너가 끝나기 전에 상태를 바로 조회해서 `Up Less than a second`로 찍혔습니다. 그래서 2초 기다린 뒤 다시 확인했습니다.

```bash
timmy518@AISiLa:~$ docker run -d --name no-it-demo2 ubuntu:24.04 bash  # 다시 -i·-t 없이 -d만
efb3dba321130a543d8e9d24df86d5623c3a95c10d2d092ec0c4b0c984b3f221
timmy518@AISiLa:~$ sleep 2
timmy518@AISiLa:~$ docker ps -a --filter name=no-it-demo2 --format "table {{.Names}}\t{{.Status}}"
NAMES         STATUS
no-it-demo2   Exited (0) 2 seconds ago
timmy518@AISiLa:~$ docker rm no-it-demo2
no-it-demo2
```

**확인 포인트**

- `no-it-demo`: 명령 없이 실행된 bash는 표준 입력에서 명령을 읽습니다. `-i`·`-t`가 없으면 읽을 입력이 없어(입력이 바로 끝남) 스스로 종료합니다. 시작 직후 조회는 거의 같은 순간이라 `Up Less than a second`로 찍혔지만, 2초 뒤 다시 확인한 보충 실험(③-1)에서 `Exited (0)`가 확인됐습니다.
- `-dit`로 띄운 3개는 `docker ps`(실행 중인 것만 표시)에 모두 `Up`으로 나오고, 아래 ④에서 5초·10초 뒤에도 `Up`입니다. bash가 입력을 기다리며 계속 실행되기 때문입니다.
- 각 컨테이너 ID의 앞 12자리(`8bd3bd2d3e64`, `8d80de17ddf5`, `e347a3611276`)가 ④의 프롬프트(`root@8bd3bd2d3e64` 등)와 같아서, 의도한 컨테이너에 들어갔음을 확인할 수 있습니다.

**④ exec와 attach의 차이 관찰**

세 컨테이너에서 각각 `exec` 후 `exit`, `attach` 후 `Ctrl+P` → `Ctrl+Q`, `attach` 후 `exit`를 하고 상태를 비교했습니다. `echo "my PID is $$"`는 지금 셸의 PID(프로세스 번호)를 출력합니다.

```bash
timmy518@AISiLa:~$ docker exec -it exec-demo bash  # 컨테이너 안에 새 bash를 띄워 들어감
root@8bd3bd2d3e64:/# echo "my PID is $$"
my PID is 9
root@8bd3bd2d3e64:/# exit
exit
timmy518@AISiLa:~$ docker ps -a --filter name=exec-demo --format "table {{.Names}}\t{{.Status}}"
NAMES       STATUS
exec-demo   Up 5 seconds
timmy518@AISiLa:~$ docker attach attach-demo  # 메인 bash(PID 1)에 연결 → echo 후 Ctrl+P, Ctrl+Q
root@8d80de17ddf5:/# echo "my PID is $$"
my PID is 1
read escape sequence
timmy518@AISiLa:~$ docker ps -a --filter name=attach-demo --format "table {{.Names}}\t{{.Status}}"
NAMES         STATUS
attach-demo   Up 10 seconds
timmy518@AISiLa:~$ docker attach attach-exit-demo  # 메인 bash(PID 1)에 연결 → echo 후 exit
root@e347a3611276:/# echo "my PID is $$"
my PID is 1

exit
timmy518@AISiLa:~$ docker ps -a --filter name=attach-exit-demo --format "table {{.Names}}\t{{.Status}}"
NAMES              STATUS
attach-exit-demo   Exited (0) 2 seconds ago
timmy518@AISiLa:~$ docker rm -f ubuntu-shell exec-demo attach-demo attach-exit-demo  # 정리
ubuntu-shell
exec-demo
attach-demo
attach-exit-demo
```

**확인 포인트**

- exec: PID가 `9`(1이 아님)입니다. 컨테이너 안에 bash를 **새로 하나 더** 띄운 것이라, `exit`해도 그 bash만 끝나고 컨테이너는 `Up 5 seconds`로 계속 실행됩니다.
- attach + `Ctrl+P` → `Ctrl+Q`: PID가 `1`, 즉 컨테이너의 **메인 프로세스**에 직접 연결되었습니다. 키를 누르면 화면에 `read escape sequence`가 찍히고 연결만 끊겨(detach) 컨테이너는 `Up 10 seconds`로 유지됩니다.
- attach + `exit`: 같은 PID 1 bash를 `exit`로 끝내자 컨테이너도 `Exited (0)`이 되었습니다.
- 마지막 `docker rm -f`로 `ubuntu-shell`과 비교용 컨테이너 3개를 정리했습니다(`-f`: 실행 중이어도 강제로 멈추고 삭제).

**exec와 attach 정리**

| 구분 | `docker exec -it <컨테이너> bash` | `docker attach <컨테이너>` |
|---|---|---|
| 연결 대상 | 컨테이너 안에 **새 프로세스**(bash)를 띄워 연결 | 이미 실행 중인 **메인 프로세스**의 입출력에 연결 |
| PID (`echo $$`) | `9` — 1이 아닌 새 프로세스 | `1` — 메인 프로세스 |
| `exit` 하면 | 내가 띄운 bash만 끝남 → 컨테이너 **유지** (`Up 5 seconds`) | 메인 프로세스가 끝남 → 컨테이너 **종료** (`Exited (0)`) |
| 안전하게 빠져나오기 | `exit` | `Ctrl+P` → `Ctrl+Q` (detach, `Up 10 seconds`로 유지). `-it`로 실행한 컨테이너에서만 동작합니다. attach 중 `Ctrl+C`는 메인 프로세스에 전달되므로, `-it` 없이 띄운 컨테이너(예: `-d`로만 띄운 nginx)에서는 컨테이너가 멈출 수 있습니다 |
| 주 용도 | 실행 중인 컨테이너 안을 점검·디버깅 (5.5·5.8에서 `docker exec <컨테이너> wget ...`으로 컨테이너 안에서 요청을 보낸 것도 exec) | 메인 프로세스의 출력을 직접 보거나 그 프로세스에 입력할 때 |

전체 로그: [`logs/06_containers.log`](logs/06_containers.log)

### 5.7 Dockerfile 커스텀 이미지

미션의 **(A) 방식**(웹 서버 베이스 이미지 + 정적 콘텐츠/설정 교체)으로 커스텀 이미지 `my-web:1.0`을 만들었습니다. 명령은 저장소 폴더(`~/codyssey/dev-workstation`)에서 실행했습니다.

**선택한 기존 베이스: 공식 `nginx:1.30.6-alpine` 이미지**

- 검증된 웹 서버(NGINX)를 그대로 쓰고, 보여 줄 페이지([`app/`](app/))와 설정([`nginx/`](nginx/))만 바꾸면 됩니다.
- Alpine 리눅스 기반이라 가볍습니다.
- 공식 이미지는 컨테이너가 시작될 때 설정 템플릿(`/etc/nginx/templates/*.template`)을 처리해 주므로, 환경 변수(`APP_ENV`)를 설정에 넣기 쉽습니다.
- 버전 태그를 고정해서 언제 빌드해도 같은 NGINX 버전(1.30.6)을 씁니다.

**Dockerfile** — 저장소의 [`Dockerfile`](Dockerfile) 전체입니다(07 로그의 `cat Dockerfile` 출력과 같습니다). 주석 번호 (1)~(7)이 아래 표의 번호와 짝을 이룹니다.

```dockerfile
# (1) 베이스 이미지: 공식 NGINX 이미지 (Alpine 리눅스 기반이라 가볍다)
#     버전 태그를 고정해서 언제 빌드해도 같은 NGINX 버전(1.30.6)을 쓴다.
#     (이미지 내용까지 완전히 고정하려면 태그 뒤에 @sha256:... digest 를 붙인다)
FROM nginx:1.30.6-alpine

# (2) 이미지 메타데이터: 제목(title)·설명·작성자. docker image inspect 로 확인할 수 있다.
#     (이미지 이름 my-web:1.0 은 여기가 아니라 docker build -t 로 정한다)
LABEL org.opencontainers.image.title="dev-workstation-web" \
      org.opencontainers.image.description="Codyssey pre-course: custom NGINX image (static site + /health + /info)" \
      org.opencontainers.image.authors="timmy518"

# (3) 기본 실행 모드. 실행할 때 docker run -e APP_ENV=prod 처럼 바꿀 수 있다.
ENV APP_ENV=dev

# (4) 설정 교체: 템플릿을 넣어두면 컨테이너 시작 시 /etc/nginx/conf.d/default.conf 로 만들어진다.
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template

# (5) 정적 콘텐츠 교체: 기본 "Welcome to nginx!" 페이지 대신 내 페이지를 넣는다.
COPY app/ /usr/share/nginx/html/

# (6) 문서화: 이 컨테이너는 80번 포트에서 요청을 받는다. (실제 연결은 docker run -p 로 한다)
EXPOSE 80

# (7) 헬스체크: 10초마다 /health 를 호출한다. 3초 안에 응답이 없으면 실패 1회로 세고,
#     시작 후 5초 동안의 실패는 세지 않으며, 3번 연속 실패하면 unhealthy 로 표시한다 (재시작은 하지 않음).
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/health || exit 1
```

**커스텀 포인트와 목적**

| 번호 | 커스텀 포인트 | 명령 | 목적 |
|---|---|---|---|
| (1) | 베이스 버전 고정 | `FROM nginx:1.30.6-alpine` | 태그를 고정해서 언제 빌드해도 같은 NGINX 버전(1.30.6)을 씁니다. 태그는 같은 이름으로 다시 만들어 올릴 수 있는 이름표라서(예: 보안 패치), 이미지 내용까지 완전히 고정하려면 `@sha256:...` digest를 붙입니다 |
| (2) | 메타데이터 | `LABEL org.opencontainers.image.*` (title, description, authors) | 이미지의 제목(title)·설명·작성자 정보를 이미지에 기록합니다(`docker image inspect`로 확인). 이미지 이름 `my-web:1.0`은 LABEL이 아니라 `docker build -t`로 정합니다 |
| (3) | 실행 모드 | `ENV APP_ENV=dev` | 기본값 `dev`를 이미지에 넣어 둡니다. 실행할 때 `docker run -e APP_ENV=prod`처럼 덮어쓸 수 있어서, 다시 빌드하지 않고 동작을 바꿉니다(설정과 코드 분리, [5.8](#58-포트-매핑과-접속-증거)의 `web-8081`) |
| (4) | 설정 교체 | `COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template` | [`nginx/default.conf.template`](nginx/default.conf.template)으로 `/health`·`/info` 엔드포인트와 `X-Served-By`·`X-App-Env` 응답 헤더를 추가합니다. 공식 이미지가 컨테이너 시작 때 템플릿을 envsubst로 처리해 `/etc/nginx/conf.d/default.conf`를 만드는데, 이때 **컨테이너에 실제로 있는 환경 변수 이름**(`APP_ENV`)만 값으로 바뀝니다. `$hostname`·`$uri`는 같은 이름의 환경 변수가 없어서 그대로 남았다가, 요청을 처리할 때 nginx가 채웁니다 |
| (5) | 콘텐츠 교체 | `COPY app/ /usr/share/nginx/html/` | 기본 "Welcome to nginx!" 페이지 대신 내 페이지([`app/index.html`](app/index.html))를 웹 루트에 넣습니다 |
| (6) | 포트 문서화 | `EXPOSE 80` | 컨테이너가 80번에서 요청을 받는다는 것을 기록하는 **문서 역할만** 합니다. 포트를 열거나 연결하지 않으며(5.8 ①의 `-p` 없는 컨테이너는 `localhost`로 접속되지 않음), 실제 연결은 `docker run -p`로 합니다 |
| (7) | 헬스체크 | `HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 CMD wget ...` | 10초마다 `/health`를 호출합니다. 단, 시작 후 5초(`--start-period`) 동안은 `--start-interval`(지정하지 않으면 5초) 간격으로 검사하므로 첫 검사는 시작 약 5초 뒤에 돌고, 성공하면 바로 `(healthy)`가 됩니다([5.9](#59-바인드-마운트-반영)의 `web-bind`가 `Up 6 seconds`에 이미 `(healthy)`인 이유). 3초 안에 응답이 없으면 실패 1회로 세고, 시작 후 5초 동안의 실패는 세지 않으며, 3번 연속 실패하면 `unhealthy`로 표시합니다(재시작은 하지 않음). 정상이면 `docker ps`에 `(healthy)`가 붙습니다 |

`HEALTHCHECK` 줄 끝의 `|| exit 1`은 wget이 실패하면 종료 코드를 1로 맞춥니다. Docker는 확인 명령의 종료 코드가 0이면 정상, 1이면 실패로 판정합니다.

**`.dockerignore` — 빌드 컨텍스트에서 뺄 파일**

`docker build` 맨 끝의 `.`은 현재 폴더를 빌드 컨텍스트(Docker에 보내는 빌드 재료)로 쓴다는 뜻입니다. [`.dockerignore`](.dockerignore)에 적은 파일은 컨텍스트에서 빠지므로 `COPY`로도 이미지에 들어갈 수 없습니다. 내용은 다음과 같습니다(07 로그의 `cat .dockerignore` 출력).

```gitignore
# 이미지에 필요 없는 파일은 빌드 컨텍스트에서 뺀다 (빌드가 빨라지고, 불필요한 파일이 이미지에 들어가지 않는다)
.git
.gitignore
.dockerignore
README.md
docs/
logs/

# 비밀 파일은 빌드 컨텍스트(→ 이미지 → 웹 서버)에 절대 넣지 않는다
**/.env
**/.env.*
**/*.pem
**/*.key
**/id_*
```

- 위쪽 6줄: 이미지에 필요 없는 Git 기록(`.git`)·설정 파일·README·스크린샷(`docs/`)·로그(`logs/`)를 빼서 빌드 재료를 가볍게 하고, 이미지에 섞이지 않게 합니다.
- 아래쪽 5줄(비밀 파일 패턴): 환경 변수 파일(`.env`, `.env.*`), 인증서·개인키(`*.pem`, `*.key`), SSH 키(`id_rsa`, `id_ed25519` 같은 `id_*`)입니다. `**/`는 '어느 폴더에 있든'이라는 뜻이라, 실수로 `app/` 안에 넣더라도 빠집니다. 이 이미지는 `app/`을 웹 루트에 복사하므로, 빠지지 않는다면 웹 서버가 그 파일을 그대로 내려줄 수 있습니다.

**① 빌드 재료와 베이스 이미지 원본 확인**

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ ls -la
total 88
drwxr-xr-x 7 timmy518 timmy518  4096 Nov  2 14:49 .
drwxr-xr-x 4 timmy518 timmy518  4096 Nov  2 13:46 ..
-rw-r--r-- 1 timmy518 timmy518   350 Nov  2 14:49 .dockerignore
drwxr-xr-x 8 timmy518 timmy518  4096 Nov  2 14:17 .git
-rw-r--r-- 1 timmy518 timmy518   173 Nov  2 14:49 .gitignore
-rw-r--r-- 1 timmy518 timmy518  1710 Nov  2 14:49 Dockerfile
-rw-r--r-- 1 timmy518 timmy518 47600 Nov  2 14:01 README.md
drwxr-xr-x 2 timmy518 timmy518  4096 Nov  2 14:49 app
drwxr-xr-x 3 timmy518 timmy518  4096 Nov  2 13:40 docs
drwxr-xr-x 2 timmy518 timmy518  4096 Nov  2 14:48 logs
drwxr-xr-x 2 timmy518 timmy518  4096 Nov  2 14:49 nginx
timmy518@AISiLa:~/codyssey/dev-workstation$ find app nginx -type f
app/index.html
nginx/default.conf.template
timmy518@AISiLa:~/codyssey/dev-workstation$ cat Dockerfile  # 출력은 위 Dockerfile과 같음
...
timmy518@AISiLa:~/codyssey/dev-workstation$ cat .dockerignore  # 출력은 위 .dockerignore와 같음
...
timmy518@AISiLa:~/codyssey/dev-workstation$ docker run --rm nginx:1.30.6-alpine cat /usr/share/nginx/html/index.html | grep -o "<title>.*</title>"  # 베이스 원본의 기본 페이지
Unable to find image 'nginx:1.30.6-alpine' locally
1.30.6-alpine: Pulling from library/nginx
Digest: sha256:0e52bd054126cdc040b1276c0af347aeb02a41b9cfe305d6094767ac30e97949
Status: Downloaded newer image for nginx:1.30.6-alpine
<title>Welcome to nginx!</title>
```

**확인 포인트**

- 빌드 재료는 `Dockerfile`, `app/index.html`, `nginx/default.conf.template`입니다.
- 베이스 이미지 원본의 기본 페이지 제목은 `Welcome to nginx!`입니다(④에서 비교).
- `Unable to find image 'nginx:1.30.6-alpine' locally`: 이 태그가 로컬에 없어서 Docker Hub에서 받았습니다. 레이어를 받는 줄 없이 끝난 것은 5.5에서 받은 `nginx:stable-alpine`과 digest(`sha256:0e52bd05…`)가 같아서 내용이 이미 있었기 때문입니다. 그 시점에 두 태그가 같은 이미지를 가리킨 것으로, '태그는 이름표이고 정확한 이미지는 digest로 구별한다'는 (1)의 설명과 맞습니다.

**② 이미지 빌드**

`-t my-web:1.0`으로 이름과 태그를 붙이고, 마지막 `.`(현재 폴더)을 빌드 컨텍스트로 썼습니다. `--progress=plain`은 단계별 출력을 그대로 보여 줍니다.

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ docker build --progress=plain -t my-web:1.0 .
#0 building with "default" instance using docker driver
...
#3 [internal] load .dockerignore
#3 transferring context: 392B done
#3 DONE 0.0s
...
#5 [1/3] FROM docker.io/library/nginx:1.30.6-alpine@sha256:0e52bd054126cdc040b1276c0af347aeb02a41b9cfe305d6094767ac30e97949
...
#5 DONE 0.6s

#6 [2/3] COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
#6 DONE 0.1s

#7 [3/3] COPY app/ /usr/share/nginx/html/
#7 DONE 0.0s

#8 exporting to image
...
#8 exporting manifest list sha256:87679365b5c6822b3029d48ef3606ca2c558350c6482ab36c82d0809d2558075 0.0s done
#8 naming to docker.io/library/my-web:1.0 done
#8 unpacking to docker.io/library/my-web:1.0 0.0s done
#8 DONE 0.3s
timmy518@AISiLa:~/codyssey/dev-workstation$ docker images my-web
IMAGE        ID             DISK USAGE   CONTENT SIZE   EXTRA
my-web:1.0   87679365b5c6       92.7MB         26.1MB        
```

**확인 포인트**

- `#3 [internal] load .dockerignore`: 빌드가 `.dockerignore`를 읽어 적용했습니다.
- `#5 [1/3] FROM ...nginx:1.30.6-alpine@sha256:0e52bd05…`: 태그가 digest로 풀려, 정확히 그 이미지가 베이스로 쓰였습니다.
- 빌드 단계는 `[1/3] FROM`, `[2/3] COPY`(설정 템플릿), `[3/3] COPY`(웹 페이지) 세 개뿐입니다. 파일을 바꾸지 않는 `LABEL`·`ENV`·`EXPOSE`·`HEALTHCHECK`는 단계로 나오지 않고 이미지 설정(메타데이터)에만 기록됩니다(③에서 확인).
- `naming to docker.io/library/my-web:1.0`: 이미지 이름은 `-t my-web:1.0`으로 붙었습니다.
- `docker images`의 ID `87679365b5c6`이 빌드 출력의 `exporting manifest list sha256:87679365b5c6…`과 같아서, 방금 빌드한 이미지임을 알 수 있습니다.

**③ 커스텀 포인트가 이미지에 들어갔는지 확인 (`docker image inspect`, `docker history`)**

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ docker image inspect my-web:1.0 --format '{{json .Config.Labels}}'
{"maintainer":"NGINX Docker Maintainers <docker-maint@nginx.com>","org.opencontainers.image.authors":"timmy518","org.opencontainers.image.description":"Codyssey pre-course: custom NGINX image (static site + /health + /info)","org.opencontainers.image.title":"dev-workstation-web"}
timmy518@AISiLa:~/codyssey/dev-workstation$ docker image inspect my-web:1.0 --format 'Env: {{json .Config.Env}}'
Env: ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","NGINX_VERSION=1.30.6","PKG_RELEASE=1","DYNPKG_RELEASE=1","NJS_VERSION=1.0.2","NJS_RELEASE=1","ACME_VERSION=0.4.1","APP_ENV=dev"]
timmy518@AISiLa:~/codyssey/dev-workstation$ docker image inspect my-web:1.0 --format 'ExposedPorts: {{json .Config.ExposedPorts}}'
ExposedPorts: {"80/tcp":{}}
timmy518@AISiLa:~/codyssey/dev-workstation$ docker image inspect my-web:1.0 --format 'Healthcheck: {{json .Config.Healthcheck.Test}}'
Healthcheck: ["CMD-SHELL","wget -qO- http://127.0.0.1/health || exit 1"]
timmy518@AISiLa:~/codyssey/dev-workstation$ docker history --format "table {{.CreatedBy}}\t{{.Size}}" my-web:1.0 | head -n 9  # 위쪽이 최신 기록
CREATED BY                                      SIZE
HEALTHCHECK {Test:[CMD-SHELL wget -qO- http:…   0B
EXPOSE [80/tcp]                                 0B
COPY app/ /usr/share/nginx/html/ # buildkit     24.6kB
COPY nginx/default.conf.template /etc/nginx/…   20.5kB
ENV APP_ENV=dev                                 0B
LABEL org.opencontainers.image.title=dev-wor…   0B
RUN /bin/sh -c set -x     && apkArch="$(cat …   51.8MB
ENV ACME_VERSION=0.4.1                          0B
```

**확인 포인트**

| 확인한 값 | 결과 | 확인된 커스텀 포인트 |
|---|---|---|
| `.Config.Labels` | Dockerfile에서 넣은 title·description·authors 3개 + 베이스에서 물려받은 `maintainer` | (2) LABEL |
| `.Config.Env` | 맨 끝에 `APP_ENV=dev` 추가, 베이스에서 물려받은 `NGINX_VERSION=1.30.6` | (3) ENV, (1) 고정한 버전 |
| `.Config.ExposedPorts` | `80/tcp` | (6) EXPOSE |
| `.Config.Healthcheck.Test` | `CMD-SHELL`로 `/health`를 wget으로 호출 | (7) HEALTHCHECK |

- `docker history`는 위쪽이 최신 기록입니다. 크기가 있는 `COPY` 두 줄(24.6kB, 20.5kB)만 파일을 바꾼 새 레이어입니다.
- `0B` 줄(`HEALTHCHECK`·`EXPOSE`·`ENV`·`LABEL`)은 이미지 설정(메타데이터)만 바꾼 기록이라 새 레이어를 만들지 않았습니다.
- `RUN` 줄(51.8MB)부터 아래는 베이스 이미지(nginx)의 기록입니다(`head -n 9`로 앞부분만 표시).

**④ 결과 비교 — 기본 페이지가 내 페이지로 교체됨**

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ docker run --rm my-web:1.0 cat /usr/share/nginx/html/index.html | grep -o "<title>.*</title>"
<title>Dev Workstation</title>
```

**확인 포인트**

- 같은 경로(`/usr/share/nginx/html/index.html`)의 제목이 ①의 `Welcome to nginx!`에서 `Dev Workstation`으로 바뀌었습니다. (5) `COPY app/`로 정적 콘텐츠가 교체된 것입니다. (`--rm`: 확인용 컨테이너를 끝나자마자 삭제)

전체 로그: [`logs/07_build.log`](logs/07_build.log)

**실행 결과**: ④의 `docker run --rm ... cat`은 확인용으로 `cat`만 실행하고 끝납니다. 이 이미지로 웹 서버 컨테이너를 띄워(`docker run -d --name web-8080 -p 8080:80 my-web:1.0`) `(healthy)` 상태와 HTTP 200을 확인한 기록은 [5.8](#58-포트-매핑과-접속-증거)과 [`logs/08_ports.log`](logs/08_ports.log)에 있습니다.

### 5.8 포트 매핑과 접속 증거

5.7에서 만든 `my-web:1.0`으로 웹 서버 컨테이너를 띄워 **포트 매핑(`-p`)이 없을 때와 있을 때**를 비교하고, Ubuntu의 `curl`·Windows PowerShell·Windows 브라우저에서 접속을 확인했습니다. 이 절에서 '호스트'는 Docker Engine이 설치된 WSL Ubuntu를 말합니다. 명령은 저장소 폴더(`~/codyssey/dev-workstation`)에서 실행했습니다.

**① 포트 매핑 없이 실행 — `localhost`로는 닿지 않음**

`-p` 없이 컨테이너를 띄운 뒤 호스트의 `localhost`, 컨테이너 안, 컨테이너의 내부 IP 세 곳에서 접속해 봤습니다.

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ docker run -d --name web-noport my-web:1.0
761bdf2c30eec1495656bbd98ba13b9435ef51c366e859632409928d88d53503
timmy518@AISiLa:~/codyssey/dev-workstation$ docker ps --filter name=web-noport --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
NAMES        STATUS                                     PORTS
web-noport   Up Less than a second (health: starting)   80/tcp
timmy518@AISiLa:~/codyssey/dev-workstation$ curl -sS --max-time 3 http://localhost:80  # 호스트의 localhost:80
curl: (7) Failed to connect to localhost port 80 after 0 ms: Couldn't connect to server
[exit code: 7]
timmy518@AISiLa:~/codyssey/dev-workstation$ docker exec web-noport wget -qO- http://127.0.0.1/health  # 컨테이너 안에서
ok
timmy518@AISiLa:~/codyssey/dev-workstation$ docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web-noport  # 컨테이너의 내부 IP
172.17.0.2
timmy518@AISiLa:~/codyssey/dev-workstation$ curl -sS --max-time 3 http://$(docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" web-noport)/health  # Ubuntu에서 내부 IP로
ok
timmy518@AISiLa:~/codyssey/dev-workstation$ docker rm -f web-noport
web-noport
```

**확인 포인트**

- `docker ps`의 PORTS가 `80/tcp`뿐입니다. Dockerfile의 `EXPOSE 80` 표시일 뿐이고, 호스트 포트와 연결된 것(`0.0.0.0:…->80/tcp`)은 없습니다.
- 호스트의 `localhost:80`은 `curl: (7)`(exit 7)로 연결에 실패합니다. 호스트 자신의 80번 포트에는 듣고 있는 프로그램이 없기 때문입니다.
- 컨테이너 안에서는 `/health`가 `ok`입니다. 웹 서버는 정상이고, 밖에서 들어갈 길이 없을 뿐입니다.
- 컨테이너는 Docker 내부 네트워크(bridge)에서 `172.17.0.2`를 받았고, 리눅스 호스트인 Ubuntu 안에서는 이 IP로 직접 요청하면 `ok`가 돌아옵니다.

> **`-p`가 없으면** 컨테이너에 닿는 길은 리눅스 호스트(WSL Ubuntu) 안의 Docker 브리지 네트워크뿐입니다. 호스트 자신과 같은 네트워크의 다른 컨테이너만 내부 IP(`172.17.0.x`)로 접속할 수 있습니다. `localhost`로는 닿지 않고, 내부 IP는 리눅스 호스트 안에서만 쓰는 주소라서 Windows 브라우저나 다른 PC에서는 갈 길이 없습니다. 그래서 바깥에서 접속하려면 `-p <호스트포트>:<컨테이너포트>`로 호스트 포트를 컨테이너 포트에 연결해야 합니다.

**② `-p`로 실행 — 같은 이미지로 컨테이너 2개, 호스트 포트만 다르게**

`web-8080`은 기본값 그대로, `web-8081`은 `-e APP_ENV=prod`로 환경 변수만 바꿔 실행했습니다. 헬스체크가 돌도록(시작 약 5초 뒤 첫 검사, 이후 10초 간격) 15초 기다린 뒤 상태를 확인했습니다.

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ docker run -d --name web-8080 -p 8080:80 my-web:1.0
5a2248b15e0e76760e5e6292feb15473cf891c86d54f35c867ad3c4d07fc8275
timmy518@AISiLa:~/codyssey/dev-workstation$ docker run -d --name web-8081 -p 8081:80 -e APP_ENV=prod my-web:1.0
00466df6b603d3e452f76be91daffe19f4dba2b87125019326008988db225ee4
timmy518@AISiLa:~/codyssey/dev-workstation$ docker ps --filter name=web-808 --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"  # 15초 뒤
NAMES      IMAGE        STATUS                    PORTS
web-8081   my-web:1.0   Up 15 seconds (healthy)   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp
web-8080   my-web:1.0   Up 15 seconds (healthy)   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
timmy518@AISiLa:~/codyssey/dev-workstation$ docker port web-8080
80/tcp -> 0.0.0.0:8080
80/tcp -> [::]:8080
timmy518@AISiLa:~/codyssey/dev-workstation$ docker port web-8081
80/tcp -> 0.0.0.0:8081
80/tcp -> [::]:8081
```

**확인 포인트**

- STATUS `(healthy)`: Dockerfile의 `HEALTHCHECK`(컨테이너 안에서 `/health` 호출)를 통과했습니다. 같은 이미지의 컨테이너는 ①의 `web-noport`처럼 시작 직후에는 `(health: starting)`으로 표시되고, ②의 두 컨테이너는 15초 뒤 `(healthy)`였습니다. 5.7의 이미지가 웹 서버로 정상 실행된다는 증거입니다.
- PORTS `0.0.0.0:8080->80/tcp`: 호스트의 모든 IPv4 주소(`0.0.0.0`) 8080번으로 들어온 요청을 컨테이너의 80번으로 넘긴다는 뜻입니다. `[::]:8080`은 같은 규칙의 IPv6 쪽이고, `docker port`도 같은 연결을 보여 줍니다.
- 두 컨테이너 모두 안쪽 포트는 80이고 호스트 포트만 8080/8081로 다릅니다. 호스트 포트 하나는 컨테이너 하나만 쓸 수 있기 때문입니다(⑤에서 재현).

**③ Ubuntu에서 접속 확인 (curl)**

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ curl -sS http://localhost:8080 | grep -E "<title>|<h1>"
  <title>Dev Workstation</title>
    <h1>개발자 작업실이 열렸습니다</h1>
timmy518@AISiLa:~/codyssey/dev-workstation$ curl -sS -i http://localhost:8080/health  # -i: 응답 헤더도 출력
HTTP/1.1 200 OK
Server: nginx/1.30.6
Date: Mon, 02 Nov 2026 05:50:19 GMT
Content-Type: text/plain
Content-Length: 3
Connection: keep-alive
X-Served-By: 5a2248b15e0e
X-App-Env: dev

ok
timmy518@AISiLa:~/codyssey/dev-workstation$ curl -sS http://localhost:8080/info
{"app":"dev-workstation","version":"1.0","env":"dev","served_by":"5a2248b15e0e"}
timmy518@AISiLa:~/codyssey/dev-workstation$ curl -sS http://localhost:8081/info
{"app":"dev-workstation","version":"1.0","env":"prod","served_by":"00466df6b603"}
timmy518@AISiLa:~/codyssey/dev-workstation$ curl -sS -o /dev/null -w "8080 -> HTTP %{http_code}\n" http://localhost:8080 && curl -sS -o /dev/null -w "8081 -> HTTP %{http_code}\n" http://localhost:8081
8080 -> HTTP 200
8081 -> HTTP 200
```

**확인 포인트**

- `<title>`·`<h1>`이 내 페이지([`app/index.html`](app/index.html))의 내용입니다. 기본 "Welcome to nginx!" 페이지가 아니라 커스텀 이미지의 페이지가 응답했습니다.
- `curl -i`의 `HTTP/1.1 200 OK` 아래에 nginx 설정([`nginx/default.conf.template`](nginx/default.conf.template))에서 추가한 헤더 두 개가 보입니다. `X-Served-By`는 응답한 컨테이너의 hostname(= 컨테이너 ID 앞 12자리), `X-App-Env`는 환경 변수 `APP_ENV`의 값입니다.
- `/info`의 `served_by`는 8080이 `5a2248b15e0e`, 8081이 `00466df6b603`으로, ②에서 `docker run`이 출력한 두 컨테이너 ID의 앞 12자리와 같습니다.
- 마지막 명령으로 두 포트 모두 `HTTP 200`인 것을 확인했습니다.

**④ 운영 확인 — 접근 로그와 리소스 사용량**

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ docker logs --tail 4 web-8080  # /health 요청은 access_log off 라서 기록되지 않음
2026/11/02 05:50:03 [notice] 1#1: start worker process 47
172.17.0.1 - - [02/Nov/2026:05:50:19 +0000] "GET / HTTP/1.1" 200 2022 "-" "curl/8.5.0" "-"
172.17.0.1 - - [02/Nov/2026:05:50:19 +0000] "GET /info HTTP/1.1" 200 81 "-" "curl/8.5.0" "-"
172.17.0.1 - - [02/Nov/2026:05:50:19 +0000] "GET / HTTP/1.1" 200 2022 "-" "curl/8.5.0" "-"
timmy518@AISiLa:~/codyssey/dev-workstation$ docker stats --no-stream web-8080 web-8081
CONTAINER ID   NAME       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O     PIDS
5a2248b15e0e   web-8080   0.00%     12.28MiB / 7.602GiB   0.16%     3.15kB / 6.47kB   0B / 16.4kB   13
00466df6b603   web-8081   0.00%     11.31MiB / 7.602GiB   0.15%     1.97kB / 3.36kB   0B / 12.3kB   13
```

**확인 포인트**

- 접근 로그에 ③에서 web-8080으로 보낸 요청이 남았습니다. `GET /` 두 줄은 제목 확인과 HTTP 200 확인 요청이고, 가운데 줄이 `/info` 요청입니다. `curl -i …/health`가 없는 것은 nginx 설정에서 `/health`에 `access_log off`를 걸어 두었기 때문입니다(10초마다 도는 헬스체크가 로그를 채우지 않게 하려는 설정).
- 요청한 쪽 주소 `172.17.0.1`은 Docker 브리지 네트워크의 호스트 쪽(게이트웨이) 주소입니다. 호스트의 8080번으로 들어온 요청을 Docker가 브리지 네트워크를 거쳐 컨테이너에 넘겨준 것입니다. 로그 시각은 UTC입니다(05:50 UTC = 한국 시각 14:50).
- `docker stats`: 두 컨테이너 모두 CPU 0.00%, 메모리 약 11~12MiB(한도 7.602GiB)로 실행 중입니다.

**⑤ 포트 충돌 재현 — 이미 쓰는 호스트 포트로 하나 더 실행**

`web-8080`이 8080을 쓰고 있는 상태에서 같은 호스트 포트로 컨테이너를 하나 더 띄웠습니다. 원인 가설과 해결은 [트러블슈팅 7-4](#7-4-포트-충돌-의도적으로-재현)에 정리했습니다.

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ docker run -d --name web-conflict -p 8080:80 my-web:1.0  # 8080은 web-8080이 사용 중
2d4553e95e9844fe223d1063da633d2ed37acc6eaa80b493b03895d5baf26878
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint web-conflict (7a419e9d649b9a6edfce8ec772f95d5df211167167194c716d895f2f622f7138): Bind for 0.0.0.0:8080 failed: port is already allocated

Run 'docker run --help' for more information
[exit code: 125]
timmy518@AISiLa:~/codyssey/dev-workstation$ docker ps -a --filter name=web-conflict --format "table {{.Names}}\t{{.Status}}"
NAMES          STATUS
web-conflict   Created
timmy518@AISiLa:~/codyssey/dev-workstation$ docker rm web-conflict
web-conflict
```

**확인 포인트**

- `Bind for 0.0.0.0:8080 failed: port is already allocated`, exit 125(docker run 실패): 호스트의 8080번은 이미 web-8080에 연결되어 있어서 다른 컨테이너에 또 연결할 수 없습니다.
- 컨테이너는 만들어졌지만(ID 출력) 네트워크 연결 단계에서 실패해 시작되지 못했고, `Created` 상태로 남았습니다. 그래서 `docker rm`으로 지웠습니다.

**⑥ Windows에서 접속 (PowerShell)**

Windows PowerShell에서 같은 주소로 접속했습니다. Windows PowerShell 5.1의 `curl`은 `Invoke-WebRequest`의 별칭이라 curl 프로그램인 `curl.exe`를 썼습니다. 이 두 줄도 `logs/08_ports.log` 끝에 `PS>` 프롬프트로 기록했습니다.

```powershell
PS> curl.exe -s -o NUL -w "Windows -> localhost:8080 HTTP %{http_code}\n" http://localhost:8080
Windows -> localhost:8080 HTTP 200
PS> curl.exe -s http://localhost:8081/info
{"app":"dev-workstation","version":"1.0","env":"prod","served_by":"00466df6b603"}
```

**확인 포인트**

- Windows의 `localhost:8080`이 HTTP 200이고, `localhost:8081/info`에는 Ubuntu에서 본 것과 같은 컨테이너(`served_by` `00466df6b603`)가 응답했습니다.
- 이 PC의 WSL2는 NAT 모드입니다(`wslinfo --networking-mode` → `nat`, [`logs/00_environment.log`](logs/00_environment.log)). NAT 모드의 WSL2는 Ubuntu 안에서 열린 포트를 Windows의 `localhost`로 전달합니다(localhost 전달, `localhostForwarding`). 그래서 요청이 아래 순서로 컨테이너까지 갑니다.

```text
Windows(PowerShell·Edge) → localhost:8080 → [WSL2 localhost 전달] → Ubuntu 0.0.0.0:8080 → [docker -p 8080:80] → web-8080 컨테이너의 80번
```

**정리**

| 컨테이너 | 실행 옵션 | 포트 연결 (호스트 → 컨테이너) | `env` | `served_by` (컨테이너 ID 앞 12자리) |
|---|---|---|---|---|
| `web-8080` | `-p 8080:80` | `0.0.0.0:8080` → `80` | `dev` (Dockerfile 기본값) | `5a2248b15e0e` |
| `web-8081` | `-p 8081:80 -e APP_ENV=prod` | `0.0.0.0:8081` → `80` | `prod` | `00466df6b603` |

- `served_by`가 서로 다름 → **하나의 이미지(`my-web:1.0`)로 만든 서로 다른 컨테이너 두 개**가 각각 응답했습니다.
- `env`가 `dev` / `prod`로 다름 → 이미지를 다시 빌드하지 않고 **실행할 때 넣은 환경 변수(`-e APP_ENV=prod`)만으로 동작을 바꿨습니다.** `dev`는 Dockerfile의 `ENV APP_ENV=dev` 기본값입니다.
- Windows의 `localhost`로도 컨테이너에 닿습니다. WSL2(NAT 모드)의 localhost 전달 덕분이며, 증거는 ⑥의 `PS>` 출력과 아래 브라우저 캡처 2장입니다.

**브라우저 접속 화면** — Windows의 Edge InPrivate 창에서 주소창과 응답이 함께 보이도록 캡처했습니다.

주소창 `localhost:8080` — 커스텀 페이지 "개발자 작업실이 열렸습니다"가 열린 화면

![localhost:8080 접속 화면](docs/images/08_port_8080.png)

주소창 `localhost:8081/info` — `"env":"prod"`, `"served_by":"00466df6b603"`(web-8081) JSON 응답

![localhost:8081/info 접속 화면](docs/images/08_port_8081_info.png)

전체 로그: [`logs/08_ports.log`](logs/08_ports.log)

### 5.9 바인드 마운트 반영

호스트(Ubuntu)의 폴더 `~/codyssey/practice/bind-site`를 컨테이너의 웹 루트 `/usr/share/nginx/html`에 바인드 마운트(`-v 호스트경로:컨테이너경로`)로 연결했습니다. 그다음 호스트에서 파일만 고치고, 컨테이너를 다시 만들거나 이미지를 다시 빌드하지 않은 채 응답이 바뀌는지 확인했습니다. 이미지는 5.7의 `my-web:1.0`, 호스트 포트는 8082를 썼습니다.

```bash
timmy518@AISiLa:~/codyssey/practice$ mkdir bind-site
timmy518@AISiLa:~/codyssey/practice$ printf '<h1>Bind Mount v1</h1>\n<p>host file: ~/codyssey/practice/bind-site/index.html</p>\n' > bind-site/index.html
timmy518@AISiLa:~/codyssey/practice$ cat bind-site/index.html
<h1>Bind Mount v1</h1>
<p>host file: ~/codyssey/practice/bind-site/index.html</p>
timmy518@AISiLa:~/codyssey/practice$ docker run -d --name web-bind -p 8082:80 -v "$PWD/bind-site":/usr/share/nginx/html my-web:1.0
0914cd9b49d88177ecafb3ff7d25ac0bf75a4a8ba3d1a2439e875e60e5617f66
timmy518@AISiLa:~/codyssey/practice$ docker inspect web-bind --format '{{range .Mounts}}{{.Type}}: {{.Source}} -> {{.Destination}}{{end}}'
bind: /home/timmy518/codyssey/practice/bind-site -> /usr/share/nginx/html

# [변경 전] 접속 결과
timmy518@AISiLa:~/codyssey/practice$ curl -sS http://localhost:8082
<h1>Bind Mount v1</h1>
<p>host file: ~/codyssey/practice/bind-site/index.html</p>

# 호스트에서 파일 수정 (컨테이너 재시작·재빌드 없음)
timmy518@AISiLa:~/codyssey/practice$ sed -i 's/v1/v2 (edited on host)/' bind-site/index.html
timmy518@AISiLa:~/codyssey/practice$ cat bind-site/index.html
<h1>Bind Mount v2 (edited on host)</h1>
<p>host file: ~/codyssey/practice/bind-site/index.html</p>

# [변경 후] 접속 결과 — 바로 v2 가 보인다
timmy518@AISiLa:~/codyssey/practice$ curl -sS http://localhost:8082
<h1>Bind Mount v2 (edited on host)</h1>
<p>host file: ~/codyssey/practice/bind-site/index.html</p>
timmy518@AISiLa:~/codyssey/practice$ docker exec web-bind cat /usr/share/nginx/html/index.html
<h1>Bind Mount v2 (edited on host)</h1>
<p>host file: ~/codyssey/practice/bind-site/index.html</p>

# 컨테이너는 그동안 재시작되지 않았다 (STATUS 의 Up 시간이 계속 이어짐)
timmy518@AISiLa:~/codyssey/practice$ docker ps --filter name=web-bind --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
NAMES      STATUS                   PORTS
web-bind   Up 6 seconds (healthy)   0.0.0.0:8082->80/tcp, [::]:8082->80/tcp

# 비교: 바인드 마운트가 없는 web-8080 은 이미지 안에 복사된(COPY) 파일을 쓰므로 영향이 없다
timmy518@AISiLa:~/codyssey/practice$ curl -sS http://localhost:8080 | grep -o "<h1>.*</h1>"
<h1>개발자 작업실이 열렸습니다</h1>
```

**확인 포인트**

| 비교 | 변경 전 | 변경 후 (호스트에서 `sed`로 수정) |
|---|---|---|
| 호스트 파일 (`cat bind-site/index.html`) | `Bind Mount v1` | `Bind Mount v2 (edited on host)` |
| 접속 결과 (`curl http://localhost:8082`, 브라우저) | `Bind Mount v1` | `Bind Mount v2 (edited on host)` |
| 컨테이너 `web-bind` | 실행 중 | 같은 컨테이너가 계속 실행 중 (`Up 6 seconds`) |

- `docker inspect`의 Mounts가 `bind: /home/timmy518/codyssey/practice/bind-site -> /usr/share/nginx/html`입니다. 종류가 `bind`이고 호스트 폴더가 컨테이너의 웹 루트 자리에 연결됐습니다. 그래서 이 컨테이너에서는 이미지에 COPY해 둔 원래 페이지(`app/`) 대신 `bind-site`의 파일이 보입니다.
- 호스트에서 `sed`로 파일만 고쳤는데 다음 `curl`이 바로 v2를 돌려줬습니다. `docker exec`로 본 컨테이너 안의 파일도 v2입니다. 컨테이너가 복사본이 아니라 호스트의 같은 파일을 보고 있다는 뜻입니다.
- `docker ps`의 `Up 6 seconds`는 `docker run` 때부터 이어진 실행 시간입니다. 그사이 `docker restart`·`docker run`·`docker build`를 하지 않았으므로 재시작·재빌드 없이 반영된 것입니다. 웹 루트를 통째로 바꿨는데도 `(healthy)`인 것은 `/health`가 파일이 아니라 nginx 설정(`return 200`)으로 응답하기 때문입니다.
- 마운트가 없는 `web-8080`은 그대로 "개발자 작업실이 열렸습니다"입니다. 바인드 마운트는 그 컨테이너에만 영향을 주고, 다른 컨테이너는 이미지에 COPY된 파일을 그대로 씁니다.
- 따라 할 때: `-v "$PWD/bind-site":…`는 현재 폴더(`$PWD`) 기준이라 다른 PC에서도 그대로 쓸 수 있습니다. 볼륨과의 차이는 [5.10](#510-docker-볼륨-영속성)에서 비교합니다.

**브라우저 화면** — Windows의 Edge InPrivate 창에서 같은 주소를 변경 전/후로 캡처했습니다.

주소창 `localhost:8082` — 변경 전: `Bind Mount v1`

![바인드 마운트 변경 전 (localhost:8082)](docs/images/09_bind_before.png)

주소창 `localhost:8082` — 변경 후: 컨테이너는 그대로 두고 호스트 파일만 고친 결과 `Bind Mount v2 (edited on host)`

![바인드 마운트 변경 후 (localhost:8082)](docs/images/09_bind_after.png)

전체 로그: [`logs/09_bind_mount.log`](logs/09_bind_mount.log)

### 5.10 Docker 볼륨 영속성

이름 있는 볼륨(named volume) `web-data`를 만들어 컨테이너의 `/data`에 연결하고 파일을 쓴 다음, 컨테이너를 지우고 새 컨테이너에 같은 볼륨을 연결해 데이터가 남아 있는지 확인했습니다. 비교를 위해 볼륨 없이 컨테이너 안에만 쓴 데이터가 어떻게 되는지도 `docker diff`로 확인했습니다.

**① 생성 → 연결 → 쓰기 → 컨테이너 삭제 전/후 → 새 컨테이너에서 확인**

```bash
# 1) 볼륨 생성 / 목록 / 상세 정보 (Mountpoint = Docker 가 관리하는 실제 저장 위치)
timmy518@AISiLa:~$ docker volume create web-data
web-data
timmy518@AISiLa:~$ docker volume ls
DRIVER    VOLUME NAME
local     web-data
timmy518@AISiLa:~$ docker volume inspect web-data
[
    {
        "CreatedAt": "2026-11-02T14:50:51+09:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/web-data/_data",
        "Name": "web-data",
        "Options": null,
        "Scope": "local"
    }
]

# 2) 볼륨을 /data 에 연결한 컨테이너에서 데이터 쓰기
timmy518@AISiLa:~$ docker run -d --name vol-writer -v web-data:/data ubuntu:24.04 sleep infinity
c272558aef411459b627ad3c9c732eb328c852e3647eac4e4a5777e4481fcb64
timmy518@AISiLa:~$ docker exec vol-writer sh -c 'echo "written by vol-writer at $(date +%F_%T)" > /data/note.txt && cat /data/note.txt'
written by vol-writer at 2026-11-02_05:50:51

# 3) 컨테이너 삭제 전/후 비교 — 컨테이너는 사라져도 볼륨은 남아 있다
timmy518@AISiLa:~$ docker ps -a --filter name=vol- --format "table {{.Names}}\t{{.Status}}\t{{.Mounts}}"  # [삭제 전]
NAMES        STATUS                  MOUNTS
vol-writer   Up Less than a second   web-data
timmy518@AISiLa:~$ docker rm -f vol-writer
vol-writer
timmy518@AISiLa:~$ docker ps -a --filter name=vol- --format "table {{.Names}}\t{{.Status}}\t{{.Mounts}}"  # [삭제 후]
NAMES     STATUS    MOUNTS
timmy518@AISiLa:~$ docker volume ls
DRIVER    VOLUME NAME
local     web-data

# 4) 새 컨테이너에 같은 볼륨을 연결 → 이전 컨테이너가 쓴 데이터가 그대로 있다
timmy518@AISiLa:~$ docker run -d --name vol-reader -v web-data:/data ubuntu:24.04 sleep infinity
edb1c5c803f3bcb4907328eacc2b70b1b9aaf826bb9f1235700ec776dbea5ae3
timmy518@AISiLa:~$ docker exec vol-reader cat /data/note.txt
written by vol-writer at 2026-11-02_05:50:51
timmy518@AISiLa:~$ docker exec vol-reader sh -c 'echo "appended by vol-reader" >> /data/note.txt && cat /data/note.txt'
written by vol-writer at 2026-11-02_05:50:51
appended by vol-reader
timmy518@AISiLa:~$ docker rm -f vol-reader
vol-reader
```

**확인 포인트**

- `docker volume inspect`의 `Mountpoint`(`/var/lib/docker/volumes/web-data/_data`)가 볼륨 데이터가 실제로 저장되는 곳입니다. 컨테이너 안의 `/data`는 이 폴더를 연결한 경로입니다.
- [삭제 전] `vol-writer`가 `web-data`를 연결한 채 실행 중 → `docker rm -f` → [삭제 후] 컨테이너 목록은 비었지만 `docker volume ls`에는 `web-data`가 그대로 있습니다.
- 새 컨테이너 `vol-reader`에 같은 볼륨을 연결하자, 이미 삭제된 `vol-writer`가 쓴 줄이 그대로 보였고 이어서 쓰기도 됐습니다. 데이터가 컨테이너가 아니라 볼륨에 저장된다는 증거입니다.
- `web-data`는 [00 로그](logs/00_environment.log)의 초기화 단계에서 지운 뒤 다시 만든 빈 볼륨이므로, `note.txt`는 이 실습에서 처음 쓴 파일입니다.
- `note.txt`의 시각 05:50:51은 컨테이너의 기본 시간대(UTC) 기준이라, `CreatedAt`의 14:50:51+09:00(한국 시간)과 같은 순간입니다.

**② 비교 실험 — 볼륨 없이 컨테이너 쓰기 층에만 쓴 데이터**

```bash
# 5) 비교 실험: 볼륨 없이 컨테이너 자신의 쓰기 층(writable layer)에만 쓴 데이터
timmy518@AISiLa:~$ docker run --name no-volume ubuntu:24.04 sh -c 'echo temp-data > /tmp/temp.txt && cat /tmp/temp.txt'
temp-data

#    멈춘(Exited) 컨테이너 안에는 아직 남아 있다 (docker diff: A = 추가된 파일, C = 바뀐 디렉토리)
timmy518@AISiLa:~$ docker diff no-volume
C /tmp
A /tmp/temp.txt

#    새 컨테이너는 이미지에서 빈 쓰기 층으로 시작하므로 보이지 않는다 (컨테이너끼리 공유되지 않음)
timmy518@AISiLa:~$ docker run --rm ubuntu:24.04 cat /tmp/temp.txt  # no-volume을 지우기 전
cat: /tmp/temp.txt: No such file or directory
[exit code: 1]

#    컨테이너를 지우면 그 쓰기 층과 안의 데이터도 함께 삭제된다
timmy518@AISiLa:~$ docker rm no-volume  # 이미 멈춘 컨테이너라 -f 없이 삭제
no-volume
timmy518@AISiLa:~$ docker diff no-volume
Error response from daemon: No such container: no-volume
[exit code: 1]
```

**확인 포인트**

- 볼륨 없이 쓴 파일은 그 컨테이너의 쓰기 층(이미지 위에 컨테이너마다 하나씩 생기는 층)에만 저장됩니다. 프로세스가 끝나 Exited 상태가 돼도 `docker diff`에 `A /tmp/temp.txt`가 남아 있으므로, 컨테이너가 멈추는 것만으로는 데이터가 사라지지 않습니다.
- 하지만 다른 컨테이너와는 공유되지 않습니다. 같은 이미지로 만든 새 컨테이너는 이미지 상태(빈 쓰기 층)에서 시작하므로, `no-volume`을 지우기 **전**인데도 파일이 보이지 않습니다.
- `docker rm`으로 컨테이너를 지우면 쓰기 층도 함께 삭제됩니다(`No such container`). 그 안에 있던 `temp.txt`도 함께 사라집니다.
- 정리: 컨테이너 쓰기 층의 데이터는 다른 컨테이너와 공유되지 않고 `docker rm`과 함께 삭제됩니다. 이름 있는 볼륨은 컨테이너 밖에 있어서 컨테이너를 지워도 남고, 다른 컨테이너에 다시 연결할 수 있습니다(①).

**③ 볼륨 데이터 다시 확인**

```bash
# 6) 볼륨 데이터는 볼륨이 남아 있는 한 언제든 다시 확인할 수 있다
timmy518@AISiLa:~$ docker run --rm -v web-data:/data ubuntu:24.04 ls -l /data
total 4
-rw-r--r-- 1 root root 68 Nov  2 05:50 note.txt
```

**확인 포인트**

- `vol-writer`와 `vol-reader`가 모두 삭제된 뒤에도 `note.txt`가 볼륨에 남아 있습니다. 크기 68바이트는 `vol-writer`가 쓴 줄(줄바꿈 포함 45바이트)과 `vol-reader`가 덧붙인 줄(23바이트)을 합친 값이라, 두 컨테이너가 쓴 내용이 모두 남아 있다는 뜻입니다. 컨테이너 안에서 root로 썼기 때문에 소유자는 `root`입니다.

**바인드 마운트와 볼륨 비교**

| 구분 | 바인드 마운트 ([5.9](#59-바인드-마운트-반영)) | 볼륨 (5.10) |
|---|---|---|
| 데이터 위치 | 내가 고른 호스트 폴더 (`~/codyssey/practice/bind-site`) | Docker가 관리하는 영역 (`/var/lib/docker/volumes/web-data/_data`) |
| 만드는 법 | `-v <호스트 경로>:<컨테이너 경로>` (예: `-v "$PWD/bind-site":/usr/share/nginx/html`) | `docker volume create web-data` 후 `-v web-data:/data` |
| 수명 | 호스트의 일반 폴더라 컨테이너와 상관없이 남음 (지울 때도 호스트에서 직접 삭제) | 컨테이너를 `docker rm` 해도 남음, `docker volume rm web-data`로 지워야 사라짐 |
| 주 용도 | 개발 중 코드·설정을 호스트에서 고쳐 컨테이너에 바로 반영 | DB 파일처럼 컨테이너를 바꾸거나 지워도 남아야 하는 데이터 |

전체 로그: [`logs/10_volume.log`](logs/10_volume.log)

### 5.11 Git 설정과 GitHub / VS Code 연동

Ubuntu(WSL)의 Git에 사용자 정보와 기본 브랜치를 설정하고 `git config --list`로 확인했습니다. 이어서 이 폴더를 Git 저장소로 만들어 첫 커밋을 하고, VS Code(WSL 모드)에서 GitHub에 로그인해 공개 저장소로 게시했습니다. 처음에는 `timmy518/dev-workstation`으로 게시했고, 결과물을 정리한 최종본은 제출용 저장소 [timmy518/Codyssey_E_1-1](https://github.com/timmy518/Codyssey_E_1-1)에 올렸습니다(아래 ③의 5단계).

**① Git 설정과 저장소 만들기**

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ git --version
git version 2.43.0
timmy518@AISiLa:~/codyssey/dev-workstation$ git config --global user.name "timmy518"  # 커밋 작성자 이름
timmy518@AISiLa:~/codyssey/dev-workstation$ git config --global user.email "timmy518@naver.com"  # 커밋 작성자 이메일
timmy518@AISiLa:~/codyssey/dev-workstation$ git config --global init.defaultBranch main  # 새 저장소의 첫 브랜치 이름
timmy518@AISiLa:~/codyssey/dev-workstation$ git config --global core.autocrlf input  # 저장소에 넣을 때 CRLF → LF
timmy518@AISiLa:~/codyssey/dev-workstation$ git config --list
user.name=timmy518
user.email=timmy518@naver.com
init.defaultbranch=main
core.autocrlf=input
timmy518@AISiLa:~/codyssey/dev-workstation$ git config --list --show-origin  # 값이 저장된 파일까지 표시
file:/home/timmy518/.gitconfig	user.name=timmy518
file:/home/timmy518/.gitconfig	user.email=timmy518@naver.com
file:/home/timmy518/.gitconfig	init.defaultbranch=main
file:/home/timmy518/.gitconfig	core.autocrlf=input
timmy518@AISiLa:~/codyssey/dev-workstation$ git init
Initialized empty Git repository in /home/timmy518/codyssey/dev-workstation/.git/
timmy518@AISiLa:~/codyssey/dev-workstation$ git status
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	.dockerignore
	.gitignore
	Dockerfile
	app/
	logs/
	nginx/

nothing added to commit but untracked files present (use "git add" to track)
```

**확인 포인트**

- `git config --list`에 사용자 정보(`user.name`, `user.email`)와 기본 브랜치(`init.defaultbranch=main`)가 보입니다. Git은 설정 키를 소문자로 보여 주므로 `init.defaultBranch`가 `init.defaultbranch`로 나옵니다.
- `user.name`·`user.email`은 **커밋에 기록되는 작성자 정보**입니다. GitHub 로그인 정보(비밀번호·토큰)가 아니며, GitHub 인증은 ③의 VS Code 로그인으로 따로 합니다. 이메일은 공개 저장소의 커밋에서 누구나 볼 수 있습니다([8장](#8-보안개인정보-처리)). 따라 할 때는 두 값을 본인 것으로 바꿉니다.
- `--show-origin`: 네 값 모두 `~/.gitconfig`(이 Ubuntu 사용자의 전역 설정 파일)에 저장됐습니다.
- `init.defaultBranch main`: `git init` 직후 `git status`가 `On branch main`을 보여 줍니다. 첫 브랜치의 **이름**이 `main`으로 정해진 것이고, 브랜치 자체는 첫 커밋 때 만들어집니다(그래서 `No commits yet`이 함께 나옵니다).
- Untracked 목록에 `README.md`와 스크린샷이 없는 것은 이 시점에는 아직 이 폴더에 없었기 때문입니다. 둘 다 그 뒤에 추가했습니다.
- `core.autocrlf input`: 파일을 저장소에 넣을 때(`git add`) Windows 줄바꿈(CRLF)을 리눅스 줄바꿈(LF)으로 바꾸고, 꺼낼 때는 바꾸지 않습니다. Windows와 WSL을 오가며 편집해도 저장소에는 LF로만 들어갑니다.

**첫 커밋 때 실제로 나온 CRLF 경고** — 커밋 명령의 출력은 로그 파일에 없어서, 터미널에 나온 경고 두 줄을 옮겨 적었습니다.

```text
warning: in the working copy of 'logs/03_docker_install.log', CRLF will be replaced by LF the next time Git touches it
warning: in the working copy of 'logs/08_ports.log', CRLF will be replaced by LF the next time Git touches it
```

apt 출력(03 로그)과 `curl -i`로 받은 HTTP 응답 헤더(08 로그)에 CRLF 줄바꿈이 섞여 있었기 때문입니다. `core.autocrlf=input` 설정대로 커밋에는 LF로 저장됐고, 경고는 "작업 폴더의 파일도 Git이 다음에 이 파일을 다시 쓸 때 LF로 바뀐다"는 안내입니다.

**② 설정 범위 확인** — 게시를 마친 뒤 보충으로 실행해서, 저장소(local) 설정에 원격 정보까지 보입니다.

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ git config --show-scope --list
global	user.name=timmy518
global	user.email=timmy518@naver.com
global	init.defaultbranch=main
global	core.autocrlf=input
local	core.repositoryformatversion=0
local	core.filemode=true
local	core.bare=false
local	core.logallrefupdates=true
local	remote.origin.url=https://github.com/timmy518/dev-workstation.git
local	remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
local	branch.main.remote=origin
local	branch.main.merge=refs/heads/main
```

**확인 포인트**

- Git 설정에는 범위가 세 가지 있고, 같은 항목이 여러 곳에 있으면 좁은 범위의 값이 이깁니다: `--system`(`/etc/gitconfig`, 이 리눅스의 모든 사용자) < `--global`(`~/.gitconfig`, 이 사용자의 모든 저장소) < `--local`(`.git/config`, 이 저장소만).
- `global` 4줄은 ①에서 설정한 값입니다. `local`의 `core.*` 4줄은 `git init`이 만든 기본값이고, `remote.origin.*`·`branch.main.*`은 VS Code로 게시할 때 생긴 원격 저장소 정보입니다. `system` 범위 값은 없습니다.
- WSL에서 `--global`은 이 Ubuntu 사용자에게만 적용되고, Windows 쪽 Git 설정(`%USERPROFILE%\.gitconfig`)과는 별개입니다. 그래서 VS Code를 **WSL 모드**로 열어야 Ubuntu의 Git과 이 이름·이메일로 커밋됩니다.
- `credential.helper` 항목이 없습니다. 비밀번호나 토큰을 평문 파일로 저장하는 설정이 없다는 뜻입니다.

**③ GitHub / VS Code 연동 절차**

1. **첫 커밋** — 터미널에서 `git add .` → `git commit -m "<커밋 메시지>"`. 커밋이 하나 이상 있어야 GitHub에 올릴 브랜치(`main`)가 생기므로 게시 전에 꼭 필요합니다. 이 저장소의 첫 커밋은 `f642393`이고, 위의 CRLF 경고가 이때 나왔습니다.
2. **VS Code를 WSL 모드로 열기** — 예: Ubuntu 터미널에서 `code ~/codyssey/dev-workstation` (VS Code에 WSL 확장이 있어야 함). 왼쪽 아래에 `WSL: Ubuntu-24.04`가 보이면 Ubuntu 안의 Git과 `~/.gitconfig`가 쓰입니다.
3. **GitHub 로그인** — **Sign in with GitHub** → 브라우저에서 GitHub 승인(OAuth). 비밀번호는 (필요할 때) 브라우저의 github.com 화면에만 입력하고 VS Code에는 입력하지 않습니다. VS Code는 승인 결과로 받은 접근 토큰(OAuth access token)만 운영체제의 보안 저장소에 보관하므로, 토큰이 저장소 파일에 들어가지 않습니다. 로그인되면 왼쪽 아래 계정 메뉴에 `timmy518 (GitHub)`가 표시됩니다. 로그인 도중 브라우저가 멈춘 문제는 [7-5](#7-5-vs-code의-github-로그인이-브라우저에서-멈춤)에 정리했습니다.
4. **게시** — 소스 제어(Source Control) 패널의 **Publish Branch** → **Publish to GitHub public repository**. VS Code에 `Successfully published the "timmy518/dev-workstation" repository to GitHub.` 알림이 떴습니다.
5. **최종본 게시** — 결과물을 정리한 뒤 처음 만든 저장소(`timmy518/dev-workstation`)는 웹의 Settings → Delete this repository로 지우고, 제출용 공개 저장소 `timmy518/Codyssey_E_1-1`을 GitHub 웹에서 만들었습니다(README 한 개가 든 `Initial commit` 포함). 로컬에서 원격을 `git remote add origin https://github.com/timmy518/Codyssey_E_1-1.git`으로 연결하고, 그 저장소의 `Initial commit` 위에 결과물을 커밋 하나로 얹은 뒤 VS Code의 **Sync Changes**로 올렸습니다. 3단계의 VS Code GitHub 로그인을 그대로 써서 토큰은 입력하지 않았습니다.

**④ 연동 증거**

VS Code 계정 메뉴 — `timmy518 (GitHub)`로 로그인됨, 왼쪽 아래 `WSL: Ubuntu-24.04`(WSL 모드)

![VS Code 계정 메뉴의 GitHub 로그인 상태](docs/images/11_vscode_github_login.png)

VS Code 창 — 제목 `dev-workstation [WSL: Ubuntu-24.04]`, 오른쪽 아래 게시 성공 알림

![VS Code 게시 성공 알림](docs/images/11_vscode_window.png)

게시 직후 터미널 확인 — 로컬 커밋과 GitHub `main` 비교, 원격 주소, 추적 연결, 공개 여부(GitHub API)

```bash
timmy518@AISiLa:~/codyssey/dev-workstation$ git log --oneline --decorate -n 1
f642393 (HEAD -> main, origin/main) Dev workstation 미션: Dockerfile, 웹 페이지, 단계별 실행 로그, README
timmy518@AISiLa:~/codyssey/dev-workstation$ git remote -v
origin	https://github.com/timmy518/dev-workstation.git (fetch)
origin	https://github.com/timmy518/dev-workstation.git (push)
timmy518@AISiLa:~/codyssey/dev-workstation$ git status -sb  # M = 기록 중이던 이 로그 파일
## main...origin/main
 M logs/11_git.log
timmy518@AISiLa:~/codyssey/dev-workstation$ git config --local --get-regexp '^(remote|branch)\.'
remote.origin.url https://github.com/timmy518/dev-workstation.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
branch.main.remote origin
branch.main.merge refs/heads/main
timmy518@AISiLa:~/codyssey/dev-workstation$ git ls-remote --heads origin  # GitHub 쪽 main 브랜치
f642393108977536bd969ccba903bf01a98d7d9c	refs/heads/main
timmy518@AISiLa:~/codyssey/dev-workstation$ curl -s https://api.github.com/repos/timmy518/dev-workstation | grep -E "\"(full_name|visibility|default_branch|html_url)\""
  "full_name": "timmy518/dev-workstation",
    "html_url": "https://github.com/timmy518",
  "html_url": "https://github.com/timmy518/dev-workstation",
  "visibility": "public",
  "default_branch": "main",
```

**확인 포인트**

- `git remote -v`: `origin`이 GitHub 저장소 주소(HTTPS)입니다. 주소에 사용자명이나 토큰이 들어 있지 않습니다.
- `git log`의 `(HEAD -> main, origin/main)`과 `git ls-remote`의 `f642393108977536bd969ccba903bf01a98d7d9c refs/heads/main` → 게시 직후 GitHub의 `main`이 로컬 커밋 `f642393`과 같았습니다. 게시(push)가 성공했다는 뜻입니다.
- `git status -sb`의 `## main...origin/main`과 `branch.main.remote origin`·`branch.main.merge refs/heads/main` → 로컬 `main`이 GitHub의 `main`(`origin/main`)을 추적하도록 연결됐습니다. `[ahead N]`·`[behind N]` 표시가 없으므로 아직 올리지 않은 커밋이 없다는 뜻입니다.
- GitHub API의 `"visibility": "public"`, `"default_branch": "main"` → 공개 저장소이고 기본 브랜치는 `main`입니다.
- 위 로그는 처음 게시한 저장소 `timmy518/dev-workstation`의 기록입니다. 그 저장소는 정리하면서 지웠고, 최종본은 `timmy518/Codyssey_E_1-1`에 새 커밋으로 올렸습니다(위 5단계). 그래서 지금 저장소 주소와 커밋 SHA는 위 로그와 다릅니다.

전체 로그: [`logs/11_git.log`](logs/11_git.log)

## 6. 검증 방법 요약

미션 요구 사항마다 어떤 명령으로 무엇을 확인했는지, 결과가 어디에 있는지를 한 표로 모았습니다. '실제 결과'에 적은 값(컨테이너 ID, 시각, 크기 등)은 링크한 로그에서 그대로 찾을 수 있습니다.

| 항목 | 확인 명령 | 기대 결과 | 실제 결과 | 증거 |
|---|---|---|---|---|
| 실행 환경 | PowerShell: `wsl --version`, `wsl -l -v` / bash: `grep -E … /etc/os-release`, `echo $BASH_VERSION`, `docker --version`, `git --version` | Windows 위 WSL2에서 Ubuntu가 동작하고 도구 버전이 출력됨 | Microsoft Windows 11 Home Single Language(25H2), WSL 3.0.3.0, `Ubuntu-24.04`·`Running`·VERSION `2`(WSL2), Ubuntu 24.04.5 LTS, bash 5.2.21, Docker 29.9.2, Git 2.43.0 | [00](logs/00_environment.log) |
| 숨김 파일 | `ls` / `ls -la` | `ls -la`에서만 `.hidden_config`와 `.`, `..`이 보임 | `ls` → `empty.txt`, `hello.txt`뿐 / `ls -la` → `.hidden_config` 포함 (빈 파일은 `wc -c` → `0 empty.txt`) | [01](logs/01_terminal.log) |
| 파일·디렉토리 조작 | `mkdir`, `cp`, `cp -r`, `mv`(이동·이름 변경), `rm`·`rmdir`·`rm -r` 후 `ls -la`·`cat`·`find . \| sort` / `cd`(절대·상대·`~`) 후 `pwd` | 복사·이동한 것은 목록에 보이고 지운 것은 사라짐, 경로 표기와 상관없이 같은 위치 | `backup_copy/hello_copy.txt` 생김, `docs/greeting.txt` → `Hello, Codyssey!`, 최종 `find` → `./.hidden_config`, `./docs`, `./docs/greeting.txt`만 남음 / 절대 경로·`./docs` 모두 `pwd` → `/home/timmy518/codyssey/practice/docs` | [01](logs/01_terminal.log) |
| 파일 실행 권한 | `stat`, `./hello.sh` (644 → `chmod 755`) | 644에서는 실행 거부, 755에서는 실행 | `Permission denied`(exit 126) → `-rwxr-xr-x (755)` → `hello.sh is running!` | [02](logs/02_permissions.log) |
| 디렉토리 x 권한 | `chmod 644 perm_dir` 후 `cd perm_dir`, `cat perm_dir/inside.txt`, `ls -l perm_dir` | x가 없으면 안으로 들어가기와 안의 파일 읽기가 막힘 | `cd`·`cat` 모두 `Permission denied`(exit 1), `ls -l`은 이름만 보이고 상세 정보는 `?` → 755로 되돌리자 읽기 성공 | [02](logs/02_permissions.log) |
| Docker 데몬 | `docker --version`, `docker version`, `docker info`, `systemctl is-active docker containerd` | Client와 Server(데몬) 정보가 함께 출력되고 서비스가 active | `Docker version 29.9.2`, Server Engine 29.9.2·containerd v2.4.2·runc 1.5.2, `Cgroup Driver: systemd`, `active`·`active` | [04](logs/04_docker_check.log) |
| 운영 명령 | `docker pull`, `images`, `ps`, `ps -a`, `logs`, `stats`, `stop`, `start`, `rm -f` | 이미지 목록, 상태 변화(Up ↔ Exited), 접근 로그, 자원 사용량이 출력됨 | `ubuntu:24.04`·`nginx:stable-alpine` 목록, stop 후 `ps`는 비고 `ps -a`에 `Exited (0)` → start 후 `Up`, logs에 `"GET / HTTP/1.1" 200`, stats `11.35MiB / 7.602GiB` | [05](logs/05_docker_ops.log) |
| hello-world | `docker run hello-world` | 이미지를 자동으로 받아 실행하고, 메시지 출력 후 종료 | 로컬에 없어 자동 pull → `Hello from Docker!` → `docker ps -a`에 `Exited (0)` | [06](logs/06_containers.log) |
| ubuntu 내부 ls/echo | `docker run -it --name ubuntu-shell ubuntu:24.04 bash` 후 `ls`, `echo` | 프롬프트가 `root@<컨테이너ID>`로 바뀌고 명령 결과가 출력됨 | `root@5392105b2b32:/#`에서 루트(`/`) 목록과 `Hello from inside the container` 출력, `exit` 후 `Exited (0)` | [06](logs/06_containers.log) |
| attach/exec | `docker exec -it exec-demo bash`, `docker attach attach-demo`, `echo "my PID is $$"`, `docker ps -a` | exec: PID가 1이 아니고 exit해도 유지 / attach: PID 1, Ctrl+P→Ctrl+Q면 유지, exit하면 종료 | exec: `my PID is 9` → `Up 5 seconds` / attach: `my PID is 1` → detach 후 `Up 10 seconds`, exit 후 `Exited (0)` | [06](logs/06_containers.log) |
| 커스텀 이미지 | `docker build -t my-web:1.0 .`, `docker image inspect`, `docker history`, `docker ps` | 빌드 성공, 라벨·ENV·EXPOSE·헬스체크가 이미지에 들어가고, 실행하면 healthy | `naming to docker.io/library/my-web:1.0 done`, `my-web:1.0` 92.7MB, 페이지 제목 `Welcome to nginx!` → `Dev Workstation`, 실행 후 `Up 15 seconds (healthy)` | [07](logs/07_build.log), [08](logs/08_ports.log) |
| 포트 매핑 없음 | `docker run -d --name web-noport my-web:1.0` 후 `curl http://localhost:80` | 컨테이너는 정상이지만 호스트의 `localhost`로는 접속되지 않음 | `curl: (7) Failed to connect to localhost port 80 …`(exit 7), 컨테이너 안 `wget` → `ok`, 내부 IP `172.17.0.2` → `ok` | [08](logs/08_ports.log) |
| 포트 매핑 8080/8081 | `docker run -d --name web-8080 -p 8080:80 my-web:1.0`, `… --name web-8081 -p 8081:80 …`, `docker port`, `curl`, 브라우저 | 두 호스트 포트가 각 컨테이너의 80번으로 연결되어 HTTP 200 | `0.0.0.0:8080->80/tcp`, `0.0.0.0:8081->80/tcp`, `8080 -> HTTP 200`, `8081 -> HTTP 200`, 응답한 컨테이너 `5a2248b15e0e` / `00466df6b603` | [08](logs/08_ports.log), [8080 화면](docs/images/08_port_8080.png) |
| Windows에서 접속 | PowerShell `curl.exe … http://localhost:8080`, `curl.exe -s http://localhost:8081/info`, Edge 주소창 | Windows 쪽에서도 같은 주소로 응답 | `Windows -> localhost:8080 HTTP 200`, `"env":"prod"`, 주소창에 `localhost:8080`·`localhost:8081/info`가 보이는 화면 | [08](logs/08_ports.log), [8080 화면](docs/images/08_port_8080.png), [8081 화면](docs/images/08_port_8081_info.png) |
| 환경 변수 | 기본값으로 띄운 web-8080과 `-e APP_ENV=prod`로 띄운 web-8081에 `curl …/info` | 다시 빌드하지 않고 실행 옵션만으로 값이 바뀜 | web-8080: `"env":"dev"`(헤더 `X-App-Env: dev`) / web-8081: `"env":"prod"` | [08](logs/08_ports.log), [8081 화면](docs/images/08_port_8081_info.png) |
| 포트 충돌 | web-8080 실행 중에 `docker run -d --name web-conflict -p 8080:80 my-web:1.0` | 실행 실패 | `Bind for 0.0.0.0:8080 failed: port is already allocated`(exit 125), 컨테이너는 `Created`로 남아 `docker rm`으로 삭제 | [08](logs/08_ports.log), [7-4](#7-4-포트-충돌-의도적으로-재현) |
| 바인드 마운트 | `-v "$PWD/bind-site":/usr/share/nginx/html`로 실행 → 호스트에서 `sed -i` → `curl http://localhost:8082` | 재시작·재빌드 없이 바뀐 내용이 바로 보임 | 마운트 타입 `bind`, `Bind Mount v1` → `Bind Mount v2 (edited on host)`, `Up 6 seconds (healthy)`(재시작 없음), 마운트 없는 web-8080은 그대로 | [09](logs/09_bind_mount.log), [변경 전](docs/images/09_bind_before.png) / [변경 후](docs/images/09_bind_after.png) |
| 볼륨 | `docker volume create web-data`, `-v web-data:/data`, `docker rm -f vol-writer` 후 새 컨테이너에서 `cat` | 컨테이너를 지워도 볼륨의 데이터가 남음 | 삭제 후 `docker ps -a`는 비고 `docker volume ls`에 `web-data` → vol-reader에서 `written by vol-writer at 2026-11-02_05:50:51` | [10](logs/10_volume.log) |
| 볼륨 없는 데이터 | `docker diff no-volume`, 새 컨테이너에서 `cat /tmp/temp.txt`, `docker rm` 후 `docker diff` | 컨테이너 자신의 쓰기 층에만 있어 다른 컨테이너와 공유되지 않고, rm하면 함께 사라짐 | `A /tmp/temp.txt` → 새 컨테이너는 `No such file or directory` → rm 후 `No such container: no-volume` | [10](logs/10_volume.log) |
| Git 설정 | `git config --list`, `git config --show-scope --list`, `git init` 후 `git status` | 사용자 정보와 기본 브랜치(main)가 설정됨 | `user.name=timmy518`, `user.email` 설정, `init.defaultbranch=main`, `core.autocrlf=input`(모두 global), `On branch main` | [11](logs/11_git.log) |
| GitHub 연동 | `git remote -v`, `git ls-remote --heads origin`, GitHub API 조회, VS Code 화면 | origin이 GitHub 저장소이고, 원격 main = 로컬 커밋, 공개 저장소 | 첫 게시(`timmy518/dev-workstation`) 때 원격 main `f642393…` = 로컬 `f642393 (HEAD -> main, origin/main)` 일치, `"visibility": "public"`, VS Code 계정 메뉴 `timmy518 (GitHub)`·게시 성공 알림. 최종본은 제출용 저장소 `timmy518/Codyssey_E_1-1`에 올림(origin `https://github.com/timmy518/Codyssey_E_1-1.git`, [13](logs/13_secret_check.log)의 `git remote -v`) | [11](logs/11_git.log), [로그인](docs/images/11_vscode_github_login.png), [게시](docs/images/11_vscode_window.png) |
| drvfs 권한 | `ls -l /mnt/c/Users/Public/drvfs_test.txt`, `cp` 후 `ls -l`, `chmod 644`·`install -m 644` | Windows 드라이브의 파일은 777로 보이고, 복사하면 755, 정리하면 644 | `-rwxrwxrwx` → `-rwxr-xr-x` → `-rw-r--r--` | [12](logs/12_troubleshooting.log), [7-3](#7-3-windows-드라이브에서-가져온-파일에-실행-권한이-붙음) |
| 민감정보 | 비밀값 모양 검색(GitHub 토큰·개인키·AWS 키·계정 정보가 든 URL): README 포함 모든 파일과 커밋 히스토리(`git log -p --all`) / 키워드 검색: 로그·Dockerfile·`nginx/`·`app/`·`.gitignore`·`.dockerignore` / `git remote -v`·`credential.helper` 확인 / PNG 6장의 메타데이터와 화면 확인 | 실제 비밀값 없음 | 모양 검색은 파일·히스토리 모두 0건, 키워드에 걸린 줄은 실습 파일 문구 `secret inside`처럼 단어만 같은 줄뿐, 원격 주소에 토큰 없음·`credential.helper` 없음, PNG에 글자 메타데이터 없음·화면에 토큰·인증 코드 없음 | [13](logs/13_secret_check.log), [8장](#8-보안개인정보-처리) |

확인 포인트: 7-1·7-2·7-5·7-6은 Windows 쪽 화면에서 일어난 일이라 로그 파일이 없습니다(7-6은 원인 재현 실험만 [12](logs/12_troubleshooting.log) 끝에 기록). 그래서 이 표에 넣지 않고, 7장 각 항목의 '증거' 줄에 근거를 따로 적었습니다.

---

## 7. 트러블슈팅

미션 요구(2건 이상)보다 많은 6건을 정리했습니다. 각 항목은 문제 → 원인 가설 → 확인 → 해결/대안 순서이고, 마지막 줄에 증거 위치를 적었습니다. 7-3·7-4는 로그 파일로 확인할 수 있습니다. 7-1·7-2·7-5·7-6은 Windows 쪽 화면에서 일어난 일이라 화면 메시지를 옮겨 적었고, 7-6은 원인을 나중에 같은 조건으로 재현해 [`logs/12_troubleshooting.log`](logs/12_troubleshooting.log) 끝에 기록했습니다.

| # | 문제 | 확인된 원인 | 해결 | 증거 |
|---|---|---|---|---|
| [7-1](#7-1-wsl-설치-명령이-설치를-하지-않음) | `wsl --install`이 설치 대신 안내문만 출력(exit code 1) | 관리자 권한·콘솔 창 없이 실행 (둘 중 결정 요인은 따로 확인하지 않음) | 관리자 PowerShell 새 창에서 다시 실행 | 화면 메시지 |
| [7-2](#7-2-설치-직후-wsl2가-시작되지-않음) | 설치 직후 WSL2가 시작되지 않음 | 기능을 켠 뒤 재부팅 대기 상태(`RebootPending`) | 재부팅 | 화면 메시지 |
| [7-3](#7-3-windows-드라이브에서-가져온-파일에-실행-권한이-붙음) | `/mnt/c`에서 복사한 일반 파일에 x 권한 | drvfs가 모든 파일을 777로 보여 줌 + umask 022 | `chmod 644`, `install -m 644` | [12](logs/12_troubleshooting.log) |
| [7-4](#7-4-포트-충돌-의도적으로-재현) | `port is already allocated` | 호스트 8080 포트를 web-8080이 사용 중 | 다른 호스트 포트 사용, 기존 컨테이너 정리 | [08](logs/08_ports.log) |
| [7-5](#7-5-vs-code의-github-로그인이-브라우저에서-멈춤) | VS Code의 GitHub 로그인이 브라우저에서 멈춤 | 브라우저 → VS Code로 결과가 돌아오지 못함 (세부 원인은 특정하지 않음) | 로그인을 처음부터 다시 시작 | 화면 메시지 (해결 후 상태: [캡처](docs/images/11_vscode_github_login.png)) |
| [7-6](#7-6-powershell에서-wsl로-명령을-넘길-때-변수와-따옴표가-깨짐) | PowerShell → WSL로 넘긴 명령의 따옴표·변수가 깨짐 | PowerShell 5.1의 인자 전달(안쪽 큰따옴표), `wsl --`가 거치는 기본 리눅스 셸이 큰따옴표 안의 `$f`를 먼저 해석 | 명령을 `.sh` 파일로 실행(또는 `wsl -e`, Ubuntu 터미널에서 입력) | 화면 메시지, 원인 재현 [12](logs/12_troubleshooting.log) |

### 7-1. WSL 설치 명령이 설치를 하지 않음

**문제** — 관리자 권한이 없고 콘솔 창도 없는(출력만 받아 오는) PowerShell에서 `wsl --install -d Ubuntu-24.04 --no-launch`를 실행했더니, 설치는 하지 않고 아래 안내만 출력한 뒤 끝났습니다(exit code 1). 설치 명령을 실행했는데 '설치하라'는 안내가 다시 나온 상황입니다.

```text
Linux용 Windows 하위 시스템 설치되어 있지 않습니다. 'wsl.exe --install'을 실행하여 설치할 수 있습니다.
```

**원인 가설** — ① 옵션 문법이 틀림 ② 관리자 권한(UAC 승인)이 필요함 ③ 설치 프로그램이 실제 콘솔 창을 필요로 함

**확인** — `wsl --help`의 옵션 목록에 `--install`이 있어 ①(문법)은 아니었습니다. WSL 설치는 Windows 기능(WSL, 가상 머신 플랫폼)을 켜는 작업이라 관리자 권한이 필요합니다.

**해결/대안** — `Start-Process powershell -Verb RunAs`로 **별도의 관리자 PowerShell 창**을 띄워 같은 명령을 실행하자 exit code 0으로 끝났고, WSL 3.0.3 설치와 가상 머신 플랫폼(VirtualMachinePlatform) 활성화가 완료되었습니다. 새 창은 ②와 ③을 모두 충족하므로, 둘 중 무엇이 결정적이었는지는 따로 나눠 확인하지 않았습니다. 따라 할 때는 처음부터 PowerShell을 '관리자 권한으로 실행'한 창에서 입력하면 됩니다.

**증거** — 로그 파일 없음 — 설치 당시 PowerShell 화면 메시지를 옮겨 적음. 현재 상태는 [`logs/00_environment.log`](logs/00_environment.log)의 `wsl --version`(`WSL 버전: 3.0.3.0`)과 `wsl -l -v`(`Ubuntu-24.04`가 `Running`, VERSION `2`)로 확인할 수 있습니다.

### 7-2. 설치 직후 WSL2가 시작되지 않음

**문제** — WSL 설치 직후 `wsl --status`가 아래 메시지를 출력했고, 이어서 '가상 머신 플랫폼' 구성 요소와 펌웨어(BIOS/UEFI) 가상화를 켜라고 안내했습니다.

```text
가상화가 활성화되지 않은 이 컴퓨터에서는 WSL2를 시작할 수 없습니다.
```

**원인 가설** — ① 펌웨어 설정에서 가상화가 꺼져 있음 ② 가상 머신 플랫폼 기능은 켰지만 재부팅 전이라 아직 적용되지 않음

**확인** — PowerShell에서 세 가지를 확인했습니다.

| 확인 명령 (PowerShell) | 결과 | 해석 |
|---|---|---|
| `(Get-CimInstance Win32_ComputerSystem).HypervisorPresent` | `True` | 하이퍼바이저가 이미 동작 중 → 펌웨어 가상화는 켜져 있음 (①이 아님) |
| `Get-CimInstance Win32_OptionalFeature`로 `VirtualMachinePlatform` 조회 | `InstallState` = `1` (Enabled) | 가상 머신 플랫폼 기능 자체는 켜짐 |
| `Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'` | `True` | 기능 변경을 적용하려면 재부팅이 필요한 상태 (②) |

메시지는 '가상화가 꺼져 있다'고 했지만, 실제로는 켠 기능이 재부팅을 기다리는 상태였습니다.

**해결/대안** — 재부팅하자 해결되었습니다. 이어서 Ubuntu-24.04를 설치했고, 리눅스 사용자 `timmy518`과 비밀번호는 작성자가 직접 만들었습니다. `HypervisorPresent`가 `False`라는 것만으로 펌웨어 가상화가 꺼졌다고 볼 수는 없습니다(가상 머신 플랫폼을 켜고 아직 재부팅하지 않은 PC도 `False`일 수 있음). 재부팅한 뒤에도 WSL2가 시작되지 않으면 작업 관리자 → 성능 → CPU의 '가상화' 항목이나 `(Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled`를 확인하고, 꺼져 있으면 BIOS/UEFI에서 CPU 가상화(Intel VT-x / AMD-V)를 켭니다.

**증거** — 로그 파일 없음 — 설치 당시 PowerShell 화면 메시지를 옮겨 적음. 현재 상태는 [`logs/00_environment.log`](logs/00_environment.log)에서 확인할 수 있습니다(`wsl -l -v`의 VERSION `2`, Ubuntu 쪽 `uname -r` → `6.18.54.1-microsoft-standard-WSL2`).

### 7-3. Windows 드라이브에서 가져온 파일에 실행 권한이 붙음

**문제** — Windows 쪽 폴더에서 만든 프로젝트 파일(`Dockerfile`, `index.html` 등)을 WSL의 리눅스 홈으로 복사하자, 일반 파일인데도 실행 권한(`x`)이 붙어 `-rwxr-xr-x`가 되었습니다. 원래 겪은 복사 장면은 로그가 없어서, 같은 현상을 Windows 공용 폴더(`C:\Users\Public`)의 시험 파일로 다시 재현해 기록했습니다.

**원인 가설** — ① 원본 파일이 정말로 실행 권한을 갖고 있음 ② `/mnt/c`(drvfs)는 기본 설정(`metadata` 옵션 없음)에서 리눅스 권한을 저장하지 않아 모든 파일을 777로 보여 주고, 복사할 때 그 값에 umask 022가 적용되어 755가 됨

**확인**

```bash
# 1) /mnt/c 가 어떻게 연결되어 있는지 확인 (drvfs, metadata 옵션 없음)
timmy518@AISiLa:~$ mount | grep " /mnt/c "
C:\ on /mnt/c type 9p (rw,noatime,aname=drvfs;path=C:\;uid=1000;gid=1000;symlinkroot=/mnt/,cache=0x5,access=client,msize=65536,trans=fd,rfd=19,wfd=19)

# 2) Windows 쪽 공용 폴더에 시험용 파일을 만들고 권한 확인 → 리눅스 권한 정보가 없어 777 로 보인다
timmy518@AISiLa:~$ echo "made on the Windows drive" > /mnt/c/Users/Public/drvfs_test.txt
timmy518@AISiLa:~$ ls -l /mnt/c/Users/Public/drvfs_test.txt
-rwxrwxrwx 1 timmy518 timmy518 26 Nov  2  2026 /mnt/c/Users/Public/drvfs_test.txt

# 3) 리눅스 홈 쪽으로 복사하면 777 에 umask(022)가 적용되어 755 가 된다 → 일반 파일인데 실행 권한(x)이 붙음
timmy518@AISiLa:~$ cp /mnt/c/Users/Public/drvfs_test.txt ~/drvfs_copy_test.txt && ls -l ~/drvfs_copy_test.txt
-rwxr-xr-x 1 timmy518 timmy518 26 Nov  2 14:50 /home/timmy518/drvfs_copy_test.txt
```

확인 포인트: mount 옵션에 `metadata`·`umask`·`fmask`가 없습니다. 방금 `echo`로 만든 파일은 리눅스 파일 시스템이라면 644(umask 022)여야 하는데 `-rwxrwxrwx`로 보이므로, 파일 자체가 아니라 `/mnt/c`가 777로 보여 주는 것입니다(① 아님, ② 확인). 복사본은 777에 umask 022가 적용된 `-rwxr-xr-x`입니다.

**해결/대안** — 복사한 뒤 `chmod 644`로 정리하거나, 처음부터 `install -m 644`로 권한을 정해서 복사합니다.

```bash
# 4) 해결: 복사한 뒤 일반 파일 권한(644)으로 정리하거나, install -m 644 로 권한을 정해서 복사
timmy518@AISiLa:~$ chmod 644 ~/drvfs_copy_test.txt && ls -l ~/drvfs_copy_test.txt
-rw-r--r-- 1 timmy518 timmy518 26 Nov  2 14:50 /home/timmy518/drvfs_copy_test.txt
timmy518@AISiLa:~$ install -m 644 /mnt/c/Users/Public/drvfs_test.txt ~/drvfs_install_test.txt && ls -l ~/drvfs_install_test.txt
-rw-r--r-- 1 timmy518 timmy518 26 Nov  2 14:50 /home/timmy518/drvfs_install_test.txt

# 5) 시험용 파일 정리
timmy518@AISiLa:~$ rm /mnt/c/Users/Public/drvfs_test.txt ~/drvfs_copy_test.txt ~/drvfs_install_test.txt
```

- 이 저장소의 파일도 644(폴더 755)로 정리되어 있습니다. [`logs/07_build.log`](logs/07_build.log)의 `ls -la`에서 파일은 `-rw-r--r--`, 폴더는 `drwxr-xr-x`입니다.
- 파일이 많으면 `find . -type f -exec chmod 644 {} +`와 `find . -type d -exec chmod 755 {} +`로 한 번에 정리할 수 있습니다(실행해야 하는 스크립트는 다시 `chmod 755`).
- 가장 간단한 예방법은 프로젝트를 처음부터 리눅스 홈(`~`)에서 만들고 작업하는 것입니다.
- WSL 설정으로 기본 권한을 바꾸는 방법도 있습니다. 이번에는 적용하지 않았습니다(위 mount 출력에 `metadata`가 없음). `/etc/wsl.conf`를 sudo로 열어 아래 내용을 넣고 PowerShell에서 `wsl --shutdown`을 실행한 뒤 Ubuntu를 다시 열면, 리눅스 권한 정보가 없는 Windows 파일이 644(디렉토리는 755)로 보입니다. `metadata`만 넣으면 앞으로 WSL에서 `chmod`한 값이 저장될 뿐, 이미 있던 Windows 파일은 계속 777로 보입니다.

```ini
[automount]
options = "metadata,umask=22,fmask=111"
```

**증거** — [`logs/12_troubleshooting.log`](logs/12_troubleshooting.log). 다른 PC에서도 `/mnt/c/Users/Public` 아래에 시험 파일을 만들어 같은 결과(`-rwxrwxrwx` → 복사 후 `-rwxr-xr-x`)를 볼 수 있습니다.

### 7-4. 포트 충돌 (의도적으로 재현)

**문제** — web-8080이 호스트 8080 포트를 쓰는 상태에서, 같은 호스트 포트로 컨테이너를 하나 더 띄우면 어떻게 되는지 일부러 재현했습니다.

```bash
# 5) 트러블슈팅 재현: 이미 사용 중인 호스트 포트(8080)로 컨테이너를 하나 더 띄우면?
timmy518@AISiLa:~/codyssey/dev-workstation$ docker run -d --name web-conflict -p 8080:80 my-web:1.0   # web-8080이 8080을 쓰는 중
2d4553e95e9844fe223d1063da633d2ed37acc6eaa80b493b03895d5baf26878
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint web-conflict (7a419e9d649b9a6edfce8ec772f95d5df211167167194c716d895f2f622f7138): Bind for 0.0.0.0:8080 failed: port is already allocated

Run 'docker run --help' for more information
[exit code: 125]
timmy518@AISiLa:~/codyssey/dev-workstation$ docker ps -a --filter name=web-conflict --format "table {{.Names}}\t{{.Status}}"
NAMES          STATUS
web-conflict   Created
timmy518@AISiLa:~/codyssey/dev-workstation$ docker rm web-conflict
web-conflict
```

**원인 가설** — 호스트의 8080 포트를 이미 다른 컨테이너나 다른 프로그램이 쓰고 있음

**확인** — 오류 문구 `Bind for 0.0.0.0:8080 failed: port is already allocated`가 바로 그 뜻입니다. 앞서 `docker port web-8080`이 `80/tcp -> 0.0.0.0:8080`을 보여 줘서, web-8080이 8080을 쓰고 있음을 확인했습니다([5.8](#58-포트-매핑과-접속-증거)).

확인 포인트: 출력 첫 줄에 컨테이너 ID가 찍힌 것은 컨테이너가 먼저 만들어졌다는 뜻입니다. 그 뒤 포트 연결 단계에서 실패해 한 번도 시작하지 못한 `Created` 상태로 남았고, `docker run` 자체가 실패해 exit code 125가 나왔습니다.

**해결/대안**

- 다른 호스트 포트를 씁니다. 같은 이미지라도 호스트 포트만 다르면 되므로, 이 미션의 두 번째 컨테이너는 `-p 8081:80`으로 띄웠습니다.
- 8080을 꼭 써야 하면 그 포트를 쓰는 컨테이너를 정리(`docker stop web-8080` 또는 `docker rm -f web-8080`)한 뒤 다시 실행합니다.
- 실패한 컨테이너는 `Created` 상태로 이름(`web-conflict`)을 계속 차지하므로 `docker rm web-conflict`로 지웠습니다.
- Docker가 아닌 프로그램이 포트를 쓰고 있다면 `sudo ss -ltnp`로 그 포트에서 듣고 있는 프로그램을 찾습니다.

**증거** — [`logs/08_ports.log`](logs/08_ports.log)의 5) 부분

### 7-5. VS Code의 GitHub 로그인이 브라우저에서 멈춤

**문제** — VS Code에서 GitHub 로그인을 진행하자 브라우저가 아래 화면에서 더 넘어가지 않았습니다. 다시 시도하자 `localhost에서 연결을 거부했습니다` 페이지가 나왔습니다.

```text
Launching Visual Studio Code
You will be redirected in a few moments.
```

**원인 가설** — ① Windows에 `vscode://` 링크를 처리할 프로그램(VS Code)이 등록되지 않음 ② 브라우저가 VS Code를 여는 것을 막았거나 허용 확인 창을 놓침 ③ VS Code가 기다리던 로그인 시도가 이미 끝나서(시간 초과) 결과를 받을 곳이 없음 — 다시 시도한 페이지의 `localhost` 연결 거부와 맞는 설명

**확인** — 레지스트리 `HKCU\Software\Classes\vscode\shell\open\command`에 `"<VS Code 설치 경로>\Code.exe" --open-url -- "%1"`이 등록되어 있어 ①은 아니었습니다. GitHub API로 조회했을 때 저장소가 아직 없었으므로, 로그인 결과가 VS Code까지 전달되지 않아 게시 단계로 넘어가지 못한 상태였습니다. ②와 ③ 중 어느 쪽이었는지는 따로 확인하지 않았습니다.

**해결/대안** — VS Code에서 **Sign in with GitHub**를 다시 눌러 로그인을 처음부터 새로 시작하자 정상적으로 끝났습니다. 계정 메뉴에 `timmy518 (GitHub)`가 표시되었고, 이후 Publish Branch로 저장소를 게시했습니다. 그래도 브라우저에서 VS Code로 돌아오는 단계가 계속 막히면, VS Code가 제안하는 **기기 코드(device code) 로그인**을 쓸 수 있습니다. 화면에 나온 일회용 코드를 `https://github.com/login/device`에 직접 입력하는 방식이라 되돌아오는 단계가 없습니다. 이 코드는 인증 코드이므로 캡처나 문서에 남기지 않습니다.

**증거** — 로그 파일 없음 — 브라우저·VS Code 화면에서 확인한 내용을 옮겨 적음(멈췄던 화면의 캡처는 남기지 않음). 해결 후 상태는 [VS Code 계정 메뉴 캡처](docs/images/11_vscode_github_login.png), [게시 성공 알림 캡처](docs/images/11_vscode_window.png), [`logs/11_git.log`](logs/11_git.log)의 `git ls-remote`·GitHub API(`"visibility": "public"`) 결과로 확인할 수 있습니다.

### 7-6. PowerShell에서 WSL로 명령을 넘길 때 변수와 따옴표가 깨짐

**문제** — 로그를 만들 때 Windows PowerShell 5.1에서 WSL로 명령을 넘기다가 두 번 문제가 생겼습니다.

- (a) 큰따옴표가 들어간 명령을 `wsl -- bash -c '...'`로 넘기자 첫 명령만 실행되고 나머지는 실행되지 않았습니다.
- (b) 다시 기록하던 중, 고친 파일을 Ubuntu 쪽 저장소 폴더로 복사하려고 PowerShell 스크립트에서 `` wsl -- bash -c "for f in ...; do install -m 644 `$f ..." ``를 실행하자 아래 오류가 났습니다. `$f`는 PowerShell이 자기 변수로 펼치지 않도록 백틱으로 막아(`` `$f ``) 글자 그대로 넘긴 상태였습니다.

```text
install: missing destination file operand after '/home/timmy518/codyssey/dev-workstation/'
```

**원인 가설** — ① PowerShell 5.1이 외부 프로그램(`wsl.exe`)에 인자를 넘길 때 안쪽 큰따옴표를 제대로 전달하지 못함 ② 변수 `$f`를 안쪽 bash가 아닌 다른 단계(PowerShell, 또는 `wsl.exe`가 거치는 기본 리눅스 셸)에서 먼저 해석함

**확인** — (a)는 PowerShell 5.1이 안쪽 큰따옴표를 망가뜨려 첫 명령만 실행된 경우입니다(①). (b)의 오류는 `install`이 복사할 파일 이름 없이 목적지 폴더만 받았다는 뜻이라 `$f`가 빈 값이었습니다. PowerShell은 백틱으로 막은 `$f`를 글자 그대로 넘겼습니다. 그런데 `wsl.exe`는 `-e` 없이 받은 명령줄을 기본 리눅스 셸에 넘겨 실행하고, 그 셸이 안쪽 `bash -c`가 실행되기 전에 큰따옴표 안의 `$f`를 먼저 펼쳤습니다. 그 셸에는 `$f`가 없으므로 빈 값이 들어가, 실제로는 `install -m 644  /home/timmy518/codyssey/dev-workstation/`처럼 파일 이름 자리가 빈 명령이 실행된 것입니다(②). 이 원인은 나중에 같은 조건의 짧은 명령으로 재현해 [`logs/12_troubleshooting.log`](logs/12_troubleshooting.log) 끝에 기록했습니다.

```powershell
# [7-6 재현] PowerShell 에서 wsl 로 넘긴 명령의 $변수가 언제 풀리는지 확인 (PS> 는 Windows PowerShell)
#   PowerShell 에서는 백틱(`)으로 $ 를 막아 $x 를 글자 그대로 넘겼다.
#   wsl -- (기본 리눅스 셸을 거침): 그 셸이 큰따옴표 안의 $x 를 안쪽 bash 보다 먼저 빈 값으로 풀어 [] 가 된다
#   wsl -e (기본 셸을 거치지 않음): 안쪽 bash 가 x=1 다음에 $x 를 풀어 [1] 이 된다
PS> wsl -d Ubuntu-24.04 -- bash -c "x=1; echo [`$x]"
[]
PS> wsl -d Ubuntu-24.04 -e bash -c "x=1; echo [`$x]"
[1]
```

확인 포인트: 두 명령은 `--`와 `-e`만 다르고, PowerShell이 넘긴 인자는 둘 다 `x=1; echo [$x]`로 같습니다. 기본 리눅스 셸을 거친 `--` 쪽은 그 셸이 안쪽 bash가 `x=1`을 실행하기 전에 `$x`를 빈 값으로 풀어 `[]`가 되었고, 기본 셸을 거치지 않은 `-e` 쪽은 안쪽 bash가 `x=1` 다음에 풀어 `[1]`이 되었습니다. `-e` 쪽이 `[1]`이므로 PowerShell 단계에서 `$x`가 풀린 것이 아니고, (b)의 `$f`도 `--` 쪽처럼 기본 셸에서 빈 값이 된 것입니다. 이 문제로 고친 파일이 복사되지 않은 채 기록이 진행되어, 그 기록은 버리고 2차 기록(00, 02, 04~10, 12)을 처음부터 한 번 더 했습니다([11장](#11-로그-기록-방식)).

**해결/대안** — 두 경우 모두 명령을 `.sh` 파일에 적고 `wsl -- bash 파일.sh`로 실행해 해결했습니다. 이때 명령줄에는 파일 이름만 있고 스크립트 내용은 bash가 파일에서 바로 읽으므로, 따옴표와 `$변수`가 PowerShell이나 기본 셸을 거치며 바뀌지 않습니다. (b)처럼 변수가 문제라면 `wsl -e`로 기본 셸을 건너뛰는 방법도 있습니다(위 재현의 `[1]`, PowerShell 쪽 `$`는 여전히 백틱으로 막아야 함). 따라 할 때는 Ubuntu 터미널을 열고 그 안에서 명령을 입력하면 이 문제가 생기지 않습니다.

**증거** — 원래 오류는 로그 파일 없음 — PowerShell 화면 메시지를 옮겨 적음. 원인(②)을 확인한 재현 실험은 [`logs/12_troubleshooting.log`](logs/12_troubleshooting.log) 끝(`[7-6 재현]`)에 있습니다. `logs/`의 Ubuntu 쪽 기록은 모두 스크립트 파일 방식(`wsl -- bash <스크립트>`)으로 실행한 결과입니다.

---

## 8. 보안·개인정보 처리

미션 조건(문서·로그·스크린샷에 토큰, 비밀번호, 개인키, 인증 코드를 남기지 않고, 노출되면 지우고 재발급)을 아래처럼 지켰습니다.

- **민감정보 점검** — 아래 다섯 가지를 확인했고, 명령과 결과 전체는 [`logs/13_secret_check.log`](logs/13_secret_check.log)에 있습니다.
  1. 비밀값 모양 검색: 실제 비밀값이 가지는 모양(정해진 접두어로 시작하는 GitHub 토큰, 개인키 파일의 머리글, AWS 액세스 키, 사용자명·비밀번호가 들어간 URL)을 README를 포함한 모든 파일에서 찾았습니다. 0건입니다.
  2. 커밋 히스토리 검색: 파일에서 지운 값도 예전 커밋에는 남아 있을 수 있으므로, 같은 모양을 `git log -p --all`로 모든 커밋에서 찾았습니다. 0건입니다.
  3. 키워드 검색: password·passwd·secret·token·api key·credential·비밀번호·토큰을 로그, Dockerfile, `nginx/`, `app/`, `.gitignore`, `.dockerignore`에서 찾았습니다. README는 이런 주제를 설명하는 문서라 이 단어들이 나올 수밖에 없어서 키워드 검색에서는 뺐습니다(1의 모양 검색에는 포함). 걸린 줄은 권한 실습 파일에 넣은 문구 `secret inside`([5.2](#52-권한-실습), [`logs/02_permissions.log`](logs/02_permissions.log))처럼 단어만 같은 줄뿐이고, 실제 비밀값은 없습니다.
  4. 원격 주소·인증 설정: `git remote -v`의 주소에 토큰이 없고, `credential.helper`도 설정되어 있지 않습니다.
  5. 스크린샷: 바로 아래 '스크린샷 확인'에 적었습니다.
- **스크린샷 확인** — PNG 6장은 글자 검색으로 내용을 확인할 수 없어서 두 가지를 따로 봤습니다. 파일 안에 글자 정보를 담는 메타데이터 청크(tEXt·iTXt·zTXt·eXIf)는 없었고, 한 장씩 열어 본 화면에도 토큰이나 기기 인증 코드는 보이지 않으며, 계정 사진도 GitHub 공개 프로필 그림(identicon) 외에는 없습니다. 브라우저 캡처 4장은 계정이 없는 일회용 프로필의 Edge InPrivate 창으로 찍어 평소 브라우저의 계정·즐겨찾기·방문 기록이 나오지 않게 했고, 나머지 2장은 VS Code 창입니다.
- **GitHub 인증** — VS Code의 GitHub 로그인(브라우저 승인 방식)으로 했습니다. GitHub 비밀번호는 (필요할 때) 브라우저의 github.com 화면에만 입력하고 VS Code·터미널에는 입력하지 않았습니다. VS Code는 승인 결과로 받은 접근 토큰을 운영체제의 보안 저장 기능에 보관하므로 저장소 파일에 들어가지 않습니다. `git config --show-scope --list`([`logs/11_git.log`](logs/11_git.log))에 `credential.helper`가 없어서, 토큰을 평문 파일로 저장하는 설정도 없습니다. 원격 주소도 토큰이 없는 `https://github.com/timmy518/Codyssey_E_1-1.git`입니다([`logs/13_secret_check.log`](logs/13_secret_check.log)의 `git remote -v`). 최종본도 같은 VS Code 로그인으로 Sync Changes를 눌러 올렸으므로([5.11](#511-git-설정과-github--vs-code-연동)) 토큰을 입력하지 않았습니다.
- **Ubuntu 비밀번호** — 리눅스 사용자 `timmy518`과 비밀번호는 작성자가 직접 입력해서 만들었고, 어디에도 기록하지 않았습니다. Docker 설치([5.3](#53-docker-설치))는 관리자(root) 셸에서 실행해서 로그에 sudo 비밀번호 입력 장면이 없습니다.
- **docker 그룹 주의** — `usermod -aG docker`로 sudo 없이 Docker를 쓰게 했습니다(`logs/03`의 `989(docker)`, `logs/04`의 `srw-rw---- 1 root docker … /var/run/docker.sock`). 하지만 Docker 데몬은 root로 실행되므로 docker 그룹은 **사실상 root 권한**과 같습니다(예: `docker run -v /:/host …`로 호스트 전체 파일에 접근 가능). 혼자 쓰는 개인 WSL 개발 환경이라 편의상 추가했고, 여러 사람이 쓰는 서버라면 sudo로 실행하거나 rootless 모드를 검토해야 합니다.
- **커밋 이메일·식별 정보** — 커밋 작성자 이메일(`timmy518@naver.com`)은 공개 저장소에서 누구나 볼 수 있다는 것을 알고 선택했습니다. 숨기려면 GitHub Settings → Emails에 있는 noreply 주소(`<숫자ID>+<사용자명>@users.noreply.github.com`)를 `git config --global user.email`에 넣으면 앞으로 만드는 커밋부터 숨겨집니다. 이미 올린 커밋에는 지금 주소가 그대로 남으므로, 그것까지 숨기려면 히스토리를 다시 써서(작성자 이메일 변경) 강제 푸시해야 합니다. 로그 프롬프트에 보이는 리눅스 사용자명(`timmy518`)과 PC 이름(`AISiLa`)은 인증 정보가 아니어서 가리지 않았습니다.
- **비밀 파일 차단** — 비밀 파일이 Git 저장소나 이미지에 들어가지 않도록 두 파일에 패턴을 넣었습니다.

| 파일 | 비밀 관련 패턴 | 막는 것 |
|---|---|---|
| `.gitignore` | `.env`, `.env.*`, `!.env.example`, `*.pem`, `*.key`, `id_*` | 환경 변수 파일·인증서·개인키(SSH 키 등)가 실수로 커밋되는 것. 값을 비워 둔 예시 파일 `.env.example`만 예외로 커밋 허용 |
| `.dockerignore` | `**/.env`, `**/.env.*`, `**/*.pem`, `**/*.key`, `**/id_*` (+ `.git`, `README.md`, `docs/`, `logs/`) | 비밀 파일이 빌드 컨텍스트 → 이미지 → 웹 서버 루트(`/usr/share/nginx/html`)로 들어가 누구나 내려받을 수 있게 되는 것 |

Dockerfile은 `app/`과 nginx 템플릿만 `COPY`하지만, 나중에 `COPY . …`처럼 바뀌더라도 비밀 파일이 이미지에 들어가지 않도록 `.dockerignore`로 한 번 더 막았습니다. 빌드 컨텍스트에서 빠진 파일은 Docker 데몬에 전달조차 되지 않습니다.

**민감정보가 노출되었을 때의 대응 순서**

1. 노출된 토큰·키를 즉시 폐기(revoke)하고 재발급합니다. 이미 누군가 복사했을 수 있으므로 지우는 것보다 무효화가 먼저입니다.
2. 파일에서 지웁니다. 새 커밋으로 지워도 예전 커밋에는 남아 있으므로 `git filter-repo` 같은 도구로 히스토리에서도 제거합니다.
3. 강제 푸시(`git push --force`)로 GitHub의 히스토리를 바꿉니다.
4. 같은 점검(파일 검색과 커밋 히스토리 검색)을 다시 실행해 남은 곳이 없는지 확인합니다.

---

## 9. 개념 정리 (과제 목표)

**절대 경로 vs 상대 경로** — 절대 경로는 루트(`/`)부터 시작하는 전체 주소라서 어디에서 실행해도 같은 곳을 가리킵니다(예: `/etc/os-release`, `/home/$USER/codyssey/practice/docs`). 상대 경로는 현재 위치(`pwd`)를 기준으로 해석되므로, 같은 `cd ./docs`라도 실행한 위치에 따라 도착지가 달라집니다. `.`은 현재 디렉토리, `..`은 상위 디렉토리, `~`는 홈 디렉토리(`$HOME`)를 뜻합니다. [5.1](#51-터미널-기본-조작)에서는 절대 경로로 `docs`에 들어간 뒤 `cd ..`, `cd ./docs`로 움직이며 매번 `pwd`로 위치를 확인했습니다. 실행 위치가 달라질 수 있는 곳에는 절대 경로가 안전해서, [5.9](#59-바인드-마운트-반영)의 `docker run -v`에는 `"$PWD/bind-site"`로 절대 경로를 만들어 넘겼습니다.

**파일 권한 r/w/x와 755·644** — `ls -l`의 첫 10글자는 종류 1자리(`-` 파일, `d` 디렉토리)와 소유자·그룹·기타 사용자 각 3자리(r 읽기, w 쓰기, x 실행)입니다. 숫자 표기는 자리마다 r=4, w=2, x=1을 더한 값이라, 755는 `rwxr-xr-x`(소유자만 수정, 모두 읽기·실행: 스크립트·디렉토리), 644는 `rw-r--r--`(소유자만 수정, 모두 읽기: 일반 파일)입니다. 디렉토리에서는 r이 이름 목록 보기, w가 안에 파일 만들기·지우기(x와 함께 있을 때), x가 '안으로 들어가기(통과)'라서, [5.2](#52-권한-실습)에서 `perm_dir`을 644로 바꾸자 이름은 보여도 `cd`와 `cat`이 막혔습니다. 새 파일·디렉토리의 기본 권한은 umask가 정하며, `umask 0022`는 기본값(파일 666, 디렉토리 777)에서 그룹·기타의 w 비트를 꺼서 644/755를 만듭니다. 빼기가 아니라 비트 끄기라서, umask가 033이면 새 파일은 633이 아니라 644가 됩니다.

**이미지와 컨테이너** — 이미지는 실행에 필요한 파일과 설정을 담은 읽기 전용 틀이고, 컨테이너는 그 이미지 위에 자기만의 쓰기 층(writable layer)을 얹어 격리된 환경(자기 파일 시스템·네트워크·프로세스 번호)에서 실행한 것입니다. 그래서 같은 `my-web:1.0`으로 띄운 web-8080과 web-8081이 서로 다른 컨테이너(`5a2248b15e0e`, `00466df6b603`)로 따로 응답했고, attach한 컨테이너의 메인 bash는 자기 PID를 1로 출력했습니다. 컨테이너 안에서 바꾼 파일은 그 컨테이너의 쓰기 층에만 남고 이미지는 바뀌지 않습니다(`docker diff` → `A /tmp/temp.txt`). 멈춘(Exited) 컨테이너도 `docker ps -a`에 남아 있다가, `docker rm`으로 지울 때 쓰기 층과 함께 사라집니다. ([5.5](#55-docker-기본-운영-명령), [5.6](#56-컨테이너-실행-실습), [5.10](#510-docker-볼륨-영속성))

**커스텀 이미지** — Dockerfile은 '어떤 베이스 이미지 위에 무엇을 바꿀지' 적은 레시피이고, `docker build -t my-web:1.0 .`이 이 레시피와 빌드 컨텍스트(현재 폴더에서 `.dockerignore`에 적은 것을 뺀 나머지)로 새 이미지를 만듭니다. 이 프로젝트는 검증된 공식 이미지 `nginx:1.30.6-alpine`을 `FROM`으로 고르고, nginx 설정 템플릿과 정적 페이지를 `COPY`로 바꿨으며, `ENV`·`LABEL`·`EXPOSE`·`HEALTHCHECK`로 실행 정보를 더했습니다. 파일을 바꾸는 `COPY`·`RUN`·`ADD`만 새 레이어(파일 변경 묶음)를 만들고 그 밖의 명령은 이미지 설정(메타데이터)만 바꾸므로, `docker history`에서 이 Dockerfile이 더한 줄 중 크기가 있는 것은 `COPY` 두 줄(24.6kB, 20.5kB)뿐이고 `LABEL`·`ENV`·`EXPOSE`·`HEALTHCHECK` 줄은 0B입니다(그 아래 `RUN` 51.8MB 등은 베이스 이미지의 기록). 결과는 같은 경로의 페이지 제목이 `Welcome to nginx!`에서 `Dev Workstation`으로 바뀐 것과, 실행한 컨테이너가 `(healthy)`가 된 것으로 확인했습니다. ([5.7](#57-dockerfile-커스텀-이미지), [5.8](#58-포트-매핑과-접속-증거))

**포트 매핑이 필요한 이유** — 컨테이너는 Docker가 만든 브리지 네트워크 안에서 자기 IP(이번에는 `172.17.0.2`)를 받고, 그 IP의 80번 포트에서 요청을 기다립니다. 그래서 포트 매핑 없이 띄우면 컨테이너 안에서는 `ok`가 나와도 호스트의 `localhost:80`에는 듣는 프로그램이 없어 `curl: (7)`로 실패했고, WSL Ubuntu 안에서는 내부 IP로 닿지만 Windows 브라우저나 다른 PC는 이 내부망에 닿지 못합니다. `-p 호스트포트:컨테이너포트`(예: `-p 8080:80`)는 Docker가 호스트의 8080 포트에서 요청을 받아 컨테이너의 80번으로 넘기게 하는 규칙이고, `docker ps`에는 `0.0.0.0:8080->80/tcp`로 표시됩니다. 같은 이미지라도 호스트 포트만 다르게(8080, 8081) 주면 여러 개를 띄울 수 있고, 호스트 포트 하나는 한 번에 하나만 쓸 수 있습니다([7-4](#7-4-포트-충돌-의도적으로-재현)). Windows에서는 WSL2(NAT 모드)가 `localhost` 요청을 Ubuntu로 넘겨 주므로 PowerShell과 Edge에서도 HTTP 200을 받았습니다([5.8](#58-포트-매핑과-접속-증거)).

**볼륨과 바인드 마운트** — 둘 다 컨테이너 밖의 저장 공간을 컨테이너 안 경로에 연결해서, 컨테이너를 지우면 사라지는 쓰기 층이 아닌 곳에 데이터를 둡니다. 바인드 마운트는 내가 고른 호스트 폴더(`~/codyssey/practice/bind-site`)를 그대로 연결하므로, 호스트에서 파일을 고치자 재시작 없이 바로 반영되었습니다([5.9](#59-바인드-마운트-반영)). 볼륨은 Docker가 만들고 관리하는 저장 공간(`/var/lib/docker/volumes/web-data/_data`)으로, `docker volume create`로 만들고 `-v 볼륨이름:/경로`로 연결합니다. 컨테이너를 지운 뒤 새 컨테이너에 같은 볼륨을 연결하자 같은 데이터를 읽었습니다([5.10](#510-docker-볼륨-영속성)). 개발 중인 코드·설정처럼 내가 직접 고치는 파일은 바인드 마운트, DB 파일처럼 컨테이너가 바뀌어도 남아야 하는 데이터는 볼륨이 알맞습니다.

**Git과 GitHub** — Git은 내 컴퓨터에서 동작하는 버전 관리 프로그램으로, `git init`·`git commit`·`git log`는 인터넷 없이도 되고 기록은 저장소의 `.git` 폴더에 쌓입니다. GitHub는 Git 저장소를 인터넷에 올려 공유하고 이슈·풀 리퀘스트·리뷰로 협업하는 원격 플랫폼입니다. 둘은 원격 저장소 설정(`origin` = `https://github.com/timmy518/Codyssey_E_1-1.git`)으로 이어지고, 로컬 커밋은 `git push`(VS Code에서는 Publish Branch·Sync Changes)로 GitHub에 올립니다. 처음에는 VS Code의 Publish Branch로 `timmy518/dev-workstation`에 게시했고(그때 로컬 `f642393` = 원격 `main`), 결과물을 정리한 최종본은 제출용 저장소 `timmy518/Codyssey_E_1-1`에 올렸습니다. `user.name`·`user.email`은 커밋에 남는 작성자 정보일 뿐 GitHub 로그인 정보가 아니며, GitHub 인증은 VS Code의 브라우저 승인으로 따로 했습니다([5.11](#511-git-설정과-github--vs-code-연동)).

---

## 10. 재현 방법

Docker가 동작하는 터미널(Windows는 WSL2 Ubuntu 터미널, macOS는 OrbStack이나 Docker Desktop을 켠 터미널)에서 아래 순서대로 실행하면 같은 결과를 확인할 수 있습니다. 나와야 하는 결과는 각 줄 끝 주석에 적었습니다.

```bash
# 0) Docker 동작 확인
docker --version
docker run --rm hello-world                       # Hello from Docker!

# 1) 저장소 받기 — WSL이면 리눅스 홈(~) 아래에 받기 (/mnt/c 아래는 7-3 권한 문제)
cd ~
git clone https://github.com/timmy518/Codyssey_E_1-1.git
cd Codyssey_E_1-1

# 2) 커스텀 이미지 빌드
docker build -t my-web:1.0 .
docker images my-web                              # my-web:1.0

# 3) 같은 이미지로 컨테이너 2개 — 호스트 포트만 다르게, 8081은 환경 변수로 모드 변경
docker run -d --name web-8080 -p 8080:80 my-web:1.0
docker run -d --name web-8081 -p 8081:80 -e APP_ENV=prod my-web:1.0
sleep 15; docker ps --filter name=web-808         # STATUS (healthy), PORTS 0.0.0.0:8080->80/tcp

# 4) 접속 확인 — 브라우저에서도 http://localhost:8080 , http://localhost:8081/info
curl -i http://localhost:8080/health              # HTTP/1.1 200 OK … ok
curl http://localhost:8080/info                   # …"env":"dev"…
curl http://localhost:8081/info                   # …"env":"prod"…

# 5) 바인드 마운트 — 호스트 파일을 고치면 재시작 없이 반영
mkdir -p ~/codyssey/practice/bind-site && cd ~/codyssey/practice
printf '<h1>Bind Mount v1</h1>\n' > bind-site/index.html
docker run -d --name web-bind -p 8082:80 -v "$PWD/bind-site":/usr/share/nginx/html my-web:1.0
sleep 2; curl http://localhost:8082               # <h1>Bind Mount v1</h1>
sed -i 's/v1/v2 (edited on host)/' bind-site/index.html
curl http://localhost:8082                        # <h1>Bind Mount v2 (edited on host)</h1>

# 6) 볼륨 — 컨테이너를 지워도 데이터 유지
docker volume create web-data
docker run -d --name vol-writer -v web-data:/data ubuntu:24.04 sleep infinity
docker exec vol-writer sh -c 'echo "hello volume" > /data/note.txt'
docker rm -f vol-writer
docker run --rm -v web-data:/data ubuntu:24.04 cat /data/note.txt   # hello volume

# 7) 정리
docker rm -f web-8080 web-8081 web-bind
docker volume rm web-data
docker rmi my-web:1.0                             # (선택) 이미지까지 지우기
rm -r ~/codyssey/practice/bind-site               # (선택) 바인드 마운트 실습 폴더
```

**주의사항**

- **포트가 이미 쓰이는 경우** — `port is already allocated`가 나오면 호스트 쪽 숫자만 바꿉니다(예: `-p 9080:80` → `http://localhost:9080`). [7-4](#7-4-포트-충돌-의도적으로-재현) 참고.
- **Windows** — WSL 설치는 관리자 PowerShell에서 `wsl --install -d Ubuntu-24.04`로 하고, WSL2를 처음 켜면 재부팅이 필요할 수 있습니다([7-1](#7-1-wsl-설치-명령이-설치를-하지-않음), [7-2](#7-2-설치-직후-wsl2가-시작되지-않음)). 명령은 PowerShell에서 `wsl -- bash -c "…"`로 넘기지 말고 Ubuntu 터미널 안에서 입력합니다([7-6](#7-6-powershell에서-wsl로-명령을-넘길-때-변수와-따옴표가-깨짐)).
- **docker 권한** — `permission denied … docker.sock`이 나오면 `sudo usermod -aG docker $USER`를 실행한 뒤 터미널을 새로 엽니다(WSL은 PowerShell에서 `wsl --shutdown` 후 다시 열기). docker 그룹이 사실상 root 권한이라는 점은 [8장](#8-보안개인정보-처리)을 참고하세요.
- **macOS** — 미션 안내대로 OrbStack(또는 Docker Desktop)을 실행하면 터미널에서 같은 `docker` 명령을 그대로 씁니다. WSL 관련 단계(7-1·7-2·7-3·7-6)는 해당하지 않습니다. macOS 기본 `sed`는 BSD 판이라 5)의 수정 명령을 `sed -i '' 's/v1/v2 (edited on host)/' bind-site/index.html`로 바꿔 씁니다.

---

## 11. 로그 기록 방식

**기록 방법**

- 명령은 Windows PowerShell 5.1에서 `wsl -- bash <스크립트>`로 Ubuntu의 bash에 넘겨 실행했습니다. 명령을 스크립트 파일에 담은 것은 [7-6](#7-6-powershell에서-wsl로-명령을-넘길-때-변수와-따옴표가-깨짐)의 따옴표·변수 문제를 피하기 위해서입니다.
- 작은 기록용 함수가 각 명령을 자식 `bash -c`로 실행하고, 프롬프트 줄(`사용자@호스트:현재경로$ 명령`)과 출력을 함께 저장했습니다. 그래서 실패 메시지가 `bash: line 1: ...` 형태로 남았습니다. 터미널에 그대로 입력하면 같은 내용이 `bash: ...` 형태로 나옵니다.
- 대화형 장면(`docker run -it`, `docker exec -it`, `docker attach`)은 `script` 명령으로 만든 가상 터미널(pseudo-terminal)에서 키 입력을 사이사이 쉬어 가며 보내 기록했고, 화면 색상 코드만 지웠습니다.
- Windows에서 실행한 명령(00의 `[1]`, 08과 12의 마지막 두 명령)은 `PS>` 뒤에 명령을, 그 아래에 출력을 적었습니다.
- `#`으로 시작하는 줄은 설명이고, `[exit code: N]` 줄은 명령이 실패했을 때의 종료 코드입니다.

| exit code | 뜻 | 나온 곳 |
|---|---|---|
| 126 | 실행 권한 없음 | 02 `./hello.sh` |
| 7 | curl이 서버에 연결하지 못함 | 08 `curl http://localhost:80` |
| 125 | `docker run` 자체가 실패 | 08 포트 충돌 |
| 1 | 일반 오류(권한 거부, 파일·컨테이너 없음 등) | 02, 10 |

- 시각: 컨테이너 안에서 찍힌 시각(nginx 접근 로그의 `+0000`, 볼륨 실습의 `date`)은 UTC이고, 호스트 쪽 시각(`ls -l`, `docker volume inspect`의 `+09:00`)은 한국 시간이라 9시간 차이가 납니다(예: 05:50 UTC = 14:50 KST).

**두 번에 걸친 기록**

| 차수 | 시각 (11월 2일, KST) | 기록한 로그 |
|---|---|---|
| 1차 | 13:4x | 01, 03, 11의 앞부분(Git 설정과 `git init`) |
| 2차 (검토 후 다시 기록) | 14:4x–14:5x | 00(`[3]` 초기화 포함), 02, 04~10, 12 — 번호 순서대로 |
| 보충 | — | 11에 GitHub 연동 증거와 설정 범위(`--show-scope`) 메모 추가, 06 끝에 `no-it-demo2` 재확인 실험 추가, 12 끝에 7-6 원인 재현 실험 추가, 13 민감정보 점검 |

- 1차 기록을 문서와 대조해 검토했더니 준비 명령이 빠진 곳, 실행 순서가 로그 번호와 다른 곳, 결론을 뒷받침하지 못하는 비교 실험(볼륨 없는 데이터) 등이 나왔습니다. 그래서 00의 `[3]`에서 컨테이너·이미지·볼륨·빌드 캐시와 02·09의 실습 파일을 지우고(`docker system df`가 전부 0) 02, 04\~10, 12를 번호 순서대로 다시 기록했습니다. 04의 `docker info`가 `Images: 0`이고 05~07에서 이미지를 새로 내려받는 것은 이 때문입니다.
- 2차 기록은 한 번, [7-6](#7-6-powershell에서-wsl로-명령을-넘길-때-변수와-따옴표가-깨짐) (b)의 문제로 고친 파일이 복사되지 않은 채 진행되어 처음부터 한 차례 더 기록했습니다. 지금 `logs/`의 00, 02, 04~10, 12는 그 마지막 기록입니다. 00의 `[3]`이 지운 컨테이너(`Up About a minute`인 web-8080·web-8081·web-bind)와 hello-world(`Exited (0) 2 minutes ago`)는 이 버린 시도가 남긴 것입니다.
- 01·03과 11의 앞부분은 1차 기록을 그대로 썼습니다. 그래서 01·03의 시각(13:4x)이 다른 로그(14:4x)보다 이릅니다.
- 검토 후 로그에서 고친 것은 설명 줄과 보충 실험뿐이고, 명령과 출력은 고치지 않았습니다.
  - 설명(`#`) 줄 수정: 00의 `[3]` 설명(다시 기록한 범위를 02, 04\~10, 12로 바로잡음), 03의 `# 3)`(설치 출력 중 종료 코드와 `Setting up` 줄만 보여 준다는 것), 06의 `no-it-demo` 설명(첫 조회가 `Up`으로 찍힌 이유와 보충 실험 안내), 08의 `# 6)`(글자가 깨져 있던 한글 설명을 원래 문장으로 복구), 11의 `# 4)`(`git add`·`git commit`은 기록 밖에서 실행했고 아래는 그 결과라는 것).
  - 보충 실험 추가: 06 끝에 2초 기다린 재확인 실험(`no-it-demo2` → `Exited (0)`, [5.6](#56-컨테이너-실행-실습) ③-1), 12 끝에 `wsl --`와 `wsl -e`를 비교한 [7-6](#7-6-powershell에서-wsl로-명령을-넘길-때-변수와-따옴표가-깨짐) 원인 재현 실험.

**로그에 없는 것** — WSL 설치([7-1](#7-1-wsl-설치-명령이-설치를-하지-않음), [7-2](#7-2-설치-직후-wsl2가-시작되지-않음)), VS Code·GitHub 로그인과 게시([5.11](#511-git-설정과-github--vs-code-연동) 스크린샷, [7-5](#7-5-vs-code의-github-로그인이-브라우저에서-멈춤)), PowerShell → WSL 전달 오류([7-6](#7-6-powershell에서-wsl로-명령을-넘길-때-변수와-따옴표가-깨짐), 원인 재현 실험만 12 끝에 있음), 첫 커밋 때 터미널에 나온 CRLF 경고([5.11](#511-git-설정과-github--vs-code-연동))는 로그 파일이 없습니다. 화면에 나온 메시지를 옮겨 적었거나 스크린샷으로 남겼고, 7장에서는 각 항목의 '증거' 줄에 이를 밝혔습니다.

