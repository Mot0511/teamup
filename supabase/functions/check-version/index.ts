import "jsr:@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (req) => {
  return new Response(
    JSON.stringify({
      currentVersion: "1.2.0",
      newFeatures: [
        "Создание публичных команд (может вступить кто угодно).",
        "Выбор своей любимой игры и изменение аватарки прямо на экране профиля.",
        "Прикрепление игры к команде.",
        "Исправлена проблема с выбором картинок (аватарок, вложений в сообщения, иконок команд).",
        "Нововведения на экране описания обновления смотрятся более аккуратно."
      ]
    }),
    { headers: { "Content-Type": "application/json" } },
  )
})