const sdk = require('matrix-js-sdk');
const commander = require('commander');

commander
  .version('1.0.0', '-v, --version')
  .usage('[OPTIONS]...')
  .option('-h, --homeserver <string>', 'Homeserver to use for testing')
  .option('-u, --username <string>', 'Username to use for testing')
  .option('-p, --password <string>', 'password to use for testing')
  .parse(process.argv);

options = commander.opts();

function main(){
    if(!options.homeserver)
    {
        console.log("Please provide a homeserver")
        return;
    }

    console.log(options.homeserver)

    if(!options.username){
        console.log("Please provide a username");
        return;
    }

    if(!options.password){
        console.log("Please provide a password");
        return
    }
    
    const client = sdk.createClient({ baseUrl: options.homeserver });
    client.login("m.login.password", {"user": options.username, "password": options.password}).then((response) => {
        console.log(response.access_token);
    });
    
}

main();