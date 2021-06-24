# stf-generator-docker

This repo contains the dockerized version of the The Stratosphere Testing Framework (stf)

The Stratosphere Testing Framework (stf) is a network security research
framework to analyze the behavioral patterns of network connections in the
[Stratosphere Project](https://stratosphereips.org).


## Usage

the docker images is available at https://hub.docker.com/repository/docker/harpomaxx/stf-generator

you can buld your own image as usual:
```

git pull https://github.com/harpomaxx/stf-generator-docker

cd stf-generator-docker

docker build --rm -t stf-generator .

```

### A very simple example 

Given a **pcap** capture file named **test.pcap** located in your working directory,  you can generate the traffic behavior model in the following way:
```
docker run  --rm --name stf-generator  --user $UID:$GID -v $PWD:$PWD -w $PWD harpomaxx/stf-generator ./test.pcap
```
If everything goes well  two files with the *.biargus* and *.binetflow* extensions and  tab-separated file **test.pcap.tsv**.

```
ModelId	State	LabelName
0-0-0-man	1	
0-18-1-man	8	
181.20.178.50-192.168.1.67-22-tcp	5	
192.168.1.1-192.168.1.14--arp	1	
192.168.1.11-224.0.0.251-5353-udp	1	
192.168.1.124-224.0.0.251-5353-udp	4	
192.168.1.14-104.237.191.1-443-tcp	2	
192.168.1.14-162.125.18.133-443-tcp	8	
192.168.1.14-162.125.4.3-443-tcp	99.
```
### Source

You can reach the original stf repo [here](https://github.com/stratosphereips/StratosphereTestingFramework)




