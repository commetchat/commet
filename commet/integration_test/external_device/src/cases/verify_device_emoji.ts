import { MatrixClient } from "matrix-js-sdk";
import { VerificationRequest, VerificationRequestEvent } from "matrix-js-sdk/lib/crypto/verification/request/VerificationRequest";
function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}


export async function verifyMyDeviceEmoji(client: MatrixClient, deviceID: string): Promise<void> {
    var request = await client.requestVerification(client.getUserId()!, [deviceID]);

    request.on(VerificationRequestEvent.Change, async () => {
        console.log("CHANGED");
        if(request.done || request.cancelled){
            return;
        }

        if(request.started){
            await request.accept();
            const verifier = request.beginKeyVerification('m.sas.v1', {userId: client.getUserId()!, deviceId: deviceID});
            verifier.on('show_sas', async (sas_data : any)=>{
                console.log("Show sas");
                console.log(sas_data);
                await sas_data.confirm();
            })

        }

    });
}
  