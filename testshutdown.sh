curl -X POST -H "application/json" -d '{"password":"hello world"}' http://127.0.0.1:8088/hash
curl  http://localhost:8088/hash/1
curl -X POST -d 'shutdown' http://127.0.0.1:8088/hash
curl -X POST -H "application/json" -d '{"password":"suzanne"}' http://127.0.0.1:8088/hash
