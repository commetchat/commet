import { MatrixClient } from "matrix-js-sdk";
import { Phase, VerificationRequest, VerificationRequestEvent } from "matrix-js-sdk/lib/crypto/verification/request/VerificationRequest";
function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}

export async function verify_me_with_emoji(client: MatrixClient, deviceID: string): Promise<void> {
    console.log("Running test case");
    var request = await client.requestVerification(client.getUserId()!, [deviceID]);
    console.log("Request sent");
    request.on(VerificationRequestEvent.Change, async () => {
        console.log("Request changed");
        console.log(request.phase);

        if(request.done || request.cancelled){
            return;
        }

        await request.accept();

        if(request.ready){
            console.log("Request ready");
            const verifier = request.beginKeyVerification('m.sas.v1', {userId: client.getUserId()!, deviceId: deviceID});
            console.log("Created verifier")
            verifier.on('show_sas', async (sas_data : any)=>{
                console.log("Show sas, confirming");
                await sas_data.confirm();
            })

            console.log("Verifying")
            await verifier.verify();
        }
    });
}
  