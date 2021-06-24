FROM ubuntu:20.04

# Install dependencies
RUN apt-get update -y
RUN apt-get install -y argus-client curl python2 build-essential python2.7-dev

RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py && python2 get-pip.py
RUN pip2 install persistent
RUN pip2 install prettytable
RUN pip2 install Btrees
RUN pip2 install python-dateutil
RUN pip2 install ZODB
RUN pip2 install numpy

# Create app directory
WORKDIR ./stratosphere-generator

# Bundle app source
COPY stf/StratosphereTestingFramework/ .
COPY init.sh .

ENTRYPOINT [ "./init.sh" ]
#ENTRYPOINT ["python2", "/stratosphere-generator/mg.py", "-p"]
