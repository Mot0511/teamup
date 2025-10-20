import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }

interface Notification {
  id: string
  user_id: string
  body: string
}
interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: Notification
  schema: 'public'
}
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)
Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()
  console.log(payload.record.text)
  const message = payload.record
  const chatID = message.chat
  const teamName = (await supabase.from('chats').select('name').eq('id', chatID).single()).data.name
  const users = await supabase.from('members').select('member').eq('chat', chatID)

  const fcmTokens = []
  for (const user of users.data.filter(user => user.member != payload.record.sender)) {
    const isOnline = (await supabase.from('users').select('isOnline').eq('uid', user.member).single()).data.isOnline
    if (!isOnline) {
      const fcmToken = await supabase.from('fcm_tokens').select('fcm_token').eq('user_id', user.member)
      if (fcmToken.data.length) {
        fcmTokens.push(fcmToken.data[0].fcm_token)
      }  
    }
  }
  const sender = await supabase.from('users').select('username').eq('uid', payload.record.sender).single();
  const storage = supabase.storage.from('main');

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })
  for (const token of fcmTokens) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: token,
            notification: {
              title: sender.data.username,
              body: payload.record.text,
            },
            android: {
              priority: "high",
            },
            data: {
              screen: teamName != null ? `team-${chatID}` : `chat-${chatID}`,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            }
          },
        }),
      }
    )
    const resData = await res.json()
    if (res.status < 200 || 299 < res.status) {
      throw resData
    }
  }
  return new Response(JSON.stringify(resData), {
    headers: { 'Content-Type': 'application/json' },
  })
})
const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}