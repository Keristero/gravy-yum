### ubuntu setup
clone the repo
`git clone --recurse-submodules --remote-submodules https://github.com/Keristero/gravy-yum.git`

install rust + cargo (if you dont already have it)
`curl https://sh.rustup.rs -sSf | sh`
restart your terminal after install

get build essentials
`sudo apt install build-essential`

get libssl
`sudo apt install libssl-dev`

get pkg-config
`sudo apt-get install pkg-config`

now compile and run the server
`cd gravy-yum`
`./update-and-run.sh`

### auto backups
you will need nodejs
`npm install zip-a-folder`
`node autobackup.js`

every day at 1am a new zip will be created in backups/