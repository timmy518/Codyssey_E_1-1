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
