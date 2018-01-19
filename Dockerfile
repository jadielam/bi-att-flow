# To Build:
# docker build -t training -f training.Dockerfile .

# To run:
# nvidia-docker run -v /home/ubuntu/deep_learning_image/examples/classification:/examples/classification -t training

FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04

ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

RUN mkdir -p $CONDA_DIR && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh && \
    apt-get update && \
    apt-get install -y wget git libhdf5-dev g++ graphviz openmpi-bin libgl1-mesa-glx && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh && \
    echo "c59b3dd3cad550ac7596e0d599b91e75d88826db132e4146030ef471bb434e9a *Miniconda3-4.2.12-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash /Miniconda3-4.2.12-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.2.12-Linux-x86_64.sh

# Python
ARG python_version=3.5.2

RUN conda install -y python=${python_version} && \
    pip install --upgrade pip && \
    pip install tensorflow-gpu==0.12 && \
    conda install Pillow scikit-learn notebook pandas matplotlib mkl nose pyyaml six h5py && \
    conda install jinja2 tqdm theano pygpu bcolz imageio flask opencv && \
    pip install sklearn_pandas && \
    pip install xgboost easydict nltk && \
    pip install keras==2.1.3 && \
    conda clean -yt

# Creating src folder
RUN mkdir src
ADD code/ src/qa
ENV PYTHONPATH=:/src/qa
EXPOSE 8888

# Download models
RUN mkdir src/model
RUN pip install awscli
ARG aws_access_key
ARG aws_secret_access_key
ARG aws_default_region
RUN AWS_ACCESS_KEY_ID=${aws_access_key} AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} AWS_DEFAULT_REGION=${aws_default_region} aws s3 sync s3://jadiel-deep-learning/models/bi-att-flow/ src/model/
#RUN ["tar -xzvf src/model/save.tar.gz"]

#RUN ["/bin/bash", "-c", "chmod +x download.sh"]
#RUN "./download.sh"
#RUN ["/bin/bash", "-c", "python -m squad.prepro"]

# Running python as entry point
ENTRYPOINT ["/bin/bash"]
