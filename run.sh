cd Scriptable-OpenNetBattle-Server
git pull
cargo build --release
cp ./target/release/net_battle_server ../onb-server
cd ../onb-server
chmod +rwx ./run.sh
./net_battle_server