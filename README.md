# Docker Container for Data Science Notebooks

A mashup of the jupyterlab and the NVidia CUDA container
with Python 3 hand installed and using credstash to manage any secrets (notebook password,
github plugin oauth, etc.)

## Usage
It's easiest to use this container together with [dockerutils](https://pypi.python.org/pypi/dockerutils).

Create a docker directory in your repository and place the following dockerutils.cfg file in that directory:

## Credentials
There are a number of credentials utlized by this container, including: notebook password, github plugin OAuth 
credentials, google drive OAuth credentials, etc.

The pattern for exposing these credentials to the docker container is to store the
credentials in credstash, and then bind mount the current user's .aws directory into
the container upon container start.

The code assumes an aws profile of 'ds-notebook'. If unable to access credstash, 
appropriate defaults will be used if available. In most cases extensions will not
function.

## Configuration
### dockerutils.cfg
```ini
[notebook]
volumes=--mount type=bind,source={project_root},target=/home/jovyan/project -v /data:/data --mount type=bind,source=/Users/{user}/.aws,target=/home/jovyan/.aws
ports=-p 8888:8888
```

### AWS
In your ~/.aws directory create a credentials and config file simlar to the following:

**credentials**
```ini
[ds-notebook]
aws_secret_access_key = ...
aws_access_key_id = ....
```

**config**
```ini
[profile ds-notebook]
region = us-west-2
```

### Docker Configuration in Derived Repo
Create a docker/notebook subdirectory and place a Dockefile similar to the following in that directory:

**DockerFile**
```dockerfile
USER root

ADD pip.conf /home/jovyan/.pip/pip.conf
ADD requirements.txt /tmp/requirements.txt

RUN pip install -r /tmp/requirements.txt
RUN fix-permissions /home/$NB_USER/.pip

USER $NB_USER
CMD start-project-notebook.sh
```

### Related Extensions
#### github
[Jupyterlab Github](https://github.com/jupyterlab/jupyterlab-github)

Requires credstash credentials named: github.client_id, github.client_secret

#### Google Drive
[Realtime Collaboration via Google Drive](https://github.com/jupyterlab/jupyterlab-google-drive/blob/master/docs/advanced.md#Realtime-API)

Requires credstash credential named: google.drive.client_id

## Versions

1.0.14 - Add labmanager and matplotlib jupyterlab extensions
1.0.13 - Include GraphViz in the image
1.0.12 - Update to latest CUDA cdNN Tensorflow
1.0.11 - Include Tensorflow (both CPU and GPU, using dockerutils handling of GPU)
        - add start-project-notebook.sh (derived project simplification)
1.0.10 - No changes to Dockerfile source, rebuild to pick up latest jupyterlab beta (v0.31.10)