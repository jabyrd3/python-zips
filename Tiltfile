docker_compose('./docker-compose.yml')
docker_build('zips:latest', '.', 
  ignore=[],
  live_update = [
    sync('./', '/zips'),
    restart_container()
  ])
