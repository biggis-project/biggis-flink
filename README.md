# BigGIS Flink
[![Build Status](https://api.travis-ci.org/biggis-project/biggis-flink.svg)](https://travis-ci.org/biggis-project/biggis-flink)
Docker container for Apache Flink

## Prerequisites
Docker Compose >= 1.9.0

## Deployment

**On local setup**:
```sh
docker-compose up -d
```

**On Rancher**:
* Add host label `flink_jobmanager=true` to any of your hosts.
* Create new Flink stack `flink` via Rancher WebUI and deploy `docker-compose.rancher.yml`.


## Ports
- Flink WebUI is running on port `8081`
- Flink Jobmanager RPC port `6123`
