# Docker containerized PrusaLink

## Configuration

Check the configuration settings in `prusalink.ini`, and verify their
correctness on your system.

The network port of the service inside the container is mapped by the
docker-compose.yml file to port 8008; please adjust as appropriate for the
container host system.

The serial port for your printer needs to be assigned to the container, verify
that the value in docker-compose.yml is correct. If you have python3 and
pyserial installed, you can check this by running:

```
$ python3 -m serial.tools.miniterm
```

### Camera enablement

I've been unsuccessful so far enabling the camera support with a standard USB webcam.

## Running

It should be as simple as running

```
docker-compose up -d
```

Then opening up http://<your server ip>:8008/ in a browser and going through
the configuration steps presented.  The printer configuration settings will be
stored in a docker volume called `prusalink` (actually `prusalink_prusalink` as
docker-compose generates it with the container name and the volume name).
