import "jsr:@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()
  const team = payload.record

  let users = (await supabase.from('members').select('member').eq('chat', team.id)).data.map(user => user.member)

  const team_size = users.length

  users = users.filter(user => {
    const isOnline = (await supabase.from('users').select('isOnline').eq('uid', user).single()).data.isOnline
    if (!isOnline) {
      return true
    }
    return false
  })
  
  const fcmTokens = await supabase.from('fcm_tokens').select('fcm_token').overlaps('user_id', users)

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })
  for (let token of fcmTokens) {
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
    JSON.stringify(data),
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