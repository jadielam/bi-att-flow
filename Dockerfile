# To Build:
# docker build -t qa .

# To run:
# nvidia-docker run --env AWS_ACCESS_KEY=<<YOUR_ACCESS_KEY>> \
# --env AWS_SECRET_ACCESS_KEY=<<YOUR_SECRET_ACCESS>> \
# --env AWS_DEFAULT_REGION=us-east-1 \
# -p 8888:8888 -t qa

FROM nvidia/cuda:9.0-cudnn7-runtime-ubuntu16.04

# Installing dependencies for python packages
RUN apt-get update -y && apt-get -y install \
    gcc \
    libgtk2.0-dev \
    curl \
    vim

# Installing conda
RUN curl -LO http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh
RUN bash Miniconda-latest-Linux-x86_64.sh -p /miniconda -b
RUN rm Miniconda-latest-Linux-x86_64.sh
ENV PATH=/miniconda/bin:${PATH}
RUN conda update -y conda

# Use the environment.yaml to create the conda environment
ADD environment.yaml .
RUN conda env create -f environment.yaml

# Creating src folder
RUN mkdir src
ADD code/ src/qa
RUN ["/bin/bash", "-c", "source activate qa" ]
WORKDIR src/qa
ENV PYTHONPATH=:/src/qa
EXPOSE 8888

# Download
RUN ["/bin/bash", "-c", "chmod +x download.sh; ./download.sh"]
RUN ["/bin/bash", "-c", "python -m squad.prepro"]
RUN mkdir src/model
RUN ["aws s3 sync s3://jadiel-deep-learning/models/bi-att-flow/ /src/model/"]
RUN ["tar -xzvf /src/model/save.tar.gz"]

# Running python as entry point
ENTRYPOINT ["/bin/bash", "-c", "source activate qa && python"]
#ENTRYPOINT ["/bin/bash"]
