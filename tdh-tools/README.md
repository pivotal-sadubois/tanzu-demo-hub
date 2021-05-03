# Tanzu Demo Hub Tools Container

Package the tools needed to run Tanzu Demo Hub installation and demos in a container.
Configuration files can be mounted into the container as readonly docker volumes.
We will need to mount some directories as readwrite to allow writeback.

## Building

For building the containers see `build.sh`
You will have to change to your dockerhub username to push the image to your registry account.

## Running the tools

Start the container with your uid:gid in interactive mode to execute a single command only (here `kubectl get pods -A`)

```
$ docker run -u $(id -u):$(id -g) -it --rm --name tdhtools -v $HOME:$HOME:ro -e "KUBECONFIG=$HOME/.kube/config" demosteveschmidt/tdhtools:v0.1 kubectl get pods -A
```
NOTE: replace demosteveschmidt with your DockerHub username


Staring the container in detached mode (keeps runnign in the background until the sleep specified in the Dockerfile times out)
NOTE: $HOME/tmp needs to exist; replace demosteveschmidt with your DockerHub username

```
$ docker run --rm --name tdhtools -v $HOME:$HOME:ro -v $HOME/tmp:$HOME/tmp:rw -e "KUBECONFIG=$HOME/.kube/config" -d demosteveschmidt/tdhtools:v0.1
```

Run a shell in the container

```
$ docker exec -it tdhtools /bin/bash
```

Run a command that exits

```
$ docker exec -it tdhtools kubectl get pods -A
```


TODO:

- tdhShell: Command to start the docker container and execute the command passed as parameters
