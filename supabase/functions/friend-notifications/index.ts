import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }
import { corsHeaders } from '../_shared/cors.ts'

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
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  const payload: WebhookPayload = await req.json()
  const request = payload.record

  const from_user = (await supabase.from('users').select('username').eq('uid', request.from_user).single()).data
  const fcm_token = (await supabase.from('fcm_tokens').select('fcm_token').eq('user_id', request.to_user).single()).data.fcm_token

  const primaryRequest = (await supabase.from('friends').select().eq('from_user', request.to_user)).data
  let notification;
  if (primaryRequest) {
    notification = {
      title: `${user.username} одобрил заявку в друзья`,
    }
  } else {
    notification = {
      title: 'Новый запрос в друзья',
      body: `${user.username} хочет с вами подружиться`,
    }
  }

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })
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
          token: fcm_token,
          notification: notification,
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
  return new Response(JSON.stringify(resData), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
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