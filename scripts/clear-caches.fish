rm ~/.bun/install/cache

go clean --modcache

docker system prune -a --volumes --force
