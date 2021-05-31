# build the container from Dockerfile

# NOTE: change DOCKERHUB_USER with your dockerhub username

export DOCKERHUB_USER=demosteveschmidt

if [ ! -f ./kubectl ]
then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
fi

docker build -t $DOCKERHUB_USER/tdhtools:v0.1 .

docker push $DOCKERHUB_USER/tdhtools:v0.1
