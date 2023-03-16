import * as sdk from 'matrix-js-sdk';
import { verifyMyDeviceEmoji } from './cases/verify_device_emoji';


var olm = require('@matrix-org/olm');
var commander = require('commander');

global.Olm = olm;

commander
  .version('1.0.0', '-v, --version')
  .usage('[OPTIONS]...')
  .option('-h, --homeserver <string>', 'Homeserver to use for testing')
  .option('-u, --username <string>', 'Username to use for testing')
  .option('-p, --password <string>', 'password to use for testing')
  .option('-t, --test_case <string>', 'Named test case to use')
  .option('-d, --device_id <string>', 'ID of the device to be verified')
  .parse(process.argv);

const options = commander.opts();

async function login(){
    const loginClient = sdk.createClient({ baseUrl: options.homeserver });

    var result = await loginClient.login("m.login.password", {"user": options.username, "password": options.password});
    console.log(result);

    var client = sdk.createClient({ baseUrl: options.homeserver, userId: result.user_id, accessToken: result.access_token, deviceId: result.device_id })
    await client.initCrypto();
    client.startClient();
    return client;
}

async function main(){
    if(!options.homeserver) {
        console.log("Please provide a homeserver")
        return;
    }

    if(!options.username) {
        console.log("Please provide a username");
        return;
    }

    if(!options.password){
        console.log("Please provide a password");
        return
    }

    const client = await login();
    console.log(client);

    if(options.test_case == "verify_my_device_emoji") {
        await verifyMyDeviceEmoji(client, options.device_id);
    }
}


main();
console.log("DONE");