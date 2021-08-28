const { zip } = require('zip-a-folder');
const path = require('path')
const hour_ms = 1000*60*60
const memory_path = `./memory`
const backups_path = `./backups`

async function main(){
    let d = new Date()
    let new_backup_name = encodeURIComponent(`${d}.zip`)
    let backup_path = path.join(backups_path,new_backup_name)
    await zip(memory_path, backup_path);
    console.log(`backed up ${memory_path} as ${backup_path}`)
}

setInterval(()=>{
    let d = new Date()
    let hour = d.getHours()
    if(hour == 1){
        main(d)
    }
},hour_ms)