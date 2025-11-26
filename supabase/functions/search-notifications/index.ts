import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'npm:@supabase/supabase-js@2'
import serviceAccount from '../service-account.json' with { type: 'json' }
import { JWT } from 'npm:google-auth-library@9'

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
  const team = payload.record

  const {data: memberRows} = await supabase.from('members').select('member').eq('chat', team.id)
  const users = memberRows.map(m => m.member)

  const offlineUsers = []

  for (let user of users) {
    const {data: userRow} = await supabase.from('users').select('isOnline').eq('uid', user).single()

    if (!userRow?.isOnline) {
      offlineUsers.push(user)
    }
  }

  
  const fcmTokens = await supabase.from('fcm_tokens').select('fcm_token').in('user_id', offlineUsers)
  console.log(fcmTokens)
  console.log(team.name)
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })
  for (let row of fcmTokens.data) {
    const fcmToken = row.fcm_token

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
            token: fcmToken,
            notification: {
              title: 'Команда найдена',
            },
            android: {
              priority: "high",
            },
            data: {
              screen: `team-${team.id}`,
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


  return new Response(
    JSON.stringify({ok: true}),
    { headers: { "Content-Type": "application/json" } },
  )
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