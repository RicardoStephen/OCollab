# CS3110-Final-Project

### A real-time collaborative editor written in Ocaml, using Eliom, js_of_ocaml and Redis.

## Installation

From a clean [cs3110 virtual machine](https://cornell.box.com/cs3110vm-2015fa):
```
make install && make
```

Point the browser to <http://localhost:8080> and have fun!

## Troubleshooting

We have tested our installation on a clean cs3110 machine. However, things might not always go the way we expect.

### Slow installation

The installation of Eliom, js_of_ocaml etc. takes quite a while (up to 10 minutes). Please be patient.

### Make error

If a problem is encountered while compiling, try running `make clean && make` again.

### Redis Server

Upon installation of redis-server from apt, an instance of the server should start automatically. If it doesn't, and a "Failed to connect to Redis" error is seen, then try starting the service with `sudo service redis-server start`. Alternatively, start an instance of redis-server in the background with `redis-server &`. The server must be running on port 6379, and should be bound to 127.0.0.1.

### Port conflict

Ocsigenserver, the web server, is set to run as vagrant on port 8080. If another program is using that port, please stop it before running `make` again.

## Online Demo

An online demo is available at <http://ocollab.sc-wu.com>.

