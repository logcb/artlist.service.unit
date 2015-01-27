Flightplan = require "flightplan"
flightplan = new Flightplan
flightplan.briefing
  destinations:
    "website": [{
      host: "artlist.website" # "104.236.246.144"
      username: "core"
      agent: process.env.SSH_AUTH_SOCK
      readyTimeout: 30000
    }]
    "xyz": [{
      host: "artlist.log.forêtboréale.xyz"
      username: "core"
      agent: process.env.SSH_AUTH_SOCK
      readyTimeout: 30000
    }]

flightplan.remote ["reboot"], (remote) ->
  remote.sudo("reboot --force --reboot")

flightplan.remote ["status", "inspect", "default"], (remote) ->
  remote.exec "id"
  remote.exec "df /"
  remote.exec "docker images"
  remote.exec "docker ps --all"
  remote.exec "docker info"
  remote.exec "systemctl status artlist"

flightplan.remote "start", (remote) ->
  remote.sudo "systemctl start artlist"
  remote.exec "systemctl status artlist"

flightplan.remote "stop", (remote) ->
  remote.sudo "systemctl stop artlist"
  remote.exec "systemctl status artlist", failsafe: true

flightplan.remote ["restart"], (remote) ->
  remote.sudo("systemctl stop artlist")
  remote.sudo("systemctl start artlist")
  remote.exec("systemctl status artlist")

flightplan.local ["setup", "make_certificates"], (local) ->
  local.exec("make")

flightplan.remote ["setup", "setup_public_folder"], (remote) ->
  if remote.exec("ls artlist", failsafe:yes, silent:yes).code isnt 0
    remote.log "Establishing artlist folder for publically accesible files"
    remote.exec "mkdir artlist"
  else
    remote.log "artlist folder for publically accesible files is established"

flightplan.remote ["setup", "setup_repo"], (remote) ->
  if remote.exec("ls artlist.git", failsafe:yes, silent:yes).code isnt 0
    remote.log "Making artlist.git to receive deploy commits"
    remote.exec("git init --bare artlist.git")
  else
    remote.log "artlist.git is established"

flightplan.local ["setup", "setup_repo"], (local) ->
  local.log "Adding post receive hook to artlist.git"
  local.transfer "git-post-receive-hook", "artlist.git/hooks/post-receive"

flightplan.local ["setup", "build"], (local) ->
  imageFiles = [
    "artlist_image/Dockerfile"
    "artlist_image/artlist.nginx.conf"
    "artlist_image/artlist.website.certificates.pem"
    "artlist_image/artlist.website.secret.key"
  ]
  local.log "Transfering artlist_image files:", JSON.stringify(imageFiles)
  local.transfer imageFiles, "/home/core"

flightplan.remote ["setup", "build"], (remote) ->
  remote.log "Building /home/core/artlist_image"
  remote.exec "docker build --tag artlist_image /home/core/artlist_image"
  remote.exec "docker images"
  remote.log "Removing build files"
  remote.exec "rm -rf artlist_image"

flightplan.local ["setup", "setup_service"], (local) ->
  local.log "Transfering artlist.service unit file"
  local.transfer "artlist.service", "/home/core"

flightplan.remote ["setup", "setup_service"], (remote) ->
  remote.log "Linking artlist service with systemd"
  remote.sudo "systemctl link /home/core/artlist.service"

flightplan.remote ["erase"], (remote) ->
  remote.exec("rm -rf artlist")
  remote.exec("rm -rf artlist.git")
  remote.exec("rm -rf artlist.service")

flightplan.remote ["erase", "clean", "remove_expired_docker_containers"], (remote) ->
  expiredContainerList = remote.exec("docker ps --all | grep Exited", {failsafe:yes}).stdout
  if expiredContainerList
    containerIDs = (entry.split(" ")[0] for entry in expiredContainerList.trim().split("\n")).join(" ")
    remote.log "Removing containers:", containerIDs
    remote.exec "docker rm #{containerIDs}"
  else
    remote.log "No expired docker containers."

flightplan.remote ["erase", "clean", "remove_expired_docker_images"], (remote) ->
  expiredImageList = remote.exec("docker images | grep '^<none>' | awk '{print $3}'", failsafe:yes).stdout
  if expiredImageList
    expiredImageIDs = (id for id in expiredImageList.trim().split("\n")).join(" ")
    console.info expiredImageIDs
    remote.log "Removing containers:", expiredImageIDs
    remote.exec("docker rmi #{expiredImageIDs}")
  else
    remote.log "No expired docker images."
